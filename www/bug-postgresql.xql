<?xml version="1.0"?>

<queryset>
   <rdbms><type>postgresql</type><version>7.1</version></rdbms>

    <fullquery name="filter_bug_numbers">
        <querytext>
            select b.bug_number
            from   $from_bug_clause,
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
            where  cas.workflow_id = :workflow_id
            and    cas.object_id = b.bug_id
            and    cfsm.case_id = cas.case_id
            and    st.state_id = cfsm.current_state
            and    [join $where_clauses "\n    and "]
            order  by $order_by_clause
        </querytext>
    </fullquery>


</queryset>
