ad_page_contract {
    Shows one bug.

    @author Lars Pind (lars@pinds.com)
    @creation-date 2002-03-20
    @cvs-id $Id$
} {
    bug_number:integer,notnull
    {user_agent_p:boolean 0}
    {show_patch_status "open"}
    filter:array,optional
}

#####
#
# Setup
#
#####

set return_url "[ad_conn url]?[export_vars -url { bug_number filter:array }]"

set project_name [bug_tracker::conn project_name]
set package_id [ad_conn package_id]
set package_key [ad_conn package_key]

set user_id [ad_conn user_id]

permission::require_permission -object_id $package_id -privilege read



#####
#
# Workflow definition
#
#####

set workflow_states { open resolved closed }

set workflow_actions { edit comment reassign resolve reopen close }

set workflow_roles { submitter assignee }


# By state
array set workflow_enabled_actions {
    open { comment edit reassign resolve }
    resolved { comment edit resolve reopen close }
    closed { comment edit reopen }
}

# By action
array set workflow_action_privileges {
    edit { write }
    comment { read }
    reassign { write }
    resolve { write }
    reopen { write }
    close { write }
}

# By action
array set workflow_action_label {
    edit "Edit"
    comment "Comment"
    reassign "Reassign"
    resolve "Resolve"
    reopen "Reopen"
    close "Close"
}

# By action
array set workflow_action_allowed_roles {
    edit { assignee submitter }
    comment { assignee submitter }
    reassign { assignee }
    resolve {}
    reopen { submitter }
    close {}
}

# By action
array set workflow_action_assigned_roles {
    edit {}
    comment {}
    reassign {}
    resolve { assignee }
    reopen {}
    close { submitter }
}

# By action
array set workflow_new_status {
    {} {}
    edit {}
    comment {}
    reassign {}
    resolve resolved
    reopen open
    close closed
}

# By action
array set workflow_edit_fields {
    {} {}
    edit { component_id bug_type summary severity priority found_in_version assignee fix_for_version resolution fixed_in_version }
    comment {}
    reassign { assignee }
    resolve { resolution fixed_in_version }
    reopen {}
    close {}
}

# By current state or new state (after action)
array set workflow_hide_fields {
    open { resolution fixed_in_version }
    resolved {}
    closed {}
}


#####
#
# Permissions
#
#####

foreach role $workflow_roles {
    set user_role($role) 0
}

db_1row permission_info {
    select b.bug_id,
           b.status,
           o.creation_user as submitter_user_id,
           b.assignee
    from   bt_bugs b,
           acs_objects o
    where  b.bug_number = :bug_number
    and    b.project_id = :package_id
    and    o.object_id = b.bug_id
} -column_array bug

# If the user has submitted the bug he gets write permission
if { [info exists bug(submitter_user_id)] && ($bug(submitter_user_id) == $user_id) } { 
    set user_role(submitter) 1
}
    
# If the user is assigned to the bug, he gets write permission
if { [info exists bug(assignee)] && ($bug(assignee) == $user_id) } { 
    set user_role(assignee) 1
}   

array set action_permission_p [list {} 1]

foreach loop_action $workflow_actions {
    set action_permission_p($loop_action) 0
    
    foreach role [concat $workflow_action_assigned_roles($loop_action) $workflow_action_allowed_roles($loop_action)] {
        if { $user_role($role) } {
            set action_permission_p($loop_action) 1
            break
        }
    }
    
    if { !$action_permission_p($loop_action) } {
        foreach priv $workflow_action_privileges($loop_action) {
            if { [permission::permission_p -object_id $bug(bug_id) -privilege $priv] } {
                set action_permission_p($loop_action) 1
                break
            }
        }
    }
}


#####
#
# Action
#
#####

set action [form get_action bug]

# Registration required for all actions
if { ![empty_string_p $action] } {
    ad_maybe_redirect_for_registration
}

# Check permissions
if { !$action_permission_p($action) } {
    bug_tracker::security_violation -user_id $user_id -bug_id $bug(bug_id) -action $action
}

# Buttons
set actions [list]
if { [empty_string_p $action] } {
    foreach enabled_action $workflow_enabled_actions(${bug(status)}) {
        if { $action_permission_p($enabled_action) } {
            lappend actions [list "     $workflow_action_label($enabled_action)     " $enabled_action]
        }
    }
}

#####
#
# Create the form
#
#####

form create bug -mode display -actions $actions -cancel_url $return_url

element create bug bug_number_display \
        -datatype integer \
        -widget inform \
        -mode display \
        -label "Bug #"

