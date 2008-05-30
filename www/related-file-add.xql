<?xml version="1.0"?>
<queryset>

    <fullquery name="get_bug_id">
        <querytext>
            select b.bug_id
            from   bt_bugs b
            where  b.bug_number = :bug_number
            and    b.project_id = :package_id
        </querytext>
    </fullquery>

    <fullquery name="update_revision_description">
        <querytext>
      update cr_revisions
      set description = :description
      where revision_id = :revision_id
        </querytext>
    </fullquery>

</queryset>
