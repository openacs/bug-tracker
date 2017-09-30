<master src="../lib/master">
<property name="doc(title)">@page_title;literal@</property>
<property name="context">@context;literal@</property>

#bug-tracker.Before_getting_started#

<p>

<if @admin_p;literal@ true>
  #bug-tracker.Please_visit_admin_page#
</if>
<else>
  #bug-tracker.Please_contact_admin#
</else>
