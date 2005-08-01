<?xml version="1.0"?>

<queryset>
   <rdbms><type>oracle</type><version>8.1.6</version></rdbms>

    <fullquery name="select_distributions">
      <querytext>
        select child.keyword_id as child_id,
               child.heading as child_heading,
               parent.keyword_id as parent_id,
               parent.heading as parent_heading,
               decode(child.keyword_id, null, 0, (select count(*) from bt_bugs where project_id = :package_id and component_id = (select component_id from bt_keyword_component_map where keyword_id = child.keyword_id))) end as num_bugs,
	       (select component_id from bt_keyword_component_map where keyword_id = child.keyword_id) as component_id,
               (select content_keyword.is_leaf(parent.keyword_id) from dual) as is_leaf
        from   cr_keywords parent, 
               cr_keywords child
        where  parent.parent_id = :component_keyword_id
	and    child.parent_id (+) = parent.keyword_id
        order  by parent.heading, child.heading
      </querytext>
    </fullquery>

</queryset>
