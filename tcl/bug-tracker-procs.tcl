ad_library {

    Bug Tracker Library

    @creation-date 2002-05-03
    @author Lars Pind <lars@collaboraid.biz>
    @cvs-id bug-tracker-procs.tcl,v 1.13.2.7 2003/03/05 18:13:39 lars Exp

}

namespace eval bug_tracker {}

ad_proc bug_tracker::conn { args } {

    global bt_conn

    set flag [lindex $args 0]
    if { [string index $flag 0] ne "-" } {
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
                    component - components - Component - Components -
                    patch - patches - Patch - Patches {
                        if { ![info exists bt_conn($var)] } {
                            get_pretty_names -array bt_conn
                        }
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
                        error "[_ bug-tracker.Unknown_variable]"
                    }
                }
            }
        }

        default {
            error "[_ bug-tracker.Unknown_flag]"
        }
    }
}

ad_proc bug_tracker::get_pretty_names {
    -array:required
    {-package_id ""}
} {
    upvar $array row

    if { $package_id eq "" } {
        set package_id [ad_conn package_id]
    }
    set row(bug) [lang::util::localize [parameter::get -package_id $package_id -parameter "TicketPrettyName" -default "bug"]]
    set row(bugs) [lang::util::localize [parameter::get -package_id $package_id -parameter "TicketPrettyPlural" -default "bugs"]]
    set row(Bug) [string totitle $row(bug)]
    set row(Bugs) [string totitle $row(bugs)]

    set row(component) [lang::util::localize [parameter::get -package_id $package_id -parameter "ComponentPrettyName" -default "component"]]
    set row(components) [lang::util::localize [parameter::get -package_id $package_id -parameter "ComponentPrettyPlural" -default "components"]]
    set row(Component) [string totitle $row(component)]
    set row(Components) [string totitle $row(components)]

    set row(patch) [lang::util::localize [parameter::get -package_id $package_id -parameter "PatchPrettyName" -default "patch"]]
    set row(patches) [lang::util::localize [parameter::get -package_id $package_id -parameter "PatchPrettyPlural" -default "patches"]]
    set row(Patch) [string totitle $row(patch)]
    set row(Patches) [string totitle $row(patches)]
}

ad_proc bug_tracker::get_bug_id {
    {-bug_number:required}
    {-project_id:required}
} {
    return [db_string bug_id {}]
}


ad_proc bug_tracker::get_page_variables {
    {extra_spec ""}
} {
    Adds the bug listing filter variables for use in the page contract.

    ad_page_contract { doc } [bug_tracker::get_page_variables { foo:integer { bar "" } }]
} {
    set filter_vars {
        page:naturalnum,optional
        f_state:integer,optional
        f_fix_for_version:integer,optional
        f_distribution:integer,optional
        f_component:integer,optional
        orderby:token,optional
        project_id:naturalnum,optional
        {format:word "table"}
    }
    foreach { parent_id parent_heading } [bug_tracker::category_types] {
        lappend filter_vars "f_category_$parent_id:naturalnum,optional"
    }
    try {
        bug_tracker::bug::get_instance_workflow_id
    } on ok {workflow_id} {
        foreach action_id [workflow::get_actions -workflow_id $workflow_id] {
             lappend filter_vars "f_action_$action_id:naturalnum,optional"
         }
    } on error {errorMsg} {
        ns_log notice "bug_tracker::get_page_variables called on non-workflow package"
    }
    return [concat $filter_vars $extra_spec]
}

ad_proc bug_tracker::get_export_variables {
    {-package_id ""}
    {extra_vars ""}
} {
    Gets a list of variables to export for the bug list
} {
    if { $package_id eq "" } {
        set package_id [ad_conn package_id]
    }
    set export_vars {
        f_state
        f_fix_for_version
        f_component
        orderby
        format
        page
    }
    foreach { parent_id parent_heading } [bug_tracker::category_types] {
        lappend export_vars "f_category_$parent_id"
    }
    foreach action_id [workflow::get_actions \
                          -workflow_id [bug_tracker::bug::get_instance_workflow_id \
                                           -package_id $package_id]] {
        lappend export_vars "f_action_$action_id"
    }

    return [concat $export_vars $extra_vars]
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
    {-package_id ""}
} {
    if { $package_id eq "" } {
        set package_id [ad_conn package_id]
    }

    return [util_memoize [list bug_tracker::get_project_info_internal $package_id]]
}

