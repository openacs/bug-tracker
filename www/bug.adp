<master src="../lib/master">
<property name="title">@page_title@</property>
<property name="context_bar">@context_bar@</property>

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
