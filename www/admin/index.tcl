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

set context_bar [ad_context_bar]

db_1row project_info { 
    select p.maintainer,
           u.first_names as maintainer_first_names,
           u.last_name as maintainer_last_name,
           u.email as maintainer_email
    from   bt_projects p left outer join 
           cc_users u on (u.user_id = p.maintainer)
    where  p.project_id = :package_id
} -column_array project
set project(maintainer_url) [acs_community_member_url -user_id $project(maintainer)]

set project_edit_url "project-edit"
set project_maintainer_edit_url "project-maintainer-edit"
set versions_edit_url "versions"
set permissions_edit_url "/permissions/one?[export_vars -url { { object_id {[ad_conn package_id]} } }]"
set severity_codes_edit_url "severity-codes"
set priority_codes_edit_url "priority-codes"

db_multirow -extend { edit_url delete_url maintainer_url view_bugs_url } components components { 
    select c.component_id,
           c.component_name,
           c.description,
           c.maintainer,
           u.first_names as maintainer_first_names,
           u.last_name as maintainer_last_name,
           u.email as maintainer_email,
           (select count(*) from bt_bugs where component_id = c.component_id) as num_bugs
    from   bt_components c left outer join 
           cc_users u on (u.user_id = c.maintainer)
    where  c.project_id = :package_id
    order  by upper(component_name)
} {
    set edit_url "component-ae?[export_vars -url { component_id }]"
    if { $num_bugs == 0 } {
        set delete_url "component-delete?[export_vars -url { component_id }]"
    } else {
        set view_bugs_url "../?[export_vars { { filter.component_id $component_id } }]"
    }
    set maintainer_url [acs_community_member_url -user_id $maintainer]
}

set component_add_url "component-ae"

db_multirow versions versions {
    select v.version_id,
           v.version_name,
           v.description,
           v.anticipated_freeze_date,
           v.actual_freeze_date,
           v.anticipated_release_date,
           v.actual_release_date,
           v.maintainer,
           u.first_names as maintainer_first_names,
           u.last_name as maintainer_last_name,
           u.email as maintainer_email,
           v.supported_platforms,
           v.active_version_p,
           v.assignable_p
    from   bt_versions v left outer join 
           cc_users u on (u.user_id = v.maintainer)
    where  v.project_id = :package_id
}


ad_return_template



