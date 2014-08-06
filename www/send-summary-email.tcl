# packages/bug-tracker/www/send-summary-email.tcl
#
ad_page_contract {

    sends an email of the summary of selected bugs

    @author Deds Castillo (deds@i-manila.com.ph)
    @creation-date 2007-11-14
    @cvs-id $Id$
} {
    workflow_id:naturalnum,notnull
    {bug_id:naturalnum,optional,multiple ""}
    return_url:optional
}

set title "[_ bug-tracker.Send_Summary_Email]"
set context [list $title]
set package_id [ad_conn package_id]
set user_id [auth::require_login]
set sender_email [acs_user::get_element -user_id $user_id -element email]

if {(![info exists return_url] || $return_url eq "")} {
    set return_url "./"
}

if {![llength $bug_id]} {
    ad_returnredirect -message "[_ bug-tracker.No_selected_bugs]" $return_url
    ad_script_abort
} elseif {[llength $bug_id] == 1} {
    set bug_id [split [lindex $bug_id 0]]
}

set bug_pretty [bug_tracker::conn Bugs]
set bug_pretty_s [bug_tracker::conn Bug]

set dummy_case_id ""
set success_inform_text_list [list]
set error_inform_text_list [list]

foreach one_bug_id $bug_id {
    set found_p [db_string check_exists {} -default 0]
    
    if {!$found_p} {
        lappend error_inform_text_list "[_ bug-tracker.send_email_error] [_ bug-tracker.Bug_not_found_2]"
    } else {
        bug_tracker::bug::get -bug_id $one_bug_id -array bug_info
        lappend success_inform_text_list "[_ bug-tracker.send_email_success_inform]"
    }
}

set success_inform_text_stub [join $success_inform_text_list "<br>"]
set errors_inform_text_stub [join $error_inform_text_list "<br>"]

ad_form -name bug -cancel_url $return_url -export { return_url workflow_id } -form  {
    {success_inform_text_stub:text(inform)
        {label "[_ bug-tracker.send_summary_email_perform]"}
    }
    {errors_inform_text_stub:text(inform)
        {label "[_ bug-tracker.send_summary_email_errors]"}
    }
    {recipient_list:text
        {label "[_ bug-tracker.send_summary_email_Recipients]"}
        {help_text "[_ bug-tracker.send_summary_email_Recipients_help]"}
    }
    {bug_id:text(hidden)
        {label "[_ bug_tracker.ID]"}
    }
} -on_request {
} -on_submit {

    set p_keyword_id 0
    foreach {keyword_id keyword_label} [bug_tracker::category_types -package_id $package_id] {
        if {$keyword_label eq "[_ bug-tracker.Priority]"} {
            set p_keyword_id $keyword_id
        }
    }

    set package_instance_name [ad_conn instance_name]
    set subsite_instance_name [lang::util::localize "[subsite::get_element -element instance_name]"]

    # TODO: currently hardcoded html
    # need to convert to something more configurable
    
    set html_content "<p><b>[_ bug-tracker.send_summary_email_header]</b></p><table cellpadding=3><tr><td style=\"border:1px solid \#ddd;\">[bug_tracker::conn Bug] [_ bug-tracker.number_symbol]</td><td style=\"border:1px solid \#ddd;\">[_ bug-tracker.Summary]</td><td style=\"border:1px solid \#ddd;\">[_ bug-tracker.State]</td><td style=\"border:1px solid \#ddd;\">[_ bug-tracker.Assigned_To]</td><td style=\"border:1px solid \#ddd;\">Priority</td></tr>"

    db_foreach get_bugs "" {
        if {$cat_keyword_id == $p_keyword_id} {
            set bug_url [export_vars -base "[ad_url][ad_conn package_url]bug" {bug_number}]
            append html_content "<tr><td style=\"border:1px solid \#ddd;\">$bug_number</td><td style=\"border:1px solid \#ddd;\"><a href=\"$bug_url\">$summary</a></td><td style=\"border:1px solid \#ddd;\">$pretty_state</td><td style=\"border:1px solid \#ddd;\">$assignee_first_names $assignee_last_name</td><td style=\"border:1px solid \#ddd;\">$heading</td></tr>"
        }
    }
    append html_content "</table>"

    set final_recipient_list [list]
    foreach one_email [split $recipient_list " "] {
      set one_email [string trim $one_email]
      if {$one_email ne "" } {
           lappend final_recipient_list $one_email
      }
    }
    acs_mail_lite::send \
        -to_addr $final_recipient_list \
        -from_addr $sender_email \
        -subject "[_ bug-tracker.send_summary_email_subject]" \
        -body $html_content \
        -mime_type "text/html"

} -after_submit {
    ad_returnredirect $return_url
}

if { [form is_request bug] } {
    foreach field {success_inform_text_stub errors_inform_text_stub} {
        if {[set $field] eq ""} {
            element set_properties bug $field -widget hidden
        }
    }
}