ad_proc bug_tracker::get_project_info_flush {
    {-package_id ""}
} {
    if { $package_id eq "" } {
        set package_id [ad_conn package_id]
    }

    util_memoize_flush [list bug_tracker::get_project_info_internal $package_id]
}

ad_proc bug_tracker::set_project_name {
    {-package_id ""}
    project_name
} {
    if { $package_id eq "" } {
        set package_id [ad_conn package_id]
    }

    db_dml project_name_update {}

    # Flush cache
    util_memoize_flush [list bug_tracker::get_project_info_internal $package_id]]
}



#####
#
# Stats procs
#
#####


ad_proc -public bug_tracker::bugs_exist_p {
    {-package_id {}}
} {
    Returns whether any bugs exist in a project
} {
    if { $package_id eq "" } {
        set package_id [ad_conn package_id]
    }

    return [util_memoize [list bug_tracker::bugs_exist_p_not_cached -package_id $package_id]]
}

ad_proc -public bug_tracker::bugs_exist_p_set_true {
    {-package_id {}}
} {
    Sets bug_exists_p true. Useful for when you add a new bug, so you know that a bug will exist.
} {
    if { $package_id eq "" } {
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
            error "[_ bug-tracker.No_user_in_database]"
        }
    } else {
        return [array get result]
    }
}

ad_proc bug_tracker::get_user_prefs {
    {-package_id ""}
    -user_id
} {
    if { $package_id eq "" } {
        set package_id [ad_conn package_id]
    }

    if { ![info exists user_id] } {
        set user_id [ad_conn user_id]
    }

    return [util_memoize [list bug_tracker::get_user_prefs_internal $package_id $user_id]]
}

ad_proc bug_tracker::get_user_prefs_flush {
    {-package_id ""}
    -user_id
} {
    if { $package_id eq "" } {
        set package_id [ad_conn package_id]
    }

    if { ![info exists user_id] } {
        set user_id [ad_conn user_id]
    }

    util_memoize_flush [list bug_tracker::get_user_prefs_internal $package_id $user_id]
}


#####
#
# Status
#
#####

