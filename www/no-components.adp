<master src="../lib/master">
<property name="title">@page_title;noquote@</property>
<property name="context">@context;noquote@</property>

#bug-tracker.Before_getting_started#

<p>

<if @admin_p@>
  #bug-tracker.Please_visit_admin_page#
</if>
<else>
  #bug-tracker.Please_contact_admin#
</else>
