<?xml version="1.0"?>

<queryset>
   <rdbms><type>postgresql</type><version>7.1</version></rdbms>

<fullquery name="bugs">
  <querytext>
    
    select q.*,
           km.keyword_id
    from (
        select b.bug_id,
               b.bug_number,
               b.summary,
               b.comment_content,
               b.comment_format,
               b.component_id,
               b.creation_date,
               to_char(b.creation_date, 'fmMM/DDfm/YYYY') as creation_date_pretty,
               b.creation_user as submitter_user_id,
               submitter.first_names as submitter_first_names,
               submitter.last_name as submitter_last_name,
               submitter.email as submitter_email,
               st.pretty_name as pretty_state,
               st.short_name as state_short_name,
               st.state_id,
               st.hide_fields,
               b.resolution,
               b.found_in_version,
               b.fix_for_version,
               b.fixed_in_version,
               assignee.party_id as assignee_party_id,
               assignee.email as assignee_email,
               assignee.name as assignee_name
        from   $from_bug_clause,
               cc_users submitter,
               workflow_cases cas left outer join
               (select rpm.case_id,
                       p.party_id,
                       p.email,
                       acs_object__name(p.party_id) as name
                  from workflow_case_role_party_map rpm,
                       parties p
                 where rpm.role_id = :action_role
                   and p.party_id = rpm.party_id
                 ) assignee on (cas.case_id = assignee.case_id),
               workflow_case_fsm cfsm,
               workflow_fsm_states st 
        where  submitter.user_id = b.creation_user
        and    cas.workflow_id = :workflow_id
        and    cas.object_id = b.bug_id
        and    cfsm.case_id = cas.case_id
        and    st.state_id = cfsm.current_state
        and    [join $where_clauses "\n    and "]
        order  by $order_by_clause
    ) q left outer join
    cr_item_keyword_map km on (km.item_id = q.bug_id)
  </querytext>
</fullquery>

<fullquery name="stats_by_category">
  <querytext>
        select km.keyword_id as unique_id,
               count(b.bug_id) as num_bugs
        from   cr_keywords kw join 
               cr_item_keyword_map km using (keyword_id) left outer join
               bt_bugs b on (b.bug_id = km.item_id),
               workflow_cases cas,
               workflow_case_fsm cfsm
        where  kw.parent_id = :parent_id
        and    b.project_id = :package_id
        and    cas.object_id = b.bug_id
        and    cfsm.case_id = cas.case_id
        and    cfsm.current_state = :initial_state_id
        group  by kw.heading, unique_id
        order  by kw.heading

  </querytext>
</fullquery>

<fullquery name="stats_by_fix_for_version">
  <querytext>

        select b.fix_for_version as unique_id,
               v.version_name as name,
               count(b.bug_id) as num_bugs
        from   bt_bugs b left outer join
               bt_versions v on (v.version_id = b.fix_for_version),
               workflow_cases cas,
               workflow_case_fsm cfsm           
        where  b.project_id = :package_id
        and    cas.object_id = b.bug_id
        and    cfsm.case_id = cas.case_id
        and    cfsm.current_state = :initial_state_id
        group  by unique_id, v.anticipated_freeze_date, name
        order  by v.anticipated_freeze_date, name

  </querytext>
</fullquery>

<fullquery name="stats_by_assigned_action">
  <querytext>

    select a.action_id || '.' || cfsm.current_state || '.' || p.party_id as unique_id,
           acs_object__name(p.party_id) as name,
           a.pretty_name as stat_name,
           count(b.bug_id) as num_bugs
    from   bt_bugs b,
           workflow_cases cas,
           workflow_case_fsm cfsm,
           workflow_actions a,
           workflow_case_role_party_map crpm,
           parties p
    where  b.project_id = :package_id
      and  cas.object_id = b.bug_id            
      and  (a.always_enabled_p = 't'
            or exists (select 1
                       from   workflow_fsm_action_en_in_st aeis
                       where  aeis.state_id = cfsm.current_state
                         and  aeis.action_id = a.action_id
                         and  aeis.assigned_p = 't'
                       )
           )
      and cfsm.case_id = cas.case_id
      and crpm.case_id = cas.case_id
      and crpm.role_id = a.assigned_role
      and crpm.party_id = p.party_id
    group by a.action_id || '.' || cfsm.current_state || '.' || p.party_id, acs_object__name(p.party_id), a.pretty_name
    order by stat_name, name

  </querytext>
</fullquery>

<fullquery name="stats_by_component">
  <querytext>

    select unique_id,
           name,
           count(b.bug_id) as num_bugs
     from   bt_bugs b,
            workflow_cases cas,
            workflow_case_fsm cfsm,
           (select coalesce('com/'||com.url_name||'/', trim(to_char(com.component_id,'99999999'))) as unique_id,
                   com.component_name as name,
                   com.component_id
            from   bt_components com
            where  com.project_id = :package_id) c
     where  c.component_id = b.component_id
     and    cas.object_id = b.bug_id
     and    cas.case_id = cfsm.case_id
     and    cfsm.current_state = :initial_state_id
     group  by unique_id, name
     order  by name

  </querytext>
</fullquery>


</queryset>
