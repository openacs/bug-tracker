ad_page_contract {
    Shows one bug.

    @author Lars Pind (lars@pinds.com)
    @creation-date 2002-03-20
    @cvs-id $Id$
} {
    mode:optional
    bug_number:integer,notnull
    edit:optional
    comment:optional
    resolve:optional
    reopen:optional
    cancel:optional
    close:optional
    {user_agent_p:boolean 0}
    {show_patch_status "open"}
    filter:array,optional
}

set return_url "[ad_conn url]?[export_vars -url { bug_number filter:array }]"

# If the user hit cancel, ignore everything else
if { [exists_and_not_null cancel] } {
    ad_returnredirect $return_url
    ad_script_abort
}

ad_require_permission [ad_conn package_id] read

if { ![info exists mode] } {
    if { [exists_and_not_null edit] } {
        set mode "edit"
    } elseif { [exists_and_not_null comment] } {
        set mode "comment"
    } elseif { [exists_and_not_null resolve] } {
        set mode "resolve"
    } elseif { [exists_and_not_null reopen] } {
        set mode "reopen"
    } elseif { [exists_and_not_null close] } {
        set mode "close"
    } else {
        set mode "view"
    }
}

switch -- $mode {
    edit {
        set edit_fields { component_id bug_type summary severity priority found_in_version assignee fix_for_version resolution fixed_in_version }
    }
    comment {
        set edit_fields {}
    }
    resolve {
        set edit_fields { resolution fixed_in_version }
    }
    default {
        set edit_fields {}
    }
}
foreach field $edit_fields {
    set field_editable_p($field) 1
}



if { ![string equal $mode "view"] } {
    ad_maybe_redirect_for_registration
}    

set write_p [ad_permission_p [ad_conn package_id] write]

set project_name [bug_tracker::conn project_name]
set package_id [ad_conn package_id]
set package_key [ad_conn package_key]

set user_id [ad_conn user_id]


#
# Filter management
#

set filter_parsed [bug_tracker::parse_filters filter]

