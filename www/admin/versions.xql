<?xml version="1.0"?>
<queryset>

  <fullquery name="current_version">
    <querytext>
    select v.version_id,
           v.version_name,
           v.description,
           v.anticipated_freeze_date,
           v.actual_freeze_date,
           v.anticipated_release_date,
           v.maintainer,
           v.supported_platforms,
           v.active_version_p,
           v.assignable_p,
           (select count(*) 
            from   bt_bugs b 
            where  b.found_in_version = v.version_id 
               or  b.fix_for_version = v.version_id
               or  b.fixed_in_version = v.version_id) as num_bugs
    from   bt_versions v
    where  v.project_id = :package_id
    and    v.active_version_p = 't'
    and    v.actual_release_date is null
    </querytext>
  </fullquery>

  <fullquery name="future_versions">
    <querytext>
    
    select v.version_id,
           v.version_name,
           v.description,
           v.anticipated_freeze_date,
           v.actual_freeze_date,
           v.anticipated_release_date,
           v.maintainer,
           v.supported_platforms,
           v.active_version_p,
           v.assignable_p,
           (select count(*) 
            from   bt_bugs b 
            where  b.found_in_version = v.version_id 
               or  b.fix_for_version = v.version_id
               or  b.fixed_in_version = v.version_id) as num_bugs
    from   bt_versions v
    where  v.project_id = :package_id
    and    v.actual_release_date is null
    and    v.active_version_p = 'f'
    order by v.anticipated_release_date, version_name

    </querytext>
  </fullquery>

  <fullquery name="past_versions">
    <querytext>

    select v.version_id,
           v.version_name,
           v.description,
           v.anticipated_freeze_date,
           v.actual_freeze_date,
           v.anticipated_release_date,
           v.actual_release_date,
           v.maintainer,
           v.supported_platforms,
           v.active_version_p,
           v.assignable_p,
           (select count(*) 
            from   bt_bugs b 
            where  b.found_in_version = v.version_id 
               or  b.fix_for_version = v.version_id
               or  b.fixed_in_version = v.version_id) as num_bugs
    from   bt_versions v
    where  v.project_id = :package_id
    and    v.actual_release_date is not null
    order by v.actual_release_date, version_name
    </querytext>
  </fullquery>
  
</queryset>
