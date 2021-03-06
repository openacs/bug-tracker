<?xml version="1.0"?>
<queryset>

<fullquery name="bug_tracker::install::package_upgrade.select_project_ids">
    <querytext>
        select project_id
        from bt_projects
    </querytext>
</fullquery>

<fullquery name="bug_tracker::install::package_upgrade.select_case_ids">
    <querytext>
      select wc.case_id
      from workflow_cases wc, bt_bugs b
      where wc.object_id = b.bug_id
    </querytext>
</fullquery>

<fullquery name="bug_tracker::install::package_upgrade.select_folder_ids">
    <querytext>
      select folder_id
      from bt_projects
    </querytext>
</fullquery>

<fullquery name="bug_tracker::install::package_upgrade.update_project">
    <querytext>
      update bt_projects
      set workflow_id = :workflow_id
      where project_id = :project_id
    </querytext>
</fullquery>

</queryset>
