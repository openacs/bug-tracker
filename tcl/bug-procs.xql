<?xml version="1.0"?>
<queryset>

<fullquery name="bug_tracker::bug::get.select_bug_data">
    <querytext>
      select b.bug_id,
             b.project_id,
             b.bug_number,
             b.summary,
             b.component_id,
             to_char(b.creation_date,'YYYY-MM-DD HH24:MI:SS') as creation_date,
             to_char(b.creation_date, 'YYYY-MM-DD HH24:MI:SS') as creation_date_pretty,
             b.resolution,
             b.user_agent,
             b.found_in_version,
             b.found_in_version,
             b.fix_for_version,
             b.fixed_in_version,
             to_char(current_timestamp, 'YYYY-MM-DD HH24:MI:SS') as now_pretty
      from   bt_bugs b
      where  b.bug_id = :bug_id
    </querytext>
</fullquery>

<fullquery name="bug_tracker::bug::insert.select_sysdate">
    <querytext>
        select current_timestamp from dual
    </querytext>
</fullquery>

<partialquery name="bug_tracker::bug::get_query.orderby_category_from_bug_clause">
  <querytext>
         left outer join cr_item_keyword_map km_order on (km_order.item_id = b.bug_id) 
         join cr_keywords kw_order on (km_order.keyword_id = kw_order.keyword_id and kw_order.parent_id = [ns_dbquotevalue $orderby_parent_id])
  </querytext>
</partialquery>
 
<!-- bd: the inline view assign_info returns names
     of assignees as well as pretty_names of assigned actions.
     I'm left-outer-joining against this view.

     WARNING: In the query below I assume there can be at most one
     person assigned to a bug.  If more people are assigned you will get
     multiple rows per bug in the result set.  Current bug tracker
     doesn't have UI for creating such conditions. If you add UI that
     allows user to break this assumption you'll also need to deal with
     this.
-->
<fullquery name="bug_tracker::bug::get_query.bugs_pagination">
  <querytext>
    select b.bug_id,
           b.project_id,
           b.bug_number,
           b.summary,
           lower(b.summary) as lower_summary,
           b.comment_content,
           b.comment_format,
           b.component_id,
           b.creation_date,
           to_char(b.creation_date, 'YYYY-MM-DD HH24:MI:SS') as creation_date_pretty,
           b.creation_user as submitter_user_id,
           submitter.first_names as submitter_first_names,
           submitter.last_name as submitter_last_name,
           submitter.email as submitter_email,
           lower(submitter.first_names) as lower_submitter_first_names,
           lower(submitter.last_name) as lower_submitter_last_name,
           lower(submitter.email) as lower_submitter_email,
           st.pretty_name as pretty_state,
           st.short_name as state_short_name,
           st.state_id,
           st.hide_fields,
           b.resolution,
           b.found_in_version,
           b.fix_for_version,
           b.fixed_in_version,
           cas.case_id
           $more_columns
    from $from_bug_clause,
         acs_users_all submitter,
         workflow_cases cas,
         workflow_case_fsm cfsm,
         workflow_fsm_states st 
    where submitter.user_id = b.creation_user
      and cas.workflow_id = :workflow_id
      and cas.object_id = b.bug_id
      and cfsm.case_id = cas.case_id
      and cfsm.parent_enabled_action_id is null
      and st.state_id = cfsm.current_state 
      [bug_tracker::user_bugs_only_where_clause]
    [template::list::filter_where_clauses -and -name "bugs"]
    [template::list::orderby_clause -orderby -name "bugs"]
  </querytext>
</fullquery>

<fullquery name="bug_tracker::bug::get_query.bugs">
  <querytext>
select q.*,
       km.keyword_id,
       assign_info.*
