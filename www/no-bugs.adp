<master src="../lib/master">
<property name="title">@project_name;noquote@</property>
<property name="context_bar">@context_bar;noquote@</property>

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

