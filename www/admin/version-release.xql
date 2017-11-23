<?xml version="1.0"?>
<queryset>

  <fullquery name="update_version">      
    <querytext>      
      update bt_versions
      set    actual_release_date = $actual_release_date
      where  version_id = :version_id     
    </querytext>
  </fullquery>

  <fullquery name="version_select">
    <querytext>      
      select version_name,
      to_char(anticipated_release_date, 'YYYY MM DD HH24 MI') as anticipated_release_date, 
      to_char(coalesce(actual_release_date, current_timestamp), 'YYYY MM DD HH24 MI')  as actual_release_date
      from   bt_versions
      where  version_id = :version_id
    </querytext>
  </fullquery>
  
</queryset>
