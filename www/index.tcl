ad_page_contract {
    Bug listing page.
    
    @author Lars Pind (lars@pinds.com)
    @creation-date 2002-03-20
    @cvs-id $Id$
} {
    filter:optional,array,multiple
}

ad_require_permission [ad_conn package_id] read

set project_name [bug_tracker::conn project_name]
set package_id [ad_conn package_id]
set package_key [ad_conn package_key]

bug_tracker::get_pretty_names -array pretty_names

set project_root_keyword_id [bug_tracker::conn project_root_keyword_id]

# Is this project using multiple versions?
set versions_p [bug_tracker::versions_p]

if { [info exists filter] } {
    if { [array names filter] == [list "assignee"] && $filter(assignee) == [ad_conn user_id] } {
        set context_bar [bug_tracker::context_bar "My [bug_tracker::conn bugs]"]
    } else {
        set context_bar [bug_tracker::context_bar "Filtered [bug_tracker::conn bug] list"]
    }
} else {
    set context_bar [bug_tracker::context_bar]
}

set admin_p [ad_permission_p [ad_conn package_id] admin]

set return_url "[ad_conn url][ad_decode [ad_conn query] "" "" "?[ad_conn query]"]"

set num_components [db_string num_components {}]

if { $num_components == 0 } {
    ad_return_template "no-components"
    return
}

if { ![bug_tracker::bugs_exist_p] } {
    ad_return_template "no-bugs"
    return
}


#####
#
# Filter management
#
#####

set filter_parsed [bug_tracker::parse_filters filter]

set human_readable_filter [bug_tracker::conn filter_human_readable]
set where_clauses [bug_tracker::conn filter_where_clauses]
set from_bug_clause [bug_tracker::conn filter_from_bug_clause]
set order_by_clause [bug_tracker::conn filter_order_by_clause]

lappend where_clauses "b.project_id = :package_id"

if { [llength [array names filter]] > 0 && [array names filter] != "orderby" } {
    set clear_url [ad_conn package_url]
}

#####
#
# Order by
#
#####

if { [info exists filter(orderby)] } { 
    set save_orderby $filter(orderby)
    unset filter(orderby)
}
set displaymode_form_export_vars [export_vars -form { filter:array }]
if { [info exists save_orderby] } {
    set filter(orderby) $save_orderby
    unset save_orderby
}

multirow create orderby value label selected_p

multirow append orderby {} "[bug_tracker::conn Bug] number" [exists_and_equal filter(orderby) {}]


foreach { category_type_id label } [bug_tracker::category_types] {
    multirow append orderby \
        $category_type_id \
        $label \
        [exists_and_equal filter(orderby) $category_type_id]
}


#####
#
# Last n days filter
#
#####

multirow create options_n_days url label selected_p 

foreach n_days { 1 3 7 30 90 365 all } {
    multirow append options_n_days ".?[bug_tracker::filter_url_vars -array filter -override [list n_days $n_days]]" $n_days [exists_and_equal filter_n_days $n_days]

}


#####
#
# Get bug list
#
#####

set truncate_len [ad_parameter "TruncateDescriptionLength" -default 200]

set workflow_id [bug_tracker::bug::get_instance_workflow_id]
set initial_state_id [workflow::fsm::get_initial_state -workflow_id $workflow_id]

# Role will be assignee or submitter
set action_role [db_string select_resolve_role {}]

set initial_action_id [workflow::get_element -workflow_id $workflow_id -element initial_action_id]

set bugs_count 0
set last_bug_id {}

