# packages/bug-tracker/www/bulk-update-op.tcl

ad_page_contract {
    
    performs a bulk action on bugs
    
    @author Deds Castillo (deds@i-manila.com.ph)
    @creation-date 2007-01-16
    @cvs-id $Id$
} {
    workflow_id:naturalnum,notnull
    op:notnull
    bug_id:naturalnum,notnull,multiple
    {return_url:optional,trim,notnull "./"}
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

set user_id [auth::require_login]
set package_id [ad_conn package_id]

if {[llength $bug_id] == 1} {
    set bug_id [split [lindex $bug_id 0]]
}

set action_id [workflow::action::get_id \
                   -workflow_id $workflow_id \
                   -short_name $op]

workflow::action::get -action_id $action_id -array action

set action_pretty_name [lang::util::localize $action(pretty_name)]
set action_short_name $action(short_name)

set bug_pretty [bug_tracker::conn Bugs]
set bug_pretty_s [bug_tracker::conn Bug]
set page_title "[_ bug-tracker.Bulk_update_op]"
set context [list $page_title]

##########
# DEDS: Generate some information on what actions will be performed
# for the selected bugs. The drawback of this is that there will be a
# set of steps to execute for each bug id to get the information. We
# need to do it because we do not predetermine enabled actions for
# each bug before the bulk action operation is submitted as that would
# be costly. If this proves to be costly as well then this can just be
# removed as it is still checked before the actual
# bug_tracker::bug::edit operation for each bug but doing that may
# need some changes to the code as well as this is the one that
# determines if a user have permission on at least one of the bugs
#
# Is there a better way to do this?
##########

set security_inform_text_list [list]
set success_inform_text_list [list]
set error_inform_text_list [list]

set dummy_case_id ""

foreach one_bug_id $bug_id {
    set found_p [db_string check_exists {} -default 0]
    
    if {!$found_p} {
        lappend error_inform_text_list "[_ bug-tracker.bulk_action_error] [_ bug-tracker.Bug_not_found_2]"
    } else {
        set case_id [workflow::case::get_id \
                         -object_id $one_bug_id \
                         -workflow_short_name [bug_tracker::bug::workflow_short_name]]

        bug_tracker::bug::get -bug_id $one_bug_id -array bug_info
                
        # check cached list first
        set action_id_list [workflow::case::get_enabled_actions -case_id $case_id]
        if {[lsearch $action_id_list $action_id] != -1} {
            set enabled_action_id [workflow::case::action::get_enabled_action_id \
                                       -case_id $case_id \
                                       -action_id $action_id \
                                       -any_parent]
            # Check permissions
            if { ![workflow::case::action::available_p -enabled_action_id $enabled_action_id] } {
                lappend security_inform_text_list "[_ bug-tracker.bulk_actions_security_no_perms]"
            } else {
                # assign dummy case id placeholder so that we can
                # generate assignee widgets when the op is reassign
                if {$dummy_case_id eq ""} {
                    set dummy_case_id $case_id
                }
                if {![array exists dummy_bug_info]} {
                    bug_tracker::bug::get -bug_id $one_bug_id -array dummy_bug_info -enabled_action_id $enabled_action_id
                }
                lappend success_inform_text_list "[_ bug-tracker.bulk_actions_success_inform]"
            }
        } else {
            lappend security_inform_text_list "[_ bug-tracker.bulk_actions_security_not_enabled]"
        }
    }
}

set success_inform_text_stub [join $success_inform_text_list "<br>"]
set security_inform_text_stub [join $security_inform_text_list "<br>"]
set errors_inform_text_stub [join $error_inform_text_list "<br>"]

set resolver_role_id [db_string get_resolver_role_id {} -default {}]

ad_form -name bug -cancel_url $return_url -export { return_url workflow_id op} -form  {
    {success_inform_text_stub:text(inform)
        {label "[_ bug-tracker.bulk_actions_perform]"}
    }
    {errors_inform_text_stub:text(inform)
        {label "[_ bug-tracker.bulk_actions_errors]"}
    }
    {security_inform_text_stub:text(inform)
        {label "[_ bug-tracker.bulk_actions_security_violations]"}
    }
    {resolution:text(select),optional
        {label "[_ bug-tracker.Resolution]"}
        {options {[bug_tracker::resolution_get_options]}}
        {mode display}
    }
    {fixed_in_version:text(select),optional
        {label "[_ bug-tracker.Fixed_in_Version]"}
        {options {[bug_tracker::version_get_options -include_undecided]}}
        {mode display}
    }
}

if { $dummy_case_id ne "" } {
    workflow::case::role::add_assignee_widgets -case_id $dummy_case_id -form_name bug -role_ids $resolver_role_id
} else {
    ad_form -extend -name bug -form {
        {role_resolver:text(hidden),optional}
    }
}

ad_form -extend -name bug -form {
    {description:richtext(richtext),optional
        {label "[_ bug-tracker.Description]"} 
        {html {cols 60 rows 13}} 
    }
    {bug_id:text(hidden)
        {label "[_ bug-tracker.ID]"}
    }
} -on_request {
} -on_submit {

    set description [element get_value bug description]

    foreach one_bug_id $bug_id {
        set found_p [db_string check_exists {} -default 0]
        
        if {$found_p} {
            set case_id [workflow::case::get_id \
                             -object_id $one_bug_id \
                             -workflow_short_name [bug_tracker::bug::workflow_short_name]]
            
            set action_id_list [workflow::case::get_enabled_actions -case_id $case_id]
            if {[lsearch $action_id_list $action_id] != -1} {
                set enabled_action_id [workflow::case::action::get_enabled_action_id \
                                           -case_id $case_id \
                                           -action_id $action_id \
                                           -any_parent]
                # last chance to check permissions
                if { [workflow::case::action::available_p -enabled_action_id $enabled_action_id] } {
                    array unset row
                    foreach field [workflow::action::get_element -action_id $action_id -element edit_fields] {
                        set row($field) [element get_value bug $field]
                    }
                    bug_tracker::bug::edit \
                        -bug_id $one_bug_id \
                        -enabled_action_id $enabled_action_id \
                        -description [template::util::richtext::get_property contents $description] \
                        -desc_format [template::util::richtext::get_property format $description] \
                        -array row \
                        -entry_id {}
                }
            }
        }
    }
} -after_submit {
    ad_returnredirect $return_url
}

if { [form is_request bug] } {
    foreach field {success_inform_text_stub security_inform_text_stub errors_inform_text_stub} {
        if {[set $field] eq ""} {
            element set_properties bug $field -widget hidden
        }
    }
}

if { ![form is_valid bug] } {
    set present_fields [workflow::action::get_element -action_id $action_id -element edit_fields]
    set all_fields {resolution fixed_in_version role_resolver}
    
    if {"resolution" ni $present_fields} {
        element set_properties bug resolution -options [concat {{{} {}}} [element get_property bug resolution options]]
    }

    foreach field $present_fields { 
        element set_properties bug $field -mode edit 
    }
    
    foreach field $all_fields {
        if {[lsearch $present_fields $field] == -1 || $dummy_case_id eq ""} {
            element set_properties bug $field -widget hidden
        }
    }

    # Is this project using multiple versions?
    if {![bug_tracker::versions_p]} {
        element set_properties bug fixed_in_version -widget hidden
    }

}
