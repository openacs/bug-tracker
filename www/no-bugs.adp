<master src="../lib/master">
<property name="doc(title)">@page_title;literal@</property>
<property name="context">@context;literal@</property>

<p>
  <i>#bug-tracker.This_project_is_empty#</i>
</p>

<if @admin_p@ true>
  <p>
    <b>&raquo;</b> <a href="admin/">#bug-tracker.Project_administration#</a>
  </p>
</if>

<p>
  <b>&raquo;</b> <a href="bug-add">#bug-tracker.Submit_a_new_bug#</a>
</p>


