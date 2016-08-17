ad_page_contract { 
    Bug-Tracker project admin page.
    
    @author Lars Pind (lars@pinds.com)
    @creation-date 2002-03-26
    @cvs-id $Id$
} {
}

set project_name [bug_tracker::conn project_name]
set package_id [ad_conn package_id]
set package_key [ad_conn package_key]
set page_title [_ bug-tracker.Administration]

set bugs_exist_p [bug_tracker::bugs_exist_p]

bug_tracker::get_pretty_names -array pretty_names

set versions_p [bug_tracker::versions_p]

set context_bar [ad_context_bar]

db_1row project_info { } -column_array project

set workflow_id [bug_tracker::bug::get_instance_workflow_id]

set project(maintainer_url) [acs_community_member_url -user_id $project(maintainer)]

set project_edit_url "project-edit"
set project_maintainer_edit_url "project-edit"
set versions_edit_url "versions"
set categories_edit_url "categories"
set permissions_edit_url "permissions"
set workflow_url [site_node::get_package_url -package_key workflow]
set workflow_edit_url [export_vars -base "${workflow_url}admin/workflow-edit" {workflow_id}]
set parameters_edit_url [export_vars -base /shared/parameters {
    { return_url "[ad_return_url]" }
    { package_id "[ad_conn package_id]" }
}]
set severity_codes_edit_url "severity-codes"
set priority_codes_edit_url "priority-codes"
set workflow_pretty_name [workflow::get_element -element pretty_name \
                             -workflow_id $workflow_id]
db_multirow -extend { edit_url delete_url maintainer_url view_bugs_url } components components {} {
    set edit_url [export_vars -base component-ae { component_id }]
    if { $num_bugs == 0 } {
        set delete_url [export_vars -base component-delete { component_id }]
        set view_bugs_url {}
    } else {
        set view_bugs_url [export_vars -base ../ { { filter.component_id $component_id } { filter.status any } }]
        set delete_url {}
    }
    set maintainer_url [acs_community_member_url -user_id $maintainer]
}

set component_add_url "component-ae"
set access_edit_url "access-policy-edit"
set access_policy_name [lindex [bug_tracker::access_policy] 0]
