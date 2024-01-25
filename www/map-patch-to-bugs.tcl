ad_page_contract {
    Page for viewing and editing one patch.

    @author Peter Marklund (peter@collaboraid.biz)
    @creation-date 2002-09-04
    @cvs-id $Id$
} {
    patch_number:integer,notnull
    bug_number:integer,optional,multiple
    component_id:naturalnum,optional
    {show_all_components_p:boolean "0"}
    {show_only_open_p:boolean "1"}
    {offset:integer "0"}
    {interval_size "50"}
    cancel:optional
    {return_url:trim,notnull,localurl ""}
}


set package_id [ad_conn package_id]
set user_id [ad_conn user_id]
set redirect_url [expr {$return_url ne "" ? $return_url : "patch?patch_number=$patch_number"}]

bug_tracker::get_pretty_names -array pretty_names

if { [info exists cancel] && $cancel ne "" } {
    # The user chose to abort the mapping so redirect without further processing
    ad_returnredirect $redirect_url
    ad_script_abort
}

set write_p [permission::permission_p -object_id $package_id -privilege write]
set user_is_submitter_p [expr {$user_id == [bug_tracker::get_patch_submitter -patch_number $patch_number]}]

if { !($user_is_submitter_p || $write_p) } {
    ad_return_forbidden "[_ bug-tracker.Permission]" "[_ bug-tracker.You_1]"
    ad_script_abort
}


if { [info exists bug_number] && $bug_number ne "" } {
    # Do the mapping
    foreach one_bug_number $bug_number {
        set bug_id [db_string get_bug_id_for_number {}]
        set patch_id [db_string get_patch_id_for_number {}]

        bug_tracker::map_patch_to_bug -patch_id $patch_id -bug_id $bug_id
    }

    ad_returnredirect $redirect_url
    ad_script_abort
}

set patch_summary [db_string get_patch_summary {}]
set page_title "[_ bug-tracker.Mapping]"
set context [list "$page_title"]

# Build the component filter
if { ![info exists component_id] || $component_id eq "" } {
    set component_id [db_string component_id_for_patch {}]
}
set component_where_clause ""
set component_filter ""

set Component_name [bug_tracker::conn Component]
set Components_name [bug_tracker::conn Components]

if { $component_id ne "" } {
    set component_name [bug_tracker::component_get_name -component_id $component_id]
    set component_filter_url [export_vars -base map-patch-to-bugs {patch_number component_id return_url offset show_only_open_p interval_size}]
    if { $show_all_components_p } {
        set component_filter [subst {\[
            <a href="[ns_quotehtml $component_filter_url&show_all_components_p=0]">[_ bug-tracker.Only]</a> |
            [_ bug-tracker.All_1] \]}]
    } else {
        set component_where_clause "\n     and bt_bugs.component_id = :component_id"

        set component_filter [subst {\[
            [_ bug-tracker.Only_1] |
            <a href="[ns_quotehtml $component_filter_url&show_all_components_p=1]">[_ bug-tracker.All_1]</a> \]}]
    }
}

# Build the bug status filter
set workflow_id [bug_tracker::bug::get_instance_workflow_id]
set initial_state_id [workflow::fsm::get_initial_state -workflow_id $workflow_id]

set open_filter_url [export_vars -base map-patch-to-bugs {
    patch_number component_id return_url offset show_all_components_p interval_size
}]
set only_open_label [_ bug-tracker.Only_2]
set any_status_label [_ bug-tracker.Bugs]
if { $show_only_open_p } {
    set open_where_clause "and cfsm.current_state = :initial_state_id"
    set open_filter [subst {$only_open_label |
        <a href="[ns_quotehtml $open_filter_url&show_only_open_p=0]">$any_status_label</a>
    }]
} else {
    set open_where_clause ""
    set open_filter [subst {
        <a href="[ns_quotehtml $open_filter_url&show_only_open_p=1]">$only_open_label</a> |
        $any_status_label
    }]
}

set sql_where_clause "bt_bugs.project_id = :package_id
                  and bt_bugs.bug_id = cas.object_id
                  and cas.case_id = cfsm.case_id
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
set bug_count [db_string bug_count_for_mapping {}]

ns_set create pagination_export_var_set \
    patch_number          $patch_number \
    component_id          $component_id \
    return_url            $return_url \
    show_all_components_p $show_all_components_p \
    show_only_open_p      $show_only_open_p

db_multirow open_bugs select_open_bugs [subst -nocommands {
    select bt_bugs.bug_number,
           bt_bugs.summary,
           to_char(acs_objects.creation_date, 'YYYY-MM-DD HH24:MI:SS') as creation_date_pretty
      from bt_bugs, acs_objects, workflow_cases cas, workflow_case_fsm cfsm
     where bt_bugs.bug_id = acs_objects.object_id
       and $sql_where_clause
     order by acs_objects.creation_date desc
    offset :offset rows
    fetch first :interval_size rows only
}]

ad_return_template

# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
