<?xml version="1.0"?>

<queryset>
   <rdbms><type>oracle</type><version>8.1.6</version></rdbms>

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
               to_char(o.creation_date, 'fmMM/DDfm/YYYY') as creation_date_pretty,
               st.pretty_name as status,
               b.resolution,
               b.user_agent,
               b.found_in_version,
               b.fix_for_version,
               b.fixed_in_version,
               to_char(sysdate, 'fmMon/DDfm/YYYY') as now_pretty
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
               nvl(ver.version_name, 'None') as current_version_name
        from   apm_packages pck, 
               bt_projects prj,
               (select * from bt_versions where active_version_p = 't') ver 
        where  pck.package_id = :package_id 
        and    prj.project_id = pck.package_id
        and    prj.project_id = ver.project_id (+)
    
      </querytext>
</fullquery>
 
<fullquery name="bug_tracker::bugs_exist_p_not_cached.select_bugs_exist_p">      
      <querytext>
        select 1 
        from  bt_bugs 
        where project_id = :package_id 
        and   rownum = 1
      </querytext>
</fullquery>

<fullquery name="bug_tracker::get_user_prefs_internal.user_info">      
      <querytext>
      
        select u.first_names as user_first_names, 
               u.last_name as user_last_name,
               u.email as user_email,
               ver.version_id as user_version_id,
               nvl(ver.version_name, 'None') as user_version_name
        from   cc_users u,
               bt_user_prefs up,
               bt_versions ver
        where  u.user_id = :user_id
        and    up.user_id = u.user_id
        and    up.project_id = :package_id
        and    up.user_version = ver.version_id (+)
    
      </querytext>
</fullquery>
 
<fullquery name="bug_tracker::delete_all_project_keywords.keywords_delete">      
      <querytext>
        begin
             bt_project.keywords_delete(:package_id, 'f');
        end;
      </querytext>
</fullquery>

<fullquery name="bug_tracker::parse_filters.assignee_name">      
      <querytext>
       select acs_object.name(party_id) from parties where party_id = :filter_assignee 
      </querytext>
</fullquery>

  <partialquery name="bug_tracker::parse_filters.n_days_filter">      
      <querytext>
        b.creation_date + :filter_n_days > sysdate
      </querytext>
  </partialquery>

  <partialquery name="bug_tracker::parse_filters.keyword_filter">
      <querytext>
        content_keyword.is_assigned(b.bug_id, $keyword_id, 'none') = 't'
      </querytext>
  </partialquery>

  <partialquery name="bug_tracker::parse_filters.orderby_filter_from_bug">
      <querytext>
         , cr_item_keyword_map km_order,
         cr_keywords kw_order
      </querytext>
  </partialquery>
 
  <partialquery name="bug_tracker::parse_filters.orderby_filter_where">
      <querytext>
               km_order.item_id (+) = b.bug_id
           and km_order.keyword_id = kw_order.keyword_id 
           and kw_order.parent_id = :filter_orderby
      </querytext>
  </partialquery>
 
  <fullquery name="bug_tracker::project_delete.delete_project">
    <querytext>
        begin
             bt_project.delete(:project_id);
        end;
    </querytext>
  </fullquery>

  <fullquery name="bug_tracker::project_new.create_project">
    <querytext>
        begin
             bt_project.new(:project_id);
        end;
    </querytext>
  </fullquery>

<fullquery name="bug_tracker::bug_delete.delete_bug_case">
    <querytext> 
        begin
             workflow_case.delete(:case_id);
        end;
    </querytext>
</fullquery>
 
<fullquery name="bug_tracker::bug_delete.delete_notification">
    <querytext>
        begin
             notification.delete(:notification_id);
        end;
    </querytext>
</fullquery>

<fullquery name="bug_tracker::bug_delete.delete_cr_item">
    <querytext>
        begin
             content_item.delete(:bug_id);
        end;
    </querytext>
</fullquery>
 
</queryset>
