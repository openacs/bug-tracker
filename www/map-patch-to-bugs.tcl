ad_page_contract {
    Page for viewing and editing one patch.

    @author Peter Marklund (peter@collaboraid.biz)
    @date 2002-09-04
    @cvs-id $Id$
} {
    patch_number:integer,notnull
    bug_number:integer,optional,multiple    
    component_id:integer,optional
    {show_all_components_p "0"}
    {show_only_open_p "1"}
    {offset:integer "0"}
    {interval_size "50"}
    cancel:optional
    {return_url ""}
}

set package_id [ad_conn package_id]
set user_id [ad_conn user_id]
set redirect_url [ad_decode $return_url "" "patch?patch_number=$patch_number" $return_url]

if { [exists_and_not_null cancel] } {
    # The user chose to abort the mapping so redirect without further processing
    ad_returnredirect $redirect_url
    ad_script_abort
}

set write_p [ad_permission_p $package_id write]
set user_is_submitter_p [expr $user_id == [bug_tracker::get_patch_submitter -patch_number $patch_number]]

if { ![expr $user_is_submitter_p || $write_p] } {            
    ad_return_forbidden "Security Violation" "You do not have permission to map this patch to a bug. Only the submitter of the patch and users with write permission on this Bug Tracker project (package instance) may do so."            
    ad_script_abort
}


if { [exists_and_not_null bug_number] } {
    # Do the mapping
    foreach one_bug_number $bug_number {
        set bug_id [db_string get_bug_id_for_number "select bug_id from bt_bugs where bug_number = :one_bug_number and project_id = :package_id"]
        set patch_id [db_string get_patch_id_for_number "select patch_id from bt_patches where patch_number = :patch_number and project_id = :package_id"]

        bug_tracker::map_patch_to_bug -patch_id $patch_id -bug_id $bug_id
    }

    ad_returnredirect $redirect_url
    ad_script_abort
}

set patch_summary [db_string get_patch_summary "select summary from bt_patches where patch_number = :patch_number and project_id = :package_id"]
set page_title "Mapping Patch #$patch_number \"$patch_summary\" to a Bug"
set context_bar [ad_context_bar "$page_title"]

# Build the component filter
if { ![exists_and_not_null component_id] } {
    set component_id [db_string component_id_for_patch "select component_id from bt_patches where patch_number = :patch_number and project_id = :package_id"]
}
set component_where_clause ""
set component_filter ""
if { ![empty_string_p $component_id] } {
    set component_name [db_string component_name "select component_name from bt_components where component_id = :component_id"]
    set component_filter_url "map-patch-to-bugs?[export_vars -url {patch_number component_id return_url offset show_only_open_p interval_size}]"
    if { $show_all_components_p } {
        set component_filter "\[ <a href=\"$component_filter_url&show_all_components_p=0\">Only Component \"$component_name\"</a> | All Components \]"
    } else {
        set component_where_clause "\n     and bt_bugs.component_id = :component_id"
    
        set component_filter "\[ Only Component \"$component_name\" | <a href=\"$component_filter_url&show_all_components_p=1\">All Components</a> \]"
    }
}

# Build the bug status filter
set open_filter_url "map-patch-to-bugs?[export_vars -url {patch_number component_id return_url offset show_all_components_p interval_size}]"
set only_open_label "Only Open Bugs"
set any_status_label "Bugs of any Status"
if { $show_only_open_p } {
    set open_where_clause "and bt_bugs.status = 'open'"
    set open_filter "$only_open_label | <a href=\"$open_filter_url&show_only_open_p=0\">$any_status_label</a>"
} else {
    set open_where_clause ""
    set open_filter "<a href=\"$open_filter_url&show_only_open_p=1\">$only_open_label</a> | $any_status_label"
}

set sql_where_clause "bt_bugs.project_id = :package_id
                      $open_where_clause
                      $component_where_clause
                  and bt_bugs.bug_id not in (select bug_id
                                             from bt_patch_bug_map
                                             where patch_id = (select patch_id
                                                               from bt_patches
                                                               where patch_number = :patch_number
                                                                 and project_id = :package_id
                                                               )
                                             )"

# Build the pagination filter
set bug_count [db_string bug_count_for_mapping \
        "select count(*)
         from bt_bugs
         where $sql_where_clause"]
set pagination_export_var_set [ad_tcl_vars_to_ns_set patch_number component_id return_url show_all_components_p show_only_open_p] 

db_multirow open_bugs select_open_bugs \
        "select bt_bugs.bug_number,
                bt_bugs.summary,
                to_char(acs_objects.creation_date, 'fmMM/DDfm/YYYY') as creation_date_pretty                
                from bt_bugs, acs_objects
                where bt_bugs.bug_id = acs_objects.object_id
                 and  $sql_where_clause
               order by acs_objects.creation_date desc
               limit $interval_size offset $offset"

ad_return_template
