ad_page_contract {
    Add/Edit form for User Preferences.
    (Auto-generated by formwizard.tcl)

    @author Lars Pind (lars@pinds.com)
    @creation-date March 28, 2002
    @cvs-id $Id$
} {
    cancel:optional
    {return_url ""}
}

# If the user hit cancel, ignore everything else
if { [exists_and_not_null cancel] } {
    ad_returnredirect $return_url
    ad_script_abort
}

# User needs to be logged in here
ad_maybe_redirect_for_registration

ad_require_permission [ad_conn package_id] read

# Set some common bug-tracker variables
set project_name [bug_tracker::conn project_name]
set package_id [ad_conn package_id]
set package_key [ad_conn package_key]

set page_title "Your Preferences"

set context_bar [ad_context_bar $page_title]

set user_id [ad_conn user_id]



template::form create bt_user_prefs

template::element create bt_user_prefs user_version \
        -label "Your version" \
        -widget select \
        -datatype integer \
        -options [concat { { "None" "" } } \
        [db_list_of_lists versions { select version_name, version_id from bt_versions where project_id = :package_id order by anticipated_freeze_date, version_name }]] \
        -optional  

template::element create bt_user_prefs return_url \
        -datatype text \
        -widget hidden \
        -value $return_url

if { [template::form is_request bt_user_prefs] } {
    db_1row get_current_values {
        select user_version
        from   bt_user_prefs
        where  user_id = :user_id
        and    project_id = :package_id
    }
    template::element set_properties bt_user_prefs user_version -value $user_version
}

if { [template::form is_valid bt_user_prefs] } {
    # valid form submission

    set user_version [template::element::get_value bt_user_prefs user_version]

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