from (
  select b.bug_id,
         b.project_id,
         b.bug_number,
         b.summary,
         lower(b.summary) as lower_summary,
         b.comment_content,
         b.comment_format,
         b.component_id,
         to_char(b.creation_date,'YYYY-MM-DD HH24:MI:SS') as creation_date,
         to_char(b.creation_date, 'YYYY-MM-DD HH24:MI:SS') as creation_date_pretty,
         b.creation_user as submitter_user_id,
         submitter.first_names as submitter_first_names,
         submitter.last_name as submitter_last_name,
         submitter.email as submitter_email,
         lower(submitter.first_names) as lower_submitter_first_names,
         lower(submitter.last_name) as lower_submitter_last_name,
         lower(submitter.email) as lower_submitter_email,
         st.pretty_name as pretty_state,
         st.short_name as state_short_name,
         st.state_id,
         st.hide_fields,
         b.resolution,
         b.found_in_version,
         b.fix_for_version,
         b.fixed_in_version,
         cas.case_id
         $more_columns
    from $from_bug_clause,
         acs_users_all submitter,
         workflow_cases cas,
         workflow_case_fsm cfsm,
         workflow_fsm_states st 
   where submitter.user_id = b.creation_user
     and cas.workflow_id = :workflow_id
     and cas.object_id = b.bug_id
     and cfsm.case_id = cas.case_id
     and cfsm.parent_enabled_action_id is null
     and st.state_id = cfsm.current_state
   [template::list::filter_where_clauses -and -name "bugs"]
   [bug_tracker::user_bugs_only_where_clause]
   [template::list::page_where_clause -and -name bugs -key bug_id]
) q
left outer join
  cr_item_keyword_map km
on (bug_id = km.item_id)
left outer join
  (select cru.user_id as assigned_user_id,
          aa.action_id,
          aa.case_id,
          wa.pretty_name as action_pretty_name,
          p.first_names as assignee_first_names,
          p.last_name as assignee_last_name
     from workflow_case_assigned_actions aa,
          workflow_case_role_user_map cru,
          workflow_actions wa,
	  persons p
    where aa.case_id = cru.case_id
      and aa.role_id = cru.role_id
      and cru.user_id = p.person_id
      and wa.action_id = aa.action_id
  ) assign_info
on (q.case_id = assign_info.case_id)
   [template::list::orderby_clause -orderby -name "bugs"]
  </querytext>
</fullquery>

<partialquery name="bug_tracker::bug::get_list.filter_assignee_null_where_clause">
  <querytext>
          exists (select 1
                  from workflow_case_assigned_actions aa left outer join
                    workflow_case_role_party_map wcrpm
                      on (wcrpm.case_id = aa.case_id and wcrpm.role_id = aa.role_id)
                  where aa.case_id = cas.case_id
                    and aa.action_id = $action_id
                    and wcrpm.party_id is null
                 )
  </querytext>
</partialquery>

<fullquery name="bug_tracker::bug::cache_flush.get_project_id">
    <querytext>
      select project_id from bt_bugs where bug_id = :bug_id
    </querytext>
</fullquery>

<fullquery name="bug_tracker::bug::delete.get_case_id">
    <querytext>
        select case_id
        from   workflow_cases
        where  object_id = :bug_id
    </querytext>
</fullquery>

<fullquery name="bug_tracker::bug::get_instance_workflow_id.get_instance_workflow_id">
    <querytext>
        select workflow_Id
        from bt_projects
        where project_id = :package_id
    </querytext>
</fullquery>

<fullquery name="bug_tracker::bug::instance_workflow_create.get_workflow_id">
    <querytext>
      select w1.workflow_id
      from workflows w, workflows w1
      where w.workflow_id = :workflow_id
        and w.short_name = w1.short_name
        and w1.object_id = :package_id
    </querytext>
</fullquery>

<fullquery name="bug_tracker::bug::instance_workflow_create.update_project">
    <querytext>
      update bt_projects
      set workflow_id = :workflow_id
      where project_id = :package_id
    </querytext>
</fullquery>

<fullquery name="bug_tracker::bug::instance_workflow_delete.update_project">
    <querytext>
      update bt_projects
      set workflow_id = null
      where project_id = :package_id
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
             to_char(ba.action_date, 'YYYY-MM-DD HH24:MI:SS') as action_date_pretty,
             ba.comment_s,
             ba.comment_format
      from   bt_bug_actions ba,
             cc_users actor
      where  ba.bug_id = :bug_id
      and    actor.user_id = ba.actor
      order  by action_date
    </querytext>
  </fullquery>

  <fullquery name="bug_tracker::bug::capture_resolution_code::do_side_effect.select_resolution_code">
    <querytext>
        select resolution
        from   bt_bugs
        where  bug_id = :object_id
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
 
  <partialquery name="bug_tracker::bug::get_list.filter_assignee_where_clause">
      <querytext>
          exists (select 1
                  from   workflow_case_assigned_actions aa,
                    workflow_case_role_party_map wcrpm
                  where  aa.case_id = cas.case_id
                  and    aa.action_id = $action_id
                  and    wcrpm.case_id = aa.case_id
                  and    wcrpm.role_id = aa.role_id
                  and    wcrpm.party_id = :f_action_$action_id
                 )
      </querytext>
  </partialquery>

</queryset>

