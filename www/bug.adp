<master src="../lib/master">
<property name="title">@page_title@</property>
<property name="context_bar">@context_bar@</property>
<property name="notification_link">@notification_link@</property>

<if @mode@ eq "view">
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

<formtemplate id="bug" style="standard-lars"></formtemplate>

<p>

<if @button_form_export_vars@ not nil>
  <blockquote>
    <form method="GET" action="bug">
      @button_form_export_vars@
      <multiple name="button">
        <input type="submit" name="@button.name@" value="     @button.label@     ">
      </multiple>
    </form>
  </blockquote>
</if>

<if @mode@ eq "view">
  <div style="font-size: 75%;" align="right">
    <if @user_agent_p@ false>
      (<a href="@show_user_agent_url@">show user agent</a>)
    </if>
    <else>
      (<a href="@hide_user_agent_url@">hide user agent</a>)
    </else>
  </div>
</if>

<p>
