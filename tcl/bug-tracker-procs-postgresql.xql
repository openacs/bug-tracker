<?xml version="1.0"?>

<queryset>
   <rdbms><type>postgresql</type><version>7.1</version></rdbms> 
 
   <fullquery name="bug_tracker::delete_all_project_keywords.keywords_delete">      
      <querytext>
        select bt_project__keywords_delete(:package_id, 'f')
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

</queryset>
