<?xml version="1.0"?>

<queryset>
   <rdbms><type>postgresql</type><version>7.1</version></rdbms>

    <fullquery name="select_distributions">
      <querytext>
        select child.keyword_id as child_id,
               child.heading as child_heading,
               parent.keyword_id as parent_id,
               parent.heading as parent_heading,
               case when child.keyword_id is null then 0 else (select count(*) from bt_bugs where project_id = :package_id and component_id = (select component_id from bt_keyword_component_map where keyword_id = child.keyword_id)) end as num_bugs,
	       (select component_id from bt_keyword_component_map where keyword_id = child.keyword_id) as component_id,
               (select content_keyword__is_leaf(parent.keyword_id)) as is_leaf
        from   cr_keywords parent left outer join
               cr_keywords child on (child.parent_id = parent.keyword_id)
        where  parent.parent_id = :component_keyword_id
        order  by parent.heading, child.heading
      </querytext>
    </fullquery>

</queryset>
