<?xml version="1.0"?>

<queryset>
   <rdbms><type>postgresql</type><version>7.1</version></rdbms> 
 
   <fullquery name="bug_tracker::delete_all_project_keywords.keywords_delete">      
      <querytext>
        select bt_project__keywords_delete(:package_id, 'f')
      </querytext>
   </fullquery>

  <fullquery name="bug_tracker::parse_filters.assignee_name">      
      <querytext>
       select acs_object__name(party_id) from parties where party_id = :filter_assignee 
      </querytext>
  </fullquery>

  <partialquery name="bug_tracker::parse_filters.keyword_filter">
      <querytext>
        content_keyword__is_assigned(b.bug_id, $keyword_id, 'none')
      </querytext>
  </partialquery>

  <!-- This partial query does not have a counterpart in oracle and there is not direct reference to it in tcl... -->
  <partialquery name="bug_tracker::parse_filters.orderby_filter_from_bug">
      <querytext>
         left outer join cr_item_keyword_map km_order on (km_order.item_id = b.bug_id) 
         join cr_keywords kw_order on (km_order.keyword_id = kw_order.keyword_id and kw_order.parent_id = :filter_orderby)
      </querytext>
  </partialquery>

  <!-- This partial query does not have a counterpart in oracle and there is not direct reference to it in tcl... -->  
  <partialquery name="bug_tracker::parse_filters.orderby_filter_where">
      <querytext>
          1=1
      </querytext>
  </partialquery>
 
  <fullquery name="bug_tracker::project_delete.delete_project">
    <querytext>
        select bt_project__delete(:project_id);
    </querytext>
  </fullquery>

  <fullquery name="bug_tracker::project_new.create_project">
    <querytext>
        select bt_project__new(:project_id);
    </querytext>
  </fullquery>

  <fullquery name="bug_tracker::assignee_get_options.assignees">
    <querytext>
       select acs_object__name(p.party_id) || ' (' || p.email || ')'  as label,
	party_id from  parties p
	where party_id in (select distinct(party_id) from workflow_case_role_party_map,
				workflow_cases
				where workflow_case_role_party_map.case_id = workflow_cases.case_id
				and workflow_cases.workflow_id = :workflow_id)
    </querytext>
  </fullquery>

</queryset>
