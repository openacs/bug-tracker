# packages/bug-tracker/www/related-file-add.tcl

ad_page_contract {
    
    attach a related file to a bug
    
    @author Deds Castillo (deds@i-manila.com.ph)
    @creation-date 2007-01-15
    @cvs-id $Id$
} {
    bug_number:integer,notnull
    return_url:optional,trim,notnull
} -properties {
} -validate {
    valid_return_url -requires return_url {
	# actually, one should use the page filter localurl from OpenACS 5.9
	if {[util::external_url_p $return_url]} {
	    ad_complain "invalid return_url"
	}
    }
} -errors {
}

set package_id [ad_conn package_id]

if {![info exists return_url]} {
    set return_url [export_vars -base "bug" {bug_number}]
}

set bug_title "[bug_tracker::conn Bug] #$bug_number"

set page_title "[_ bug-tracker.Upload_related_file]"
set context [list [list "$return_url" "$bug_title"] $page_title]

# Get the bug_id
if { ![db_0or1row get_bug_id {} -column_array bug] } {
    ad_return_complaint 1 [_ bug-tracker.Bug_not_found]
    ad_script_abort
}

array set bt_project_info [bug_tracker::get_project_info]

ad_form \
    -name related \
    -html {enctype multipart/form-data} \
    -export { bug_number return_url } \
    -form {
        {upload_file:file(file) {label "[_ bug-tracker.Related_File_File]"}}
        {description:text(textarea),optional {label "[_ bug-tracker.Related_File_Description]"} {html "rows 5 cols 35"}}
        {folder_id:integer(hidden)}
        {bug_id:integer(hidden),optional}
    } -on_request {
        set folder_id $bt_project_info(project_folder_id)
        set bug_id $bug(bug_id)
    } -validate {
        {upload_file
            {([info exists upload_file] && $upload_file ne "")}
            "[_ bug-tracker.Related_File_File_required]"
        }
    } -after_submit {
        db_transaction {
            set filename [template::util::file::get_property filename $upload_file]
            set revision_id [content::item::upload_file \
                                 -parent_id $folder_id \
                                 -upload_file $upload_file]

            # prevent cross-site scripting
            set description [ad_html_to_text -showtags -no_format -- $description]
            db_dml update_revision_description {}

            set target_object_id [content::revision::item_id -revision_id $revision_id]
            application_data_link::new -this_object_id $bug_id -target_object_id $target_object_id
            
            set case_id [workflow::case::get_id \
                             -object_id $bug_id \
                             -workflow_short_name [bug_tracker::bug::workflow_short_name]]

            workflow::case::fsm::get -case_id $case_id -array case

            foreach available_enabled_action_id [workflow::case::get_available_enabled_action_ids -case_id $case_id] {
                workflow::case::enabled_action_get -enabled_action_id $available_enabled_action_id -array enabled_action
                workflow::action::get -action_id $enabled_action(action_id) -array available_action
                if {$available_action(short_name) eq "comment"} {
                    set action_id $enabled_action(action_id)
                    array set row {}
                    foreach field [workflow::action::get_element -action_id $action_id -element edit_fields] {
                        set row($field) ""
                    }
                    foreach {category_id category_name} [bug_tracker::category_types] {
                        set row($category_id) ""
                    }
                    set bug_pretty [bug_tracker::conn bug]
                    bug_tracker::bug::edit \
                        -bug_id $bug_id \
                        -user_id [ad_conn user_id] \
                        -enabled_action_id $available_enabled_action_id \
                        -description "[_ bug-tracker.related_file_new_comment]" \
                        -desc_format text/html \
                        -array row
                    
                    break
                }
            }
        }

        ad_returnredirect $return_url
        ad_script_abort
    }

