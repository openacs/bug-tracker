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
                        component_id - filter - filter_human_readable - filter_where_clauses - filter_order_by_clause {
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

    ad_proc get_bug_id {
        {-bug_number:required}
        {-project_id:required}
    } {
        return [db_string bug_id { select bug_id from bt_bugs where bug_number = :bug_number and project_id = :project_id }]
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
    
        return [util_memoize "bug_tracker::get_user_prefs_internal $package_id $user_id"]
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
    
    ad_proc patch_status_get_options {} {
        return { { "Open" open } { "Accepted" accepted } { "Refused" refused }  { "Deleted" deleted }}
    }

    ad_proc patch_status_pretty {
        status
    } {
        array set status_codes {
            open      "Open"
            accepted  "Accepted"
            refused   "Refused"
            deleted   "Deleted"
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
    
    ad_proc patch_action_pretty {
        action
    } {

        array set action_codes {
            open "Opened"
            edit "Edited"
            comment "Comment"
            accept "Accepted"
            reopen "Reopened"
            refuse "Refused"
            delete "Deleted"
        }

        if { [info exists action_codes($action)] } {
            return $action_codes($action)
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
    } {
        if { ![info exists package_id] } {
            set package_id [ad_conn package_id]
        }

        set user_id [ad_conn user_id]

        # This picks out users who are already assigned to some bug in this
        set sql {
            select distinct q.*
            from (
                select u.first_names || ' ' || u.last_name as name, u.user_id
                from   bt_bugs b, cc_users u
                where  b.project_id = :package_id
                and    u.user_id = b.assignee
                union
                select u.first_names || ' ' || u.last_name as name, u.user_id
                from   cc_users u
                where  u.user_id = :user_id
            ) q
            order  by name
        }

        set users_list [db_list_of_lists users $sql]
    
        set users_list [concat { { "Unassigned" "" } } $users_list]
        lappend users_list { "Search..." ":search:"}

        return $users_list
    }
    


    
    #####
    #
    # Notification
    #
    #####
    
    ad_proc bug_notify {
        {-bug_id:required}
        {-action ""}
        {-comment ""}
        {-comment_format ""}
        {-resolution ""}
        {-patch_summary ""}
    } {
        set package_id [ad_conn package_id]
    
        db_1row bug {
            select b.bug_id,
                   b.bug_number,
                   b.summary,
                   b.project_id,
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

        set subject_start "Bug #$bug(bug_number). [ad_html_to_text -- [string_truncate -len 30 $bug(summary)]]"
        set body_start "Bug #$bug(bug_number). $bug(summary)"

        if { ![string equal $action "patched"] } {
            set subject "$subject_start: [bug_action_pretty $action $resolution] by [conn user_first_names] [conn user_last_name]"
            
            set body "$body_start
            
            Action: [bug_action_pretty $action $resolution] by [conn user_first_names] [conn user_last_name]
            "
            if { ![empty_string_p $comment] } {
                append body "
                Comment:
                
                [bug_convert_comment_to_text -comment $comment -format $comment_format]
                "
            }            

        } else {
            # The bug was patched - we use different text in this case
            set subject "$subject_start was patched by [conn user_first_names] [conn user_last_name]"
            
            set body "$body_start

            A patch with summary \"$patch_summary\" has been entered for this bug."
        }
            
        append body "
            [ad_url][ad_conn package_url]bug?[export_vars -url { { bug_number $bug(bug_number) } }]
            "

        # Use the Notification service to alert (could be immediately, or daily, or weekly)
        # people who have signed up for notification on this bug
        notification::new \
            -type_id [notification::type::get_type_id -short_name bug_tracker_bug_notif] \
            -object_id $bug(bug_id) \
            -response_id $bug(bug_id) \
            -notif_subject $subject \
            -notif_text $body
       
        # Use the Notification service to alert people who have signed up for notification
        # in this bug tracker package instance
        notification::new \
            -type_id [notification::type::get_type_id -short_name bug_tracker_project_notif] \
            -object_id $bug(project_id) \
            -response_id $bug(bug_id) \
            -notif_subject $subject \
            -notif_text $body        
    }        

    ad_proc add_instant_alert { 
        {-bug_id:required}
        {-user_id:required}
    } {
        notification::request::new \
                -type_id [notification::type::get_type_id -short_name bug_tracker_bug_notif] \
                -user_id $user_id \
                -object_id $bug_id \
                -interval_id [notification::get_interval_id -name "daily"] \
                -delivery_method_id [notification::get_delivery_method_id -name "email"]            
    }    

    ad_proc get_notification_link {
        {-type:required}
        {-object_id:required}
        {-pretty_name:required}
        {-url:required}
    } {
        Returns a list with the url, label, and title for a notifications link (subscribe or unsubscribe).
    } {

        set user_id [ad_conn user_id]

        set notification_link [list]
        # Only present the link to logged in users.
        if { $user_id != "0" } {
            set type_id [notification::type::get_type_id -short_name $type]

            set request_id [notification::request::get_request_id -type_id $type_id -object_id $object_id -user_id $user_id]

            if { ![empty_string_p $request_id] } {
                # The user is already subscribed
                lappend notification_link [notification::display::unsubscribe_url -request_id $request_id -url $url]
                lappend notification_link "Unsubscribe"
                lappend notification_link "Unsubscribe from notifications for this $pretty_name"
            } else {
                # The user is not subscribed
                lappend notification_link [notification::display::subscribe_url \
                        -type       bug_tracker_project_notif \
                        -object_id  $object_id \
                        -url        $url \
                        -user_id    $user_id \
                        -pretty_name "a $pretty_name"
                ]
                lappend notification_link "Subscribe"
                lappend notification_link "Subscribe to notifications for this $pretty_name"
            }
        }

        return $notification_link
    }

    ad_proc map_patch_to_bug {
        {-patch_id:required}
        {-bug_id:required}
    } {                
        db_dml map_patch_to_bug {
            insert into bt_patch_bug_map (patch_id, bug_id) values (:patch_id, :bug_id)
        }        
    }

    ad_proc unmap_patch_from_bug {
        {-patch_number:required}
        {-bug_number:required}
    } {
        set package_id [ad_conn package_id]
        db_dml unmap_patch_from_bug {
            delete from bt_patch_bug_map
              where bug_id = (select bug_id from bt_bugs 
                              where bug_number = :bug_number
                                and project_id = :package_id)
                and patch_id = (select patch_id from bt_patches
                                where patch_number = :patch_number
                                and project_id = :package_id)
        }
    }

    ad_proc get_mapped_bugs {
        {-patch_number:required}
        {-only_open_p "0"}
    } {
        Return a list of lists with the bug number in the first element and the bug
        summary in the second.
    } {
        set bug_list [list]
        set package_id [ad_conn package_id]

        set open_clause [ad_decode $only_open_p "1" "\n        and bt_bugs.status = 'open'" ""]

        db_foreach get_bugs_for_patch "select bt_bugs.bug_number,
                                              bt_bugs.summary
                                       from bt_bugs, bt_patch_bug_map
                                       where bt_bugs.bug_id = bt_patch_bug_map.bug_id
                                         and bt_patch_bug_map.patch_id = (select patch_id
                                                                          from bt_patches
                                                                          where patch_number = :patch_number
                                                                            and project_id = :package_id
                                                                         )
                                         $open_clause" {

            lappend bug_list [list "$summary" "$bug_number"]
        }

        return $bug_list
    }

    ad_proc get_bug_links {
        {-patch_id:required}
        {-patch_number:required}
        {-write_or_submitter_p:required}
    } {
        set bug_list [get_mapped_bugs -patch_number $patch_number]
        set bug_link_list [list]

        if { [llength $bug_list] == "0"} {
            return ""
        } else {
            
            foreach bug_item $bug_list {

                set bug_number [lindex $bug_item 1]
                set bug_summary [lindex $bug_item 0]

                set unmap_url "unmap-patch-from-bug?[export_vars -url { patch_number bug_number } ]"
                if { $write_or_submitter_p } {
                    set unmap_link "(<a href=\"$unmap_url\">unmap</a>)"
                } else {
                    set unmap_link ""
                }
                lappend bug_link_list "<a href=\"bug?bug_number=$bug_number \">$bug_summary</a> $unmap_link"
            } 

            if { [llength $bug_link_list] != 0 } {
                set bugs_string [join $bug_link_list ",&nbsp;"]
            } else {
                set bugs_string "No bugs." 
            }

            return $bugs_string
        }
  }

    ad_proc get_patch_links {
        {-bug_id:required}
        {-show_patch_status "open"}
    } {
        set patch_list [list]

        switch -- $show_patch_status {
            open {
                set status_where_clause "and bt_patches.status = :show_patch_status"
            }
            all {
                set status_where_clause ""
            }
        }

        db_foreach get_patches_for_bug \
                "select bt_patches.patch_number,
        bt_patches.summary,
        bt_patches.status
        from bt_patch_bug_map, bt_patches
        where bt_patch_bug_map.bug_id = :bug_id
        and bt_patch_bug_map.patch_id = bt_patches.patch_id
        $status_where_clause
        " {
            
            set status_indicator [ad_decode $show_patch_status "all" "($status)" ""]
            lappend patch_list "<a href=\"patch?patch_number=$patch_number\">$summary</a> $status_indicator"
        } if_no_rows { 
            set patches_string "No patches." 
        }

        if { [llength $patch_list] != 0 } {
            set patches_string [join $patch_list ",&nbsp;"]
        }

        return $patches_string
    }

    ad_proc get_patch_submitter {
        {-patch_number:required}
    } {
        set package_id [ad_conn package_id]
        return [db_string patch_submitter_id "select acs_objects.creation_user
                                                from bt_patches, acs_objects
                                                where bt_patches.patch_number = :patch_number
                                                  and bt_patches.project_id = :package_id
                                                  and bt_patches.patch_id = acs_objects.object_id"]
    }

    ad_proc update_patch_status {
        {-patch_number:required}
        {-new_status:required}
    } {
        set package_id [ad_conn package_id]
        db_dml update_patch_status "update bt_patches 
                                      set status = :new_status
                                    where bt_patches.project_id = :package_id
                                      and bt_patches.patch_number = :patch_number"
    }

    ad_proc get_uploaded_patch_file_content {
        
    } {
        set patch_file [ns_queryget patch_file]
       
        if { [empty_string_p $patch_file] } {
            # No patch file was uploaded
            return ""
        }

        set tmp_file [ns_queryget patch_file.tmpfile]
        set tmp_file_channel [open $tmp_file r]
        set content [read $tmp_file_channel]

        return $content
    }

    ad_proc parse_filters { filter_array_name } {
        Parses the array named in 'filter_array_name', setting local
        variables for the filter parameters, and constructing a chunk
        that can be used in a query, plus a human readable
        string. Sets the result in bug_tracker::conn as
        'filter_human_readable', 'filter_where_clauses', and
        'filter_order_by_clause'.
    } {
        upvar $filter_array_name filter

        set where_clauses [list]

        set valid_filters {
            status
            bug_type
            fix_for_version:integer
            severity:integer
            priority:integer
            assignee:integer
            component_id:integer
            actionby:integer
            {orderby ""}
        }
        
        foreach name $valid_filters {
            if { [llength $name] > 1 } {
                set default [lindex $name 1]
                set name [lindex $name 0]
            } else {
                if { [info exists default] } {
                    unset default
                }
            }
            if { [llength [split $name ":"]] > 1 } {
                set filters [split [lindex [split $name ":"] 1] ,]
                set name [lindex [split $name ":"] 0]
            } else {
                set filters [list]
            }
            if { [info exists filter($name)] } {
                upvar __filter_$name var
                set var $filter($name)

                if { [lsearch -exact $filters "integer"] != -1 && ![empty_string_p $var]} {
                    validate_integer $name $var
                }
            } elseif { [info exists default] } {
                upvar __filter_$name var
                set var $default
            }
            # also upvar it under its real name
            upvar __filter_$name __filter_$name
        }
        
        
        if { ![info exists __filter_status] } {
            if { [info exists __filter_actionby] } {
                set __filter_status ""
            } else {
                set __filter_status "open"
            }
        }
        
        if { ![empty_string_p $__filter_status] } {
            lappend where_clauses "b.status = :__filter_status"
            set human_readable_filter "All $__filter_status bugs"
        } else {
            lappend where_clauses "b.status != 'closed'"
            set human_readable_filter "All open and resolved bugs"
        }
        
        if { [info exists __filter_bug_type] } {
            lappend where_clauses "b.bug_type = :__filter_bug_type"
            append human_readable_filter " of type [bug_tracker::bug_type_pretty $__filter_bug_type]"
        }
        
        if { [info exists __filter_assignee] } {
            if { [empty_string_p $__filter_assignee] } {
                lappend where_clauses "b.assignee is null"
                append human_readable_filter " that are unassigned"
            } else {
                lappend where_clauses "b.assignee = :__filter_assignee"
                if { $__filter_assignee == [ad_conn user_id] } {
                    append human_readable_filter " assigned to me"
                } else {
                    append human_readable_filter " assigned to [db_string assignee_name { select first_names || ' ' || last_name from cc_users where user_id = :__filter_assignee }]"
                }
            }
        }
        
        if { [info exists __filter_actionby] } {
            lappend where_clauses "((b.status = 'open' and b.assignee = :__filter_actionby) or (b.status = 'resolved' and o.creation_user = :__filter_actionby))"
            if { $__filter_actionby ==  [ad_conn user_id] } {
                append human_readable_filter " awaiting action by me"
            } else {
                append human_readable_filter " awaiting action by [db_string actionby_name { select first_names || ' ' || last_name from cc_users where user_id = :__filter_actionby }]"
            }
        }
        
        if { [info exists __filter_severity] } {
            lappend where_clauses "b.severity = :__filter_severity"
            append human_readable_filter " where severity is [db_string severity_name { select severity_name from bt_severity_codes where severity_id = :__filter_severity }]"
        }
        
        if { [info exists __filter_priority] } {
            lappend where_clauses "b.priority = :__filter_priority"
            append human_readable_filter " with a priority of [db_string priority_name { select priority_name from bt_priority_codes where priority_id = :__filter_priority }]"
        }
        
        if { ![empty_string_p [conn component_id]] } {
            set __filter_component_id [conn component_id]
        }

        if { [info exists __filter_component_id] } {
            lappend where_clauses "b.component_id = :__filter_component_id"
            append human_readable_filter " in [db_string component_name { select component_name from bt_components where component_id = :__filter_component_id }]"
            conn -set component_id $__filter_component_id
        }
        
        if { [info exists __filter_fix_for_version] } {
            if { [empty_string_p $__filter_fix_for_version] } {
                lappend where_clauses "b.fix_for_version is null"
                append human_readable_filter " where fix for version is undecided"
            } else {
                lappend where_clauses "b.fix_for_version = :__filter_fix_for_version"
                append human_readable_filter " to be fixed in version [db_string version_name { select version_name from bt_versions where version_id = :__filter_fix_for_version }]"
            }
        }
        
        switch -exact -- $__filter_orderby {
            severity {
                set order_by_clause "sc.sort_order, b.bug_number desc"
                append human_readable_filter ", most severe bugs first"
            }
            priority {
                set order_by_clause "pc.sort_order, b.bug_number desc"
                append human_readable_filter ", highest priority bugs first"
            }
            default {
                set order_by_clause "b.bug_number desc"
            }
        }

        conn -set filter [array get filter]
        conn -set filter_human_readable $human_readable_filter
        conn -set filter_where_clauses $where_clauses
        conn -set filter_order_by_clause $order_by_clause
    }

    ad_proc context_bar { args } {
        Context bar that takes the component information into account
    } {
        set component_id [conn component_id]
        if { ![empty_string_p $component_id] } {
            db_1row component_name {
                select component_name, url_name from bt_components where component_id = :component_id
            }
            if { [llength $args] == 0 } {
                return [eval ad_context_bar [list $component_name]]
            } else {
                return [eval ad_context_bar [list [list "[ad_conn package_url]com/$url_name/" $component_name]] $args]
            }
        } else {
            return [eval ad_context_bar $args]
        }
    }

}

