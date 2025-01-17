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

ad_proc -public bug_tracker::bug::cache_flush {
    -bug_id:required
} {
    Flush all list builder instances and other appropriate things for the given bug-tracker
    package instance.
} {
    set project_id [db_string get_project_id {}]
    template::cache flush "bugs,project_id=$project_id,*"
    util_memoize_flush_regexp -log "^bug_tracker::.*_get_filter_data_not_cached -package_id $project_id"
}

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
    {-enabled_action_id {}}
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
    set row(bug_number_display) "$row(bug_number)"
    set row(component_name) [bug_tracker::component_get_name -component_id $row(component_id) -package_id $row(project_id)]
    set row(found_in_version_name) [bug_tracker::version_get_name -version_id $row(found_in_version) -package_id $row(project_id)]
    set row(fix_for_version_name) [bug_tracker::version_get_name -version_id $row(fix_for_version) -package_id $row(project_id)]
    set row(fixed_in_version_name) [bug_tracker::version_get_name -version_id $row(fixed_in_version) -package_id $row(project_id)]

    # Get state information
    workflow::case::fsm::get -case_id $case_id -array case -enabled_action_id $enabled_action_id
    set row(pretty_state) $case(pretty_state)
    if { $row(resolution) ne "" } {
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
    {-fix_for_version ""}
    {-assign_to ""}
} {
    Inserts a new bug into the content repository.
    You probably don't want to run this yourself - to create a new bug, use bug_tracker::bug::new
    and let it do the hard work for you.

    @see bug_tracker::bug::new
    @return bug_id The same bug_id passed in, just for convenience.

} {
    if { $user_agent eq "" && [ad_conn isconnected] } {
        set user_agent [ns_set get [ns_conn headers] "User-Agent"]
    }

    set comment_content $description
    set comment_format $desc_format

    if { ![info exists creation_date] || $creation_date eq "" } {
        set creation_date [db_string select_sysdate {}]
    }

    set extra_vars [ns_set create]
    oacs_util::vars_to_ns_set \
        -ns_set $extra_vars \
        -var_list { bug_id package_id component_id found_in_version summary
                    user_agent comment_content comment_format creation_date
                    fix_for_version assign_to}


    set bug_id [package_instantiate_object \
                    -creation_user $user_id \
                    -creation_ip $ip_address \
                    -extra_vars $extra_vars \
                    -package_name "bt_bug" \
                    "bt_bug"]

    cache_flush -bug_id $bug_id

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
    {-keyword_ids {}}
    {-fix_for_version {}}
    {-assign_to ""}
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
                -fix_for_version $fix_for_version ]

        foreach keyword_id $keyword_ids {
            content::keyword::item_assign -item_id $bug_id -keyword_id $keyword_id
        }

        set assignment [list]
        if {$assign_to ne ""} {
            lappend assignment "resolver" $assign_to
        }

        set case_id [workflow::case::new \
                -workflow_id [workflow::get_id -object_id $package_id -short_name [workflow_short_name]] \
                -object_id $bug_id \
                -comment $description \
                -comment_mime_type $desc_format \
                -user_id $user_id \
                -assignment $assignment \
                -package_id $package_id]

        if {[lindex [bug_tracker::access_policy] 1] eq "user_bugs"} {
            bug_tracker::grant_direct_read_permission -bug_id $bug_id -party_id $user_id
        }

        return $bug_id
    }
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

    if { $user_id eq "" } {
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

    cache_flush -bug_id $bug_id

    return $bug_id
}



ad_proc -public bug_tracker::bug::edit {
    -bug_id:required
    -enabled_action_id:required
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
            if { [info exists row($category_id)] && $row($category_id) ne "" } {
                content::keyword::item_assign -item_id $bug_id -keyword_id $row($category_id)
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
                -enabled_action_id $enabled_action_id \
                -comment $description \
                -comment_mime_type $desc_format \
                -user_id $user_id \
                -entry_id $entry_id

    }
    return $bug_id
}


ad_proc bug_tracker::bug::delete { bug_id } {
    Delete a Bug Tracker bug.
    This should only ever be run when un-instantiating a project!

    @author Mark Aufflick
} {

    # Probably not necessary if developers follow the instructions in the
    # header comment ...
    cache_flush -bug_id $bug_id

    set case_id [db_string get_case_id {}]
    db_exec_plsql delete_bug_case {}

    content::item::delete -item_id $bug_id
}


