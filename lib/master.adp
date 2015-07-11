<master>
  <property name="doc(title)">@title;literal@</property>
  <if @signatory@ not nil><property name="signatory">@signatory;literal@</property></if>
  <if @focus@ not nil><property name="focus">@focus;literal@</property></if>
  <if @displayed_object_id@ not nil><property name="displayed_object_id">@displayed_object_id;literal@</property></if>
  <property name="body_start_include">/packages/bug-tracker/lib/version-bar</property>
  <if @context_bar@ not nil>
    <property name="context_bar">@context_bar;literal@</property>
  </if>
  <if @context@ not nil>
    <property name="context">@context;literal@</property>
  </if>

<include src="nav-bar" notification_link="@notification_link;literal@">
<slave>
<include src="nav-bar" notification_link="@notification_link;literal@">
