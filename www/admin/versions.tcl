ad_page_contract { 
    Bug-Tracker versions admin page.
    
    @author Lars Pind (lars@pinds.com)
    @date 2002-03-26
    @cvs-id $Id$
} {
}

set project_name [bug_tracker::conn project_name]
set package_id [ad_conn package_id]
set package_key [ad_conn package_key]

set context_bar [ad_context_bar "Versions"]

set version_add_url "version-ae?[export_vars -url { { return_url "versions" } }]"

set return_url "versions"

db_multirow -extend { actual_release_date maintainer_url edit_url delete_url } current_version current_version {
    select v.version_id,
           v.version_name,
           v.description,
           v.anticipated_freeze_date,
           v.actual_freeze_date,
           v.anticipated_release_date,
           v.maintainer,
           u.first_names as maintainer_first_names,
           u.last_name as maintainer_last_name,
           u.email as maintainer_email,
           v.supported_platforms,
           v.active_version_p,
           v.assignable_p,
           case when v.assignable_p = 't' then 'Yes' else 'No' end as assignable_p_pretty
    from   bt_versions v left outer join 
           cc_users u on (u.user_id = v.maintainer)
    where  v.project_id = :package_id
    and    v.active_version_p = 't'
} { 
    set edit_url "version-ae?[export_vars -url { version_id return_url }]"
    set delete_url "version-delete?[export_vars -url { version_id return_url }]"
    set maintainer_url [acs_community_member_url -user_id $maintainer]
}

db_multirow -extend { actual_release_date maintainer_url edit_url delete_url set_active_url } future_version future_versions {
    select v.version_id,
           v.version_name,
           v.description,
           v.anticipated_freeze_date,
           v.actual_freeze_date,
           v.anticipated_release_date,
           v.maintainer,
           u.first_names as maintainer_first_names,
           u.last_name as maintainer_last_name,
           u.email as maintainer_email,
           v.supported_platforms,
           v.active_version_p,
           v.assignable_p,
           case when v.assignable_p = 't' then 'Yes' else 'No' end as assignable_p_pretty
    from   bt_versions v left outer join 
           cc_users u on (u.user_id = v.maintainer)
    where  v.project_id = :package_id
    and    v.actual_release_date is null
    and    v.active_version_p = 'f'
    order by v.anticipated_release_date, version_name
} { 
    set edit_url "version-ae?[export_vars -url { version_id return_url }]"
    set delete_url "version-delete?[export_vars -url { version_id return_url }]"
    set maintainer_url [acs_community_member_url -user_id $maintainer]
    set set_active_url "version-set-active?[export_vars -url { version_id return_url }]"
}

db_multirow -extend { maintainer_url edit_url delete_url } past_version past_versions {
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
           v.assignable_p,
           case when v.assignable_p = 't' then 'Yes' else 'No' end as assignable_p_pretty
    from   bt_versions v left outer join 
           cc_users u on (u.user_id = v.maintainer)
    where  v.project_id = :package_id
    and    v.actual_release_date is not null
    order by v.actual_release_date, version_name
} { 
    set edit_url "version-ae?[export_vars -url { version_id return_url }]"
    set delete_url "version-delete?[export_vars -url { version_id return_url }]"
    set maintainer_url [acs_community_member_url -user_id $maintainer]
}

ad_return_template



