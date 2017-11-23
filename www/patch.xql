<?xml version="1.0"?>
<queryset>

<fullquery name="patch_status">
      <querytext>
select status from bt_patches where patch_number = :patch_number and project_id = :package_id
      </querytext>
</fullquery>


<fullquery name="get_patch_content">
      <querytext>
select content from bt_patches where patch_number = :patch_number and project_id = :package_id
      </querytext>
</fullquery>


<fullquery name="actions">
      <querytext>
        select bt_patch_actions.action_id,
               bt_patch_actions.action,
               bt_patch_actions.actor as actor_user_id,
               actor.first_names as actor_first_names,
               actor.last_name as actor_last_name,
               actor.email as actor_email,
               bt_patch_actions.action_date,
               to_char(bt_patch_actions.action_date, 'YYYY-MM-DD HH24:MI:SS') as action_date_pretty,
               bt_patch_actions.comment_text,
               bt_patch_actions.comment_format
        from   bt_patch_actions,
               acs_users_all actor
        where  bt_patch_actions.patch_id = :patch_id
        and    actor.user_id = bt_patch_actions.actor
        order  by action_date
      </querytext>
</fullquery>

<fullquery name="update_patch">
      <querytext>
        update bt_patches set    [join $update_exprs ", "] where  patch_id = :patch_id
      </querytext>
</fullquery>

<fullquery name="patch_action">
      <querytext>
            insert into bt_patch_actions
            (action_id, patch_id, action, actor, comment_text, comment_format)
            values
            (:action_id, :patch_id, :action, :user_id, :description, :desc_format)
      </querytext>
</fullquery>

<fullquery name="patch_id">
      <querytext>
          select patch_id from bt_patches where patch_number = :patch_number and project_id = :package_id
      </querytext>
</fullquery>

 <fullquery name="get_enabled_action_id">
      <querytext>
          select enabled_action_id from workflow_case_enabled_actions
          where action_id=:action_id and case_id=:case_id
      </querytext>
</fullquery>

<fullquery name="patch">
  <querytext>
     select bt_patches.patch_id,
            bt_patches.patch_number,
            bt_patches.project_id,
            bt_patches.component_id,
            bt_patches.summary,
            bt_patches.content,
            bt_patches.generated_from_version,
            bt_patches.apply_to_version,
            bt_patches.applied_to_version,
            bt_patches.status,
            bt_components.component_name,
            acs_objects.creation_user as submitter_user_id,
            submitter.first_names as submitter_first_names,
            submitter.last_name as submitter_last_name,
            submitter.email as submitter_email,
            acs_objects.creation_date,
            to_char(acs_objects.creation_date, 'YYYY-MM-DD HH24:MI:SS') as creation_date_pretty,
            to_char(current_timestamp, 'YYYY-MM-DD HH24:MI:SS') as now_pretty
     from bt_patches,
          acs_objects,
          acs_users_all submitter,
          bt_components
     where bt_patches.patch_number = :patch_number
       and bt_patches.project_id = :package_id
       and bt_patches.patch_id = acs_objects.object_id
       and bt_patches.component_id = bt_components.component_id
       and submitter.user_id = acs_objects.creation_user
  </querytext>
</fullquery>

</queryset>