ad_proc -public bug_tracker::bug::get_watch_link {
    {-bug_id:required}
} {
    Get link for watching a bug.
    @return 3-tuple of url, label and title.
} {
    set user_id [ad_conn user_id]
    set return_url [ad_return_url]

    # Get the type id
    set type "workflow_case"
    set type_id [notification::type::get_type_id -short_name $type]
    # get some i18n text
    set bug_name "[bug_tracker::conn bug]"

    # Check if subscribed
    set request_id [notification::request::get_request_id \
                        -type_id $type_id \
                        -object_id $bug_id \
                        -user_id $user_id]

    set subscribed_p [expr {$request_id ne ""}]

    if { !$subscribed_p } {
        set url [notification::display::subscribe_url \
                     -type $type \
                     -object_id $bug_id \
                     -url $return_url \
                     -user_id $user_id \
                     -pretty_name "[_ bug-tracker.this_bug]"]
        set label "[_ bug-tracker.watch_this_bug]"
        set title "[_ bug-tracker.request_notification_for_bug]"
    } else {
        set url [notification::display::unsubscribe_url -request_id $request_id -url $return_url]
        set label "[_ bug-tracker.stop_watching_bug]"
        set title "[_ bug-tracker.unsubscribe_to_bug]"
    }
    return [list $url $label $title]
}

ad_proc -private bug_tracker::bug::workflow_create {} {
    Create the 'bug' workflow for bug-tracker
} {
    set spec {
        bug {
            pretty_name "#bug-tracker.Bug#"
            package_key "bug-tracker"
            object_type "bt_bug"
            callbacks {
                bug-tracker.FormatLogTitle
                bug-tracker.BugNotificationInfo
            }
            roles {
                submitter {
                    pretty_name "#bug-tracker.Submitter#"
                callbacks {
                        workflow.Role_DefaultAssignees_CreationUser
                    }
                }
                resolver {
                    pretty_name "#bug-tracker.Resolver#"
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
                    pretty_name "#bug-tracker.state_open#"
                    hide_fields { resolution fixed_in_version }
                }
                resolved {
                    pretty_name "#bug-tracker.Resolved#"
                }
                closed {
                    pretty_name "#bug-tracker.Closed#"
                }
            }
            actions {
                open {
                    pretty_name "#bug-tracker.action_open#"
                    pretty_past_tense "#bug-tracker.Opened#"
                    new_state open
                    initial_action_p t
                }
                comment {
                    pretty_name "#bug-tracker.Comment#"
                    pretty_past_tense "#bug-tracker.Commented#"
                    allowed_roles { submitter resolver }
                    privileges { read write }
                    always_enabled_p t
                }
                edit {
                    pretty_name "#acs-kernel.common_Edit#"
                    pretty_past_tense "#bug-tracker.Edited#"
                    allowed_roles { submitter resolver }
                    privileges { write }
                    always_enabled_p t
                    edit_fields {
                        component_id
                        summary
                        found_in_version
                        role_resolver
                        fix_for_version
                        resolution
                        fixed_in_version
                    }
                }
                reassign {
                    pretty_name "#bug-tracker.Reassign#"
                    pretty_past_tense "#bug-tracker.Reassigned#"
                    allowed_roles { submitter resolver }
                    privileges { write }
                    enabled_states { resolved }
                    assigned_states { open }
                    edit_fields { role_resolver }
                }
                resolve {
                    pretty_name "#bug-tracker.Resolve#"
                    pretty_past_tense "#bug-tracker.Resolved#"
                    assigned_role resolver
                    enabled_states { resolved }
                    assigned_states { open }
                    new_state resolved
                    privileges { write }
                    edit_fields { resolution fixed_in_version }
                    callbacks { bug-tracker.CaptureResolutionCode }
                }
                close {
                    pretty_name "#bug-tracker.Close#"
                    pretty_past_tense "#bug-tracker.Closed#"
                    assigned_role submitter
                    assigned_states { resolved }
                    new_state closed
                    privileges { write }
                }
                reopen {
                    pretty_name "#bug-tracker.Reopen#"
                    pretty_past_tense "#bug-tracker.Reopened#"
                    allowed_roles { submitter }
                    enabled_states { resolved closed }
                    new_state open
                    privileges { write }
                }
            }
        }
    }

    set workflow_id [workflow::fsm::new_from_spec -spec $spec]

    return $workflow_id
}

ad_proc -private bug_tracker::bug::workflow_delete {} {
    Delete the 'bug' workflow for bug-tracker
} {
    set workflow_id [get_package_workflow_id]
    if { $workflow_id ne "" } {
        workflow::delete -workflow_id $workflow_id
    }
}

