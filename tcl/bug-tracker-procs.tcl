ad_library {

    Bug Tracker Library

    @creation-date 2002-05-03
    @author Lars Pind <lars@collaboraid.biz>
    @cvs-id $Id$

}

namespace eval bug_tracker {

    ad_proc conn { args } {
    
        global bt_conn
    
        set flag [lindex $args 0]
        if { [string index $flag 0] != "-" } {
            set var $flag
            set flag "-get"
        } else {
            set var [lindex $args 1]
        }
    
        switch -- $flag {
            -set {
                set bt_conn($var) [lindex $args 2]
            }
    
            -get {
                if { [info exists bt_conn($var)] } {
                    return $bt_conn($var)
                } else {
                    switch -- $var {
                        project_name - project_description - current_version_id - current_version_name {
                            array set info [get_project_info]
                            foreach name [array names info] {
                                set bt_conn($name) $info($name)
                            }
                            return $bt_conn($var)
                        }
                        user_first_names - user_last_name - user_email - user_version_id - user_version_name {
                            if { [ad_conn user_id] == 0 } {
                                return ""
                            } else {
                                array set info [get_user_prefs]
                                foreach name [array names info] {
                                    set bt_conn($name) $info($name)
                                }
                                return $bt_conn($var)
                            }
                        }
                        component_id {
                            return {}
                        }
                        default {
                            error "Unknown variable $var"
                        }
                    }
                }
            }
    
            default {
                error "bt_conn: unknown flag $flag"
            }
        }
    }
    
    #####
    #
    # Cached project info procs
    # 
    #####
    
    ad_proc get_project_info_internal {
        package_id
    } {
        set found_p [db_0or1row project_info {
            select pck.instance_name as project_name,
                   prj.description as project_description,
                   ver.version_id as current_version_id,
                   coalesce(ver.version_name, 'None') as current_version_name
            from   apm_packages pck, 
                   bt_projects prj 
                   left outer join bt_versions ver 
                   on (ver.project_id = prj.project_id and active_version_p = 't')
            where  pck.package_id = :package_id 
            and    prj.project_id = pck.package_id
        } -column_array result]
        
        if { !$found_p } {
            set count [db_string count_project { select count(*) from bt_projects where project_id = :package_id }]
            if { $count == 0 } {
                db_exec_plsql create_project {
                    select bt_project__new(:package_id)
                }
                # we call ourselves again, so we'll get the info this time
                return [get_project_info_internal $package_id]
            } else {
                error "Couldn't find project in database"
            }
        } else {
            return [array get result]
        }
    }
    
    ad_proc get_project_info {
        -package_id
    } {
        if { ![info exists package_id] } {
            set package_id [ad_conn package_id]
        }
    
        # temp hack: don't cache
        return [get_project_info_internal $package_id]
    
        #    return [util_memoize "bt_get_project_info_internal $package_id"]
    }
    
    ad_proc set_project_name {
        -package_id
        project_name
    } {
        if { ![info exists package_id] } {
            set package_id [ad_conn package_id]
        }
        
        db_dml project_name_update {
            update apm_packages
            set    instance_name = :project_name
            where  package_id = :package_id
        }
        
        # Flush cache
        util_memoize_flush "bt_get_project_info_internal $package_id"
    }
    
    
    
    
    #####
    #
    # Cached user prefs procs
    #
    #####
    
    ad_proc get_user_prefs_internal {
        package_id
        user_id
    } {
        set found_p [db_0or1row user_info {
            select u.first_names as user_first_names, 
                   u.last_name as user_last_name,
                   u.email as user_email,
                   ver.version_id as user_version_id,
                   coalesce(ver.version_name, 'None') as user_version_name
            from   cc_users u,
                   bt_user_prefs up
                   left outer join bt_versions ver
                   on (ver.version_id = up.user_version)
            where  u.user_id = :user_id
            and    up.user_id = u.user_id
            and    up.project_id = :package_id
        } -column_array result]
    
        if { !$found_p } {
            set count [db_string count_user_prefs { select count(*) from bt_user_prefs where project_id = :package_id and user_id = :user_id }]
            if { $count == 0 } {
                db_dml create_user_prefs {
                    insert into bt_user_prefs (user_id, project_id) values (:user_id, :package_id)
                }
                # we call ourselves again, so we'll get the info this time
                return [get_user_prefs_internal $package_id $user_id]
            } else {
                error "Couldn't find user in database"
            }
        } else {
            return [array get result]
        }
    }
    
