<master src="../lib/master">
<property name="title">@page_title@</property>
<property name="context_bar">@context_bar@</property>
<if @notification_link@ not nil><property name="notification_link">@notification_link@</property></if>

<if @action_id@ nil>
  <table align="right">
    <tr>
      <td>
        <multiple name="navlinks">
          <if @navlinks.url@ not nil><a href="@navlinks.url@">&nbsp;&nbsp;@navlinks.label@&nbsp;&nbsp;</a></if>
          <else>&nbsp;&nbsp;@navlinks.label@&nbsp;&nbsp;</else>
          <if @navlinks.rownum@ lt @navlinks:rowcount@>&nbsp;&nbsp;&nbsp;</if>
        </multiple>
      </td>
    </tr>
  </table>
</if>

<p>
  <formtemplate id="bug" style="standard-lars"></formtemplate>
</p>

<if @user_id@ eq 0>
  <p>
    You're not logged in. For more options, <a href="@login_url@">log in now</a>.
  </p>
</if>

<if @action_id@ nil>
  <div style="font-size: 75%;" align="right">
    <if @user_agent_p@ false>
      (<a href="@show_user_agent_url@">show user agent</a>)
    </if>
    <else>
      (<a href="@hide_user_agent_url@">hide user agent</a>)
    </else>
  </div>
</if>

