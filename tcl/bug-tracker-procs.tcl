ad_library {

    Bug Tracker Library

    @creation-date 2002-05-03
    @author Lars Pind <lars@collaboraid.biz>
    @cvs-id bug-tracker-procs.tcl,v 1.13.2.7 2003/03/05 18:13:39 lars Exp

}

namespace eval bug_tracker {}

ad_proc bug_tracker::package_key {} {
    return "bug-tracker"
}

ad_proc bug_tracker::conn { args } {

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
                    bug - bugs - Bug - Bugs - 
                    component - components - Component - Components {
                        get_pretty_names -array bt_conn
                        return $bt_conn($var)
                    }
                    project_name - project_description - 
                    project_root_keyword_id - project_folder_id - 
                    current_version_id - current_version_name {
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
                    component_id - 
                    filter - filter_human_readable - 
                    filter_where_clauses - 
                    filter_order_by_clause - filter_from_bug_clause {
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

ad_proc bug_tracker::get_pretty_names { 
    -array:required
} {
    upvar $array row

    set row(bug) [parameter::get -parameter "TicketPrettyName" -default "bug"]
    set row(bugs) [parameter::get -parameter "TicketPrettyPlural" -default "bugs"]
    set row(Bug) [string totitle $row(bug)]
    set row(Bugs) [string totitle $row(bugs)]

    set row(component) [parameter::get -parameter "ComponentPrettyName" -default "component"]
    set row(components) [parameter::get -parameter "ComponentPrettyPlural" -default "components"]
    set row(Component) [string totitle $row(component)]
    set row(Components) [string totitle $row(components)]
}

ad_proc bug_tracker::get_bug_id {
    {-bug_number:required}
    {-project_id:required}
} {
    return [db_string bug_id {}]
}

#####
#
# Cached project info procs
# 
#####

ad_proc bug_tracker::get_project_info_internal {
    package_id
} {
    db_1row project_info {} -column_array result
    
    return [array get result]
}

ad_proc bug_tracker::get_project_info {
    -package_id
} {
    if { ![info exists package_id] } {
        set package_id [ad_conn package_id]
    }

    return [util_memoize [list bug_tracker::get_project_info_internal $package_id]]
}

ad_proc bug_tracker::get_project_info_flush {
    -package_id
} {
    if { ![info exists package_id] } {
        set package_id [ad_conn package_id]
    }

    util_memoize_flush [list bug_tracker::get_project_info_internal $package_id]
}

ad_proc bug_tracker::set_project_name {
    -package_id
    project_name
} {
    if { ![info exists package_id] } {
        set package_id [ad_conn package_id]
    }
    
    db_dml project_name_update {}
    
    # Flush cache
    util_memoize_flush [list bug_tracker::get_project_info_internal $package_id]]
}
   


#####
#
# Stats procs (cache eventually)
#
#####
 

ad_proc -public bug_tracker::bugs_exist_p {
    {-package_id {}}
} {
    Returns whether any bugs exist in a project
} {
    if { ![exists_and_not_null package_id] } {
        set package_id [ad_conn package_id]
    }

    return [util_memoize [list bug_tracker::bugs_exist_p_not_cached -package_id $package_id]]
}
    
ad_proc -public bug_tracker::bugs_exist_p_set_true {
    {-package_id {}}
} {
    Sets bug_exists_p true. Useful for when you add a new bug, so you know that a bug will exist.
} {
    if { ![exists_and_not_null package_id] } {
        set package_id [ad_conn package_id]
    }

    return [util_memoize_seed [list bug_tracker::bugs_exist_p_not_cached -package_id $package_id] 1]
}
    
ad_proc -public bug_tracker::bugs_exist_p_not_cached {
    -package_id:required
} {
    Returns whether any bugs exist in a project. Not cached.
} {
    return [db_string select_bugs_exist_p {} -default 0]
}
    
    
    
#####
#
# Cached user prefs procs
#
#####

ad_proc bug_tracker::get_user_prefs_internal {
    package_id
    user_id
} {
    set found_p [db_0or1row user_info { } -column_array result]

    if { !$found_p } {
        set count [db_string count_user_prefs {}]
        if { $count == 0 } {
            db_dml create_user_prefs {}
            # we call ourselves again, so we'll get the info this time
            return [get_user_prefs_internal $package_id $user_id]
        } else {
            error "Couldn't find user in database"
        }
    } else {
        return [array get result]
    }
}

ad_proc bug_tracker::get_user_prefs {
    -package_id
    -user_id
} {
    if { ![info exists package_id] } {
        set package_id [ad_conn package_id]
    }

    if { ![info exists user_id] } {
        set user_id [ad_conn user_id]
    }

    return [util_memoize [list bug_tracker::get_user_prefs_internal $package_id $user_id]]
}

ad_proc bug_tracker::get_user_prefs_flush {
    -package_id
    -user_id
} {
    if { ![info exists package_id] } {
        set package_id [ad_conn package_id]
    }

    if { ![info exists user_id] } {
        set user_id [ad_conn user_id]
    }

    util_memoize_flush [list bug_tracker::get_user_prefs_internal $package_id $user_id]
}
    
    
#####
#
# Bug Types
#
#####

ad_proc bug_tracker::bug_type_get_options {} {
    return { { "Bug" bug } { "Suggestion" suggestion } { "Todo" todo } }
}

ad_proc bug_tracker::bug_type_pretty {
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

ad_proc bug_tracker::status_get_options {
    {-package_id ""}
} {
    if { [empty_string_p $package_id] } {
        set package_id [ad_conn package_id]
    }

    set workflow_id [bug_tracker::bug::get_instance_workflow_id -package_id $package_id]
    set state_ids [workflow::fsm::get_states -workflow_id $workflow_id]

    set option_list [list]
    foreach state_id $state_ids {
        workflow::state::fsm::get -state_id $state_id -array state
        lappend option_list [list "$state(pretty_name)" $state(short_name)]
    }

    return $option_list
}

ad_proc bug_tracker::status_pretty {
    status
} {
    set workflow_id [bug_tracker::bug::get_instance_workflow_id]
    if { [catch {set state_id [workflow::state::fsm::get_id -workflow_id $workflow_id -short_name $status]} error] } {
        return ""
    }

    workflow::state::fsm::get -state_id $state_id -array state
    
    return $state(pretty_name)
}

ad_proc bug_tracker::patch_status_get_options {} {
    return { { "Open" open } { "Accepted" accepted } { "Refused" refused }  { "Deleted" deleted }}
}

ad_proc bug_tracker::patch_status_pretty {
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

ad_proc bug_tracker::resolution_get_options {} {
    return { 
        { "Fixed" fixed } { "By Design" bydesign } { "Won't Fix" wontfix } { "Postponed" postponed } 
        { "Duplicate" duplicate } { "Not Reproducable" norepro } { "Need Info" needinfo } 
    }
}

ad_proc bug_tracker::resolution_pretty {
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

ad_proc bug_tracker::severity_codes_get_options {
} {
# XXX FIXME obsolete
    set package_id [ad_conn package_id]
    return [util_memoize [list bug_tracker::severity_codes_get_options_not_cached $package_id]]
}

ad_proc bug_tracker::severity_codes_get_options_not_cached {
    package_id
} {
# XXX FIXME obsolete
    set severity_list [db_list_of_lists severities {
        select sort_order || ' - ' || severity_name, severity_id 
        from   bt_severity_codes 
        where  project_id = :package_id
        order  by sort_order
    }]
        
    return $severity_list
}

ad_proc bug_tracker::severity_get_default {
} {
# XXX FIXME obsolete
    set package_id [ad_conn package_id]
    return [util_memoize [list bug_tracker::severity_get_default_not_cached $package_id]]
}

ad_proc bug_tracker::severity_get_default_not_cached {
    package_id
} {
# XXX FIXME obsolete
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

ad_proc bug_tracker::priority_codes_get_options {
} {
# XXX FIXME obsolete
    set package_id [ad_conn package_id]
    return [util_memoize [list bug_tracker::priority_codes_get_options_not_cached $package_id]]
}

ad_proc bug_tracker::priority_codes_get_options_not_cached {
    package_id
} {
# XXX FIXME obsolete
    set priority_list [db_list_of_lists priorities { 
        select sort_order || ' - ' || priority_name, priority_id 
        from   bt_priority_codes 
        where  project_id = :package_id
        order  by sort_order 
    }]
    
    return $priority_list
}

ad_proc bug_tracker::priority_get_default {
} {
# XXX FIXME obsolete
    set package_id [ad_conn package_id]
    return [util_memoize [list bug_tracker::priority_get_default_not_cached $package_id]]
}

ad_proc bug_tracker::priority_get_default_not_cached {
    package_id
} {
# XXX FIXME obsolete
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
# Categories/Keywords
#
#####

ad_proc bug_tracker::category_parent_heading {
    {-package_id ""}
    -keyword_id:required
} {
    foreach elm [get_keywords -package_id $package_id] {
        set child_id [lindex $elm 0]
        set child_heading [lindex $elm 1]
        set parent_id [lindex $elm 2]
        set parent_heading [lindex $elm 3]
 
        if { $child_id == $keyword_id } {
            return $parent_heading
        }
    }
}

ad_proc bug_tracker::category_heading {
    {-package_id ""}
    -keyword_id:required
} {
    foreach elm [get_keywords -package_id $package_id] {
        set child_id [lindex $elm 0]
        set child_heading [lindex $elm 1]
        set parent_id [lindex $elm 2]
        set parent_heading [lindex $elm 3]
 
        if { $child_id == $keyword_id } {
            return $child_heading
        }
    }
}

ad_proc bug_tracker::category_types {
    {-package_id ""}
} {
    @return Returns the category types for this instance as an
    array-list of { parent_id1 heading1 parent_id2 heading2 ... }
} {
    array set heading [list]
    set parent_ids [list]
    
    set last_parent_id {}
    foreach elm [get_keywords -package_id $package_id] {
        set child_id [lindex $elm 0]
        set child_heading [lindex $elm 1]
        set parent_id [lindex $elm 2]
        set parent_heading [lindex $elm 3]
 
        if { $parent_id != $last_parent_id } {
            set heading($parent_id) $parent_heading
            lappend parent_ids $parent_id
            set last_parent_id $parent_id
        }
    }
    
    set result [list]
    foreach parent_id $parent_ids {
        lappend result $parent_id $heading($parent_id)
    }
    return $result
}

ad_proc bug_tracker::category_get_options {
    {-package_id ""}
    {-parent_id:required}
} {
    @param parent_id The category type's keyword_id
    @return options-list for a select widget for the given category type
} {
    set options [list]
    foreach elm [get_keywords -package_id $package_id] {
        set elm_child_id [lindex $elm 0]
        set elm_child_heading [lindex $elm 1]
        set elm_parent_id [lindex $elm 2]
 
        if { $elm_parent_id == $parent_id } {
            lappend options [list $elm_child_heading $elm_child_id]
        }
    }
    return $options
}


## Cache maintenance

ad_proc -private bug_tracker::get_keywords {
    {-package_id ""}
} {
    if { ![exists_and_not_null package_id] } {
        set package_id [ad_conn package_id]
    }
    return [util_memoize [list bug_tracker::get_keywords_not_cached -package_id $package_id]]
}

ad_proc -private bug_tracker::get_keywords_flush {
    {-package_id ""}
} {
    if { ![exists_and_not_null package_id] } {
        set package_id [ad_conn package_id]
    }
    util_memoize_flush [list bug_tracker::get_keywords_not_cached -package_id $package_id]
}

ad_proc -private bug_tracker::get_keywords_not_cached {
    -package_id:required
} {
    return [db_list_of_lists select_package_keywords {}]
}





ad_proc -public bug_tracker::set_default_keyword {
    {-package_id ""}
    {-parent_id:required}
    {-keyword_id:required}
} {
    Set the default keyword for a given type (parent)
} {
    if { ![exists_and_not_null package_id] } {
        set package_id [ad_conn package_id]
    }

    # LARS NEW QUERIES

    db_dml delete_existing { 
        delete
        from   bt_default_keywords 
        where  project_id = :package_id 
        and    parent_id = :parent_id
    }
    
    db_dml insert_new { 
        insert into bt_default_keywords (project_id, parent_id, keyword_id)
        values (:package_id, :parent_id, :keyword_id)
    }
    get_default_keyword_flush -package_id $package_id -parent_id $parent_id
}

ad_proc -public bug_tracker::get_default_keyword {
    {-package_id ""}
    {-parent_id:required}
} {
    Get the default keyword for a given type (parent)
} {
    if { ![exists_and_not_null package_id] } {
        set package_id [ad_conn package_id]
    }

    return [util_memoize [list bug_tracker::get_default_keyword_not_cached -package_id $package_id -parent_id $parent_id]]
}

ad_proc -public bug_tracker::get_default_keyword_flush {
    {-package_id ""}
    {-parent_id:required}
} {
    Flush the cache for 
} {
    if { ![exists_and_not_null package_id] } {
        set package_id [ad_conn package_id]
    }

    util_memoize_flush [list bug_tracker::get_default_keyword_not_cached -package_id $package_id -parent_id $parent_id]
}


ad_proc -private bug_tracker::get_default_keyword_not_cached {
    {-package_id:required}
    {-parent_id:required}
} {
    Get the default keyword for a given type (parent), not cached.
} {
    # LARS NEW QUERIES

    return [db_string default { 
        select keyword_id
        from   bt_default_keywords
        where  project_id = :package_id
        and    parent_id = :parent_id
    } -default {}]
}





ad_proc -public bug_tracker::get_default_configurations {} {
    Get the package's default configurations for categories and parameters.
} {
    return {
        "Bug-Tracker" {
            categories {
                "Bug Type" {
                    "*Bug"
                    "Suggestion"
                    "Todo"
                }
                "Priority" {
                    "1 - High"
                    "*2 - Normal"
                    "3 - Low"
                }
                "Severity" {
                    "1 - Critical"
                    "2 - Major"
                    "*3 - Normal"
                    "4 - Minor"
                    "5 - Trivial"
                    "6 - Enhancement"
                }
            }
            parameters {
                TicketPrettyName "bug"
                TicketPrettyPlural "bugs"
                ComponentPrettyName "component"
                ComponentPrettyPlural "components"
                PatchesP "1"
                VersionsP "1"
            }
        }
        "Ticket-Tracker" {
            categories {
                "Ticket Type" {
                    "*Todo"
                    "Suggestion"
                }
                "Priority" {
                    "1 - High"
                    "*2 - Normal"
                    "3 - Low"
                }
            }
            parameters {
                TicketPrettyName "ticket"
                TicketPrettyPlural "tickets"
                ComponentPrettyName "area"
                ComponentPrettyPlural "areas"
                PatchesP "0"
                VersionsP "0"
            }
        }
    }
}

ad_proc -public bug_tracker::delete_all_project_keywords {
    {-package_id ""}
} {
    Deletes all the keywords in a project
} {
    if { ![exists_and_not_null package_id] } {
        set package_id [ad_conn package_id]
    }
    db_exec_plsql keywords_delete {}
    bug_tracker::get_keywords_flush -package_id $package_id
}

ad_proc -public bug_tracker::install_keywords_setup {
    {-package_id ""}
    -spec:required
} {
    @param spec is an array-list of { Type1 { cat1 cat2 cat3 } Type2 { cat1 cat2 cat3 } }
    Default category within type is denoted by letting the name start with a *, 
    which is removed before creating the keyword.
} {
    set root_keyword_id [bug_tracker::conn project_root_keyword_id -package_id $package_id]

    foreach { category_type categories } $spec {
        set category_type_id [cr::keyword::get_keyword_id \
                                  -parent_id $root_keyword_id \
                                  -heading $category_type]
        
        if { [empty_string_p $category_type_id] } {
            set category_type_id [cr::keyword::new \
                                      -parent_id $root_keyword_id \
                                      -heading $category_type]
        }
        
        foreach category $categories {
            if { [string equal [string index $category 0] "*"] } {
                set default_p 1
                set category [string range $category 1 end]
            } else {
                set default_p 0
            }                  
            
            set category_id [cr::keyword::get_keyword_id \
                                 -parent_id $category_type_id \
                                 -heading $category]
            
            if { [empty_string_p $category_id] } {
                set category_id [cr::keyword::new \
                                     -parent_id $category_type_id \
                                     -heading $category]
            }

            if { $default_p } {
                bug_tracker::set_default_keyword \
                    -parent_id $category_type_id \
                    -keyword_id $category_id
            }
        }
    }
    bug_tracker::get_keywords_flush -package_id $package_id
}

ad_proc -public bug_tracker::install_parameters_setup {
    {-package_id ""}
    -spec:required
} {
    @param parameters as an array-list of { name value name value ... }
} {
    foreach { name value } $spec {
        parameter::set_value -package_id $package_id -parameter $name -value $value
    }
}



#####
#
# Versions
#
#####

ad_proc bug_tracker::version_get_options {
    -package_id
    -include_unknown:boolean
    -include_undecided:boolean
} {
    if { ![exists_and_not_null package_id] } {
        set package_id [ad_conn package_id]
    }
    
    set versions_list [util_memoize [list bug_tracker::version_get_options_not_cached $package_id]]

    if { $include_unknown_p } {
        set versions_list [concat { { "Unknown" "" } } $versions_list]
    } 
    
    if { $include_undecided_p } {
        set versions_list [concat { { "Undecided" "" } } $versions_list]
    } 
    
    return $versions_list
}


ad_proc bug_tracker::versions_p {
    {-package_id ""}
} { 
    Is the versions feature turned on?
} {
    if { ![exists_and_not_null package_id] } {
        set package_id [ad_conn package_id]
    }
    
    return [parameter::get -package_id [ad_conn package_id] -parameter "VersionsP" -default 1]
}


ad_proc bug_tracker::versions_flush {} {
    set package_id [ad_conn package_id]
    util_memoize_flush [list bug_tracker::version_get_options_not_cached $package_id]
}

ad_proc bug_tracker::version_get_options_not_cached {
    package_id
} {
    set versions_list [db_list_of_lists versions {}]
    
    return $versions_list
}

ad_proc bug_tracker::version_get_name {
    {-package_id ""}
    {-version_id:required}
} {
    if { [empty_string_p $version_id] } {
        return {}
    }
    foreach elm [version_get_options -package_id $package_id] {
        set name [lindex $elm 0]
        set id [lindex $elm 1]
        if { [string equal $id $version_id] } {
            return $name
        }
    }
    error "Version_id $version_id not found"
}


#####
#
# Components
#
#####

ad_proc bug_tracker::components_get_options {
    {-package_id ""}
    -include_unknown:boolean
} {
    if { ![exists_and_not_null package_id] } {
        set package_id [ad_conn package_id]
    }

    set components_list [util_memoize [list bug_tracker::components_get_options_not_cached $package_id]]

    if { $include_unknown_p } {
        set components_list [concat { { "Unknown" "" } } $components_list]
    } 
    
    return $components_list
}

ad_proc bug_tracker::components_flush {} {
    set package_id [ad_conn package_id]
    util_memoize_flush [list bug_tracker::components_get_options_not_cached $package_id]
    util_memoize_flush [list bug_tracker::components_get_url_names_not_cached -package_id $package_id]
}

ad_proc bug_tracker::components_get_options_not_cached {
    package_id
} {
    set components_list [db_list_of_lists components {}]

    return $components_list
}

ad_proc bug_tracker::component_get_name {
    {-package_id ""}
    {-component_id:required}
} {
    if { [empty_string_p $component_id] } {
        return {}
    }
    foreach elm [components_get_options -package_id $package_id] {
        set id [lindex $elm 1]
        if { [string equal $id $component_id] } {
            return [lindex $elm 0]
        }
    }
    error "Component_id $component_id not found"
}

ad_proc bug_tracker::component_get_url_name {
    {-package_id ""}
    {-component_id:required}
} {
    if { [empty_string_p $component_id] } {
        return {}
    }
    foreach { id url_name } [components_get_url_names -package_id $package_id] {
        if { [string equal $id $component_id] } {
            return $url_name
        }
    }
    return {}
}

ad_proc bug_tracker::components_get_url_names {
    {-package_id ""}
} {
    if { ![exists_and_not_null package_id] } {
        set package_id [ad_conn package_id]
    }
    return [util_memoize [list bug_tracker::components_get_url_names_not_cached -package_id $package_id]]
}

ad_proc bug_tracker::components_get_url_names_not_cached {
    {-package_id:required}
} {
    db_foreach select_component_url_names {} {
        lappend result $component_id $url_name
    }
    return $result
}


#####
#
# Description
#
#####

ad_proc bug_tracker::bug_convert_comment_to_html {
    {-comment:required}
    {-format:required}
} {
    return [ad_html_text_convert -from $format -to text/html -- $comment]
}

ad_proc bug_tracker::bug_convert_comment_to_text {
    {-comment:required}
    {-format:required}
} {
    return [ad_html_text_convert -from $format -to text/plain -- $comment]
}

#####
#
# Actions
#
#####

ad_proc bug_tracker::bug_action_pretty {
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
        patched "Patched"
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

ad_proc bug_tracker::patch_action_pretty {
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
# Maintainers
#
#####

ad_proc ::bug_tracker::users_get_options {
    -package_id
} {
    if { ![info exists package_id] } {
        set package_id [ad_conn package_id]
    }
    
    set user_id [ad_conn user_id]
    
    # This picks out users who are already assigned to some bug in this
    set sql {
        select first_names || ' ' || last_name || ' (' || email || ')'  as name, 
               user_id
        from   cc_users
        where  user_id in (
                      select maintainer
                      from   bt_projects
                      where  project_id = :package_id
                      
                      union
                      
                      select maintainer
                      from   bt_versions
                      where  project_id = :package_id
                      
                      union
                      
                      select maintainer
                      from   bt_components
                      where  project_id = :package_id
                )
        or     user_id = :user_id
        order  by name
    }
    
    set users_list [db_list_of_lists users $sql]
    
    set users_list [concat { { "Unassigned" "" } } $users_list]
    lappend users_list { "Search..." ":search:"}
    
    return $users_list
}

ad_proc ::bug_tracker::users_get_searchquery {
    -package_id
} {

}

ad_proc -private bug_tracker::get_maintainer_role_id {
    -package_id
} {
    if { ![info exists package_id] } {
        set package_id [ad_conn package_id]
    }
    # We're using the assignee widget for a certain role to assign the version maintainer
    set workflow_id [bug_tracker::bug::get_instance_workflow_id -package_id [ad_conn package_id]]
    set role_ids [workflow::get_roles -workflow_id $workflow_id]
    
    # LARS HACK:
    # We'll use the last role in sort order
    return [lindex $role_ids end]
}
    

#####
#
# Patches
#
#####

ad_proc bug_tracker::patches_p {} { 
    Is the patch submission feature turned on?
} {
    return [parameter::get -package_id [ad_conn package_id] -parameter "PatchesP" -default 1]
}

ad_proc bug_tracker::map_patch_to_bug {
    {-patch_id:required}
    {-bug_id:required}
} {                
    db_dml map_patch_to_bug {}
}

ad_proc bug_tracker::unmap_patch_from_bug {
    {-patch_number:required}
    {-bug_number:required}
} {
    set package_id [ad_conn package_id]
    db_dml unmap_patch_from_bug {}
}

ad_proc bug_tracker::get_mapped_bugs {
    {-patch_number:required}
    {-only_open_p "0"}
} {
    Return a list of lists with the bug number in the first element and the bug
    summary in the second.
} {
    set bug_list [list]
    set package_id [ad_conn package_id]

    if { $only_open_p } {
        set workflow_id [bug_tracker::bug::get_instance_workflow_id]
        set initial_state [workflow::fsm::get_initial_state -workflow_id $workflow_id]

        set open_clause "\n        and exists (select 1 
                                               from workflow_cases cas, 
                                                    workflow_case_fsm cfsm 
                                               where cas.case_id = cfsm.case_id 
                                                 and cas.object_id = b.bug_id 
                                                 and cfsm.current_state = :initial_state)"
    } else {
        set open_clause ""
    }

    db_foreach get_bugs_for_patch {} {
        lappend bug_list [list "[bug_tracker::conn Bug] #$bug_number: $summary" "$bug_number"]
    }

    return $bug_list
}

ad_proc bug_tracker::get_bug_links {
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
            set bugs_string [join $bug_link_list "<br>"]
        } else {
            set bugs_string "No bugs." 
        }

        return $bugs_string
    }
}

ad_proc bug_tracker::get_patch_links {
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

    db_foreach get_patches_for_bug "" {
        
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

ad_proc bug_tracker::get_patch_submitter {
    {-patch_number:required}
} {
    set package_id [ad_conn package_id]
    return [db_string patch_submitter_id {}] 
}

ad_proc bug_tracker::update_patch_status {
    {-patch_number:required}
    {-new_status:required}
} {
    set package_id [ad_conn package_id]
    db_dml update_patch_status ""
}

ad_proc bug_tracker::get_uploaded_patch_file_content {
    
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

ad_proc bug_tracker::parse_filters { filter_array_name } {
    Parses the array named in 'filter_array_name', setting local
    variables for the filter parameters, and constructing a chunk
    that can be used in a query, plus a human readable
    string. Sets the result in bug_tracker::conn as
    'filter_human_readable', 'filter_where_clauses', 'filter_from_bug_clause', 
    'filter_order_by_clause'.
} {
    upvar $filter_array_name filter

    set where_clauses [list]  
    set from_bug_clause "bt_bugs b"

    set workflow_id [bug_tracker::bug::get_instance_workflow_id]
    set initial_state_id [workflow::fsm::get_initial_state -workflow_id $workflow_id]

    set valid_filters {
        {status $initial_state_id}
        {action_id}
        fix_for_version:integer
        assignee:integer
        action_id:integer
        component_id:integer
        keyword:integer,multiple
        {n_days 7}
        {orderby ""}
    }

    foreach name $valid_filters {
        if { [llength $name] > 1 } {
            set default [subst [lindex $name 1]]
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

        # special case for annoying tcl'ism, whereby if you say
        # lappend foo(bar) {}, your foo(bar) entry will be equal to {{}}, 
        # which we run into, because the page defines filters as 
        # :array,multiple
        if { [info exists filter($name)] && [string equal $filter($name) {{}}] } {
            if { [lsearch -exact $filters "multiple"] != -1 } {
                unset filter($name)
            } else {
                set filter($name) {}
            }
        }

        if { [info exists filter($name)] } {
            upvar filter_$name var
            set var $filter($name)

            if { [lsearch -exact $filters "integer"] != -1 && ![empty_string_p $var]} {
                if { [lsearch -exact $filters "multiple"] != -1 } {
                    foreach elm $var {
                        validate_integer $name $elm
                    }
                } else {
                    validate_integer $name $var
                }
            }
            
        } elseif { [info exists default] } {
            upvar filter_$name var
            set var $default
        }
        # also upvar it under its real name
        upvar filter_$name filter_$name
    }

    if { [info exists filter_status] && ![string equal $filter_status "any"] } {
        lappend where_clauses "cfsm.current_state = :filter_status"
        
        set status_pretty [workflow::state::fsm::get_element \
                               -state_id $filter_status \
                               -element pretty_name]
        
        set human_readable_filter "All $status_pretty [bug_tracker::conn bugs]"
    } else {
        set human_readable_filter "[bug_tracker::conn Bugs] of any status"
    }
    
    if { [info exists filter_bug_type] } {
        lappend where_clauses "b.bug_type = :filter_bug_type"
        append human_readable_filter " of type [bug_tracker::bug_type_pretty $filter_bug_type]"
    }
    
    if { [info exists filter_assignee] } {
        if { [empty_string_p $filter_assignee] } {
            lappend where_clauses "assignee.party_id is null"

            append human_readable_filter " that are unassigned"
        } else {            

            lappend where_clauses "assignee.party_id = :filter_assignee"

            if { $filter_assignee == [ad_conn user_id] } {
                append human_readable_filter " assigned to me"
            } else {
                append human_readable_filter " assigned to [db_string assignee_name {}]"
            }
        }
    } 
 
    if { [info exists filter_keyword] } {
        set keyword_human [list]
        foreach keyword_id $filter_keyword {
            lappend where_clauses [db_map keyword_filter]
            set category_name [category_heading -keyword_id $keyword_id]

            # LARS:
            # This is a hack to be smart about stripping out the "1 - " or "A - " part
            # if people use that naming style
            regsub {^[a-zA-Z0-9]\s[-*]*\s} $category_name {} category_name

            lappend keyword_human "[category_parent_heading -keyword_id $keyword_id] is $category_name"
        }
        append human_readable_filter " where [join $keyword_human " and "]"
    }
    
    if { ![empty_string_p [conn component_id]] } {
        set filter_component_id [conn component_id]
    }

    if { [info exists filter_component_id] } {
        lappend where_clauses "b.component_id = :filter_component_id"
        append human_readable_filter " in [component_get_name -component_id $filter_component_id]"
        conn -set component_id $filter_component_id
    }
    
    if { [info exists filter_fix_for_version] } {
        if { [empty_string_p $filter_fix_for_version] } {
            lappend where_clauses "b.fix_for_version is null"
            append human_readable_filter " where fix for version is undecided"
        } else {
            lappend where_clauses "b.fix_for_version = :filter_fix_for_version"
            append human_readable_filter " to be fixed in version [db_string version_name {}]"
        }
    }
    
    if { [empty_string_p $filter_orderby] } {
        set order_by_clause "b.bug_number desc"
    } else {
        append from_bug_clause [db_map orderby_filter_from_bug]
        lappend where_clauses [db_map orderby_filter_where]
        set order_by_clause "kw_order.heading, bug_number desc "
    }
    
    if { ![empty_string_p $filter_n_days] } {
        if { ![string equal $filter_n_days "all"] } {
            lappend where_clauses [db_map n_days_filter]
            append human_readable_filter " opened in the last $filter_n_days days"
        }
    }

    conn -set filter [array get filter]
    conn -set filter_human_readable $human_readable_filter
    conn -set filter_where_clauses $where_clauses
    conn -set filter_order_by_clause $order_by_clause
    conn -set filter_from_bug_clause $from_bug_clause
}

ad_proc bug_tracker::filter_url_vars { 
    {-array:required}
    {-override:required}
} {
    Returns query args for the URL string, overriding the existing filters with the new one given by name and value.
    Existing orderby and n_days filters are kept, however, unless that's the one you're  replacing
    @param array the name of the array in the caller's scope holding the current filter values
    @param override an array list of new values to set instead
} {
    upvar $array cur_filters
    
    array set filter [list]
    
    foreach keeper { orderby n_days } {
        if { [info exists cur_filters($keeper)] } {
            set filter($keeper) $cur_filters($keeper)
        }
    }

    array set filter $override
    return [export_vars { filter:array }]
}

ad_proc bug_tracker::context_bar { args } {
    Context bar that takes the component information into account
} {
    set component_id [conn component_id]
    if { ![empty_string_p $component_id] } {
        set component_name [bug_tracker::component_get_name -component_id $component_id]
        set url_name [bug_tracker::component_get_url_name -component_id $component_id]
        if { [llength $args] == 0 } {
            return [eval ad_context_bar [list $component_name]]
        } else {
            return [eval ad_context_bar [list [list "[ad_conn package_url]com/$url_name/" $component_name]] $args]
        }
    } else {
        return [eval ad_context_bar $args]
    }
}

ad_proc bug_tracker::security_violation {
    -user_id:required
    -bug_id:required
    -action:required
} {
    ns_log Notice "$user_id doesn't have permission to '$action' on bug $bug_id"
    ad_return_forbidden \
            "Security Violation" \
            "<blockquote>
    You don't have permission to '$action' on this bug.
    <br>
    This incident has been logged.
    </blockquote>"
    ad_script_abort
}
ad_proc bug_tracker::bug_delete { bug_id } {
    Delete a Bug Tracker bug.
    This should only ever be run when un-instantiating a project!

    @author Mark Aufflick
} {
    set case_id [db_string get_case_id {}]
    db_exec_plsql delete_bug_case {}
    set notifications [db_list get_notifications {}]
    foreach notification_id $notifications {
        db_exec_plsql delete_notification {}
    }
    db_dml unset_revisions {}
    db_exec_plsql delete_cr_item {}
}

ad_proc bug_tracker::project_delete { project_id } {
    Delete a Bug Tracker project and all its data.

    @author Peter Marklund
} {
    #manually delete all bugs to avoid wierd integrity constraints
    while { [set bug_id [db_string min_bug_id {}]] > 0 } {
        bug_delete $bug_id
    }
    db_exec_plsql delete_project {}
}

ad_proc bug_tracker::project_new { project_id } {
    Create a new Bug Tracker project for a package instance.

    @author Peter Marklund
} {
    db_exec_plsql create_project {}
}

ad_proc bug_tracker::bug_notify {
    {-bug_id:required}
    {-action ""}        
    {-comment ""}
    {-comment_format ""}
    {-resolution ""}
    {-patch_summary ""}     
} {                             
    set package_id [ad_conn package_id]
                            
    db_1row bug {} -column_array bug
    set bug(found_in_version_name) [version_get_name -version_id $bug(found_in_version)]
    set bug(fix_for_version_name) [version_get_name -version_id $bug(fix_for_version)]
    set bug(fixed_in_version_name) [version_get_name -version_id $bug(fixed_in_version)]

    get_pretty_names -array pretty_names
    
    set subject "$pretty_names(Bug) #$bug(bug_number). [ad_html_to_text -- [string_truncate -len 30 $bug(summary)]]: [bug_action_pretty $action $resolution] by [conn user_first_names] [conn user_last_name]"

    set body "$pretty_names(Bug) no: #$bug(bug_number)
Summary: $bug(summary)

$pretty_names(Component): $bug(component_name)
Status: $bug(status)
"

foreach {category_id category_name} [bug_tracker::category_types] {
    append body "$category_name: [cr::keyword::item_get_assigned -item_id $bug(bug_id) -parent_id $category_id]
"
}

append body "Found in version: $bug(found_in_version_name)

Action: [bug_action_pretty $action $resolution]
By user: [conn user_first_names] [conn user_last_name] <[conn user_email]>

"

    if { ![string equal $action "patched"] } {
        if { ![empty_string_p $comment] } {
            append body "Comment:\n\n[bug_convert_comment_to_text -comment $comment -format $comment_format]\n\n"
        }

    } else {
        append body "\n\nSummary: $patch_summary\n\n"
    }


    append body "--\nTo comment on, edit, resolve, close, or reopen this bug, go to:\n[ad_url][ad_conn package_url]bug?[export_vars -url { { bug_number $bug(bug_number) } }]\n"

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

