ad_page_contract {
    Bug listing page.
    
    @author Lars Pind (lars@pinds.com)
    @creation-date 2002-03-20
    @cvs-id $Id$
} {
    filter:optional,array
}

ad_require_permission [ad_conn package_id] read

set project_name [bug_tracker::conn project_name]
set package_id [ad_conn package_id]
set package_key [ad_conn package_key]

if { [info exists filter] } {
    if { [array names filter] == [list "actionby"] && $filter(actionby) == [ad_conn user_id] } {
        set context_bar [bug_tracker::context_bar "My bugs"]
    } else {
        set context_bar [bug_tracker::context_bar "Filtered bug list"]
    }
} else {
    set context_bar [bug_tracker::context_bar]
}

set admin_p [ad_permission_p [ad_conn package_id] admin]

set return_url "[ad_conn url][ad_decode [ad_conn query] "" "" "?[ad_conn query]"]"

set num_components [db_string num_components { select count(component_id) from bt_components where project_id = :package_id }]

if { $num_components == 0 } {
    ad_return_template "no-components"
    return
}

set num_bugs [db_string num_bugs { select count(bug_id) from bt_bugs where project_id = :package_id }]

set user_id [ad_conn user_id]

# Notifications for a project. Provide a link for logged in users
set notification_link [bug_tracker::get_notification_link \
        -type       bug_tracker_project_notif \
        -object_id  $package_id \
        -url        $return_url \
        -pretty_name "project"]

if { $num_bugs == 0 } {
    ad_return_template "no-bugs"
    return
}

#
# Filter management
#

set filter_parsed [bug_tracker::parse_filters filter]

set human_readable_filter [bug_tracker::conn filter_human_readable]
set where_clauses [bug_tracker::conn filter_where_clauses]
set order_by_clause [bug_tracker::conn filter_order_by_clause]

lappend where_clauses "b.project_id = :package_id"

if { [llength [array names filter]] > 0 } {
    set clear_url [ad_conn package_url]
}

#
# Order by
#

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
foreach value { "" severity priority } label { "Bug number" "Severity" "Priority" } {
    if { [info exists filter(orderby)] && [string equal $filter(orderby) $value] } {
        set selected_p 1
    } else {
        set selected_p 0
    }
    multirow append orderby $value $label $selected_p
}

#
# Get bug list
#

set truncate_len [ad_parameter "TruncateDescriptionLength" -default 200]

db_multirow -extend { description_short submitter_url status_pretty resolution_pretty bug_type_pretty original_esimate_pretty latest_estimate_pretty elapsed_time_pretty assignee_url bug_url } bugs bugs "
    select b.bug_id,
           b.bug_number,
           b.summary,
           bact.comment as description,
           bact.comment_format as desc_format,
           b.component_id,
           c.component_name,
           o.creation_date,
           to_char(o.creation_date, 'fmMM/DDfm/YYYY') as creation_date_pretty,
           o.creation_user as submitter_user_id,
           submitter.first_names as submitter_first_names,
           submitter.last_name as submitter_last_name,
           submitter.email as submitter_email,
           pc.sort_order || ' - ' || pc.priority_name as priority_pretty,
           sc.sort_order || ' - ' || sc.severity_name as severity_pretty,
           b.status,
           b.resolution,
           b.bug_type,
           b.original_estimate_minutes,
           b.latest_estimate_minutes, 
           b.elapsed_time_minutes,
           b.found_in_version,
           coalesce((select version_name 
                     from   bt_versions found_in_v 
                     where  found_in_v.version_id = b.found_in_version), 'Unknown') as found_in_version_name,
           b.fix_for_version,
           coalesce((select version_name 
                     from   bt_versions fix_for_v 
                     where  fix_for_v.version_id = b.fix_for_version), 'Undecided') as fix_for_version_name,
           b.fixed_in_version,
           coalesce((select version_name 
                     from   bt_versions fixed_in_v 
                     where  fixed_in_v.version_id = b.fixed_in_version), 'Unknown') as fixed_in_version_name,
           b.assignee as assignee_user_id,
           assignee.first_names as assignee_first_names,
           assignee.last_name as assignee_last_name,
           assignee.email as assignee_email
    from   bt_bugs b left outer join
           cc_users assignee on (assignee.user_id = b.assignee),
           bt_bug_actions bact,
           bt_components c,
           acs_objects o,
           bt_priority_codes pc,
           bt_severity_codes sc,
           cc_users submitter
    where  c.component_id = b.component_id
    and    bact.bug_id = b.bug_id
    and    bact.action = 'open'
    and    o.object_id = b.bug_id
    and    pc.priority_id = b.priority
    and    sc.severity_id = b.severity
    and    submitter.user_id = o.creation_user
    and    [join $where_clauses " and "]
    order  by $order_by_clause
" {
    set description_short [string_truncate -len $truncate_len -format $desc_format -- $description]
    set summary [ad_quotehtml $summary]
    set submitter_url [acs_community_member_url -user_id $submitter_user_id]
    set status_pretty [bug_tracker::status_pretty $status]
    set resolution_pretty [bug_tracker::resolution_pretty $resolution]
    set bug_type_pretty [bug_tracker::bug_type_pretty $bug_type]
    set original_estimate_pretty [ad_decode $original_estimate_minutes "" "" 0 "" "$original_estimate_minutes minutes"]
    set latest_estimate_pretty [ad_decode $latest_estimate_minutes "" "" 0 "" "$latest_estimate_minutes minutes"]
    set elapsed_time_pretty [ad_decode $elapsed_time_minutes "" "" 0 "" "$elapsed_time_minutes minutes"]
    set assignee_url [acs_community_member_url -user_id $assignee_user_id]
    set bug_url "bug?[export_vars { bug_number filter:array }]"
}

