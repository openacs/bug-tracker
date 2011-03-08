# packages/bug-tracker/www/related-file-delete.tcl

ad_page_contract {
    
    deletes a related file from a bug
    
    @author Deds Castillo (deds@i-manila.com.ph)
    @creation-date 2007-01-16
    @cvs-id $Id$
} {
    bug_id:notnull
    related_object_id:notnull
    return_url:optional
} -properties {
} -validate {
} -errors {
}

set package_id [ad_conn package_id]

# Get the bug_number
if { ![db_0or1row get_bug_number {}] } {
    ad_return_complaint 1 [_ bug-tracker.Bug_not_found_2]
    ad_script_abort
}

if {![exists_and_not_null return_url]} {
    set return_url [export_vars -base "bug" {bug_number}]
}

set bug_name [bug_tracker::conn Bug]
set bug_title "$bug_name #$bug_number"

set page_title "[_ bug-tracker.Delete_related_file]"
set context [list [list "$return_url" "$bug_title"] $page_title]

ad_form \
    -name delete_related \
    -export { bug_id related_object_id return_url } \
    -cancel_url $return_url \
    -form {
        {inform:text(inform) {label "[_ bug-tracker.Confirm_delete_related_file]"}}
    } -on_request {
        set inform "[_ bug-tracker.Confirm_delete_related_file_text]"
    } -on_submit {
        set rel_id [db_string get_rel_id {} -default 0]
        if {$rel_id} {
            db_transaction {
                db_dml delete_relation {}
                set filename [content::item::get_title -item_id $related_object_id -is_live t]
                content::item::delete -item_id $related_object_id

                set case_id [workflow::case::get_id \
                                 -object_id $bug_id \
                                 -workflow_short_name [bug_tracker::bug::workflow_short_name]]
                workflow::case::fsm::get -case_id $case_id -array case

                foreach available_enabled_action_id [workflow::case::get_available_enabled_action_ids -case_id $case_id] {
                    workflow::case::enabled_action_get -enabled_action_id $available_enabled_action_id -array enabled_action
                    workflow::action::get -action_id $enabled_action(action_id) -array available_action
                    if { [string eq $available_action(short_name) "comment"] } {
                        set action_id $enabled_action(action_id)
                        array set row [list]
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
                            -description "[_ bug-tracker.related_file_delete_comment]" \
                            -desc_format text/html \
                            -array row

                        break
                    }
                    
                }
            }
        }
    } -after_submit {
        ad_returnredirect $return_url
        ad_script_abort
    }

