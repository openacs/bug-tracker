<?xml version="1.0"?>
<queryset>

<fullquery name="bug_tracker::project_new.instance_info">
      <querytext>
      select p.instance_name, o.creation_user, o.creation_ip from apm_packages p join acs_objects o on (p.package_id = o.object_id) where  p.package_id = :project_id
      </querytext>
</fullquery>


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
       order by bt_patches.summary
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

<fullquery name="bug_tracker::project_delete.min_bug_id">
    <querytext>
        select min(bug_id)
        from   bt_bugs
        where  project_id = :project_id
    </querytext>
</fullquery>

<fullquery name="bug_tracker::project_new.bt_projects_insert">
    <querytext>
      insert into bt_projects
        (project_id, folder_id, root_keyword_id)
       values
         (:project_id, :folder_id, :keyword_id)
    </querytext>
</fullquery>

<fullquery name="bug_tracker::project_new.bt_components_insert">
    <querytext>
      insert into bt_components
        (component_id, project_id, component_name)
      values
        (:component_id, :project_id, 'General')
    </querytext>
</fullquery>

  <fullquery name="bug_tracker::state_get_filter_data_not_cached.select">
    <querytext>
      select st.pretty_name,
             st.state_id,
             count(b.bug_id)
      from   workflow_fsm_states st,
             bt_bugs b,
             workflow_cases cas,
             workflow_case_fsm cfsm
      where  st.workflow_id = :workflow_id
      and    cas.workflow_id = :workflow_id
      and    cas.object_id = b.bug_id
      and    cfsm.case_id = cas.case_id
      and    st.state_id = cfsm.current_state
             [bug_tracker::user_bugs_only_where_clause]
      group  by st.state_id, st.pretty_name, st.sort_order
      order  by st.sort_order
    </querytext>
  </fullquery>

  <fullquery name="bug_tracker::component_get_filter_data_not_cached.select">
    <querytext>
      select c.component_name,
             c.component_id,
             count(b.bug_id) as num_bugs
       from  bt_bugs b,
             bt_components c
       where b.project_id = :package_id
       and   c.component_id = b.component_id
             [bug_tracker::user_bugs_only_where_clause]
       group by c.component_name, c.component_id
       order by c.component_name
    </querytext>
  </fullquery>

  <fullquery name="bug_tracker::get_related_files_links.get_related_files_for_bug">      
    <querytext>
      select l.rel_id,
             l.object_id_two as related_object_id,
             r.title as related_title,
             i.name as related_name,
             o.creation_user as related_creation_user,
             r.revision_id as related_revision_id
        from acs_data_links l,
             cr_items i,
             cr_revisions r,
             acs_objects o
       where l.object_id_one = :bug_id
             and l.object_id_two = i.item_id
             and r.revision_id = i.live_revision
             and i.item_id = o.object_id
             and (i.content_type = 'content_revision' or i.content_type = 'image')
       order by l.object_id_two
    </querytext>
  </fullquery>

  <partialquery name="bug_tracker::set_access_policy.get_all_bugs">
      <querytext>
          select bug_id
            from bt_bugs
      </querytext>
  </partialquery>

  <partialquery name="bug_tracker::set_access_policy.get_user_bugs">
      <querytext>
          select bug_id
            from bt_bugs
           where project_id = :package_id
             and bug_id in (select wc.object_id
                              from workflow_cases wc,
                                   workflow_case_role_party_map rpm 
                             where wc.case_id = rpm.case_id
                               and rpm.party_id = :user_id)
      </querytext>
  </partialquery>

  <partialquery name="bug_tracker::set_access_policy.get_all_users">
      <querytext>
        select distinct rpm.party_id
          from workflow_cases wc,
               workflow_case_role_party_map rpm,
               bt_bugs b
         where wc.case_id = rpm.case_id
           and b.bug_id = wc.object_id
           and b.project_id = :package_id
      </querytext>
  </partialquery>

  <fullquery name="bug_tracker::access_policy.get_bug">
      <querytext>
        select min(bug_id) as bug_id
         from bt_bugs 
        where project_id = :package_id
      </querytext>
  </fullquery>

  <partialquery name="bug_tracker::user_bugs_only_where_clause.user_bugs_only">
      <querytext>
       and exists (select 1
                     from acs_object_party_privilege_map
                    where object_id = b.bug_id
                      and party_id = :user_id
                      and privilege = 'read')
      </querytext>
  </partialquery>
 
</queryset>
