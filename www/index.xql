<?xml version="1.0"?>
<queryset>

<fullquery name="num_components">      
      <querytext>
       select count(component_id) from bt_components where project_id = :package_id 
      </querytext>
</fullquery>

<fullquery name="select_resolve_role">      
      <querytext>
      
    select a.assigned_role
    from   workflow_actions a,
           workflow_fsm_action_en_in_st aeis
    where  a.action_id = aeis.action_id
    and    aeis.state_id = :initial_state_id
    and    a.workflow_id = :workflow_id
    and    a.assigned_role is not null

      </querytext>
</fullquery>

<fullquery name="by_status">
  <querytext>
    
    select st.state_id as unique_id,
           count(b.bug_id) as num_bugs,
           st.pretty_name as name
    from   workflow_fsm_states st,
           bt_bugs b,
           workflow_cases cas,
           workflow_case_fsm cfsm
    where  st.workflow_id = :workflow_id
    and    b.project_id = :package_id
    and    cas.workflow_id = :workflow_id
    and    cas.object_id = b.bug_id
    and    cfsm.case_id = cas.case_id
    and    st.state_id = cfsm.current_state
    group  by st.state_id, st.pretty_name, st.sort_order
    order  by st.sort_order
  </querytext>
</fullquery>

<fullquery name="stats_by_unassigned_action">
  <querytext>

    select count(*) as num_bugs
    from  bt_bugs,
          workflow_cases cas,
          workflow_case_fsm cfsm
    where cas.object_id = bt_bugs.bug_id
      and cas.case_id = cfsm.case_id
      and cfsm.current_state = '4'
      and not exists (select 1
                      from workflow_actions a,
                           workflow_fsm_action_en_in_st aeis,
                           workflow_case_role_party_map rpm
                      where a.workflow_id = cas.workflow_id
                        and a.action_id = aeis.action_id
                        and aeis.state_id = '4'
                        and rpm.case_id = cas.case_id
                        and rpm.role_id = a.assigned_role
                     )
  </querytext>
</fullquery>


</queryset>