element create bug component_id \
        -datatype integer \
        -widget select \
        -mode display \
        -label "Component" \
        -options [bug_tracker::components_get_options]

element create bug bug_type \
        -datatype text \
        -widget select \
        -mode display \
        -label "Type of bug" \
        -options [bug_tracker::bug_type_get_options] \
        -optional

element create bug summary  \
        -datatype text \
        -widget text \
        -mode display \
        -label "Summary" \
        -html { size 50 } \
        -before_html "<b>" \
        -after_html "</b>"

element create bug submitter \
        -datatype text \
        -widget inform \
        -mode display \
        -label "Submitted by"

element create bug status \
        -widget select \
        -mode display \
        -datatype text \
        -options [bug_tracker::status_get_options] \
        -label "Status" \
        -before_html "<b>" \
        -after_html "</b>"

element create bug resolution \
        -widget select \
        -mode display \
        -datatype text \
        -label "Resolution" \
        -options [ad_decode $action resolve [bug_tracker::resolution_get_options] [concat {{"" ""}} [bug_tracker::resolution_get_options]]] \
        -optional

element create bug severity \
        -datatype integer \
        -widget select \
        -mode display \
        -label "Severity" \
        -options [bug_tracker::severity_codes_get_options] \
        -optional

element create bug priority \
        -datatype integer \
        -widget select \
        -mode display \
        -label "Priority" \
        -options [bug_tracker::priority_codes_get_options] \
        -optional

element create bug found_in_version \
        -datatype text \
        -widget select \
        -mode display \
        -label "Found in Version" \
        -options [bug_tracker::version_get_options -include_unknown] \
        -optional

element create bug patches \
        -datatype text \
        -widget   inform \
        -mode display \
        -label [ad_decode $show_patch_status "open" "Open Patches (<a href=\"$return_url&show_patch_status=all\">show all</a>)" "all" "All Patches (<a href=\"$return_url&show_patch_status=open\">show only open)" "Patches"]

element create bug user_agent \
        -datatype text \
        -widget inform \
        -mode display \
        -label "User Agent"

element create bug assignee \
        -widget search \
        -mode display \
        -datatype search \
        -result_datatype integer \
        -label {Assigned to} \
        -options [bug_tracker::users_get_options] \
        -optional \
        -search_query {
    select distinct u.first_names || ' ' || u.last_name || ' (' || u.email || ')' as name, u.user_id
    from   cc_users u
    where  upper(coalesce(u.first_names || ' ', '')  || coalesce(u.last_name || ' ', '') || u.email || ' ' || coalesce(u.screen_name, '')) like upper('%'||:value||'%')
    order  by name
}

element create bug fix_for_version \
        -datatype text \
        -widget select \
        -mode display \
        -label "Fix for Version" \
        -options [bug_tracker::version_get_options -include_undecided] \
        -optional

element create bug fixed_in_version \
        -datatype text \
        -widget select \
        -mode display \
        -label "Fixed in Version" \
        -options [bug_tracker::version_get_options -include_undecided] \
        -optional

element create bug description  \
        -datatype text \
        -widget comment \
        -history [bug_tracker::bug::get_activity_html -bug_id $bug(bug_id)] \
        -label "Description" \
        -html { cols 60 rows 13 } \
        -format_element desc_format \
        -format_options { { "Plain" plain } { "HTML" html } { "Preformatted" pre } } \
        -optional

# Hidden elements

element create bug return_url \
        -datatype text \
        -widget hidden \
        -value $return_url

element create bug bug_number \
        -datatype integer \
        -widget hidden

# Export filters
foreach name [array names filter] { 
    element create bug filter.$name -datatype text -widget hidden -value $filter($name)
}

# Set editable fields
foreach field $workflow_edit_fields($action) {
    element set_properties bug $field -mode edit
}


    

#####
#
# Valid form submission: Store in DB and get out of here
#
#####

if { [form is_valid bug] } {

    # Get values from form
    array set row [list]

    foreach column $workflow_edit_fields($action) {
        set row($column) [element get_value bug $column]
    }

    # Set new status
    if { ![empty_string_p $workflow_new_status($action)] } {
        set row(status) $workflow_new_status($action)
    }

    bug_tracker::bug::edit \
            -bug_id $bug(bug_id) \
            -action $action \
            -description [element get_value bug description] \
            -desc_format [ns_queryget desc_format] \
            -array row

    ad_returnredirect $return_url
    ad_script_abort
}




#####
#
# Display form
#
#####

