<?xml version="1.0"?>
<queryset>

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
             ba.comment_s,
             ba.comment_format
      from   bt_bug_actions ba,
             cc_users actor
      where  ba.bug_id = :bug_id
      and    actor.user_id = ba.actor
      order  by action_date
    </querytext>
  </fullquery>

  <fullquery name="bug_tracker::bug::capture_resolution_code::do_side_effect.insert_resolution_code">
    <querytext>
        insert into workflow_case_log_data
          (entry_id, key, value)
        select :entry_id, 'resolution', resolution
        from   bt_bugs
        where  bug_id = :object_id
    </querytext>
  </fullquery>

  <fullquery name="bug_tracker::bug::format_log_title::format_log_title.select_resolution">
    <querytext>
        select value
        from   workflow_case_log_data
        where  entry_id = :entry_id
        and    key = 'resolution'
    </querytext>
  </fullquery>

  <fullquery name="bug_tracker::bug::get_component_maintainer::get_assignees.select_component_maintainer">
    <querytext>
        select c.maintainer
        from   bt_components c,
               bt_bugs b
        where  b.bug_id = :object_id
        and    c.component_id = b.component_id
    </querytext>
  </fullquery>

  <fullquery name="bug_tracker::bug::get_project_maintainer::get_assignees.select_project_maintainer">
    <querytext>
        select p.maintainer
        from   bt_projects p,
               bt_bugs b
        where  b.bug_id = :object_id
        and    p.project_id = b.project_id
    </querytext>
  </fullquery>

  <fullquery name="bug_tracker::bug::notification_info::get_notification_info.select_notification_tag">
    <querytext>
        select email_subject_name
        from   bt_projects p,
               bt_bugs b
        where  b.bug_id = :object_id
        and    p.project_id = b.project_id
    </querytext>
  </fullquery>

</queryset>

