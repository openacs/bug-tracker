<?xml version="1.0"?>
<!DOCTYPE queryset PUBLIC "-//OpenACS//DTD XQL 1.0//EN" "http://www.thecodemill.biz/repository/xql.dtd">
<!--  -->
<!-- @author Victor Guerra (guerra@galileo.edu) -->
<!-- @creation-date 2005-02-07 -->
<!-- @arch-tag: 292d04cf-1ac9-4f48-ba54-0cf802fbd0bc -->
<!-- @cvs-id $Id$ -->

<queryset>
  
  <rdbms>
    <type>postgresql</type>
    <version>7.2</version>
  </rdbms>
  
  <fullquery name = "bug_tracker::scheduled::close_bugs.too_old">
    <querytext>
      select 1
      from acs_objects
      where object_id = :bug_id and
      (now()::date - last_modified::date) > :time_to_compare_with
    </querytext>
  </fullquery>
</queryset>