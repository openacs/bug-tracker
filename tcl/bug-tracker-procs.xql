<?xml version="1.0"?>
<queryset>

<fullquery name="bug_tracker::get_bug_id.bug_id">      
      <querytext>
       select bug_id from bt_bugs
       where  bug_number = :bug_number
       and    project_id = :project_id 
      </querytext>
</fullquery>

 
<fullquery name="bug_tracker::set_project_name.project_name_update">      
      <querytext>
      
        update apm_packages
        set    instance_name = :project_name
        where  package_id = :package_id
    
      </querytext>
</fullquery>


 
<fullquery name="bug_tracker::get_user_prefs_internal.count_user_prefs">      
      <querytext>
       select count(*) from bt_user_prefs where project_id = :package_id and user_id = :user_id 
      </querytext>
</fullquery>

 
<fullquery name="bug_tracker::get_user_prefs_internal.create_user_prefs">      
      <querytext>
      
                insert into bt_user_prefs (user_id, project_id) values (:user_id, :package_id)
            
      </querytext>
</fullquery>

 
<fullquery name="bug_tracker::severity_codes_get_options_not_cached.severities">      
      <querytext>
      
        select sort_order || ' - ' || severity_name, severity_id 
        from   bt_severity_codes 
        where  project_id = :package_id
        order  by sort_order
    
      </querytext>
</fullquery>

 
<fullquery name="bug_tracker::priority_codes_get_options_not_cached.priorities">      
      <querytext>
       
        select sort_order || ' - ' || priority_name, priority_id 
        from   bt_priority_codes 
        where  project_id = :package_id
        order  by sort_order 
    
      </querytext>
</fullquery>

 
<fullquery name="bug_tracker::version_get_options_not_cached.versions">      
      <querytext>
       select version_name, version_id from bt_versions where project_id = :package_id order by version_name 
      </querytext>
</fullquery>

 
<fullquery name="bug_tracker::components_get_options_not_cached.components">      
      <querytext>
       select component_name, component_id from bt_components where project_id = :package_id order by component_name 
      </querytext>
</fullquery>

 

<fullquery name="bug_tracker::components_get_url_names_not_cached.select_component_url_names">      
      <querytext>
       select component_id, url_name from bt_components where project_id = :package_id
      </querytext>
</fullquery>

 
<fullquery name="bug_tracker::map_patch_to_bug.map_patch_to_bug">      
      <querytext>
      
        insert into bt_patch_bug_map (patch_id, bug_id) values (:patch_id, :bug_id)
    
      </querytext>
</fullquery>

 
<fullquery name="bug_tracker::unmap_patch_from_bug.unmap_patch_from_bug">      
      <querytext>
      
        delete from bt_patch_bug_map
          where bug_id = (select bug_id from bt_bugs 
                          where bug_number = :bug_number
                            and project_id = :package_id)
            and patch_id = (select patch_id from bt_patches
                            where patch_number = :patch_number
                            and project_id = :package_id)
    
      </querytext>
</fullquery>

 
<fullquery name="bug_tracker::get_mapped_bugs.get_bugs_for_patch">      
      <querytext>
      select b.bug_number,
             b.summary
      from   bt_bugs b, bt_patch_bug_map bpbm
      where  b.bug_id = bpbm.bug_id
      and    bpbm.patch_id = (select patch_id
                              from bt_patches
                              where patch_number = :patch_number
                              and project_id = :package_id
                              )
             $open_clause
      </querytext>
</fullquery>

 
<fullquery name="bug_tracker::get_patch_links.get_patches_for_bug">      
      <querytext>
      select bt_patches.patch_number,
             bt_patches.summary,
             bt_patches.status
        from bt_patch_bug_map, bt_patches
       where bt_patch_bug_map.bug_id = :bug_id
         and bt_patch_bug_map.patch_id = bt_patches.patch_id
             $status_where_clause
    
      </querytext>
</fullquery>

 
<fullquery name="bug_tracker::get_patch_submitter.patch_submitter_id">      
      <querytext>
      select acs_objects.creation_user
        from bt_patches, acs_objects
       where bt_patches.patch_number = :patch_number
         and bt_patches.project_id = :package_id
         and bt_patches.patch_id = acs_objects.object_id
      </querytext>
</fullquery>

 
<fullquery name="bug_tracker::update_patch_status.update_patch_status">      
      <querytext>
      update bt_patches 
         set status = :new_status
       where bt_patches.project_id = :package_id
         and bt_patches.patch_number = :patch_number
      </querytext>
</fullquery>

 
<fullquery name="bug_tracker::parse_filters.component_name">      
      <querytext>
       select component_name from bt_components where component_id = :filter_component_id 
      </querytext>
</fullquery>

 
<fullquery name="bug_tracker::parse_filters.version_name">      
      <querytext>
       select version_name from bt_versions where version_id = :filter_fix_for_version 
      </querytext>
</fullquery>

 
<fullquery name="bug_tracker::parse_filters.component_name">      
      <querytext>
      
            select component_name, url_name from bt_components where component_id = :component_id
        
      </querytext>
</fullquery>

<fullquery name="bug_tracker::get_keywords_not_cached.select_package_keywords">
    <querytext>
        
        select child.keyword_id as child_id,
               child.heading as child_heading,
               parent.keyword_id as parent_id,
               parent.heading as parent_heading
        from   bt_projects p,
               cr_keywords parent,
               cr_keywords child
        where  p.project_id = :package_id
        and    parent.parent_id = p.root_keyword_id
        and    child.parent_id = parent.keyword_id
        order  by parent.heading, child.heading
    </querytext>
</fullquery>

<fullquery name="bug_tracker::project_delete.unset_project_revisions">
    <querytext>
        update cr_items
        set live_revision = null, latest_revision = null
        where parent_id = :folder_id
    </querytext>
</fullquery>

<fullquery name="bug_tracker::project_delete.min_bug_id">
    <querytext>
        select min(bug_id)
        from   bt_bugs
        where  project_id = :project_id
    </querytext>
</fullquery>

<fullquery name="bug_tracker::bug_delete.get_case_id">
    <querytext>
        select case_id
        from   workflow_cases
        where  object_id = :bug_id
    </querytext>
</fullquery>

<fullquery name="bug_tracker::bug_delete.get_notifications">
    <querytext>
        select notification_id
        from   notifications
        where  response_id = :bug_id
    </querytext>
</fullquery>

<fullquery name="bug_tracker::bug_delete.unset_revisions">
    <querytext>
        update cr_items
        set live_revision = null, latest_revision = null
        where item_id = :bug_id
    </querytext>
</fullquery>
 
</queryset>
