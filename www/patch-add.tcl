ad_page_contract {
    Page with a form for adding a patch. If the page
    is requested without a bug number then the user
    will optionally be taken to a page where bugs
    that the patch covers can be chosen.

    @author Peter Marklund (peter@collaboraid.biz)
    @date 2002-09-10
    @cvs-id $Id$
} {
    bug_number:integer,optional
    cancel:optional
    component_id:optional
    {return_url ""}    
}

# If the user hit cancel, ignore everything else
if { [exists_and_not_null cancel] } {
    set bug_view_url "bug?[export_vars { bug_number }]"
    ad_returnredirect $bug_view_url
    ad_script_abort
}

ad_require_permission [ad_conn package_id] create

# User needs to be logged in here
ad_maybe_redirect_for_registration

# Set some common bug-tracker variables
set project_name [bug_tracker::conn project_name]
set package_id [ad_conn package_id]
set package_key [ad_conn package_key]
set page_title "New Patch"
set context_bar [ad_context_bar $page_title]
set user_id [ad_conn user_id]

# Create the form
form create patch -html { enctype multipart/form-data }

element create patch patch_id \
        -datatype integer \
        -widget hidden

element create patch component_id \
        -datatype integer \
        -widget select \
        -label "Component" \
        -options [bug_tracker::components_get_options]

element create patch summary  \
        -datatype text \
        -label "Summary" \
        -html { size 50 }

element create patch description  \
        -datatype text \
        -widget textarea \
        -label "Description" \
        -html { cols 50 rows 10 } \
        -optional

element create patch description_format \
                -datatype text \
                -widget select \
                -label "Description format" \
                -options { { "Plain" plain } { "HTML" html } { "Preformatted" pre } }

element create patch version_id \
        -datatype text \
        -widget select \
        -label "Generated from Version" \
        -options [bug_tracker::version_get_options -include_unknown] \
        -optional
    
element create patch patch_file \
        -datatype filename \
        -widget file \
        -label "Patch file:" \

if { [exists_and_not_null bug_number] } {
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
            -label "Choose Bugs for this Patch" \
            -options { {Yes 1} {No 0} } \
            -values { 1 }
}


if { [form is_request patch] } {
    # Form requested

    if { [exists_and_not_null bug_number] } {
        element set_properties patch bug_number -value $bug_number
    }

    element set_properties patch patch_id -value [db_nextval "acs_object_id_seq"]

    element set_properties patch version_id \
            -value [db_string user_version { select user_version from bt_user_prefs where user_id = :user_id and project_id = :package_id }]

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

        db_exec_plsql new_patch {
            select bt_patch__new(
                :patch_id,
                :package_id,
                :component_id,
                :summary,
                :description,
                :description_format,
                :content,
                :version_id,
                :user_id,
                :ip_address
            )
        }        

        # Redirect to the view page for the created patch by default
        if { [empty_string_p $return_url] } {
            set patch_number [db_string patch_number_for_id "select patch_number 
            from bt_patches 
            where patch_id = :patch_id"]

            set redirect_url "patch?[export_vars { patch_number }]"
        } else {
            set redirect_url $return_url
        }
        
        # Fetch any provided bug id to map the patch to
        catch {set bug_number [element get_value patch bug_number]}
        if { [info exists bug_number] } {
            # There is a bug id provided - map it to the patch
            set bug_id [bug_tracker::get_bug_id -bug_number $bug_number -project_id $package_id]
            bug_tracker::map_patch_to_bug -patch_id $patch_id -bug_id $bug_id

            # Trigger notifications for the bug that we are mapping to
            bug_tracker::bug_notify \
                -bug_id $bug_id \
                -action "patched" \
                -patch_summary $summary

        } else {
            # No bug id provided so redirect to page for selecting bugs if the
            # user wishes to go there
            set select_bugs_p [element get_value patch select_bugs_p]
            
            if { $select_bugs_p } {
                set redirect_url "map-patch-to-bugs?[export_vars -url { return_url patch_number component_id }]"
            }
        }
    }

    ad_returnredirect $redirect_url
    ad_script_abort
}

ad_return_template
