<?xml version="1.0"?>
<queryset>

<fullquery name="bug_tracker::parse_filters.assignee_name">
  <querytext>
    select acs_object.name(party_id) from parties where party_id = :filter_assignee
  </querytext>
</fullquery>

<fullquery name="bug_tracker::assignee_get_options.assignees">
  <querytext>
       select acs_object.name(p.party_id) || ' (' || p.email || ')'  as label,
	party_id from  parties p
	where party_id in (select distinct(party_id) from workflow_case_role_party_map,
				workflow_cases
				where workflow_case_role_party_map.case_id = workflow_cases.case_id
				and workflow_cases.workflow_id = :workflow_id)
  </querytext>
</fullquery>

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

  <partialquery name="bug_tracker::parse_filters.n_days_filter">      
      <querytext>
        b.creation_date + interval :filter_n_days day > current_timestamp
      </querytext>
  </partialquery>
  
  <fullquery name="bug_tracker::bug_notify.bug">      
      <querytext>
      
        select b.bug_id,
               b.bug_number,
               b.summary,
               b.project_id,
               o.creation_user as submitter_user_id,
               submitter.first_names as submitter_first_names,
               submitter.last_name as submitter_last_name,
               submitter.email as submitter_email,
               b.component_id,
               c.component_name,
               o.creation_date,
               to_char(o.creation_date, 'YYYY-MM-DD HH24:MI:SS') as creation_date_pretty,
               st.pretty_name as status,
               b.resolution,
               b.user_agent,
               b.found_in_version,
               b.fix_for_version,
               b.fixed_in_version,
               to_char(current_timestamp, 'YYYY-MM-DD HH24:MI:SS') as now_pretty
        from   bt_bugs b,
               acs_objects o,
               bt_components c,
               cc_users submitter,
               workflow_cases cas,
               workflow_case_fsm cfsm,
               workflow_fsm_states st
        where  b.bug_id = :bug_id
        and    b.project_id = :package_id
        and    o.object_id = b.bug_id
        and    c.component_id = b.component_id
        and    submitter.user_id = o.creation_user
        and    cas.object_id = b.bug_id
        and    cfsm.case_id = cas.case_id
        and    cfsm.current_state = st.state_id
    
      </querytext>
  </fullquery>

  <fullquery name="bug_tracker::get_project_info_internal.project_info">      
      <querytext>
      
        select pck.instance_name as project_name,
               prj.description as project_description,
               prj.folder_id as project_folder_id,
               prj.root_keyword_id as project_root_keyword_id,
               ver.version_id as current_version_id,
               coalesce(ver.version_name, 'None') as current_version_name
        from   apm_packages pck, 
               bt_projects prj 
               left outer join bt_versions ver 
               on (ver.project_id = prj.project_id and active_version_p = 't')
        where  pck.package_id = :package_id 
        and    prj.project_id = pck.package_id
    
      </querytext>
  </fullquery>

  <fullquery name="bug_tracker::bugs_exist_p_not_cached.select_bugs_exist_p">      
      <querytext>
        select 1 from dual where exists (select 1 
        from  bt_bugs 
        where project_id = :package_id)
      </querytext>
  </fullquery>

  <fullquery name="bug_tracker::get_user_prefs_internal.user_info">      
      <querytext>
      
        select u.first_names as user_first_names, 
               u.last_name as user_last_name,
               u.email as user_email,
               ver.version_id as user_version_id,
               coalesce(ver.version_name, 'None') as user_version_name
        from   cc_users u,
               bt_user_prefs up
               left outer join bt_versions ver
               on (ver.version_id = up.user_version)
        where  u.user_id = :user_id
        and    up.user_id = u.user_id
        and    up.project_id = :package_id
    
      </querytext>
  </fullquery>

  <fullquery name="bug_tracker::category_get_filter_data_not_cached.select">
    <querytext>
        select kw.heading,
               km.keyword_id,
               count(b.bug_id)
        from   cr_keywords kw join
               cr_item_keyword_map km using (keyword_id) left outer join
               bt_bugs b on (b.bug_id = km.item_id)
        where  kw.parent_id = :parent_id
        and    b.project_id = :package_id
               [bug_tracker::user_bugs_only_where_clause]
        group  by kw.heading, km.keyword_id
        order  by kw.heading
    </querytext>
  </fullquery>

  <fullquery name="bug_tracker::version_get_filter_data_not_cached.select">
    <querytext>
        select v.version_name,
               b.fix_for_version,
               count(b.bug_id) as num_bugs
        from   bt_bugs b left outer join 
               bt_versions v on (v.version_id = b.fix_for_version)
        where  b.project_id = :package_id
               [bug_tracker::user_bugs_only_where_clause]
        group  by b.fix_for_version, v.anticipated_freeze_date, v.version_name
        order  by v.anticipated_freeze_date, v.version_name
    </querytext>
  </fullquery>

  <fullquery name="bug_tracker::assignee_get_filter_data_not_cached.select">
    <querytext>
      select p.first_names || ' ' || p.last_name as name,
             crum.user_id,
             count(b.bug_id) as num_bugs
      from   bt_bugs b,
             workflow_case_assigned_actions aa left outer join
             workflow_case_role_user_map crum on (crum.case_id = aa.case_id and crum.role_id = aa.role_id) left outer join
             persons p on (p.person_id = crum.user_id)
      where  aa.workflow_id = :workflow_id
      and    aa.action_id = :action_id
      and    aa.object_id = b.bug_id
             [bug_tracker::user_bugs_only_where_clause]
      group  by p.first_names, p.last_name, crum.user_id
    </querytext>
  </fullquery>  

   <fullquery name="bug_tracker::project_new.instance_info">
     <querytext>
	select p.instance_name, o.creation_user, o.creation_ip
	from apm_packages p join acs_objects o on (p.package_id = o.object_id)
        where p.package_id = :project_id
     </querytext>
   </fullquery>
   
</queryset>