    ad_proc get_user_prefs {
        -package_id
        -user_id
    } {
        if { ![info exists package_id] } {
            set package_id [ad_conn package_id]
        }
    
        if { ![info exists user_id] } {
            set user_id [ad_conn user_id]
        }
    
        # temp hack: don't cache
        return [get_user_prefs_internal $package_id $user_id]
    
        #    return [util_memoize "bt_get_user_prefs_internal $package_id $user_id"]
    }
    
    
    #####
    #
    # Bug Types
    #
    #####
    
    ad_proc bug_type_get_options {} {
        return { { "Bug" bug } { "Suggestion" suggestion } { "Todo" todo } }
    }
    
    ad_proc bug_type_pretty {
        bug_type
    } {
        array set bug_types {
            bug "Bug"
            suggestion "Suggestion"
            todo "Todo"
        }
        if { [info exists bug_types($bug_type)] } {
            return $bug_types($bug_type)
        } else {
            return ""
        }
    }
    
    
    #####
    #
    # Status
    #
    #####
    
    ad_proc status_get_options {} {
        return { { "Open" open } { "Resolved" resolved } { "Closed" closed } }
    }
    
    ad_proc status_pretty {
        status
    } {
        array set status_codes {
            open "Open"
            resolved "Resolved"
            closed "Closed"
        }
        if { [info exists status_codes($status)] } {
            return $status_codes($status)
        } else {
            return ""
        }
    }
    
    
    
    #####
    #
    # Resolution
    #
    #####
    
    ad_proc resolution_get_options {} {
        return { 
            { "Fixed" fixed } { "By Design" bydesign } { "Won't Fix" wontfix } { "Postponed" postponed } 
            { "Duplicate" duplicate } { "Not Reproducable" norepro } { "Need Info" needinfo } 
        }
    }
    
    ad_proc resolution_pretty {
        resolution
    } {
        array set resolution_codes {
            fixed "Fixed"
            bydesign "By Design" 
            wontfix "Won't Fix" 
            postponed "Postponed"
            duplicate "Duplicate"
            norepro "Not Reproducable"
            needinfo "Need Info"
        }
        if { [info exists resolution_codes($resolution)] } {
            return $resolution_codes($resolution)
        } else {
            return ""
        }
    }
    
    
    
    #####
    #
    # Severity/Priority codes
    #
    #####
    
    ad_proc severity_codes_get_options {
    } {
        set package_id [ad_conn package_id]
        
        set severity_list [db_list_of_lists severities {
            select sort_order || ' - ' || severity_name, severity_id 
            from   bt_severity_codes 
            where  project_id = :package_id
            order  by sort_order
        }]
            
        return $severity_list
    }
    
    ad_proc severity_get_default {
    } {
        set package_id [ad_conn package_id]
        
        set default_severity_id [db_string default_severity {
            select severity_id
            from   bt_severity_codes 
            where  project_id = :package_id
            and    default_p = 't'
            order  by sort_order
            limit 1
        } -default ""]
        
        return $default_severity_id
    }
    
    ad_proc priority_codes_get_options {
    } {
        set package_id [ad_conn package_id]
        
        set priority_list [db_list_of_lists priorities { 
            select sort_order || ' - ' || priority_name, priority_id 
            from   bt_priority_codes 
            where  project_id = :package_id
            order  by sort_order 
        }]
        
        return $priority_list
    }
    
    ad_proc priority_get_default {
    } {
        set package_id [ad_conn package_id]
        
        set default_priority_id [db_string default_priority {
            select priority_id
            from   bt_priority_codes 
            where  project_id = :package_id
            and    default_p = 't'
            order  by sort_order
            limit 1
        } -default ""]
        
        return $default_priority_id
    }
    
    
    
    #####
    #
    # Versions
    #
    #####
    
    ad_proc version_get_options {
        -include_unknown:boolean
        -include_undecided:boolean
    } {
        set package_id [ad_conn package_id]
        
        set versions_list [db_list_of_lists versions \
                { select version_name, version_id from bt_versions where project_id = :package_id order by version_name }]
    
        if { $include_unknown_p } {
            set versions_list [concat { { "Unknown" "" } } $versions_list]
        } 
        
        if { $include_undecided_p } {
            set versions_list [concat { { "Undecided" "" } } $versions_list]
        } 
        
        return $versions_list
    }
    
    
    #####
    #
    # Components
    #
    #####
    
