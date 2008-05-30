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

    <fullquery name="get_rel_id">
        <querytext>
            select rel_id
            from acs_data_links, cr_items
            where object_id_one = :bug_id
                  and object_id_two = :related_object_id
                  and item_id = object_id_two
                  and (content_type = 'content_revision' or content_type = 'image')
        </querytext>
    </fullquery>

    <fullquery name="delete_relation">
        <querytext>
            delete
            from acs_data_links
            where rel_id = :rel_id
        </querytext>
    </fullquery>

</queryset>
