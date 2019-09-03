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

</queryset>