    ad_proc components_get_options {
        -include_unknown:boolean
    } {
        set package_id [ad_conn package_id]
    
        set components_list [db_list_of_lists components \
                { select component_name, component_id from bt_components where project_id = :package_id order by component_name }]
    
        if { $include_unknown_p } {
            set components_list [concat { { "Unknown" "" } } $components_list]
        } 
        
        return $components_list
    }
    
    
    #####
    #
    # Description
    #
    #####
    
    ad_proc bug_convert_comment_to_html {
        -comment
        -format
    } {
        switch $format {
            html {
                return [ad_html_text_convert -from html -to html -- $comment]
            }
            pre {
                return "<font size=\"+0\"><pre>[ad_html_text_convert -from html -to html -- $comment]</pre></font>"
            }
            default {
                return [ad_html_text_convert -from text -to html -- $comment]
            }
        }
    }
    
    ad_proc bug_convert_comment_to_text {
        -comment
        -format
    } {
        switch $format {
            html {
                return [ad_html_text_convert -from html -to text -- $comment]
            }
            default {
                return [ad_html_text_convert -from text -to text -- $comment]
            }
        }
    }
    
    #####
    #
    # Actions
    #
    #####
    
    ad_proc bug_action_pretty {
        action
        {resolution ""}
    } {
        array set action_codes {
            open "Opened"
            edit "Edited"
            reassign "Reassigned"
            comment "Comment"
            resolve "Resolved"
            reopen "Reopened"
            close "Closed"
        }
        if { [info exists action_codes($action)] } {

            set action_pretty $action_codes($action)

            if { [string equal $action "resolve"] } {
                set resolution_pretty [resolution_pretty $resolution]
                if { ![empty_string_p $resolution_pretty] } {
                    append action_pretty " ($resolution_pretty)"
                }
            }

            return $action_pretty
        } else {
            return ""
        }
    }    
    
    #####
    #
    # Users (assignee)
    #
    #####
    
    ad_proc users_get_options {
        -package_id
        -include_unassigned:boolean
    } {
        if { ![info exists package_id] } {
            set package_id [ad_conn package_id]
        }

        # Lars:
        # This is using acs_permission__permission_p in the where clause of a query
        # This is a no-no, but I don't know what else to do here
        set sql {
            select first_names || ' ' || last_name, 
                   user_id 
            from   cc_users 
            where  acs_permission__permission_p(:package_id, user_id, 'write') = 't'
            order  by first_names, last_name
        }

        set users_list [db_list_of_lists users $sql]
    
        if { $include_unassigned_p } {
            set users_list [concat { { "Unassigned" "" } } $users_list]
        } 
        
        return $users_list
    }
    


    
    #####
    #
    # Notification
    #
    #####
    
    ad_proc bug_notify {
        bug_id
        action
        comment
        comment_format
        {resolution ""}
    } {
        ns_log Notice "bug_id = $bug_id"
    
        set package_id [ad_conn package_id]
    
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
            where  b.bug_id = :bug_id
            and    b.project_id = :package_id
            and    o.object_id = b.bug_id
            and    c.component_id = b.component_id
            and    pc.priority_id = b.priority
            and    sc.severity_id = b.severity
            and    submitter.user_id = o.creation_user
        } -column_array bug
    
        set subject "Bug #$bug(bug_number). [string_truncate -len 30 $bug(summary)]: [bug_action_pretty $action $resolution] by [conn user_first_names] [conn user_last_name]"
    
        set body "Bug #$bug(bug_number). $bug(summary)
    
    Action: [bug_action_pretty $action $resolution] by [conn user_first_names] [conn user_last_name]
    "
        if { ![empty_string_p $comment] } {
            append body "
    Comment:
    
    [bug_convert_comment_to_text -comment $comment -format $comment_format]
    "
        }
    
        append body "
    [ad_url][ad_conn package_url]bug?[export_vars -url { { bug_number $bug(bug_number) } }]
    "
    
        array set recipient [list]
        set recipient(${bug(submitter_email)}) 1
        set recipient(${bug(assignee_email)}) 1
    
        # don't spam the current user
        set recipient([conn user_email]) 0
    
        set component_id $bug(component_id)
        set sender_email [db_string maintainer { select email from cc_users where user_id = bt_component__default_assignee(:component_id) } -default [ad_system_owner] ]
    
        foreach email [array names recipient] {
            if { $recipient($email) && ![empty_string_p $email] } {
                if {[catch {ns_sendmail $email $sender_email $subject $body} errmsg]} {
                    # In case we can't send the email
                    ns_log Notice "\[bug-tracker\] Error sending email: $errmsg"
                }
            }
        }
    }        
}
