ad_library {

    Bug Tracker Bug Library
    
    Procedures that deal with a single bug

    @creation-date 2003-01-10
    @author Lars Pind <lars@collaboraid.biz>
    @cvs-id $Id$

}

namespace eval bug_tracker::bug {}

ad_proc -public bug_tracker::bug::get {
    {-bug_id:required}
    {-array:required}
} {
    Get the fields for a bug
} {
    # Select the info into the upvar'ed Tcl Array
    upvar $array row

    db_1row select_bug_data {} -column_array row

    set row(bug_number_display) "#$row(bug_number)"
    set row(submitter_display) "[acs_community_member_link -user_id $row(submitter_user_id) \
            -label "$row(submitter_first_names) $row(submitter_last_name)" \
            ] (<a href=\"mailto:$row(submitter_email)\">$row(submitter_email)</a>)"
    set row(assignee_display) [ad_decode $row(assignee) "" "<i>Unassigned</i>" "
        [acs_community_member_link -user_id $row(assignee) \
                -label "$row(assignee_first_names) $row(assignee_last_name)"]
        (<a href=\"mailto:$row(assignee_email)\">$row(assignee_email)</a>)"]
}

ad_proc -public bug_tracker::bug::get_activity_html {
    -bug_id:required
} {
    Get the activity log for a bug as an HTML chunk
} {
    set action_html {}

    db_foreach actions {} {
        append action_html "<b>$action_date_pretty [bug_tracker::bug_action_pretty $loop_action $resolution] by $actor_first_names $actor_last_name</b>
        <blockquote>[bug_tracker::bug_convert_comment_to_html -comment $comment -format $comment_format]</blockquote>"
    }
    
    return $action_html
}

ad_proc -public bug_tracker::bug::insert {
    -bug_id:required
    -package_id:required
    -component_id:required
    -bug_type:required
    -severity:required
    -priority:required
    -found_in_version:required
    -summary:required
    -description:required
    -desc_format:required
    {-user_agent ""}
    {-user_id ""}
    {-ip_address ""}
} {
    Inserts a new bug into the database. Usually, you'll want to use bug_tracker::bug::new
    because that one sends out notifications, etc.

    @see bug_tracker::bug::new
    @return bug_id The same bug_id passed in, just for convenience.
    
} {
    if { ![exists_and_not_null user_id] } {
        set user_id [ad_conn user_id]
    }
    if { ![exists_and_not_null user_agent] } {
        set user_agent [ns_set get [ns_conn headers] "User-Agent"]
    }
    if { ![exists_and_not_null ip_address] } {
        set ip_address [ns_conn peeraddr]
    }

    db_exec_plsql bug_new {}

    return $bug_id
}

ad_proc -public bug_tracker::bug::new {
    -bug_id:required
    -package_id:required
    -component_id:required
    -bug_type:required
    -severity:required
    -priority:required
    -found_in_version:required
    -summary:required
    -description:required
    -desc_format:required
    {-user_agent ""}
    {-user_id ""}
    {-ip_address ""}
} {
    Create a new bug, then send out notifications, starts workflow, etc.

    Calls bug_tracker::bug::insert.
    
    @see bug_tracker::bug::insert.
    @return bug_id The same bug_id passed in, just for convenience.
} {
    bug_tracker::bug::insert \
            -bug_id $bug_id \
            -package_id $package_id \
            -component_id $component_id \
            -bug_type $bug_type \
            -severity $severity \
            -priority $priority \
            -found_in_version $found_in_version \
            -summary $summary \
            -description $description \
            -desc_format $desc_format \
            -user_agent $user_agent \
            -user_id $user_id \
            -ip_address $ip_address
    
    bug_tracker::bug_notify -bug_id $bug_id -action "open" -comment $description -comment_format $desc_format

    # Sign up the submitter of the bug for instant alerts. We do this after calling
    # the alert procedure so that the submitter isn't alerted about his own submittal of the bug
    bug_tracker::add_instant_alert -bug_id $bug_id -user_id $user_id

    return $bug_id
}


ad_proc -public bug_tracker::bug::update {
    -bug_id:required
    -action:required
    {-user_id ""}
    -description:required
    -desc_format:required
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

    set update_exprs [list]

    foreach column [array names row] {
        set var_$column $row($column)
        lappend update_exprs "$column = :var_$column"
    }

    db_transaction {
        if { [llength $update_exprs] > 0 } {
            db_dml update_bug "update bt_bugs \n set    [join $update_exprs ",\n        "] \n where  bug_id = :bug_id"
        }

        set action_id [db_nextval "acs_object_id_seq"]

        set resolution {}
        if { [exists_and_not_null row(resolution)] } {
            set resolution $row(resolution)
        }

        db_dml bug_action {
            insert into bt_bug_actions
            (action_id, bug_id, action, resolution, actor, comment, comment_format)
            values
            (:action_id, :bug_id, :action, :resolution, :user_id, :description, :desc_format)
        }
    }

    return $bug_id
}

ad_proc -public bug_tracker::bug::edit {
    -bug_id:required
    -action:required
    {-user_id ""}
    -description:required
    -desc_format:required
    -array:required
} {
    Edit a bug, then send out notifications, etc.

    Calls bug_tracker::bug::update.
   
    @see bug_tracker::bug::update
    @return bug_id The same bug_id passed in, just for convenience.
} {
    upvar $array row
    
    db_transaction {
        # Update the bug infor
        update \
                -bug_id $bug_id \
                -action $action \
                -user_id $user_id \
                -description $description \
                -desc_format $desc_format \
                -array row

        # Setup any assignee for alerts on the bug
        if { [info exists row(assignee)] && ![empty_string_p $row(assignee)] } {
            bug_tracker::add_instant_alert \
                    -bug_id $bug_id \
                    -user_id $row(assignee)
        }
    }

    set resolution {}
    if { [exists_and_not_null row(resolution)] } {
        set resolution $row(resolution)
    }

    # Send out notifications
    bug_tracker::bug_notify \
            -bug_id $bug_id \
            -action $action \
            -comment $description \
            -comment_format $desc_format \
            -resolution $resolution
    
    return $bug_id
}
