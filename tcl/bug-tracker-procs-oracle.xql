<?xml version="1.0"?>

<queryset>
   <rdbms><type>oracle</type><version>8.1.6</version></rdbms>

   <fullquery name="bug_tracker::delete_all_project_keywords.keywords_delete">      
     <querytext>
        begin
             bt_project.keywords_delete(:package_id, 'f');
        end;
     </querytext>
   </fullquery>

   <fullquery name="bug_tracker::parse_filters.assignee_name">      
     <querytext>
       select acs_object.name(party_id) from parties where party_id = :filter_assignee 
     </querytext>
   </fullquery>

   <partialquery name="bug_tracker::parse_filters.keyword_filter">
     <querytext>
        content_keyword.is_assigned(b.bug_id, $keyword_id, 'none') = 't'
     </querytext>
   </partialquery>

   <fullquery name="bug_tracker::project_delete.delete_project">
     <querytext>
        begin
             bt_project.del(:project_id);
        end;
     </querytext>
   </fullquery>

   <fullquery name="bug_tracker::project_new.create_project">
     <querytext>
        begin
             bt_project.new(:project_id);
        end;
     </querytext>
   </fullquery>

   <fullquery name="bug_tracker::assignee_get_options.assignees">      
     <querytext>
       select acs_object.name(p.party_id) || ' (' || p.email || ')'  as label,
	party_id from  parties p
	where party_id in (select distinct(party_id) from workflow_case_role_party_map, 
				workflow_cases	
				where workflow_case_role_party_map.case_id = workflow_cases.case_id
				and workflow_cases.workflow_id = :workflow_id)
     </querytext>
   </fullquery>

</queryset>
