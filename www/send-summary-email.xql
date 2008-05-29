<?xml version="1.0"?>

<queryset>
  
<fullquery name="check_exists">
    <querytext>
        select 1
        from   bt_bugs b
        where  b.bug_id = :one_bug_id
        and    b.project_id = :package_id
    </querytext>
</fullquery>

<fullquery name="get_bugs">
    <querytext>
        select q.*,
               km.keyword_id, pck.heading,
               assign_info.*,
               ck.keyword_id as cat_keyword_id
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
                from bt_bugs b,
                     acs_users_all submitter,
                     workflow_cases cas,
                     workflow_case_fsm cfsm,
                     workflow_fsm_states st 
               where submitter.user_id = b.creation_user
                 and b.bug_id in ([join $bug_id ,])
                 and cas.object_id = b.bug_id
                 and cfsm.case_id = cas.case_id
                 and cfsm.parent_enabled_action_id is null
                 and st.state_id = cfsm.current_state 
             ) q
        left outer join
        cr_item_keyword_map km 
           left join cr_keywords as pck on (km.keyword_id = pck.keyword_id)
           left join cr_keywords ck on (pck.parent_id = ck.keyword_id)
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
    </querytext>
</fullquery>

</queryset>