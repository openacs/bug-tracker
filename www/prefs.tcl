ad_page_contract {
    Add/Edit form for User Preferences.
    (Auto-generated by formwizard.tcl)

    @author Lars Pind (lars@pinds.com)
    @creation-date March 28, 2002
    @cvs-id $Id$
} {
    {return_url "."}
}

# User needs to be logged in here
auth::require_login

ad_require_permission [ad_conn package_id] read

# Set some common bug-tracker variables
set project_name [bug_tracker::conn project_name]
set package_id [ad_conn package_id]
set package_key [ad_conn package_key]

set page_title "[_ bug-tracker.Your]"

set context [list $page_title]

set user_id [ad_conn user_id]

ad_form -name prefs -cancel_url $return_url -form {
    {user_version:integer(select),optional
        {label "[_ bug-tracker.Your_1]"}
        {options {[bug_tracker::version_get_options -include_unknown]}}
    }
    {return_url:text(hidden)
        {value $return_url}
    }
} -on_request {
    db_0or1row select_data {
        select user_version
        from   bt_user_prefs
        where  user_id = :user_id
        and    project_id = :package_id
    }
} -after_submit {
    set user_version [element get_value prefs user_version]
    db_dml update_row {
        update bt_user_prefs
        set    user_version = :user_version
        where  user_id = :user_id
        and    project_id = :package_id
    }

    bug_tracker::get_user_prefs_flush -package_id $package_id -user_id $user_id

    ad_returnredirect $return_url
    ad_script_abort
}
