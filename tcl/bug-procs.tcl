
ad_library {

    Bug Tracker Bug Library
    
    Procedures that deal with a single bug

    @creation-date 2003-01-10
    @author Lars Pind <lars@collaboraid.biz>
    @cvs-id $Id$

}

namespace eval bug_tracker::bug {}

namespace eval bug_tracker::bug::capture_resolution_code {}
namespace eval bug_tracker::bug::format_log_title {}
namespace eval bug_tracker::bug::get_component_maintainer {}
namespace eval bug_tracker::bug::get_project_maintainer {}
namespace eval bug_tracker::bug::notification_info {}

ad_proc -public bug_tracker::bug::workflow_short_name {} {
    Get the short name of the workflow for bugs
} {
    return "bug"
}

ad_proc -public bug_tracker::bug::object_type {} {
    Get the short name of the workflow for bugs
} {
    return "bt_bug"
}

ad_proc -public bug_tracker::bug::get {
    {-bug_id:required}
    {-array:required}
    {-action_id {}}
} {
    Get the fields for a bug
} {
    # Select the info into the upvar'ed Tcl Array
    upvar $array row

    db_1row select_bug_data {} -column_array row

    # Get the case ID, so we can get state information
    set case_id [workflow::case::get_id \
            -object_id $bug_id \
            -workflow_short_name [bug_tracker::bug::workflow_short_name]]

    # Derived fields
    set row(bug_number_display) "#$row(bug_number)"
    set row(component_name) [bug_tracker::component_get_name -component_id $row(component_id)]
    set row(found_in_version_name) [bug_tracker::version_get_name -version_id $row(found_in_version)]
    set row(fix_for_version_name) [bug_tracker::version_get_name -version_id $row(fix_for_version)]
    set row(fixed_in_version_name) [bug_tracker::version_get_name -version_id $row(fixed_in_version)]


    # Get state information
    workflow::case::fsm::get -case_id $case_id -array case -action_id $action_id
    set row(pretty_state) $case(pretty_state)
    if { ![empty_string_p $row(resolution)] } {
        append row(pretty_state) " ([bug_tracker::resolution_pretty $row(resolution)])"
    }
    set row(state_short_name) $case(state_short_name)
    set row(hide_fields) $case(state_hide_fields)
    set row(entry_id) $case(entry_id)

}

ad_proc -public bug_tracker::bug::insert {
    -bug_id:required
    -package_id:required
    -component_id:required
    -found_in_version:required
    -summary:required
    -description:required
    -desc_format:required
    {-user_agent ""}
    {-user_id ""}
    {-ip_address ""}
    {-item_subtype "bt_bug"}
    {-content_type "bt_bug_revision"}
} {
    Inserts a new bug into the content repository.
    You probably don't want to run this yourself - to create a new bug, use bug_tracker::bug::new
    and let it do the hard work for you.

    @see bug_tracker::bug::new
    @return bug_id The same bug_id passed in, just for convenience.
    
} {
    if { ![exists_and_not_null user_agent] } {
        set user_agent [ns_set get [ns_conn headers] "User-Agent"]
    }

    set comment_content $description
    set comment_format $desc_format

    if { ![exists_and_not_null creation_date] } {
        set creation_date [db_string select_sysdate {}]
    }

    set extra_vars [ns_set create]
    oacs_util::vars_to_ns_set \
        -ns_set $extra_vars \
        -var_list { bug_id package_id component_id found_in_version summary user_agent comment_content comment_format creation_date }

    set bug_id [package_instantiate_object \
                    -creation_user $user_id \
                    -creation_ip $ip_address \
                    -extra_vars $extra_vars \
                    -package_name "bt_bug" \
                    "bt_bug"]
    
    return $bug_id
}

