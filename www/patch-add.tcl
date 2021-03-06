ad_page_contract {
    Page with a form for adding a patch. If the page
    is requested without a bug number then the user
    will optionally be taken to a page where bugs
    that the patch covers can be chosen.

    @author Peter Marklund (peter@collaboraid.biz)
    @creation-date 2002-09-10
    @cvs-id $Id$
} {
    bug_number:integer,optional
    component_id:naturalnum,optional
    {return_url:notnull,trim ""}
} -validate {
    valid_return_url -requires return_url {
        # actually, one should use the page filter localurl from OpenACS 5.9
        if {[util::external_url_p $return_url]} {
            ad_complain "invalid return_url"
        }
    }
}

permission::require_permission -object_id [ad_conn package_id] -privilege create

if { $return_url eq "" } {
    if { [info exists bug_number] && $bug_number ne "" } {
        set return_url [export_vars -base bug { bug_number }]
    } else {
        set return_url "patch-list"
    }
}

# User needs to be logged in here
auth::require_login

# Set some common bug-tracker variables
set project_name [bug_tracker::conn project_name]
set package_id [ad_conn package_id]
set package_key [ad_conn package_key]
set page_title [_ bug-tracker.New_2]
set context [list $page_title]
set user_id [ad_conn user_id]

# Is this project using multiple versions?
set versions_p [bug_tracker::versions_p]

# Create the form
form create patch -html { enctype multipart/form-data } -cancel_url $return_url

element create patch patch_id \
        -datatype integer \
        -widget hidden

element create patch component_id \
        -datatype integer \
        -widget select \
        -label "[_ bug-tracker.Component]" \
        -options [bug_tracker::components_get_options]

element create patch summary  \
        -datatype text \
        -label "[_ bug-tracker.Summary]" \
        -html { size 50 }

element create patch description  \
        -datatype text \
        -widget textarea \
        -label "[_ bug-tracker.Description]" \
        -html { cols 50 rows 10 } \
        -optional

element create patch description_format \
                -datatype text \
                -widget select \
                -label "[_ bug-tracker.Description_1]" \
    -options [list [list [_ bug-tracker.Plain] plain] [list [_ bug-tracker.HTML] html] ]

element create patch version_id \
        -datatype text \
        -widget select \
        -label "[_ bug-tracker.Generated]" \
        -options [bug_tracker::version_get_options -include_unknown] \
        -optional

element create patch patch_file \
        -datatype file \
        -widget file \
        -label "[_ bug-tracker.Patch]" \

if { [info exists bug_number] && $bug_number ne "" } {
    # Export the bug number
    element create patch bug_number \
        -datatype integer \
        -widget hidden

} else {
    # There is no bug number.
    # Let the user indicate if he wants to select bugs that this
    # patch covers if no bug number was supplied
    element create patch select_bugs_p \
            -datatype text \
            -widget radio \
            -label "[_ bug-tracker.Choose_1]" \
            -options { {Yes 1} {No 0} } \
            -values { 1 }
}


if { [form is_request patch] } {
    # Form requested

    if { [info exists bug_number] && $bug_number ne "" } {
        element set_properties patch bug_number -value $bug_number
    }

    element set_properties patch patch_id -value [db_nextval "acs_object_id_seq"]

    element set_properties patch version_id \
            -value [bug_tracker::conn user_version_id]

    if { !$versions_p } {
        element set_properties patch version_id -widget hidden
    }

    if { [info exists component_id] } {
        element set_properties patch component_id -value $component_id
    }
}

if { [form is_valid patch] } {
    # Form submitted

    db_transaction {

        form get_values patch patch_id component_id summary description description_format version_id patch_file

        # Get the file contents as a string
        set content [bug_tracker::get_uploaded_patch_file_content]

        set ip_address [ns_conn peeraddr]

        db_exec_plsql new_patch {}

        set patch_number [db_string patch_number_for_id {}]

        # Redirect to the view page for the created patch by default
        if { $return_url eq "" } {
            set redirect_url [export_vars -base patch { patch_number }]
        } else {
            set redirect_url $return_url
        }

        # Fetch any provided bug id to map the patch to
        catch {set bug_number [element get_value patch bug_number]}
        if { [info exists bug_number] } {
            # There is a bug id provided - map it to the patch
            set bug_id [bug_tracker::get_bug_id -bug_number $bug_number -project_id $package_id]
            bug_tracker::map_patch_to_bug -patch_id $patch_id -bug_id $bug_id

        } else {
            # No bug id provided so redirect to page for selecting bugs if the
            # user wishes to go there
            set select_bugs_p [element get_value patch select_bugs_p]

            if { $select_bugs_p } {
                set redirect_url [export_vars -base map-patch-to-bugs { return_url patch_number component_id }]
            }
        }
    }

    ad_returnredirect $redirect_url
    ad_script_abort
}

ad_return_template

# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
