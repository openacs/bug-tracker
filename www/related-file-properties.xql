<?xml version="1.0"?>
<queryset>
  
    <fullquery name="get_bug_number">
        <querytext>
            select b.bug_number
            from   bt_bugs b
            where  b.bug_id = :bug_id
            and    b.project_id = :package_id
        </querytext>
    </fullquery>

    <fullquery name="related_file_revisions">
        <querytext>
      select revision_id, cr_revisions.title as filename, cr_revisions.description
      from acs_data_links, cr_items, cr_revisions
      where object_id_one = :bug_id
            and object_id_two = :related_object_id
            and cr_items.item_id = object_id_two
            and (content_type = 'content_revision' or content_type = 'image')
            and cr_revisions.item_id = cr_items.item_id
      order by cr_revisions.revision_id desc
        </querytext>
    </fullquery>

</queryset>