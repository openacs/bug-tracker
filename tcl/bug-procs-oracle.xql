<?xml version="1.0"?>

<queryset>
   <rdbms><type>oracle</type><version>8.1.6</version></rdbms>

  <fullquery name="bug_tracker::bug::get.select_bug_data">
    <querytext>
      select b.bug_id,
             b.project_id,
             b.bug_number,
             b.summary,
             b.component_id,
             b.creation_date,
             to_char(b.creation_date, 'fmMM/DDfm/YYYY') as creation_date_pretty,
             b.resolution,
             b.user_agent,
             b.found_in_version,
             b.found_in_version,
             b.fix_for_version,
             b.fixed_in_version,
             to_char(sysdate, 'fmMM/DDfm/YYYY') as now_pretty
      from   bt_bugs b
      where  b.bug_id = :bug_id
    </querytext>
  </fullquery>

  <fullquery name="bug_tracker::bug::update.update_bug">
    <querytext>
        begin
            :1 := bt_bug_revision.new (
                bug_revision_id =>  null,
                bug_id =>           :bug_id,
                component_id =>     :component_id,
                found_in_version => :found_in_version,
                fix_for_version =>  :fix_for_version,
                fixed_in_version => :fixed_in_version,
                resolution =>       :resolution,
                user_agent =>       :user_agent,
                summary =>          :summary,
                creation_date =>    sysdate,
                creation_user =>    :creation_user,
                creation_ip =>      :creation_ip
            );
        end;
    </querytext>
  </fullquery>

  <fullquery name="bug_tracker::bug::insert.select_sysdate">
    <querytext>
        select sysdate from dual
    </querytext>
  </fullquery>


<fullquery name="bug_tracker::bug::delete.delete_bug_case">
    <querytext> 
        begin
             workflow_case_pkg.delete(:case_id);
        end;
    </querytext>
</fullquery>
 
<fullquery name="bug_tracker::bug::delete.delete_notification">
    <querytext>
        begin
             notification.delete(:notification_id);
        end;
    </querytext>
</fullquery>

<fullquery name="bug_tracker::bug::delete.delete_cr_item">
    <querytext>
        begin
             content_item.delete(:bug_id);
        end;
    </querytext>
</fullquery>
 

<fullquery name="bug_tracker::bug::get_list.select_categories">
  <querytext>
        select kw.heading,
               km.keyword_id,
               count(b.bug_id)
        from   cr_keywords kw,
               cr_item_keyword_map km,
               bt_bugs b
        where  kw.parent_id = :parent_id
        and    km.keyword_id = kw.keyword_id
        and    b.bug_id (+) = km.item_id
        and    b.project_id = :package_id
        group  by kw.heading, km.keyword_id
        order  by kw.heading

  </querytext>
</fullquery>

<fullquery name="bug_tracker::bug::get_list.select_fix_for_versions">
  <querytext>

        select v.version_name,
               b.fix_for_version,
               count(b.bug_id) as num_bugs
        from   bt_bugs b,
               bt_versions v
        where  b.project_id = :package_id
        and    v.version_id (+) = b.fix_for_version
        group  by b.fix_for_version, v.anticipated_freeze_date, v.version_name
        order  by v.anticipated_freeze_date, v.version_name

  </querytext>
</fullquery>

<fullquery name="bug_tracker::bug::get_list.select_action_assignees">
  <querytext>
    select p.first_names || ' ' || p.last_name as name,
           crum.user_id,
           count(b.bug_id) as num_bugs
    from   bt_bugs b,
           workflow_case_assigned_actions aa,
           workflow_case_role_user_map crum,
           persons p
    where  b.project_id = :package_id
    and    aa.workflow_id = :workflow_id
    and    aa.action_id = :action_id
    and    aa.object_id = b.bug_id
    and    crum.case_id (+) = aa.case_id
    and    crum.role_id (+) = aa.role_id
    and    p.person_id (+) = crum.user_id
    group  by p.first_names, p.last_name, crum.user_id
  </querytext>
</fullquery>

  <partialquery name="bug_tracker::bug::get_list.category_where_clause">
      <querytext>
         content_keyword.is_assigned(b.bug_id, :f_category_$parent_id, 'none') = 't'
      </querytext>
  </partialquery>


  <partialquery name="bug_tracker::bug::get_query.orderby_category_from_bug_clause">
      <querytext>
         , cr_item_keyword_map km_order,
         cr_keywords kw_order
      </querytext>
  </partialquery>
 
  <partialquery name="bug_tracker::bug::get_query.orderby_category_where_clause">
      <querytext>
           and km_order.item_id (+) = b.bug_id
           and km_order.keyword_id = kw_order.keyword_id 
           and kw_order.parent_id = '[db_quote $orderby_parent_id]'
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
<fullquery name="bug_tracker::bug::get_query.bugs">
  <querytext>
select q.*,
       km.keyword_id,
       assign_info.*
from (
  select b.bug_id,
         b.bug_number,
         b.summary,
         upper(b.summary) as upper_summary,
         b.comment_content,
         b.comment_format,
         b.component_id,
         b.creation_date,
         to_char(b.creation_date, 'fmMM/DDfm/YYYY') as creation_date_pretty,
         b.creation_user as submitter_user_id,
         submitter.first_names as submitter_first_names,
         submitter.last_name as submitter_last_name,
         submitter.email as submitter_email,
         upper(submitter.first_names) as upper_submitter_first_names,
         upper(submitter.last_name) as upper_submitter_last_name,
         upper(submitter.email) as upper_submitter_email,
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
         acs_users_all assignee,
         workflow_cases cas,
         workflow_case_fsm cfsm,
         workflow_fsm_states st 
   where submitter.user_id = b.creation_user
     and cas.workflow_id = :workflow_id
     and cas.object_id = b.bug_id
     and cfsm.case_id = cas.case_id
     and st.state_id = cfsm.current_state 
   $orderby_category_where_clause
   [template::list::filter_where_clauses -and -name "bugs"]
   [template::list::orderby_clause -orderby -name "bugs"]
) q,
  cr_item_keyword_map km,
  (select cru.user_id as assigned_user_id,
          aa.action_id,
          aa.case_id,
          wa.pretty_name as action_pretty_name,
          assignee.first_names as assignee_first_names,
          assignee.last_name as assignee_last_name
     from workflow_case_assigned_actions aa,
          workflow_case_role_user_map cru,
          workflow_actions wa,
          acs_users_all assignee
    where aa.case_id = cru.case_id
      and aa.role_id = cru.role_id
      and cru.user_id = assignee.user_id
      and wa.action_id = aa.action_id
  ) assign_info
where q.bug_id = km.item_id (+)
  and q.case_id = assign_info.case_id (+)

  </querytext>
</fullquery>

  <partialquery name="bug_tracker::bug::get_list.filter_assignee_null_where_clause">
      <querytext>
          exists (select 1
                  from   workflow_case_assigned_actions aa,
                         workflow_case_role_user_map crum
                  where  aa.case_id = cas.case_id
                  and    aa.action_id = $action_id
                  and    crum.case_id (+) = aa.case_id
                  and    crum.role_id (+) = aa.role_id
                  and    crum.user_id is null
                 )
      </querytext>
  </partialquery>


</queryset>
