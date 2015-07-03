<master src="../lib/master">
<property name="doc(title)">@page_title;literal@</property>
<property name="context">@context;literal@</property>
<property name="displayed_object_id">@bug.bug_id;literal@</property>

<if @notification_link@ not nil><property name="notification_link">@notification_link;literal@</property></if>

<p>
  <formtemplate id="bug"></formtemplate>
</p>

<if @user_id@ eq 0>
  <p>
    #bug-tracker.Not_logged_in#
  </p>
</if>

<if @enabled_action_id@ nil>
  <div style="font-size: 75%;" align="right">
    <if @user_agent_p@ false>
      (<a href="@show_user_agent_url@">#bug-tracker.show_user_agent#</a>)
    </if>
    <else>
      (<a href="@hide_user_agent_url@">#bug-tracker.hide_user_agent#</a>)
    </else>
  </div>
</if>