db_multirow -extend { 
    comment_short
    submitter_url 
    status_pretty
    resolution_pretty
    assignee_url
    bug_url
    component_name
    found_in_version_name
    fix_for_version_name
    fixed_in_version_name
    category_name
    category_value
} bugs bugs {} {

    if { ![string equal $bug_id $last_bug_id] } {
        incr bugs_count
        set last_bug_id $bug_id
    }

    set component_name [bug_tracker::component_get_name -component_id $component_id]
    set found_in_version_name [bug_tracker::version_get_name -version_id $found_in_version]
    set fix_for_version_name [bug_tracker::version_get_name -version_id $fix_for_version]
    set fixed_in_version_name [bug_tracker::version_get_name -version_id $fixed_in_version]
    set comment_short [string_truncate -len $truncate_len -format $comment_format $comment_content]
    set summary [ad_quotehtml $summary]
    set submitter_url [acs_community_member_url -user_id $submitter_user_id]
    set resolution_pretty [bug_tracker::resolution_pretty $resolution]
    set assignee_url {}
    if { ![empty_string_p $assignee_party_id] } {
        set assignee_url [acs_community_member_url -user_id $assignee_party_id]
    }
    set bug_url "bug?[export_vars { bug_number filter:array }]"
    set category_name [bug_tracker::category_parent_heading -keyword_id $keyword_id]
    set category_value [bug_tracker::category_heading -keyword_id $keyword_id]
    
    # Hide fields in this state
    foreach element $hide_fields {
        set $element {}
    }
}


#####
#
# Get stats
#
#####

# Stat: Status

db_multirow -extend { name_url stat_name header selected_p } stats by_status {} {
    set header "All [bug_tracker::conn bugs] by status:"
    set stat_name "Status"
    set name_url "?[bug_tracker::filter_url_vars -array filter -override [list status $unique_id]]"
    set selected_p [expr { [info exists filter(status)] && [string equal $filter(status) $unique_id] }]
}

set open_bugs_header "Open [bug_tracker::conn bugs] summary:"

# Stat: By Category

foreach { parent_id parent_heading } [bug_tracker::category_types] {
    db_multirow -extend { header selected_p stat_name name name_url } -append stats stats_by_category {} {
        set header $open_bugs_header
        set stat_name "By $parent_heading"
        set name [bug_tracker::category_heading -keyword_id $unique_id]
        set name_url "?[bug_tracker::filter_url_vars -array filter -override [list keyword $unique_id]]"
        set selected_p [expr { [info exists filter(keyword)] && [lsearch -exact $filter(keyword) $unique_id] != -1 }]
    }
}

# Stat: Fix for version

if { $versions_p } {
    db_multirow -extend { name_url stat_name header selected_p } -append stats stats_by_fix_for_version {} {
        set header $open_bugs_header
        set stat_name "Fix For"
        if { [empty_string_p $unique_id] } {
            set name "<i>Undecided</i>"
        }
        set name_url "?[bug_tracker::filter_url_vars -array filter -override [list fix_for_version $unique_id]]"
        set selected_p [expr { [info exists filter(fix_for_version)] && [string equal $filter(fix_for_version) $unique_id] }]
    }
}


# Stat: Assigned action

db_multirow -extend { name_url header selected_p } -append stats stats_by_assigned_action {} {
    set header $open_bugs_header

    regexp {^([0-9]+)\.([0-9]+)\.([0-9]+)$} $unique_id match action_id state_id assignee_id

    set name_url "?[bug_tracker::filter_url_vars -array filter -override [list assignee $assignee_id status $state_id]]"
    set selected_p [expr { [exists_and_equal filter(assignee) $assignee_id] && \
                           [exists_and_equal filter(status) $state_id] } ]
}

# Stat: Unassigned action

db_multirow -extend { unique_id name stat_name name_url header selected_p } -append stats stats_by_unassigned_action {} {
    set header $open_bugs_header

    set name "<i>Unassigned</i>"
    set stat_name "Resolve"

    set unique_id "."
    set action_id ""
    set assignee_id ""

    set name_url "?[bug_tracker::filter_url_vars -array filter -override [list assignee $assignee_id status $initial_state_id]]"
    set selected_p [expr { [exists_and_equal filter(assignee) $assignee_id] && \
                           [exists_and_equal filter(status) $initial_state_id] } ]
}

# Stat: By Component

db_multirow -extend { name_url stat_name header selected_p } -append stats stats_by_component {} {
    set header $open_bugs_header
    set stat_name "[bug_tracker::conn Components]"
    if { [string match "com/*" $unique_id] } {
        set name_url "[ad_conn package_url]$unique_id"
    } else {
        set name_url "[ad_conn package_url]?[bug_tracker::filter_url_vars -array filter -override [list component_id $unique_id]]"
    }
    set selected_p [expr { [exists_and_equal filter(component_id) $unique_id] || [string equal [ad_conn extra_url] $unique_id] }]
}