ad_proc -public bug_tracker::bug::get_package_workflow_id {} {
    Return the workflow_id for the package (not instance) workflow
} {
    return [workflow::get_id \
            -short_name [workflow_short_name] \
            -package_key bug-tracker]

}


ad_proc -public bug_tracker::bug::get_instance_workflow_id {
    {-package_id {}}
} {
    Return the workflow_id for the package (not instance) workflow
} {
    if { $package_id eq "" } {
        set package_id [ad_conn package_id]
    }
    return [db_string get_instance_workflow_id {}]
}

ad_proc -private bug_tracker::bug::instance_workflow_create {
    {-package_id:required}
    -workflow_id
} {
    Creates a clone of the given workflow for a specific package instance, or reassign
    an existing clone if it already exists.
} {
    if { ![info exists workflow_id] } {
        set workflow_id [get_package_workflow_id]
    }

    if { ![db_0or1row get_workflow_id {}] } {
        # The workflow package only allows one instance of a workflow to be bound to
        # a given object.  If the workflow doesn't exist for this package instance,
        # we clone the package workflow.  If it does, we just reuse the existing clone.
        set workflow_id [workflow::fsm::clone \
                -workflow_id $workflow_id \
                -object_id $package_id]
    }

    db_dml update_project {}

    return $workflow_id
}

ad_proc -private bug_tracker::bug::instance_workflow_delete {
    {-package_id:required}
} {
    Deletes the instance workflow
} {
    workflow::delete -workflow_id [get_instance_workflow_id -package_id $package_id]
    db_dml update_project {}
}


#####
#
# Capture resolution code
#
#####

ad_proc -private bug_tracker::bug::capture_resolution_code::pretty_name {} {
    return "[_ bug-tracker.Capture]"
}

ad_proc -private bug_tracker::bug::capture_resolution_code::do_side_effect {
    case_id
    object_id
    action_id
    entry_id
} {
    workflow::case::add_log_data \
        -entry_id $entry_id \
        -key resolution \
        -value [db_string select_resolution_code {}]
}

#####
#
# Format log title
#
#####

ad_proc -private bug_tracker::bug::format_log_title::pretty_name {} {
    return "[_ bug-tracker.Add_3]"
}