ad_proc -public bug_tracker::bug::new {
    -bug_id:required
    -package_id:required
    -component_id:required
    -found_in_version:required
    -summary:required
    -description:required
    -desc_format:required
    {-user_agent ""}
    {-user_id ""}
    {-ip_address ""}
    {-item_subtype "bt_bug"}
    {-content_type "bt_bug_revision"}
} {
    Create a new bug, then send out notifications, starts workflow, etc.

    Calls bug_tracker::bug::insert.
    
    @see bug_tracker::bug::insert.
    @return bug_id The same bug_id passed in, just for convenience.
} {
    
    db_transaction {

        set bug_id [bug_tracker::bug::insert \
                -bug_id $bug_id \
                -package_id $package_id \
                -component_id $component_id \
                -found_in_version $found_in_version \
                -summary $summary \
                -description $description \
                -desc_format $desc_format \
                -user_agent $user_agent \
                -user_id $user_id \
                -ip_address $ip_address \
                -item_subtype $item_subtype \
                -content_type $content_type \
                ]

        workflow::case::new \
                -workflow_id [workflow::get_id -object_id $package_id -short_name [workflow_short_name]] \
                -object_id $bug_id \
                -comment $description \
                -comment_mime_type $desc_format \
                -user_id $user_id
    }
    
    return $bug_id
}


ad_proc -public bug_tracker::bug::update {
    -bug_id:required
    {-user_id ""}
    {-creation_ip ""}
    -array:required
} {
    Update a bug in the DB. Usually, you'll want to use bug_tracker::bug::edit 
    because that one sends out notifications, etc.

    @see bug_tracker::bug::edit
    @return bug_id The same bug_id passed in, just for convenience.
} {
    upvar $array row

    if { ![exists_and_not_null user_id] } {
        set user_id [ad_conn user_id]
    }

    get -bug_id $bug_id -array new_row

    foreach column [array names row] {
        set new_row($column) $row($column)
    }
    set new_row(creation_user) $user_id
    set new_row(creation_ip) $creation_ip

    foreach name [array names new_row] {
        set $name $new_row($name)
    }
    set revision_id [db_exec_plsql update_bug {}]

    return $bug_id
}



ad_proc -public bug_tracker::bug::edit {
    -bug_id:required
    -action_id:required
    {-user_id ""}
    {-creation_ip ""}
    -description:required
    -desc_format:required
    -array:required
    {-entry_id {}}
} {
    Edit a bug, then send out notifications, etc.

    Calls bug_tracker::bug::update.
   
    @see bug_tracker::bug::update
    @return bug_id The same bug_id passed in, just for convenience.
} {
    upvar $array row
    
    array set assignments [list]
    
    set role_prefix "role_"
    foreach name [array names row "${role_prefix}*"] {
        set assignments([string range $name [string length $role_prefix] end]) $row($name)
        unset row($name)
    }
    
    db_transaction {
        # Update the bug info
        update \
                -bug_id $bug_id \
                -user_id $user_id \
                -creation_ip $creation_ip \
                -array row

        # Update the keywords
        foreach {category_id category_name} [bug_tracker::category_types] {
            if { [info exists row($category_id)] } {
                cr::keyword::item_assign -singular -item_id $bug_id -keyword_id $row($category_id)
            }
            # LARS:
            # We don't unassign if no value is supplied for one of the categories
            # we just leave them untouched.
        }

        set case_id [workflow::case::get_id \
                -workflow_short_name [workflow_short_name] \
                -object_id $bug_id]

        # Assignments
        workflow::case::role::assign \
                -replace \
                -case_id $case_id \
                -array assignments
        
        workflow::case::action::execute \
                -case_id $case_id \
                -action_id $action_id \
                -comment $description \
                -comment_mime_type $desc_format \
                -user_id $user_id \
                -entry_id $entry_id

    }
    return $bug_id
}


ad_proc -public bug_tracker::bug::get_watch_link {
    {-bug_id:required}
} {
    Get link for watching a bug.
    @return 3-tuple of url, label and title.
} {
    set user_id [ad_conn user_id]
    set return_url [util_get_current_url]
    
    # Get the type id
    set type "workflow_case"
    set type_id [notification::type::get_type_id -short_name $type]

    # Check if subscribed
    set request_id [notification::request::get_request_id \
                        -type_id $type_id \
                        -object_id $bug_id \
                        -user_id $user_id]

    set subscribed_p [expr ![empty_string_p $request_id]]
        
    if { !$subscribed_p } {
        set url [notification::display::subscribe_url \
                     -type $type \
                     -object_id $bug_id \
                     -url $return_url \
                     -user_id $user_id \
                     -pretty_name "this bug"]
        set label "Watch this bug"
        set title "Request notifications for all activity on this bug"
    } else {
        set url [notification::display::unsubscribe_url -request_id $request_id -url $return_url]
        set label "Stop watching this bug"
        set title "Unsubscribe to notifications for activity on this bug"
    }
    return [list $url $label $title]
}

