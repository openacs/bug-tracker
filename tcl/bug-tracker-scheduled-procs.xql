<?xml version="1.0"?>
<!DOCTYPE queryset PUBLIC "-//OpenACS//DTD XQL 1.0//EN" "http://www.thecodemill.biz/repository/xql.dtd">
<!--  -->
<!-- @author Victor Guerra (guerra@galileo.edu) -->
<!-- @creation-date 2005-02-07 -->
<!-- @arch-tag: 8b3c5588-0ebe-43fd-90a8-009e9f223abf -->
<!-- @cvs-id $Id$ -->

<queryset>
  <fullquery name ="bug_tracker::scheduled::close_bugs.open_bug">
    <querytext>
      select bug_id
      from bt_bugs
    </querytext>
  </fullquery>
</queryset>