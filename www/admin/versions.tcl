ad_page_contract { 
    Bug-Tracker versions admin page.
    
    @author Lars Pind (lars@pinds.com)
    @creation-date 2002-03-26
    @cvs-id $Id$
} {
}

set project_name [bug_tracker::conn project_name]
set package_id [ad_conn package_id]
set package_key [ad_conn package_key]

set context_bar [ad_context_bar "[_ bug-tracker.Versions]"]

set version_add_url [export_vars -base version-ae { { return_url "versions" } }]

set return_url "versions"

set yes [_ acs-kernel.common_Yes]
set no  [_ acs-kernel.common_No]

db_multirow -extend {
    maintainer_url
    edit_url
    delete_url
    release_url
    assignable_p_pretty
    maintainer_first_names
    maintainer_last_name
    maintainer_email
} current_version current_version {} {
    set m [acs_user::get -user_id $maintainer]
    set maintainer_first_names [dict get $m first_names]
    set maintainer_last_name   [dict get $m last_name]
    set maintainer_email       [dict get $m email]

    set assignable_p_pretty [expr {$assignable_p ? $yes : $no}]
    
    set edit_url [export_vars -base version-ae { version_id return_url }]
    if { $num_bugs == 0 } {
        set delete_url [export_vars -base version-delete { version_id }]
    } else {
        set delete_url {}
    }
    set release_url [export_vars -base version-release { version_id }]
    set maintainer_url [acs_community_member_url -user_id $maintainer]
}

db_multirow -extend {
    maintainer_url
    edit_url
    delete_url
    set_active_url
    assignable_p_pretty
    maintainer_first_names
    maintainer_last_name
    maintainer_email
} future_version future_versions {} {
    set m [acs_user::get -user_id $maintainer]
    set maintainer_first_names [dict get $m first_names]
    set maintainer_last_name   [dict get $m last_name]
    set maintainer_email       [dict get $m email]

    set assignable_p_pretty [expr {$assignable_p ? $yes : $no}]
    
    set edit_url [export_vars -base version-ae { version_id return_url }]
    if { $num_bugs == 0 } {
        set delete_url [export_vars -base version-delete { version_id }]
    } else {
        set delete_url {}
    }
    set maintainer_url [acs_community_member_url -user_id $maintainer]
    set set_active_url [export_vars -base version-set-active { version_id return_url }]
}

db_multirow -extend {
    maintainer_url
    edit_url
    delete_url
    assignable_p_pretty    
    maintainer_first_names
    maintainer_last_name
    maintainer_email    
} past_version past_versions {} {
    set m [acs_user::get -user_id $maintainer]
    set maintainer_first_names [dict get $m first_names]
    set maintainer_last_name   [dict get $m last_name]
    set maintainer_email       [dict get $m email]

    set assignable_p_pretty [expr {$assignable_p ? $yes : $no}]    
    
    set edit_url [export_vars -base version-ae { version_id return_url }]
    if { $num_bugs == 0 } {
        set delete_url [export_vars -base version-delete { version_id }]
    } else {
        set delete_url {}
    }
    set maintainer_url [acs_community_member_url -user_id $maintainer]
}

