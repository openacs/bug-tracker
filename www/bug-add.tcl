ad_page_contract {
    Bug add page.
    
    @author Lars Pind (lars@pinds.com)
    @creation-date 2002-03-25
    @cvs-id $Id$
} {
    {return_url ""}
}

if { [empty_string_p $return_url] } {
    set return_url "."
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

form create bug -cancel_url .

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
            -value [bug_tracker::conn user_version_id]
    
    element set_properties bug severity -value [bug_tracker::severity_get_default]
    element set_properties bug priority -value [bug_tracker::priority_get_default]
    
    if { ![empty_string_p [bug_tracker::conn component_id]] } {
        element set_properties bug component_id -value [bug_tracker::conn component_id]
    }

    element set_properties bug desc_format -value "plain"

} 


if { [form is_valid bug] } {

    form get_values bug bug_id component_id bug_type severity priority found_in_version summary description desc_format
    
    bug_tracker::bug::new \
            -bug_id $bug_id \
            -package_id $package_id \
            -component_id $component_id \
            -bug_type $bug_type \
            -severity $severity \
            -priority $priority \
            -found_in_version $found_in_version \
            -summary $summary \
            -description $description \
            -desc_format $desc_format
    
    ad_returnredirect $return_url
    ad_script_abort
}

ad_return_template