ad_proc -private bug_tracker::bug::workflow_create {} {
    Create the 'bug' workflow for bug-tracker
} {
    set spec {
        bug {
            pretty_name "Bug"
            package_key "bug-tracker"
            object_type "bt_bug"
            callbacks { 
                bug-tracker.FormatLogTitle 
                bug-tracker.BugNotificationInfo
            }
            roles {
                submitter {
                    pretty_name "Submitter"
                    callbacks { 
                        workflow.Role_DefaultAssignees_CreationUser
                    }
                }
                assignee {
                    pretty_name "Assignee"
                    callbacks {
                        bug-tracker.ComponentMaintainer
                        bug-tracker.ProjectMaintainer
                        workflow.Role_PickList_CurrentAssignees
                        workflow.Role_AssigneeSubquery_RegisteredUsers
                    }
                }
            }
            states {
                open {
                    pretty_name "Open"
                    hide_fields { resolution fixed_in_version }
                }
                resolved {
                    pretty_name "Resolved"
                }
                closed {
                    pretty_name "Closed"
                }
            }
            actions {
                open {
                    pretty_name "Open"
                    pretty_past_tense "Opened"
                    new_state "open"
                    initial_action_p t
                }
                comment {
                    pretty_name "Comment"
                    pretty_past_tense "Commented"
                    allowed_roles { submitter assignee }
                    privileges { read write }
                    always_enabled_p t
                }
                edit {
                    pretty_name "Edit"
                    pretty_past_tense "Edited"
                    allowed_roles { submitter assignee }
                    privileges { write }
                    always_enabled_p t
                    edit_fields { 
                        component_id 
                        summary 
                        found_in_version
                        role_assignee
                        fix_for_version
                        resolution 
                        fixed_in_version 
                    }
                }
                reassign {
                    pretty_name "Reassign"
                    pretty_past_tense "Reassigned"
                    allowed_role { submitter assignee }
                    privileges { write }
                    enabled_states { resolved }
                    assigned_states { open }
                    edit_fields { role_assignee }
                }
                resolve {
                    pretty_name "Resolve"
                    pretty_past_tense "Resolved"
                    assigned_role "assignee"
                    enabled_states { resolved }
                    assigned_states { open }
                    new_state "resolved"
                    privileges { write }
                    edit_fields { resolution fixed_in_version }
                    callbacks { bug-tracker.CaptureResolutionCode }
                }
                close {
                    pretty_name "Close"
                    pretty_past_tense "Closed"
                    assigned_role "submitter"
                    assigned_states { resolved }
                    new_state "closed"
                    privileges { write }
                }
                reopen {
                    pretty_name "Reopen"
                    pretty_past_tense "Reopened"
                    allowed_roles { submitter }
                    enabled_states { resolved closed }
                    new_state "open"
                    privileges { write }
                }
            }
        }
    }

#     set spec {
#         bug {
#             pretty_name "Bug"
#             package_key "bug-tracker"
#             object_type "bt_bug"
#             callbacks { 
#                 bug-tracker.FormatLogTitle 
#                 bug-tracker.BugNotificationInfo
#             }
#             roles {
#                 submitter {
#                     pretty_name "Submitter"
#                     callbacks { 
#                         workflow.Role_DefaultAssignees_CreationUser
#                     }
#                 }
#                 assignee {
#                     pretty_name Assignee
#                     callbacks {
#                         bug-tracker.ComponentMaintainer
#                         bug-tracker.ProjectMaintainer
#                         workflow.Role_PickList_CurrentAssignees
#                         workflow.Role_AssigneeSubquery_RegisteredUsers
#                     }
#                 }
#             }
#             states {
#                 open {
#                     pretty_name "Open"
#                     hide_fields { resolution fixed_in_version }
#                 }
#                 resolved {
#                     pretty_name "Resolved"
#                 }
#                 closed {
#                     pretty_name "Closed"
#                 }
#             }
#             actions {
#                 open {
#                     pretty_name Open
#                     pretty_past_tense Opened
#                     new_state "open"
#                     initial_action_p t
#                 }
#                 comment {
#                     pretty_name Comment
#                     pretty_past_tense Commented
#                     allowed_roles { submitter assignee }
#                     privileges { read write }
#                     always_enabled_p t
#                 }
#                 edit {
#                     pretty_name Edit
#                     pretty_past_tense Edited
#                     allowed_roles { submitter assignee }
#                     privileges { write }
#                     always_enabled_p t
#                     edit_fields { 
#                         component_id 
#                         bug_type
#                         summary 
#                         severity
#                         priority
#                         found_in_version
#                         role_assignee
#                         fix_for_version
#                         resolution 
#                         fixed_in_version 
#                     }
#                 }
#                 reassign {
#                     pretty_name Reassign
#                     pretty_past_tense Reassigned
#                     allowed_role { submitter assignee }
#                     privileges { write }
#                     enabled_states { open resolved }
#                     edit_fields { role_assignee }
#                 }
#                 resolve {
#                     pretty_name Resolve
#                     pretty_past_tense Resolved
#                     assigned_role "assignee"
#                     enabled_states { resolved }
#                     assigned_states { open }
#                     new_state "resolved"
#                     privileges { write }
#                     edit_fields { resolution fixed_in_version }
#                     callbacks { bug-tracker.CaptureResolutionCode }
#                 }
#                 close {
#                     pretty_name Close
#                     pretty_past_tense Closed
#                     assigned_role "submitter"
#                     assigned_states { resolved }
#                     new_state "closed"
#                     privileges { write }
#                 }
#                 reopen {
#                     pretty_name Reopen
#                     pretty_past_tense Reopened
#                     allowed_roles { submitter }
#                     enabled_states { resolved closed }
#                     new_state "open"
#                     privileges { write }
#                 }
#             }
#         }
#     }
    set workflow_id [workflow::fsm::new_from_spec -spec $spec]
    
    return $workflow_id
}