#
# Get stats
#

db_multirow -extend { name name_url } by_status by_status {
    select b.status as unique_id,
           count(b.bug_id) as num_bugs
    from   bt_bugs b
    where  b.project_id = :package_id
    group  by unique_id
    order  by bt_bug__status_sort_order(b.status)
} {
    set name "[bug_tracker::status_pretty $unique_id] Bugs"
    set name_url "?[export_vars { { filter.status $unique_id } }]"
}

db_multirow -extend { name name_url stat_name } stats stats_by_bug_type {
    select b.bug_type as unique_id,
           count(b.bug_id) as num_bugs
    from   bt_bugs b
    where  b.project_id = :package_id
    and    b.status = 'open'
    group  by unique_id
    order  by bt_bug__bug_type_sort_order(b.bug_type) 
} {
    set stat_name "Type of bug"
    set name [bug_tracker::bug_type_pretty $unique_id]
    set name_url "?[export_vars { { filter.bug_type $unique_id } }]"
}

db_multirow -extend { name_url stat_name } -append stats stats_by_fix_for_version {
    select b.fix_for_version as unique_id,
           v.version_name as name,
           count(b.bug_id) as num_bugs
    from   bt_bugs b left outer join
           bt_versions v on (v.version_id = b.fix_for_version)
    where  b.project_id = :package_id
    and    b.status = 'open'
    group  by unique_id, v.anticipated_freeze_date, name
    order  by v.anticipated_freeze_date, name
} {
    set stat_name "Fix For"
    if { [empty_string_p $unique_id] } {
        set name "<i>Undecided</i>"
    }
    set name_url "?[export_vars { { filter.fix_for_version $unique_id } }]"
}

set stat_name_val "Severity"

db_multirow -extend { name_url stat_name } -append stats stats_by_severity {
    select b.severity as unique_id,
           p.sort_order || ' - ' || p.severity_name as name,
           count(b.bug_id) as num_bugs
    from   bt_bugs b left join
           bt_severity_codes p on (p.severity_id = b.severity)
    where  b.project_id = :package_id
    and    b.status = 'open'
    group  by unique_id, name
    order  by name
} {
    set stat_name $stat_name_val
    set name_url "?[export_vars { { filter.severity $unique_id } }]"
}

set stat_name_val "Priority"

db_multirow -extend { name_url stat_name } -append stats stats_by_priority {
    select b.priority as unique_id,
           p.sort_order || ' - ' || p.priority_name as name,
           count(b.bug_id) as num_bugs
    from   bt_bugs b left join
           bt_priority_codes p on (p.priority_id = b.priority)
    where  b.project_id = :package_id
    and    b.status = 'open'
    group  by unique_id, name
    order  by name
} {
    set stat_name $stat_name_val
    set name_url "?[export_vars { { filter.priority $unique_id } }]"
}

db_multirow -extend { name_url stat_name } -append stats stats_by_assignee {
    select b.assignee as unique_id,
           assignee.first_names || ' ' || assignee.last_name as name,
           count(b.bug_id) as num_bugs
    from   bt_bugs b left outer join
           cc_users assignee on (assignee.user_id = b.assignee)
    where  b.project_id = :package_id
    and    b.status = 'open'
    group  by unique_id, name
    order  by name
} {
    set stat_name "Assigned To"
    if { [empty_string_p $unique_id] } {
        set name "<i>Unassigned</i>"
    }
    set name_url "?[export_vars -url { { filter.assignee $unique_id } }]"
}

db_multirow -extend { name_url stat_name } -append stats stats_by_actionby {
    select o.creation_user as unique_id,
           submitter.first_names || ' ' || submitter.last_name as name,
           count(b.bug_id) as num_bugs
    from   bt_bugs b join
           acs_objects o on (object_id = bug_id) join
           cc_users submitter on (submitter.user_id = o.creation_user)
    where  b.project_id = :package_id
    and    b.status = 'resolved'
    group  by unique_id, name
    order  by name
} {
    set stat_name "To Be Verified By"
    set name_url "?[export_vars -url { { filter.status resolved } { filter.actionby $unique_id } }]"
}

db_multirow -extend { name_url stat_name } -append stats stats_by_component {
    select coalesce('com/'||c.url_name||'/', trim(to_char(c.component_id,'99999999'))) as unique_id,
           c.component_name as name,
           count(b.bug_id) as num_bugs
    from   bt_bugs b left join
           bt_components c on (c.component_id = b.component_id)
    where  b.project_id = :package_id
    and    b.status = 'open'
    group  by unique_id, name
    order  by name
} {
    set stat_name "Components"
    if { [string match "com/*" $unique_id] } {
        set name_url "[ad_conn package_url]$unique_id"
    } else {
        set name_url "[ad_conn package_url]?[export_vars -url { { filter.component_id $unique_id } }]"
    }
}

ad_return_template