ad_proc bug_tracker::status_get_options {
    {-package_id ""}
} {
    if { $package_id eq "" } {
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
    return \
        [list \
             [list "[_ bug-tracker.Open]" open ] \
             [list "[_ bug-tracker.Accepted]" accepted ] \
             [list "[_ bug-tracker.Refused]" refused ] \
             [list "[_ bug-tracker.Deleted]" deleted ] \
            ]
}

ad_proc bug_tracker::patch_status_pretty {
    status
} {
    array set status_codes {
        open      bug-tracker.Open
        accepted  bug-tracker.Accepted
        refused   bug-tracker.Refused
        deleted   bug-tracker.Deleted
    }
    if { [info exists status_codes($status)] } {
        return [_ $status_codes($status)]
    } else {
        return {}
    }
}

#####
#
# Resolution
#
#####

ad_proc bug_tracker::resolution_get_options {} {
    return \
        [list \
             [list [_ bug-tracker.Fixed] fixed ] \
             [list [_ bug-tracker.By_Design] bydesign ] \
             [list [_ bug-tracker.Wont_Fix] wontfix ] \
             [list [_ bug-tracker.Postponed] postponed ] \
             [list [_ bug-tracker.Duplicate] duplicate ] \
             [list [_ bug-tracker.Not_Reproducible] norepro ] \
             [list [_ bug-tracker.Need_Info] needinfo ] \
            ]

}

ad_proc bug_tracker::resolution_pretty {
    resolution
} {
    array set resolution_codes {
        fixed bug-tracker.Fixed
        bydesign bug-tracker.By_Design
        wontfix bug-tracker.Wont_Fix
        postponed bug-tracker.Postponed
        duplicate bug-tracker.Duplicate
        norepro bug-tracker.Not_Reproducible
        needinfo bug-tracker.Need_Info
    }
    if { [info exists resolution_codes($resolution)] } {
        return [_ $resolution_codes($resolution)]
    } else {
        return ""
    }
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
    return [bug_tracker::category_parent_element -package_id $pcakage_id -keyword_id $keyword_id -element heading]
}

# TODO: This could be made faster if we do a reverse mapping array from child to parent

ad_proc bug_tracker::category_parent_element {
    {-package_id ""}
    -keyword_id:required
    {-element "heading"}
} {
    foreach elm [get_keywords -package_id $package_id] {
        set child_id [lindex $elm 0]

        if { $child_id == $keyword_id } {
            set parent(id)      [lindex $elm 2]
            set parent(heading) [lindex $elm 3]
            return $parent($element)
        }
    }
}

ad_proc bug_tracker::category_heading {
    {-package_id ""}
    -keyword_id:required
} {
    foreach elm [get_keywords -package_id $package_id] {
        lassign $elm child_id child_heading parent_id parent_heading

        if { $child_id == $keyword_id } {
            return $child_heading
        } elseif { $parent_id == $keyword_id } {
            return $parent_heading
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
        lassign $elm child_id child_heading parent_id parent_heading

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

ad_proc bug_tracker::category_get_filter_data_not_cached {
    {-package_id:required}
    {-parent_id:required}
    {-user_id ""}
    {-admin_p "f"}
    {-user_bugs_only_p "f"}
} {
    @param package_id The package (project) to select from
    @param parent_id The category type's keyword_id
    @return list-of-lists with category data for filter
} {
    return [db_list_of_lists select {}]
}

ad_proc bug_tracker::category_get_filter_data {
    {-package_id:required}
    {-parent_id:required}
    {-user_id ""}
    {-admin_p "f"}
} {
    @param package_id The package (project) to select from
    @param parent_id The category type's keyword_id
    @return list-of-lists with category data for filter
} {
    set user_bugs_only_p [bug_tracker::user_bugs_only_p]

    return [util_memoize [list bug_tracker::category_get_filter_data_not_cached \
                             -package_id $package_id \
                             -parent_id $parent_id \
                             -user_id $user_id \
                             -admin_p $admin_p \
                             -user_bugs_only_p $user_bugs_only_p]]
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
        lassign $elm elm_child_id elm_child_heading elm_parent_id

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
    if { $package_id eq "" } {
        set package_id [ad_conn package_id]
    }
    return [util_memoize [list bug_tracker::get_keywords_not_cached -package_id $package_id]]
}

ad_proc -private bug_tracker::get_keywords_flush {
    {-package_id ""}
} {
    if { $package_id eq "" } {
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
    if { $package_id eq "" } {
        set package_id [ad_conn package_id]
    }

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
    if { $package_id eq "" } {
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
    if { $package_id eq "" } {
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
    return [list \
        [_ bug-tracker.Bug_Tracker] [list \
            categories [list \
                "[_ bug-tracker.Bug_Type]" [list \
                    "[_ bug-tracker.Bug_Bug_cat]" \
                    "[_ bug-tracker.Bug_Sug_Cat]" \
                ] \
                "[_ bug-tracker.Priority]" [list \
                    "[_ bug-tracker.Prio_High_Cat]" \
                    "[_ bug-tracker.Prio_Norm_Cat]" \
                    "[_ bug-tracker.Prio_Low_Cat]" \
                ] \
                "[_ bug-tracker.Severity]" [list \
                    "[_ bug-tracker.Sev_Critical_Cat]" \
                    "[_ bug-tracker.Sev_Major_Cat]" \
                    "[_ bug-tracker.Sev_Normal_Cat]" \
                    "[_ bug-tracker.Sev_Minor_Cat]" \
                ] \
            ] \
            parameters {
                TicketPrettyName "bug"
                TicketPrettyPlural "bugs"
                ComponentPrettyName "component"
                ComponentPrettyPlural "components"
                PatchesP "1"
                VersionsP "1"
                RelatedFilesP "1"
            } \
        ] \
        [_ bug-tracker.Ticket_Tracker] [list \
            categories [list \
                "[_ bug-tracker.Ticket_Type]" [list \
                    "[_ bug-tracker.Ticket_Todo_Cat]" \
                    "[_ bug-tracker.Ticket_Sugg_Cat]" \
                ] \
                "[_ bug-tracker.Priority]" [list \
                    "[_ bug-tracker.Prio_High_Cat]" \
                    "[_ bug-tracker.Prio_Norm_Cat]" \
                    "[_ bug-tracker.Prio_Low_Cat]" \
                ] \
            ] \
            parameters {
                TicketPrettyName "ticket"
                TicketPrettyPlural "tickets"
                ComponentPrettyName "area"
                ComponentPrettyPlural "areas"
                PatchesP "0"
                VersionsP "0"
                RelatedFilesP "1"
            } \
        ] \
        [_ bug-tracker.Support_Center] [list \
            categories [list \
                "[_ bug-tracker.Message_Type]" [list \
                    "[_ bug-tracker.Support_Problem]" \
                    "[_ bug-tracker.Support_Suggestion]" \
                    "[_ bug-tracker.Support_Error]" \
                ] \
                "[_ bug-tracker.Priority]" [list \
                    "[_ bug-tracker.Prio_High_Cat]" \
                    "[_ bug-tracker.Prio_Norm_Cat]" \
                    "[_ bug-tracker.Prio_Low_Cat]" \
                ] \
            ] \
            parameters {
                TicketPrettyName "message"
                TicketPrettyPlural "messages"
                ComponentPrettyName "area"
                ComponentPrettyPlural "areas"
                PatchesP "0"
                VersionsP "0"
                RelatedFilesP "1"
            } \
        ] \
    ]
}






ad_proc -public bug_tracker::delete_all_project_keywords {
    {-package_id ""}
} {
    Deletes all the keywords in a project
} {
    if { $package_id eq "" } {
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
        set category_type_id [content::keyword::get_keyword_id \
                                  -parent_id $root_keyword_id \
                                  -heading $category_type]

        if { $category_type_id eq "" } {
            set category_type_id [content::keyword::new \
                                      -parent_id $root_keyword_id \
                                      -heading $category_type]
        }

        foreach category $categories {
            if {[string index $category 0] eq "*"} {
                set default_p 1
                set category [string range $category 1 end]
            } else {
                set default_p 0
            }

            set category_id [content::keyword::get_keyword_id \
                                 -parent_id $category_type_id \
                                 -heading $category]

            if { $category_id eq "" } {
                set category_id [content::keyword::new \
                                     -parent_id $category_type_id \
                                     -heading $category]
            }

            if { $default_p } {
                bug_tracker::set_default_keyword \
                    -package_id $package_id \
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
    {-package_id ""}
    -include_unknown:boolean
    -include_undecided:boolean
} {
    if { $package_id eq "" } {
        set package_id [ad_conn package_id]
    }

    set versions_list [util_memoize [list bug_tracker::version_get_options_not_cached $package_id]]

    if { $include_unknown_p } {
        set versions_list [concat [list [list [_ bug-tracker.Unknown] "" ] ] $versions_list]
    }

    if { $include_undecided_p } {
        set versions_list [concat [list [list [_ bug-tracker.Undecided] "" ] ] $versions_list]
    }

    return $versions_list
}


ad_proc bug_tracker::assignee_get_options {
    -workflow_id
    -include_unknown:boolean
    -include_undecided:boolean
} {
    Returns an option list containing all users that have submitted or assigned to a bug.
    Used for the add bug form. Added because the workflow api requires a case_id.
    (an item to evaluate is refactoring workflow to provide an assignee widget without a case_id)
} {

    set assignee_list [db_list_of_lists assignees {}]

    if { $include_unknown_p } {
        set assignee_list [concat { { "Unknown" "" } } $assignee_list]
    }

    if { $include_undecided_p } {
        set assignee_list [concat { { "Undecided" "" } } $assignee_list]
    }

    return $assignee_list
}


ad_proc bug_tracker::versions_p {
    {-package_id ""}
} {
    Is the versions feature turned on?
} {
    if { $package_id eq "" } {
        set package_id [ad_conn package_id]
    }

    return [parameter::get -package_id $package_id -parameter "VersionsP" -default 1]
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
    if { $version_id eq "" } {
        return {}
    }
    foreach elm [version_get_options -package_id $package_id] {
        lassign $elm name id
        if {$id eq $version_id} {
            return $name
        }
    }
    error [_ bug-tracker.Version_id [list version_id $version_id]]
}


#####
#
# Components
#
#####

ad_proc bug_tracker::component_get_filter_data_not_cached {
    {-package_id:required}
    {-user_id ""}
    {-admin_p "f"}
    {-user_bugs_only_p "f"}
} {
    @param package_id The project we're interested in
    @return list-of-lists with component data for filter
} {
    return [db_list_of_lists select {}]
}

ad_proc bug_tracker::component_get_filter_data {
    {-package_id:required}
    {-user_id ""}
    {-admin_p "f"}
} {
    @param package_id The project we're interested in
    @return list-of-lists with component data for filter
} {
    set user_bugs_only_p [bug_tracker::user_bugs_only_p]

    return [util_memoize [list bug_tracker::component_get_filter_data_not_cached \
                             -package_id $package_id \
                             -user_id $user_id \
                             -admin_p $admin_p \
                             -user_bugs_only_p $user_bugs_only_p]]
}
ad_proc bug_tracker::components_get_options {
    {-package_id ""}
    -include_unknown:boolean
} {
    if { $package_id eq "" } {
        set package_id [ad_conn package_id]
    }

    set components_list [util_memoize [list bug_tracker::components_get_options_not_cached $package_id]]

    if { $include_unknown_p } {
        set components_list [concat [list [list "[_ bug-tracker.Unknown]" {} ]] $components_list]
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
    if { $component_id eq "" } {
        return {}
    }
    foreach elm [components_get_options -package_id $package_id] {
        set id [lindex $elm 1]
        if {$id eq $component_id} {
            return [lindex $elm 0]
        }
    }
    error [_ bug-tracker.Component_id_not_found]
}

ad_proc bug_tracker::component_get_url_name {
    {-package_id ""}
    {-component_id:required}
} {
    if { $component_id eq "" } {
        return {}
    }
    foreach { id url_name } [components_get_url_names -package_id $package_id] {
        if {$id eq $component_id} {
            return $url_name
        }
    }
    return {}
}

ad_proc bug_tracker::components_get_url_names {
    {-package_id ""}
} {
    if { $package_id eq "" } {
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
# Description (still used by the patch code, to be removed when they've moved to workflow)
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

ad_proc bug_tracker::patch_action_pretty {
    action
} {

    array set action_codes {
        open bug-tracker.Opened
        edit bug-tracker.Edited
        comment bug-tracker.Comment
        accept bug-tracker.Accepted
        reopen bug-tracker.Reopened
        refuse bug-tracker.Refused
        delete bug-tracker.Deleted
    }

    if { [info exists action_codes($action)] } {
        return [_ $action_codes($action)]
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
    {-package_id ""}
} {
    if { $package_id eq "" } {
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

    set users_list [concat [list [list [_ bug-tracker.Unassigned] "" ]] $users_list]
    lappend users_list [list [_ bug-tracker.Search] ":search:"]

    return $users_list
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

    if { [llength $bug_list] == 0} {
        return ""
    } else {

        foreach bug_item $bug_list {

            lassign $bug_item bug_summary bug_number

            set unmap_url [export_vars -base unmap-patch-from-bug -url { patch_number bug_number } ]
            if { $write_or_submitter_p } {
                set unmap_link [subst {(<a href="[ns_quotehtml $unmap_url]">[_ bug-tracker.unmap]</a>)}]
            } else {
                set unmap_link ""
            }
            lappend bug_link_list "<a href=\"bug?bug_number=$bug_number \">$bug_summary</a> $unmap_link"
        }

        if { [llength $bug_link_list] != 0 } {
            set bugs_string [join $bug_link_list "<br>"]
        } else {
            set bugs_name [bug_tracker::conn bugs]
            set bugs_string [_ bug-tracker.No_Bugs]
        }

        return $bugs_string
    }
}

ad_proc bug_tracker::get_patch_links {
    {-bug_id:required}
    {-show_patch_status open}
} {
    set patch_list [list]

    switch -- $show_patch_status {
        open {
            set status_where_clause "and bt_patches.status = :show_patch_status"
        }
        default {
            set status_where_clause ""
        }
    }

    db_foreach get_patches_for_bug {} {

        set status_indicator [ad_decode $show_patch_status "all" "($status)" ""]
        lappend patch_list "<a href=\"patch?patch_number=$patch_number\" title=\"patch $patch_number\">[ns_quotehtml $summary]</a> $status_indicator"
    } if_no_rows {
        set patches_name [bug_tracker::conn patches]
        set patches_string [_ bug-tracker.No_patches]
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

    if { $patch_file eq "" } {
        # No patch file was uploaded
        return ""
    }

    set tmp_file [ns_queryget patch_file.tmpfile]
    set tmp_file_channel [open $tmp_file r]
    set content [read $tmp_file_channel]
    close $tmp_file_channel

    return $content
}

ad_proc bug_tracker::security_violation {
    -user_id:required
    -bug_id:required
    -action_id:required
} {
    workflow::action::get -action_id $enabled_action(action_id) -array action
    bug_tracker::bug::get -bug_id $bug_id -array bug

    ns_log notice "bug_tracker::security_violation: $user_id doesn't have permission to '$action(pretty_name)' on bug $bug(summary)"
    ad_return_forbidden \
        [_ bug-tracker.Permission_Denied] \
        "<blockquote>[_ bug-tracker.No_Permission_to_do_action]</blockquote>"
    ad_script_abort
}


#####
#
# Projects
#
#####


ad_proc bug_tracker::project_delete { project_id } {
    Delete a Bug Tracker project and all its data.

    @author Peter Marklund
} {
    #manually delete all bugs to avoid weird integrity constraints
    while { [set bug_id [db_string min_bug_id {}]] > 0 } {
        bug_tracker::bug::delete $bug_id
    }
    db_exec_plsql delete_project {}
}

ad_proc bug_tracker::project_new { project_id } {
    Create a new Bug Tracker project for a package instance.

    @author Peter Marklund
} {

    if {![db_0or1row already_there {select 1 from bt_projects where  project_id = :project_id} ] } {
        if {[db_0or1row instance_info { *SQL* } ]} {
            set folder_id [content::folder::new -name "bug_tracker_$project_id" \
                                                -package_id $project_id \
                                                -parent_id $project_id \
                                                -context_id $project_id]
            content::folder::register_content_type -folder_id $folder_id -content_type {bt_bug_revision} -include_subtypes t
            content::folder::register_content_type -folder_id $folder_id -content_type "content_revision"
            content::folder::register_content_type -folder_id $folder_id -content_type "image"

            set keyword_id [content::keyword::new -heading "$instance_name"]

            # Inserts into bt_projects
            set component_id [db_nextval acs_object_id_seq]
            db_dml bt_projects_insert {}
            db_dml bt_components_insert {}
        }
    }
}

ad_proc bug_tracker::version_get_filter_data_not_cached {
    {-package_id:required}
    {-user_id ""}
    {-admin_p "f"}
    {-user_bugs_only_p "f"}
} {
    @param package_id The package (project) to select from
    @return list-of-lists with fix-for-version data for filter
} {
    return [db_list_of_lists select {}]
}

ad_proc bug_tracker::version_get_filter_data {
    {-package_id:required}
    {-user_id ""}
    {-admin_p "f"}
} {
    @param package_id The package (project) to select from
    @param user_id The user to filter by for the ShowMyBugsOnlyP parameter
    @return list-of-lists with fix-for-version data for filter
} {
    set user_bugs_only_p [bug_tracker::user_bugs_only_p]

    return [util_memoize [list bug_tracker::version_get_filter_data_not_cached \
                             -package_id $package_id \
                             -user_id $user_id \
                             -admin_p $admin_p \
                             -user_bugs_only_p $user_bugs_only_p]]
}

ad_proc bug_tracker::assignee_get_filter_data_not_cached {
    {-package_id:required}
    {-workflow_id:required}
    {-action_id:required}
    {-user_id ""}
    {-admin_p "f"}
    {-user_bugs_only_p "f"}
} {
    @param package_id The package (project) to select from
    @param workflow_id The workflow we're interested in
    @param action_id The action we're interested in
    @param user_id User id for optional filtering for logged in user
    @return list-of-lists with assignee data for filter
} {
    return [db_list_of_lists select {}]
}

ad_proc bug_tracker::assignee_get_filter_data {
    {-package_id:required}
    {-workflow_id:required}
    {-action_id:required}
    {-user_id ""}
    {-admin_p "f"}
} {
    @param package_id The package (project) to select from
    @param workflow_id The workflow we're interested in
    @param action_id The action we're interested in
    @param user_id Optional user for filtering by logged in user.
    @return list-of-lists with assignee data for filter
} {
    set user_bugs_only_p [bug_tracker::user_bugs_only_p]

    return [util_memoize [list bug_tracker::assignee_get_filter_data_not_cached \
                             -package_id $package_id \
                             -workflow_id $workflow_id \
                             -action_id $action_id \
                             -user_id $user_id \
                             -admin_p $admin_p \
                             -user_bugs_only_p $user_bugs_only_p]]
}

ad_proc bug_tracker::state_get_filter_data_not_cached {
    {-package_id:required}
    {-workflow_id:required}
    {-user_id ""}
    {-admin_p "f"}
    {-user_bugs_only_p "f"}
} {
    @param package_id The package (project) to select from
    @param workflow_id The workflow we're interested in
    @return list-of-lists with state data for filter
} {
    return [db_list_of_lists select {}]
}

ad_proc bug_tracker::state_get_filter_data {
    {-package_id:required}
    {-workflow_id:required}
    {-user_id ""}
    {-admin_p "f"}
} {
    @param package_id The package (project) to select from
    @param workflow_id The workflow we're interested in
    @return list-of-lists with state data for filter
} {
    set user_bugs_only_p [bug_tracker::user_bugs_only_p]

    return [util_memoize [list bug_tracker::state_get_filter_data_not_cached \
                             -package_id $package_id \
                             -workflow_id $workflow_id \
                             -user_id $user_id \
                             -admin_p $admin_p \
                             -user_bugs_only_p $user_bugs_only_p]]
}

#####
#
# Related Files
#
#####

ad_proc bug_tracker::related_files_p {} {
    Is the related files submission feature turned on?
} {
    return [parameter::get -package_id [ad_conn package_id] -parameter "RelatedFilesP" -default 1]
}

ad_proc bug_tracker::get_related_files_links {
    {-bug_id:required}
} {
    set related_files_list [list]
    set user_id [ad_conn user_id]
    set admin_p [permission::permission_p \
                     -party_id $user_id \
                     -object_id [ad_conn package_id] \
                     -privilege "admin"]
    set return_url [ad_return_url]

    db_foreach get_related_files_for_bug {} {
        set view_url [export_vars -base related-file-download {bug_id related_object_id {t $related_revision_id}}]
        set properties_url [export_vars -base "related-file-properties" {bug_id related_object_id}]
        set delete_url [export_vars -base "related-file-delete" {bug_id related_object_id return_url}]
        set new_version_url [export_vars -base "related-file-update" {bug_id related_object_id return_url}]
        if { $related_creation_user == $user_id || $admin_p } {
            set extra_actions [subst { |
                <a href="[ns_quotehtml $new_version_url]">[_ bug-tracker.upload_new_version]</a> |
                <a href="[ns_quotehtml $delete_url]">[_ bug-tracker.delete]</a>
            }]
        } else {
            set extra_actions ""
        }
        lappend related_files_list [subst {$related_title
            <a href="[ns_quotehtml $view_url]">[_ bug-tracker.download]</a> |
            <a href="[ns_quotehtml $properties_url]">[_ bug-tracker.properties]</a>$extra_actions
        }]
    } if_no_rows {
        set related_files_string [_ bug-tracker.No_related_files]
    }

    if { [llength $related_files_list] != 0 } {
        set related_files_string [join $related_files_list "<br>"]
    }

    return $related_files_string
}

#####
#
# Related Files
#
#####

ad_proc bug_tracker::related_files_p {} {
    Is the related files submission feature turned on?
} {
    return [parameter::get -package_id [ad_conn package_id] -parameter "RelatedFilesP" -default 1]
}

ad_proc bug_tracker::get_related_files_links {
    {-bug_id:required}
} {
    set related_files_list [list]
    set user_id [ad_conn user_id]
    set admin_p [permission::permission_p \
                     -party_id $user_id \
                     -object_id [ad_conn package_id] \
                     -privilege "admin"]
    set return_url [ad_return_url]

    db_foreach get_related_files_for_bug {} {
        set view_url [export_vars -base related-file-download {bug_id related_object_id {t $related_revision_id}}]
        set properties_url [export_vars -base "related-file-properties" {bug_id related_object_id}]
        set delete_url [export_vars -base "related-file-delete" {bug_id related_object_id return_url}]
        set new_version_url [export_vars -base "related-file-update" {bug_id related_object_id return_url}]
        if { $related_creation_user == $user_id || $admin_p } {
            set extra_actions [subst { |
                <a href="[ns_quotehtml $new_version_url]">upload new version</a> |
                <a href="[ns_quotehtml $delete_url]">delete</a>
            }]
        } else {
            set extra_actions ""
        }
        lappend related_files_list [subst {$related_title
            <a href="[ns_quotehtml $view_url]">download</a> |
            <a href="[ns_quotehtml $properties_url]">properties</a>$extra_actions
        }]
    } if_no_rows {
        set related_files_string [_ bug-tracker.No_related_files]
    }

    if { [llength $related_files_list] != 0 } {
        set related_files_string [join $related_files_list "<br>"]
    }

    return $related_files_string
}

ad_proc -public bug_tracker::user_bugs_only_p {} {
    Is the user bugs only feature turned on?
    Admins always see all bugs.
} {
    return [expr {[lindex [bug_tracker::access_policy] 1] eq "user_bugs"}]
}

ad_proc -private bug_tracker::set_access_policy {
    {-all_bugs:boolean "f"}
    {-user_bugs:boolean "f"}
} {
    Set/unset direct permissions on existing bugs.
    @param all_bugs The user can see all bugs
    @param user_bugs The user can only see the bugs they are participating in.
} {
    if {$all_bugs_p && $user_bugs_p} {
        error "Select either -all_bugs or -user_bugs but not both"
    }
    set package_id [ad_conn package_id]
    set all_users [db_list get_all_users {}]
    if {$all_bugs_p} {
        set bug_ids [db_list get_all_bugs {}]
        foreach user_id $all_users {
            foreach bug_id $bug_ids {
                bug_tracker::inherit -bug_id $bug_id -party_id $user_id
            }
        }
    } elseif {$user_bugs_p} {
        foreach user_id $all_users {
            set bug_ids [db_list get_user_bugs {}]
            foreach bug_id $bug_ids {
                bug_tracker::grant_direct_read_permission -bug_id $bug_id -party_id $user_id
            }
        }
    }
}

ad_proc -private bug_tracker::grant_direct_read_permission {
    {-bug_id:required}
    {-party_id:required}
} {
    Grant direct read permissions
} {
    permission::set_not_inherit -object_id $bug_id
    permission::grant -object_id $bug_id -party_id $party_id -privilege read
}

ad_proc -private bug_tracker::inherit {
    {-bug_id:required}
    {-party_id:required}
} {
    Grant direct read permissions
} {
    permission::set_inherit -object_id $bug_id
    permission::revoke -object_id $bug_id -party_id $party_id -privilege read
}

ad_proc -public bug_tracker::access_policy {} {
    Detect and return the current access policy.
} {
    set package_id [ad_conn package_id]
    db_1row get_bug {}
    if {[permission::inherit_p -object_id $bug_id]} {
        return [list "#bug-tracker.Show_all_bugs#" all_bugs]
    } else {
        return [list "#bug-tracker.Show_user_bugs_only#" user_bugs]
    }
}


ad_proc -private bug_tracker::user_bugs_only_where_clause {} {
    Return the where clause fragment if only user's bugs should appear
} {
    if {[bug_tracker::user_bugs_only_p]} {
        return [db_map user_bugs_only]
    }
}

# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
