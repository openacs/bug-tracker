ad_page_contract {
    Page that lists patches in this Bug Tracker
    project.

    @author Peter Marklund (peter@collaboraid.biz)
    @date 2002-09-10
    @cvs-id $Id$
} {
    {component_id:integer ""}
    {version_id:integer ""}
    {offset:integer "0"}
    {interval_size "50"}
}

set package_id [ad_conn package_id]
set user_id [ad_conn user_id]

set page_title "Patch List"
set context_bar [ad_context_bar $page_title]

# Create the component filter
set component_filter_list [list]
if { [empty_string_p $component_id] } {
    lappend component_filter_list "All Components"
} else {
    lappend component_filter_list "<a href=\"patch-list?[export_vars -url -override {{component_id {}}} {version_id}]\">All Components</a>"
}
db_foreach components_for_patches {
    select bt_components.component_id as loop_component_id,
           bt_components.component_name
      from bt_components
      where exists (select 1 from bt_patches
                    where bt_patches.component_id = bt_components.component_id)
} {
    
    if { $component_id == $loop_component_id } {
        lappend component_filter_list "$component_name"
    } else {
        lappend component_filter_list "<a href=\"patch-list?[export_vars -url -override {{component_id $loop_component_id}} {version_id}]\">$component_name</a>"
    }
}
set component_filter [join $component_filter_list " | "]
if { ![empty_string_p $component_id] } {
    set component_where_clause "and bt_patches.component_id = :component_id"
} else {
    set component_where_clause ""
}


# Create the apply to version filter
set version_filter_list [list]
if { [empty_string_p $version_id] } {
    lappend version_filter_list "All Versions"
} else {
    lappend version_filter_list "<a href=\"patch-list?[export_vars -url -override {{version_id {}}} {component_id}]\">All Versions</a>"
}
db_foreach versions_for_patches {
    select version_id as loop_version_id,
           version_name
      from bt_versions
     where exists (select 1 from bt_patches
                    where apply_to_version = bt_versions.version_id)
} {

    if { $version_id == $loop_version_id } {
        lappend version_filter_list "$version_name"
    } else {
        lappend version_filter_list "<a href=\"patch-list?[export_vars -url -override {{version_id $loop_version_id}} {component_id}]\">$version_name</a>"
    }
}
set version_filter [join $version_filter_list " | "]
if { ![empty_string_p $version_id] } {
    set version_where_clause "           and bt_patches.apply_to_version = :version_id"
} else {
    set version_where_clause ""
}


# Create the pagination filter
set where_clause "bt_patches.project_id = :package_id
           $component_where_clause   
           $version_where_clause"
set patch_count [db_string patch_count "select count(*)
                                        from bt_patches
                                        where $where_clause"]
set pagination_export_var_set [ad_tcl_vars_to_ns_set component_id version_id]

db_multirow patch_list patch_list "
    select bt_patches.patch_number,
           bt_patches.summary,
           bt_patches.status,
           to_char(acs_objects.creation_date, 'fmMM/DDfm/YYYY') as creation_date_pretty
    from   bt_patches,
           acs_objects
    where  bt_patches.patch_id = acs_objects.object_id
           and $where_clause
    order  by acs_objects.creation_date desc
"

ad_return_template