# Get bug info from DB, hide form elements, set values
if { ![form is_valid bug] } {

    # Get the bug data
    bug_tracker::bug::get -bug_id $bug(bug_id) -array bug
    
    # Maybe bump to new state
    if { ![empty_string_p $workflow_new_status($action)] } {
        set bug(status) $workflow_new_status($action)
    }

    # Patches
    set bug(patches_display) "[bug_tracker::get_patch_links -bug_id $bug(bug_id) -show_patch_status $show_patch_status] &nbsp; \[ <a href=\"patch-add?[export_vars { { bug_number $bug(bug_number) } { component_id $bug(component_id) } }]\">Upload a patch</a> \]"

    # Hide elements that should be hidden depending on the bug status
    foreach element $workflow_hide_fields(${bug(status)}) {
        element set_properties bug $element -widget hidden
    }

    # Optionally hide user agent
    if { !$user_agent_p } {
        element set_properties bug user_agent -widget hidden
    }

    # Set regular element values
    foreach element { 
        bug_number component_id bug_type summary status resolution severity assignee
        priority found_in_version user_agent fix_for_version fixed_in_version 
        bug_number_display 
    } {
        # check that the element exists
        if { [info exists bug:$element] } {
            if { [form is_request bug] || [string equal [element get_property bug $element mode] "display"] } {
                element set_value bug $element $bug($element)
            }
        }
    }
    
    # Set values for elements with separate display value
    foreach element { 
        assignee submitter patches
    } {
        # check that the element exists
        if { [info exists bug:$element] } {
            element set_properties bug $element -display_value $bug(${element}_display)
        }
    }

    # Set values for description field
    element set_properties bug description \
            -header "$bug(now_pretty) [bug_tracker::bug_action_pretty $action] by [bug_tracker::conn user_first_names] [bug_tracker::conn user_last_name]"

    # Set page title
    set page_title "Bug #$bug_number: $bug(summary)"

    # Context bar
    if { [info exists filter] } {
        if { [array names filter] == [list "actionby"] && $filter(actionby) == $user_id } {
            set context_bar [bug_tracker::context_bar [list ".?[export_vars { filter:array }]" "My bugs"] $page_title]
        } else {
            set context_bar [bug_tracker::context_bar [list ".?[export_vars { filter:array }]" "Filtered bug list"] $page_title]
        }
    } else {
        set context_bar [bug_tracker::context_bar $page_title]
    }
    
    # User agent
    set show_user_agent_url "bug?[export_vars { bug_number { user_agent_p 1 }}]"
    set hide_user_agent_url "bug?[export_vars { bug_number }]"
    
    # Login
    set login_url "/register/?[export_vars { return_url }]"
    
    # Single-bug notifications 
    if { [empty_string_p $action]  } {
        set notification_link [bug_tracker::get_notification_link \
                -type       bug_tracker_bug_notif \
                -object_id  $bug(bug_id) \
                -url        $return_url \
                -pretty_name "bug"]
    }


    # Filter management
    set filter_parsed [bug_tracker::parse_filters filter]
    
    if { [empty_string_p $action] } {
    
        set human_readable_filter [bug_tracker::conn filter_human_readable]
        set where_clauses [bug_tracker::conn filter_where_clauses]
        set order_by_clause [bug_tracker::conn filter_order_by_clause]
        
        lappend where_clauses "b.project_id = :package_id"
    
        set filter_bug_numbers [db_list filter_bug_numbers "
            select bug_number 
            from   bt_bugs b join 
                   acs_objects o on (object_id = bug_id) join
                   bt_priority_codes pc on (pc.priority_id = b.priority) join
                   bt_severity_codes sc on (sc.severity_id = b.severity)
            where  [join $where_clauses " and "]
            order  by $order_by_clause
        "]
    
        set filter_bug_index [lsearch -exact $filter_bug_numbers $bug_number]
    
        multirow create navlinks url label
        
        if { $filter_bug_index != -1 } {
            
            if { $filter_bug_index > 0 } {
                multirow append navlinks "bug?[export_vars { { bug_number {[lindex $filter_bug_numbers [expr $filter_bug_index -1]]} } filter:array }]" "&lt;"
            } else {
                multirow append navlinks "" "&lt;"
            }
            
            multirow append navlinks "" "[expr $filter_bug_index+1] of [llength $filter_bug_numbers]"
            
            if { $filter_bug_index < [expr [llength $filter_bug_numbers]-1] } {
                multirow append navlinks "bug?[export_vars { { bug_number {[lindex $filter_bug_numbers [expr $filter_bug_index +1]]} } filter:array }]" "&gt;"
            } else {
                multirow append navlinks "" "&gt;"
            }
        }
    }   

}

ad_return_template