if { [string equal $mode view] } {

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


# Create the form

switch -- $mode {
    view {
        form create bug -has_submit 1
    } 
    default {
        form create bug
    }
}

element create bug bug_number \
        -datatype integer \
        -widget hidden

element create bug bug_number_i \
        -datatype integer \
        -widget inform \
        -label "Bug #"

element create bug component_id \
        -datatype integer \
        -widget [ad_decode [info exists field_editable_p(component_id)] 1 select inform] \
        -label "Component" \
        -options [bug_tracker::components_get_options]

element create bug bug_type \
        -datatype text \
        -widget [ad_decode [info exists field_editable_p(bug_type)] 1 select inform] \
        -label "Type of bug" \
        -options [bug_tracker::bug_type_get_options] \
        -optional

element create bug summary  \
        -datatype text \
        -widget [ad_decode [info exists field_editable_p(summary)] 1 text inform] \
        -label "Summary" \
        -html { size 50 }

element create bug submitter \
        -datatype text \
        -widget inform \
        -label "Submitted by"

element create bug status \
        -widget [ad_decode [info exists field_editable_p(status)] 1 select inform] \
        -datatype text \
        -options [bug_tracker::status_get_options] \
        -label "Status"

element create bug resolution \
        -widget [ad_decode [info exists field_editable_p(resolution)] 1 select inform] \
        -datatype text \
        -label "Resolution" \
        -options [ad_decode $mode resolve [bug_tracker::resolution_get_options] [concat {{"" ""}} [bug_tracker::resolution_get_options]]] \
        -optional

element create bug severity \
        -datatype integer \
        -widget [ad_decode [info exists field_editable_p(severity)] 1 select inform] \
        -label "Severity" \
        -options [bug_tracker::severity_codes_get_options] \
        -optional

element create bug priority \
        -datatype integer \
        -widget [ad_decode [info exists field_editable_p(priority)] 1 select inform] \
        -label "Priority" \
        -options [bug_tracker::priority_codes_get_options] \
        -optional

element create bug found_in_version \
        -datatype text \
        -widget [ad_decode [info exists field_editable_p(found_in_version)] 1 select inform] \
        -label "Found in Version" \
        -options [bug_tracker::version_get_options -include_unknown] \
        -optional

element create bug patches \
        -datatype text \
        -widget   inform \
        -label    [ad_decode $show_patch_status "open" "Open Patches (<a href=\"$return_url&show_patch_status=all\">show all</a>)" "all" "All Patches (<a href=\"$return_url&show_patch_status=open\">show only open)" "Patches"]

if { $user_agent_p } {
    element create bug user_agent \
            -datatype text \
            -widget inform \
            -label "User Agent"
}

element create bug assignee \
        -datatype integer \
        -widget [ad_decode [info exists field_editable_p(assignee)] 1 select inform] \
        -label "Assigned to" \
        -options [bug_tracker::users_get_options -include_unassigned] \
        -optional

element create bug fix_for_version \
        -datatype text \
        -widget [ad_decode [info exists field_editable_p(fix_for_version)] 1 select inform] \
        -label "Fix for Version" \
        -options [bug_tracker::version_get_options -include_undecided] \
        -optional

element create bug fixed_in_version \
        -datatype text \
        -widget [ad_decode [info exists field_editable_p(fixed_in_version)] 1 select inform] \
        -label "Fixed in Version" \
        -options [bug_tracker::version_get_options -include_undecided] \
        -optional

switch -- $mode {
    edit - comment - resolve - reopen - close {
        element create bug description  \
                -datatype text \
                -widget comment \
                -label "Description" \
                -html { cols 60 rows 13 } \
                -optional
        
        element create bug desc_format \
                -datatype text \
                -widget select \
                -label "Description format" \
                -options { { "Plain" plain } { "HTML" html } { "Preformatted" pre } }

    }
    default {
        element create bug description \
                -datatype text \
                -widget inform \
                -label "Description"
    }
}


element create bug return_url \
        -datatype text \
        -widget hidden \
        -value $return_url

element create bug mode \
        -datatype text \
        -widget hidden \
        -value $mode

foreach name [array names filter] { 
    element create bug filter.$name -datatype text -widget hidden -value $filter($name)
}

# If nothing else ...
set page_title "Bug #$bug_number"

set show_user_agent_url "bug?[export_vars { bug_number { user_agent_p 1 }}]"
set hide_user_agent_url "bug?[export_vars { bug_number }]"

if { [form is_request bug] } {
    
    db_1row bug {
        select b.bug_id,
               b.bug_number,
               b.summary,
               o.creation_user as submitter_user_id,
               submitter.first_names as submitter_first_names,
               submitter.last_name as submitter_last_name,
               submitter.email as submitter_email,
               b.component_id,
               c.component_name,
               o.creation_date,
               to_char(o.creation_date, 'fmMM/DDfm/YYYY') as creation_date_pretty,
               b.severity,
               sc.sort_order || ' - ' || sc.severity_name as severity_pretty,
               b.priority,
               pc.sort_order || ' - ' || pc.priority_name as priority_pretty,
               b.status,
               b.resolution,
               b.bug_type,
               b.user_agent,
               b.original_estimate_minutes,
               b.latest_estimate_minutes, 
               b.elapsed_time_minutes,
               b.found_in_version,
               coalesce((select version_name 
                         from bt_versions found_in_v 
                         where found_in_v.version_id = b.found_in_version), 'Unknown') as found_in_version_name,
               b.fix_for_version,
               coalesce((select version_name 
                         from bt_versions fix_for_v 
                         where fix_for_v.version_id = b.fix_for_version), 'Undecided') as fix_for_version_name,
               b.fixed_in_version,
               coalesce((select version_name 
                         from bt_versions fixed_in_v 
                         where fixed_in_v.version_id = b.fixed_in_version), 'Unknown') as fixed_in_version_name,
               b.assignee as assignee_user_id,
               assignee.first_names as assignee_first_names,
               assignee.last_name as assignee_last_name,
               assignee.email as assignee_email,
               to_char(now(), 'fmMM/DDfm/YYYY') as now_pretty
        from   bt_bugs b left outer join
               cc_users assignee on (assignee.user_id = b.assignee),
               acs_objects o,
               bt_components c,
               bt_priority_codes pc,
               bt_severity_codes sc,
               cc_users submitter
        where  b.bug_number = :bug_number
        and    b.project_id = :package_id
        and    o.object_id = b.bug_id
        and    c.component_id = b.component_id
        and    pc.priority_id = b.priority
        and    sc.severity_id = b.severity
        and    submitter.user_id = o.creation_user
    } -column_array bug
        
    switch -- $mode {
        resolve {
            set bug(status) "resolved"
        } 
        reopen {
            set bug(status) "open"
        }
    }
    
    element set_properties bug bug_number \
        -value $bug(bug_number)
    element set_properties bug bug_number_i \
        -value $bug(bug_number)
    element set_properties bug component_id \
        -value [ad_decode [info exists field_editable_p(component_id)] 1 $bug(component_id) $bug(component_name)]
    element set_properties bug bug_type \
            -value [ad_decode [info exists field_editable_p(bug_type)] 1 $bug(bug_type) [bug_tracker::bug_type_pretty $bug(bug_type)]]
    element set_properties bug summary \
            -value [ad_decode [info exists field_editable_p(summary)] 1 $bug(summary) "<b>$bug(summary)</b>"]
    element set_properties bug submitter \
            -value "
    [acs_community_member_link -user_id $bug(submitter_user_id) \
            -label "$bug(submitter_first_names) $bug(submitter_last_name)"]
    (<a href=\"mailto:$bug(submitter_email)\">$bug(submitter_email)</a>)"
    element set_properties bug status \
            -value [ad_decode [info exists field_editable_p(status)] 1 $bug(status) [bug_tracker::status_pretty $bug(status)]]
    element set_properties bug resolution \
            -value [ad_decode [info exists field_editable_p(resolution)] 1 $bug(resolution) [bug_tracker::resolution_pretty $bug(resolution)]]
    element set_properties bug severity \
            -value [ad_decode [info exists field_editable_p(severity)] 1 $bug(severity) $bug(severity_pretty)]
    element set_properties bug priority \
            -value [ad_decode [info exists field_editable_p(priority)] 1 $bug(priority) $bug(priority_pretty)]
    element set_properties bug found_in_version \
            -value [ad_decode [info exists field_editable_p(found_in_version)] 1 $bug(found_in_version) $bug(found_in_version_name)]

    element set_properties bug patches \
            -value "[bug_tracker::get_patch_links -bug_id $bug(bug_id) -show_patch_status $show_patch_status] &nbsp; \[ <a href=\"patch-add?bug_number=$bug(bug_number)\">Upload a patch</a> \]"

    if { $user_agent_p } {
        element set_properties bug user_agent \
                -value $bug(user_agent)
    }
    element set_properties bug fix_for_version \
            -value [ad_decode [info exists field_editable_p(fix_for_version)] 1 $bug(fix_for_version) $bug(fix_for_version_name)]
    element set_properties bug fixed_in_version \
            -value [ad_decode [info exists field_editable_p(fixed_in_version)] 1 $bug(fixed_in_version) $bug(fixed_in_version_name)]
    element set_properties bug assignee \
            -value [ad_decode [info exists field_editable_p(assignee)] 1 $bug(assignee_user_id) \
            [ad_decode $bug(assignee_user_id) "" "<i>Unassigned</i>" "
    [acs_community_member_link -user_id $bug(assignee_user_id) \
            -label "$bug(assignee_first_names) $bug(assignee_last_name)"]
    (<a href=\"mailto:$bug(assignee_email)\">$bug(assignee_email)</a>)"]]


    if { ( [string equal $bug(status) open] && ![string equal $mode "resolve"]) \
            || [string equal $mode "reopen"] } {
        element set_properties bug resolution -widget hidden
        element set_properties bug fixed_in_version -widget hidden
    }

    # Description/Actions/History

    set bug_id $bug(bug_id)

    set action_html ""

    db_foreach actions {
        select ba.action_id,
               ba.action,
               ba.resolution,
               ba.actor as actor_user_id,
               actor.first_names as actor_first_names,
               actor.last_name as actor_last_name,
               actor.email as actor_email,
               ba.action_date,
               to_char(ba.action_date, 'fmMM/DDfm/YYYY') as action_date_pretty,
               ba.comment,
               ba.comment_format
        from   bt_bug_actions ba,
               cc_users actor
        where  ba.bug_id = :bug_id
        and    actor.user_id = ba.actor
        order  by action_date
    } {
        append action_html "<b>$action_date_pretty [bug_tracker::bug_action_pretty $action $resolution] by $actor_first_names $actor_last_name</b>
        <blockquote>[bug_tracker::bug_convert_comment_to_html -comment $comment -format $comment_format]</blockquote>"
    }

    if { [string equal $mode "view"] } {
        element set_properties bug description -value $action_html
    } else {
        element set_properties bug description \
                -history $action_html \
                -header "$bug(now_pretty) [bug_tracker::bug_action_pretty $mode] by [bug_tracker::conn user_first_names] [bug_tracker::conn user_last_name]" \
                -value ""
    }

    set page_title "Bug #$bug_number: $bug(summary)"

    # If the user has submitted the bug he gets full write access on the bug
    set write_p [expr $write_p || ($bug(submitter_user_id) == [ad_conn user_id])]

    if { [string equal $mode "view"] && $write_p } {
        set button_form_export_vars [export_vars -form { bug_number filter:array }]
        multirow create button name label
        multirow append button "comment" "Comment"
        multirow append button "edit" "Edit"

        switch -- $bug(status) {
            open {
                multirow append button "resolve" "Resolve"
            }
            resolved {
                multirow append button "resolve" "Resolve"
                multirow append button "reopen" "Reopen"
                multirow append button "close" "Close"
            }
            closed {
                multirow append button "reopen" "Reopen"
            }
        }
    }

    # Notifications for a project. Provide a link for logged in users in view mode
    if { [string equal $mode "view"]  } {

        set notification_link [bug_tracker::get_notification_link \
                         -type       bug_tracker_project_notif \
                         -object_id  $bug(bug_id) \
                         -url        $return_url \
                         -pretty_name "bug"]
    } else {
        set notification_link ""
    }

    if { ![string equal $mode "view"] && !$write_p } {
        ns_log notice "$bug(submitter_user_id) doesn't have write on object $bug(bug_id)"
        ad_return_forbidden "Security Violation" "<blockquote>
        You don't have permission to edit this bug.
        <br>
        This incident has been logged.
        </blockquote>"
        ad_script_abort
    }
}

set context_bar [ad_context_bar $page_title]

if { [form is_valid bug] } {

    # Find out whether the user has permission to modify

    if { !$write_p } {
        # No write permission, is this the submitter?
        db_1row submitter { 
            select o.creation_user as submitter_user_id,
                   o.object_id
            from   bt_bugs b,
                   acs_objects o
            where  o.object_id = b.bug_id
            and    b.bug_number = :bug_number
            and    b.project_id = :package_id
        } -column_array bug
    
        # If the user has submitted the bug he gets full write access on the bug
        set write_p [expr $write_p || ($bug(submitter_user_id) == [ad_conn user_id])]
    }

    if { !$write_p } {
        ns_log notice "$bug(submitter_user_id) doesn't have write on object $bug(object_id)"
        ad_return_forbidden \
                "Security Violation" \
                "<blockquote>
        You don't have permission to edit this bug.
        <br>
        This incident has been logged.
        </blockquote>"
        ad_script_abort
    }

    set update_exprs [list]

    foreach column $edit_fields {
        set $column [element get_value bug $column]
        lappend update_exprs "$column = :$column"
    }

    switch -- $mode {
        resolve {
            set status "resolved"
            lappend update_exprs "status = :status"
        }
        reopen {
            set status "open"
            lappend update_exprs "status = :status"
        }
        close {
            set status "closed"
            lappend update_exprs "status = :status"
        }
    }

    if { ![info exists resolution] || ![string equal $mode "resolve"] } {
        set resolution {}
    }

    db_transaction {
        set bug_id [bug_tracker::get_bug_id -bug_number $bug_number -project_id $package_id]

        if { [llength $update_exprs] > 0 } {
            db_dml update_bug "update bt_bugs \n set    [join $update_exprs ",\n        "] \n where  bug_id = :bug_id"
        }

        set action_id [db_nextval "acs_object_id_seq"]
        set user_id [ad_conn user_id]
 
        foreach column { description desc_format } {
            set $column [element get_value bug $column]
        }

        db_dml bug_action {
            insert into bt_bug_actions
            (action_id, bug_id, action, resolution, actor, comment, comment_format)
            values
            (:action_id, :bug_id, :mode, :resolution, :user_id, :description, :desc_format)
        }

        # Setup any assignee for alerts on the bug
        if { [info exists assignee] && ![empty_string_p $assignee] } {
            bug_tracker::add_instant_alert -bug_id $bug_id -user_id $assignee
        }
    }

    bug_tracker::bug_notify -bug_id $bug_id \
                           -action $mode \
                           -comment $description \
                           -comment_format $desc_format \
                           -resolution $resolution

    ad_returnredirect $return_url
    ad_script_abort
}

ad_return_template