ad_proc -private bug_tracker::bug::workflow_delete {} {
    Delete the 'bug' workflow for bug-tracker
} {
    set workflow_id [get_package_workflow_id]
    if { ![empty_string_p $workflow_id] } {
        workflow::delete -workflow_id $workflow_id
    }
}

ad_proc -public bug_tracker::bug::get_package_workflow_id {} { 
    Return the workflow_id for the package (not instance) workflow
} {
    return [workflow::get_id \
            -short_name [workflow_short_name] \
            -package_key [bug_tracker::package_key]]

}


ad_proc -public bug_tracker::bug::get_instance_workflow_id {
    {-package_id {}}
} { 
    Return the workflow_id for the package (not instance) workflow
} {
    if { [empty_string_p $package_id] } {
        set package_id [ad_conn package_id]
    }

    return [workflow::get_id \
            -short_name [workflow_short_name] \
            -object_id $package_id]
}

ad_proc -private bug_tracker::bug::instance_workflow_create {
    {-package_id:required}
} {
    Creates a clone of the default bug-tracker package workflow for a
    specific package instance 
} {
    set workflow_id [workflow::fsm::clone \
            -workflow_id [get_package_workflow_id] \
            -object_id $package_id]
    
    return $workflow_id
}

ad_proc -private bug_tracker::bug::instance_workflow_delete {
    {-package_id:required}
} {
    Deletes the instance workflow
} {
    workflow::delete -workflow_id [get_instance_workflow_id -package_id $package_id]
}




#####
#
# Capture resolution code
#
#####

ad_proc -private bug_tracker::bug::capture_resolution_code::pretty_name {} {
    return "Capture resolution code in the case activity log"
}

