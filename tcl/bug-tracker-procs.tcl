
ad_proc bt_conn { args } {

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
                        array set info [bt_get_project_info]
                        foreach name [array names info] {
                            set bt_conn($name) $info($name)
                        }
                        return $bt_conn($var)
                    }
                    user_first_names - user_last_name - user_email - user_version_id - user_version_name {
                        if { [ad_conn user_id] == 0 } {
                            return ""
                        } else {
                            array set info [bt_get_user_prefs]
                            foreach name [array names info] {
                                set bt_conn($name) $info($name)
                            }
                            return $bt_conn($var)
                        }
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

ad_proc bt_get_project_info_internal {
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
            return [bt_get_project_info_internal $package_id]
        } else {
            error "Couldn't find project in database"
        }
    } else {
        return [array get result]
    }
}

ad_proc bt_get_project_info {
    -package_id
} {
    if { ![info exists package_id] } {
        set package_id [ad_conn package_id]
    }

    # temp hack: don't cache
    return [bt_get_project_info_internal $package_id]

    #    return [util_memoize "bt_get_project_info_internal $package_id"]
}

ad_proc bt_set_project_name {
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

ad_proc bt_get_user_prefs_internal {
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
            return [bt_get_user_prefs_internal $package_id $user_id]
        } else {
            error "Couldn't find user in database"
        }
    } else {
        return [array get result]
    }
}

ad_proc bt_get_user_prefs {
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
    return [bt_get_user_prefs_internal $package_id $user_id]

    #    return [util_memoize "bt_get_user_prefs_internal $package_id $user_id"]
}


#####
#
# Bug Types
#
#####

ad_proc bt_bug_type_get_options {} {
    return { { "Bug" bug } { "Suggestion" suggestion } { "Todo" todo } }
}

ad_proc bt_bug_type_pretty {
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

ad_proc bt_status_get_options {} {
    return { { "Open" open } { "Resolved" resolved } { "Closed" closed } }
}

ad_proc bt_status_pretty {
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

ad_proc bt_resolution_get_options {} {
    return { 
        { "Fixed" fixed } { "By Design" bydesign } { "Won't Fix" wontfix } { "Postponed" postponed } 
        { "Duplicate" duplicate } { "Not Reproducable" norepro } 
    }
}

ad_proc bt_resolution_pretty {
    resolution
} {
    array set resolution_codes {
        fixed "Fixed"
        bydesign "By Design" 
        wontfix "Won't Fix" 
        postponed "Postponed"
        duplicate "Duplicate"
        norepro "Not Reproducable"
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

ad_proc bt_severity_codes_get_options {
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

ad_proc bt_severity_get_default {
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

ad_proc bt_priority_codes_get_options {
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

ad_proc bt_priority_get_default {
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

ad_proc bt_version_get_options {
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

ad_proc bt_components_get_options {
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

ad_proc bt_bug_convert_comment_to_html {
    -comment
    -format
} {
    switch $format {
        html {
            return [ad_html_text_convert -from html -to html -- $comment]
        }
        pre {
            return "<font size=\"+0\"><pre>[ad_html_text_convert -from text -to html -- $comment]</pre></font>"
        }
        default {
            return [ad_html_text_convert -from text -to html -- $comment]
        }
    }
}

ad_proc bt_bug_convert_comment_to_text {
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

ad_proc bt_bug_action_pretty {
    action
} {
    array set action_codes {
        open "Opened"
        edit "Edited"
        reassign "Reassigned"
        comment "Commented added"
        resolve "Resolved"
        reopen "Reopened"
        close "Closed"
    }
    if { [info exists action_codes($action)] } {
        return $action_codes($action)
    } else {
        return ""
    }
}


#####
#
# Comment widget
#
#####

ad_proc -public template::widget::comment { element_reference tag_attributes } {

  upvar $element_reference element

  if { [info exists element(html)] } {
    array set attributes $element(html)
  }

  array set attributes $tag_attributes

  set output {}

  if { [info exists element(history)] } {
      append output "$element(history)"
  }

  if { [info exists element(header)] } {
      append output "<p><b>$element(header)</b></p>"
  }

  append output "<textarea name=\"$element(name)\""

  foreach name [array names attributes] {
    if { [string equal $attributes($name) {}] } {
      append output " $name"
    } else {
      append output " $name=\"$attributes($name)\""
    }
  }

  append output ">"

  if { [info exists element(value)] } {
    # As per scottwseago's request
    append output [ad_quotehtml $element(value)]
  } 

  append output "</textarea>"

  return $output
}

#####
#
# Users (assignee)
#
#####

ad_proc bt_users_get_options {
    -include_unassigned:boolean
} {
    set users_list [db_list_of_lists users \
            { select first_names || ' ' || last_name, user_id from cc_users order by first_names, last_name }]

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

ad_proc bt_bug_notify {
    bug_id
    action
    comment
    comment_format
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

    set subject "Bug #$bug(bug_number). $bug(summary): [bt_bug_action_pretty $action] by [bt_conn user_first_names] [bt_conn user_last_name]"

    set body "Bug #$bug(bug_number). $bug(summary)

Action: [bt_bug_action_pretty $action] by [bt_conn user_first_names] [bt_conn user_last_name]
"
    if { ![empty_string_p $comment] } {
        append body "
Comment:

[bt_bug_convert_comment_to_text -comment $comment -format $comment_format]
"
    }

    append body "
[ad_url][ad_conn package_url]bug?[export_vars -url { { bug_number $bug(bug_number) } }]
"

    array set recipient [list]
    set recipient(${bug(submitter_email)}) 1
    set recipient(${bug(assignee_email)}) 1

    # don't spam the current user
    set recipient([bt_conn user_email]) 0

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
    