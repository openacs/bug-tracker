<?xml version="1.0"?>

<queryset>
  <rdbms><type>postgresql</type><version>7.1</version></rdbms>

  <fullquery name="bug_tracker::bug::get.select_bug_data">
    <querytext>
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
             b.assignee,
             asgnu.first_names as assignee_first_names,
             asgnu.last_name as assignee_last_name,
             asgnu.email as assignee_email,
             to_char(now(), 'fmMM/DDfm/YYYY') as now_pretty
      from   bt_bugs b left outer join
             cc_users asgnu on (asgnu.user_id = b.assignee),
             acs_objects o,
             bt_components c,
             bt_priority_codes pc,
             bt_severity_codes sc,
             cc_users submitter
      where  b.bug_id = :bug_id
      and    o.object_id = b.bug_id
      and    c.component_id = b.component_id
      and    pc.priority_id = b.priority
      and    sc.severity_id = b.severity
      and    submitter.user_id = o.creation_user
    </querytext>
  </fullquery>

  <fullquery name="bug_tracker::bug::get_activity_html.actions">
    <querytext>
      select ba.action_id,
             ba.action as loop_action,
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
    </querytext>
  </fullquery>

  <fullquery name="bug_tracker::bug::insert.bug_new">
    <querytext>
      select bt_bug__new(
          :bug_id,
          :package_id,
          :component_id,
          :bug_type,
          :severity,
          :priority,
          :found_in_version,
          :summary,
          :description,
          :desc_format,
          :user_agent,
          :user_id,
          :ip_address
      )
    </querytext>
  </fullquery>

</queryset>
