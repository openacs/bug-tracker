<master src="../lib/master">
<property name="title">@project_name@</property>
<property name="context_bar">@context_bar@</property>
<property name="notification_link">@notification_link@</property>

<p>
  <i>This project is empty.</i>
</p>

<if @admin_p@ true>
  <p>
    <b>&raquo;</b> <a href="admin/">Project administration</a>
  </p>
</if>

<p>
  <b>&raquo;</b> <a href="bug-add">Submit a new @pretty_names.bug@</a>
</p>

