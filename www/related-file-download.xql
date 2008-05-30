<?xml version="1.0"?>
<queryset>

    <fullquery name="get_related_file">
        <querytext>
            select revision_id, cr_revisions.title as filename
            from acs_data_links, cr_items, cr_revisions
            where object_id_one = :bug_id
                  and object_id_two = :related_object_id
                  and cr_items.item_id = object_id_two
                  and (content_type = 'content_revision' or content_type = 'image')
                  and live_revision = revision_id
        </querytext>
    </fullquery>

    <fullquery name="get_related_revision">
        <querytext>
            select revision_id, cr_revisions.title as filename
            from acs_data_links, cr_items, cr_revisions
            where object_id_one = :bug_id
                  and object_id_two = :related_object_id
                  and cr_items.item_id = object_id_two
                  and (content_type = 'content_revision' or content_type = 'image')
                  and cr_revisions.item_id = cr_items.item_id
                  and cr_revisions.revision_id = :revision_id
        </querytext>
    </fullquery>

</queryset>