ad_proc -private bug_tracker::bug::format_log_title::format_log_title {
    case_id
    object_id
    action_id
    entry_id
    data
} {
    if { [dict exists $data resolution] } {
        return [bug_tracker::resolution_pretty [dict get $data resolution]]
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
    return "[_ bug-tracker.Bug-tracker]"
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
    return "[_ bug-tracker.Bug-tracker_1]"
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
    return "[_ bug-tracker.Bug-tracker_2]"
}

ad_proc -private bug_tracker::bug::notification_info::get_notification_info {
    case_id
    object_id
} {
    bug_tracker::bug::get -bug_id $object_id -array bug

    set url [export_vars -base "[ad_url]/[apm_package_url_from_id $bug(project_id)]bug" {
        { bug_number $bug(bug_number) }
    }]

    bug_tracker::get_pretty_names -array pretty_names

    set notification_subject_tag [db_string select_notification_tag {} -default {}]

    set one_line "$pretty_names(Bug) $bug(summary)"

    # Build up data structures with the form labels and values
    # (Note, this is something that the metadata system should be able to do for us)

    array set label {
        summary "[_ bug-tracker.Summary]"
        status "[_ bug-tracker.Status]"
        found_in_version "[_ bug-tracker.Found]"
        fix_for_version "[_ bug-tracker.Fix]"
        fixed_in_version "[_ bug-tracker.Fixed_1]"
    }

    set label(bug_number) "$pretty_names(Bug) "
    set label(component) "$pretty_names(Component)"

    set fields {
        bug_number
        component
    }

    # keywords
    foreach { category_id category_name } [bug_tracker::category_types -package_id $bug(project_id)] {
        lappend fields $category_id
        set value($category_id) [bug_tracker::category_heading \
                                     -keyword_id [content::keyword::item_get_assigned -item_id $bug(bug_id) -parent_id $category_id] \
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
    set value(found_in_version) [ad_decode $bug(found_in_version_name) "" "[_ bug-tracker.Unknown]" $bug(found_in_version_name)]
    set value(fix_for_version) [ad_decode $bug(fix_for_version_name) "" "[_ bug-tracker.Undecided]" $bug(fix_for_version_name)]
    set value(fixed_in_version) [ad_decode $bug(fixed_in_version_name) "" "[_ bug-tracker.Unknown]" $bug(fixed_in_version_name)]

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


#####
#
# Bug list
#
#####

ad_proc bug_tracker::bug::get_list {
    {-ulevel 1}
    {-package_id {}}
    {-user_id {}}
    -no_bulk_actions:boolean
} {
    upvar \#[template::adp_level] admin_p admin_p
    if { $package_id eq "" } {
        set package_id [ad_conn package_id]
    }
    set workflow_id [bug_tracker::bug::get_instance_workflow_id -package_id $package_id]
    bug_tracker::get_pretty_names -array pretty_names -package_id $package_id

    set elements {
        bug_number {
            label "[bug_tracker::conn Bug] [_ bug-tracker.number_symbol]"
            display_template {[_ bug-tracker.number_symbol]@bugs.bug_number@}
            html { align right }
        }
        summary {
            label "[_ bug-tracker.Summary]"
            link_url_eval {[export_vars -base bug -entire_form -override { bug_number }]}
            display_template {@bugs.summary;noi18n@}
            aggregate_label {[_ bug-tracker.Number]}
        }
        comment {
            label "[_ bug-tracker.Details]"
            display_col comment_short
            hide_p 1
        }
        state {
            label "[_ bug-tracker.State]"
            display_template {@bugs.pretty_state@<if @bugs.resolution@ not nil> (@bugs.resolution_pretty@)</if>}
            aggregate count
        }
        creation_date_pretty {
            label "[_ bug-tracker.Submitted]"
        }
        submitter {
            label "[_ bug-tracker.Submitter]"
            display_template {<a href="@bugs.submitter_url@">@bugs.submitter_first_names@ @bugs.submitter_last_name@</a>}
        }
        assigned_to {
            label "Assigned To"
            display_template {<a href="@bugs.assignee_url@">@bugs.assignee_first_names@
                               @bugs.assignee_last_name@</a>
                               <if @bugs.action_pretty_name@ not nil> to </if>
                               @bugs.action_pretty_name@}
        }
    }

    if { [bug_tracker::versions_p] } {
        lappend elements fix_for_version {
            label "[_ bug-tracker.Fix_1]"
            display_col fix_for_version_name
        }
    }

    lappend elements component {
        label "[_ bug-tracker.Component]"
        display_col component_name
    }

    set state_values [bug_tracker::state_get_filter_data \
                         -package_id $package_id \
                         -workflow_id $workflow_id \
                         -user_id $user_id \
                         -admin_p $admin_p]
    set state_default_value [lindex $state_values 0 1]

    set filters {
        project_id {}
        f_state {
            label "[_ bug-tracker.State]"
            values $state_values
            where_clause {cfsm.current_state = :f_state}
            default_value $state_default_value
        }
    }

    set orderbys {
        default_value bug_number,desc
        bug_number {
            label "[bug_tracker::conn Bug] \#"
            orderby bug_number
            default_direction desc
        }
        summary {
            label "[_ bug-tracker.Summary]"
            orderby_asc {lower_summary asc, summary asc, bug_number asc}
            orderby_desc {lower_summary desc, summary desc, bug_number desc}
        }
        submitter {
            label "[_ bug-tracker.Submitter]"
            orderby_asc {lower_submitter_first_names asc, lower_submitter_last_name asc, bug_number asc}
            orderby_desc {lower_submitter_first_names desc, lower_submitter_last_name desc, bug_number desc}
        }
    }

    set category_defaults [list]


    foreach { parent_id parent_heading } [bug_tracker::category_types] {
        lappend elements category_$parent_id [list label [bug_tracker::category_heading -keyword_id $parent_id] display_col category_name_$parent_id]

        set values [bug_tracker::category_get_filter_data \
                       -package_id $package_id \
                       -parent_id $parent_id \
                       -user_id $user_id \
                       -admin_p $admin_p]

        set name category_$parent_id

        set where_clause [db_map category_where_clause]

        lappend filters f_$name \
            [list \
                 label $parent_heading \
                 values $values \
                 where_clause $where_clause]

        lappend orderbys $name \
            [list \
                 label $parent_heading \
                 orderby_desc {heading desc, bug_number desc} \
                 orderby_asc {heading asc, bug_number asc}]
    }

    if { [bug_tracker::versions_p] } {
        lappend filters f_fix_for_version {
            label "[_ bug-tracker.Fix]"
            values {[bug_tracker::version_get_filter_data -package_id $package_id -user_id $user_id -admin_p $admin_p]}
            where_clause { b.fix_for_version = :f_fix_for_version }
            null_where_clause { b.fix_for_version is null }
            null_label "[_ bug-tracker.Undecided]"
        }
    }

    foreach action_id [workflow::get_actions -workflow_id $workflow_id] {
        unset -nocomplain action
        workflow::action::get -action_id $action_id -array action

        set values [bug_tracker::assignee_get_filter_data \
                       -package_id $package_id \
                       -workflow_id $workflow_id \
                       -action_id $action_id \
                       -user_id $user_id \
                       -admin_p $admin_p]

        lappend filters f_action_$action_id \
            [list \
                 label $action(pretty_name) \
                 values $values \
                 null_label "[_ bug-tracker.Unassigned]" \
                 where_clause [db_map filter_assignee_where_clause] \
                 null_where_clause [db_map filter_assignee_null_where_clause]]
    }

    # Stat: By Component

    lappend filters f_component {
        label "[_ bug-tracker.Component]"
        values {[bug_tracker::component_get_filter_data -package_id $package_id -user_id $user_id -admin_p $admin_p]}
        where_clause {b.component_id = :f_component}
    }

    upvar \#[template::adp_level] format format
    #
    # For now, use just "table" format, this there is a broken
    # substitution in the list variant, leading to
    # "package_key.message_key' does not exist in en_US", when the
    # message key is used in one of the <listelements> (such as "summary
    # or "comment").
    #
    set format table

    foreach var [bug_tracker::get_export_variables -package_id $package_id] {
        upvar \#[template::adp_level] $var $var
    }

    # Get enabled actions on the filtered state
    if {[info exists f_state]} {
        set bulk_action_f_state $f_state
    } else {
        set bulk_action_f_state $state_default_value
    }
    set enabled_actions_for_this_state [db_list get_action_ids {
        select action_id
        from workflow_fsm_action_en_in_st
        where state_id = :bulk_action_f_state
    }]

    # Generate bulk actions

    set bulk_actions {}
    if { !$no_bulk_actions_p } {
        foreach action_id [workflow::get_actions -workflow_id $workflow_id] {
            if {$action_id in $enabled_actions_for_this_state} {
                # this particular action is enabled
                # add to bulk actions
                workflow::action::get -action_id $action_id -array bulk_action_array_info
                set action_pretty_name $bulk_action_array_info(pretty_name)
                set action_short_name $bulk_action_array_info(short_name)
                lappend bulk_actions "$action_pretty_name" "bulk-update/${action_short_name}" "$action_pretty_name"
            }
        }
        lappend bulk_actions "[_ bug-tracker.Send_Summary_Email]" "send-summary-email" "[_ bug-tracker.Send_Summary_Email]"
    }

    set bulk_action_export_vars [list [list workflow_id $workflow_id] [list return_url [ad_return_url]]]

    template::list::create \
        -ulevel [expr {$ulevel + 1}] \
        -name bugs \
        -multirow bugs \
        -key bug_id \
        -class "list-tiny" \
        -sub_class "narrow" \
        -pass_properties { pretty_names } \
        -bulk_actions $bulk_actions \
        -bulk_action_method get \
        -bulk_action_export_vars $bulk_action_export_vars \
        -elements $elements \
        -filters $filters \
        -orderby $orderbys \
        -page_size [parameter::get -package_id [ad_conn package_id] -parameter PageSize] \
        -page_flush_p 0 \
        -page_query {[bug_tracker::bug::get_query -query_name bugs_pagination]} \
        -formats {
            table {
                label "[_ bug-tracker.Table]"
                layout table
            }
            list {
                label "[_ bug-tracker.List]"
                layout list
                template {
                    <p class="bt">
                      <span style="font-size: 115%;">
                        <listelement name="bug_number"><span class="bt_douce">. </span>
                        <listelement name="summary"><br>
                      </span>
                      <listelement name="comment"><br>
                      <span class="bt_douce">@pretty_names.Component@:</span> <listelement name="component">
                      <span class="bt_douce">- Opened</span> <listelement name="creation_date_pretty">
                      <span class="bt_douce">By</span> <listelement name="submitter"><br>
                      <span class="bt_douce">Status:</span>
                      <span style="color: #008000;"><b><listelement name="state"></b>
                    </p>
                }
            }
        } \
        -selected_format $format
}

ad_proc bug_tracker::bug::get_query {
    {-query_name bugs}
} {
    @param name Either "bugs" or "bugs_pagination"
    @return The query
} {

    upvar \#[template::adp_level] orderby orderby admin_p admin_p
    set package_id [ad_conn package_id]

    # Needed to handle ordering by categories
    set from_bug_clause "bt_bugs b"

    # Lars: This is a little hack because we actually need to alter the query to sort by category
    # but list builder currently doesn't support that.

    if { [info exists orderby] && [regexp {^category_(.*),.*$} $orderby match orderby_parent_id] } {
        append from_bug_clause [db_map orderby_category_from_bug_clause]

        # Branimir: The ORDER BY clause needs to be at the very end of the
        # query. That also means that we need to have in the select list every
        # column we want to order by.  Which columns we can afford to have in
        # the select list depends on which tables are we joining against.  BTW,
        # all these kludges are consequence of the initial (bad, IMHO) decision
        # to do the joins against cr_keywords in memory rather than in SQL.
        set more_columns ", kw_order.heading as heading"
    } else {
        set more_columns ""
    }

    return [db_map $query_name]
}


ad_proc bug_tracker::bug::get_multirow {
    {-package_id ""}
    {-user_id ""}
    {-truncate_len ""}
    {-query_name bugs}
} {
    if { $package_id eq "" } {
        set package_id [ad_conn package_id]
    }
    if { $truncate_len eq "" } {
        set truncate_len [parameter::get \
                             -package_id $package_id \
                             -parameter  "TruncateDescriptionLength" \
                             -default 200]
    }
    foreach var [bug_tracker::get_export_variables -package_id $package_id] {
#JOEL put this back later
        upvar \#[template::adp_level] $var $var
    }

    set workflow_id [bug_tracker::bug::get_instance_workflow_id -package_id $package_id]

    set extend_list {
        comment_short
        submitter_url
        assignee_url
        status_pretty
        resolution_pretty
        component_name
        found_in_version_name
        fix_for_version_name
        fixed_in_version_name
    }

    set category_defaults [list]

    foreach { parent_id parent_heading } [bug_tracker::category_types] {
        lappend category_defaults $parent_id {}
        lappend extend_list "category_$parent_id" "category_name_$parent_id"
    }

    set row_category $category_defaults
    set row_category_names $category_defaults
    db_multirow -extend $extend_list bugs select_bugs [get_query -query_name $query_name] {

        # parent_id is part of the column name
        set parent_id [bug_tracker::category_parent_element -keyword_id $keyword_id -element id]

        # Set the keyword_id and heading for the category with this parent
        dict set row_category $parent_id $keyword_id
        dict set row_category_name $parent_id [bug_tracker::category_heading -keyword_id $keyword_id]

        if { [db_multirow_group_last_row_p -column bug_id] } {
            set component_name [bug_tracker::component_get_name \
                                   -component_id $component_id \
                                   -package_id $package_id]
            set found_in_version_name [bug_tracker::version_get_name \
                                          -version_id $found_in_version \
                                          -package_id $package_id]
            set fix_for_version_name [bug_tracker::version_get_name \
                                         -version_id $fix_for_version\
                                         -package_id $package_id]
            set fixed_in_version_name [bug_tracker::version_get_name \
                                          -version_id $fixed_in_version \
                                          -package_id $package_id]
            set comment_short [ad_string_truncate -len $truncate_len -- $comment_content]
            set submitter_url [acs_community_member_url -user_id $submitter_user_id]
            set assignee_url [acs_community_member_url -user_id $assigned_user_id]
            set resolution_pretty [bug_tracker::resolution_pretty $resolution]

            # Hide fields in this state
            foreach element $hide_fields {
                set $element {}
            }

            # Move categories from array to normal variables, then clear the array for next row
            foreach {parent_id category} $row_category {
                set category_$parent_id $category
                if {[dict exists $row_category_name $parent_id]} {
                    set category_name_$parent_id [dict get $row_category_name $parent_id]
                } else {
                    set category_name_$parent_id {}
                }
            }


            set row_category $category_defaults
            set row_category_name $category_defaults
        } else {
            continue
        }
    }

}

ad_proc bug_tracker::bug::get_bug_numbers {} {
    bug_tracker::bug::get_list -ulevel 2
    bug_tracker::bug::get_multirow

    set filter_bug_numbers [list]
    template::multirow foreach bugs {
        lappend filter_bug_numbers $bug_number
    }

    return $filter_bug_numbers
}

# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