ad_proc -private bug_tracker::bug::capture_resolution_code::do_side_effect {
    case_id
    object_id
    action_id
    entry_id
} {
    db_dml insert_resolution_code {}
}

#####
#
# Format log title
#
#####

ad_proc -private bug_tracker::bug::format_log_title::pretty_name {} {
    return "Add resolution code to log title"
}

ad_proc -private bug_tracker::bug::format_log_title::format_log_title {
    case_id
    object_id
    action_id
    entry_id
    data_arraylist
} {
    array set data $data_arraylist

    if { [info exists data(resolution)] } {
        return [bug_tracker::resolution_pretty $data(resolution)]
    } else {
        return {}
    }
}

#####
#
# Get component maintainer
#
#####

ad_proc -private bug_tracker::bug::get_component_maintainer::pretty_name {} {
    return "Bug-tracker component maintainer"
}

ad_proc -private bug_tracker::bug::get_component_maintainer::get_assignees {
    case_id
    object_id
    role_id
} {
    return [db_string select_component_maintainer {} -default {}]
}

#####
#
# Project maintainer
#
#####

ad_proc -private bug_tracker::bug::get_project_maintainer::pretty_name {} {
    return "Bug-tracker project maintainer"
}

ad_proc -private bug_tracker::bug::get_project_maintainer::get_assignees {
    case_id
    object_id
    role_id
} {
    return [db_string select_project_maintainer {} -default {}]
}
    
#####
#
# Notification Info
#
#####

ad_proc -private bug_tracker::bug::notification_info::pretty_name {} {
    return "Bug-tracker bug info"
}

ad_proc -private bug_tracker::bug::notification_info::get_notification_info {
    case_id
    object_id
} {
    bug_tracker::bug::get -bug_id $object_id -array bug

    set url "[ad_url][apm_package_url_from_id $bug(project_id)]bug?[export_vars { { bug_number $bug(bug_number) } }]"

    bug_tracker::get_pretty_names -array pretty_names

    set notification_subject_tag [db_string select_notification_tag {} -default {}]

    set one_line "$pretty_names(Bug) #$bug(bug_number): $bug(summary)"

    # Build up data structures with the form labels and values
    # (Note, this is something that the metadata system should be able to do for us)

    array set label {
        summary "Summary"
        status "Status"
        found_in_version "Found in version"
        fix_for_version "Fix for version"
        fixed_in_version "Fixed in version"
    }

    set label(bug_number) "$pretty_names(Bug) #"
    set label(component) "$pretty_names(Component)"

    set fields {
        bug_number
        component
    }

    # keywords
    foreach { category_id category_name } [bug_tracker::category_types] {
        lappend fields $category_id
        set value($category_id) [bug_tracker::category_heading \
                                     -keyword_id [cr::keyword::item_get_assigned -item_id $bug(bug_id) -parent_id $category_id] \
                                     -package_id $bug(project_id)]
        set label($category_id) $category_name
    }

    lappend fields summary status 

    if { [bug_tracker::versions_p -package_id $bug(project_id)] } {
        lappend fields found_in_version fix_for_version fixed_in_version
    }

    set value(bug_number) $bug(bug_number)
    set value(component)  $bug(component_name)
    set value(summary) $bug(summary)
    set value(status) $bug(pretty_state)
    set value(found_in_version) [ad_decode $bug(found_in_version_name) "" "Unknown" $bug(found_in_version_name)]
    set value(fix_for_version) [ad_decode $bug(fix_for_version_name) "" "Undecided" $bug(fix_for_version_name)]
    set value(fixed_in_version) [ad_decode $bug(fixed_in_version_name) "" "Unknown" $bug(fixed_in_version_name)]

    # Remove fields that should be hidden in this state
    foreach field $bug(hide_fields) {
        set index [lsearch -exact $fields $field]
        if { $index != -1 } {
            set fields [lreplace $fields $index $index]
        }
    }
    
    # Build up the details list
    set details_list [list]
    foreach field $fields {
        lappend details_list $label($field) $value($field)
    }

    return [list $url $one_line $details_list $notification_subject_tag]
}
    