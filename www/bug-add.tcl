ad_page_contract {
    Bug add page.
    
    @author Lars Pind (lars@pinds.com)
    @creation-date 2002-03-25
    @cvs-id $Id$
} {
    cancel:optional
    {return_url ""}
}

if { [empty_string_p $return_url] } {
    set return_url "."
}

# If the user hit cancel, ignore everything else
if { [exists_and_not_null cancel] } {
    ad_returnredirect $return_url
    ad_script_abort
}

ad_require_permission [ad_conn package_id] create

# User needs to be logged in here
ad_maybe_redirect_for_registration

# Set some common bug-tracker variables
set project_name [bug_tracker::conn project_name]
set package_id [ad_conn package_id]
set package_key [ad_conn package_key]

set page_title "New Bug"

set context_bar [bug_tracker::context_bar $page_title]

set user_id [ad_conn user_id]


# Create the form

form create bug

element create bug bug_id \
        -datatype integer \
        -widget hidden

element create bug component_id \
        -datatype integer \
        -widget select \
        -label "Component" \
        -options [bug_tracker::components_get_options]

element create bug bug_type \
        -datatype text \
        -widget select \
        -label "Type of bug" \
        -options [bug_tracker::bug_type_get_options] \
        -optional

element create bug summary  \
        -datatype text \
        -label "Summary" \
        -html { size 50 }

element create bug severity \
        -datatype integer \
        -widget select \
        -label "Severity" \
        -options [bug_tracker::severity_codes_get_options] \
        -optional

element create bug priority \
        -datatype integer \
        -widget select \
        -label "Priority" \
        -options [bug_tracker::priority_codes_get_options] \
        -optional

element create bug found_in_version \
        -datatype integer \
        -widget select \
        -label "Version" \
        -options [bug_tracker::version_get_options -include_unknown] \
        -optional

element create bug description  \
        -datatype text \
        -widget textarea \
        -label "Description" \
        -html { cols 50 rows 10 } \
        -optional

element create bug desc_format \
        -datatype text \
        -widget select \
        -label "Description format" \
        -options { { "Plain" plain } { "HTML" html } { "Preformatted" pre } }

element create bug return_url \
        -datatype text \
        -widget hidden \
        -value $return_url


if { [form is_request bug] } {

    element set_properties bug bug_id -value [db_nextval "acs_object_id_seq"]

    element set_properties bug found_in_version \
            -value [db_string user_version { select user_version from bt_user_prefs where user_id = :user_id and project_id = :package_id }]
    
    element set_properties bug severity -value [bug_tracker::severity_get_default]
    element set_properties bug priority -value [bug_tracker::priority_get_default]
    
    if { ![empty_string_p [bug_tracker::conn component_id]] } {
        element set_properties bug component_id -value [bug_tracker::conn component_id]
    }

    element set_properties bug desc_format -value "plain"

} 


if { [form is_valid bug] } {

    db_transaction {

        form get_values bug bug_id component_id bug_type severity priority found_in_version summary description desc_format
        
        set ip_address [ns_conn peeraddr]
        set user_agent [ns_set get [ns_conn headers] "User-Agent"]

        db_exec_plsql new_bug {
            select bt_bug__new(
                :bug_id,
                :package_id,
                :component_id,
                :bug_type,
                :severity,
                :priority,
                :found_in_version,
                :summary,
                :description,
                :desc_format,
                :user_agent,
                :user_id,
                :ip_address
            )
        }

    }
    
    bug_tracker::bug_notify -bug_id $bug_id -action "open" -comment $description -comment_format $desc_format

    # Sign up the submitter of the bug for instant alerts. We do this after calling
    # the alert procedure so that the submitter isn't alerted about his own submittal of the bug
    bug_tracker::add_instant_alert -bug_id $bug_id -user_id $user_id

    ad_returnredirect $return_url
    ad_script_abort
}

ad_return_template
