<master src="../lib/master">
<property name="title">@project_name@</property>
<property name="context_bar">@context_bar@</property>
<property name="notification_link">@notification_link@</property>

<table border="0" cellpadding="0" cellspacing="0" width="100%">
  <tr>
    <td valign="top" width="200" style="border: solid 1px gray;" bgcolor="#ccccff" class="bt_summary_bold">

      <multiple name="stats">
        <if @stats.header@ not nil>
          <p style="padding-left: 4px; background-color: #eeeeff; padding-top: 4px; padding-bottom: 4px; margin-top: 0px; margin-bottom: 8px; ">@stats.header@</p>
        </if>
        <group column="header">
          <p style="margin-top: 0px; margin-bottom: 12px;">
            <table border="0" width="100%">
              <tr>
                <td colspan="2" class="bt_summary_bold">
                  @stats.stat_name@
                </td>
              </tr>
              <group column="stat_name">
                <tr>
                  <td width="75%" class="bt_summary">
                    <a href="@stats.name_url@">@stats.name@</a>
                  </td>
                  <td align="right" class="bt_summary">
                    @stats.num_bugs@
                  </td>
                </tr>
              </group>
            </table>
          </p>
        </group>
      </multiple>
    </td>
    <td width="25">&nbsp;</td>
    <td valign="top">
      <table border=0 width="100%" cellspacing="0" cellpadding="0" bgcolor="white">
        <tr>
          <td colspan="2">
            <table width="100%" style="border: solid 1px gray;" bgcolor="#ccccff" cellspacing="0" cellpadding="4" border="0">
              <tr>
                <td>
                  <b>Showing:</b> @human_readable_filter@
                  (<if @bugs:rowcount@ eq 0><i>none</i></if><if @bugs:rowcount@ eq 1>1 bug</if><if @bugs:rowcount@ gt 1>@bugs:rowcount@ bugs</if>)
                  <if @clear_url@ not nil>(<a href="@clear_url@">clear filters</a>)</if>
                </td>
              </tr>
            </table>
          </td>
        </tr>
        <tr>
          <td colspan="2" height="8">
            <table cellspacing="0" cellpadding="0" border="0"><tr><td height="8"></td></tr></table>
          </td>
        </tr>
        <form action="." method="get" name="displaymode_form">
          @displaymode_form_export_vars@
          <tr>
            <td colspan="2" align="right">
              Order by:
              <select name="filter.orderby" onchange="document.displaymode_form.submit();">
                <multiple name="orderby">
                  <if @orderby.selected_p@ true>
                    <option value="@orderby.value@" selected>@orderby.label@</option>
                  </if>
                  <else>
                    <option value="@orderby.value@">@orderby.label@</option>
                  </else>
                </multiple>
              </select>
              <input type="submit" value="Go">
            </td>
          </tr>
        </form>
        <tr>
          <td colspan="2" height="16">
            <table cellspacing="0" cellpadding="0" border="0"><tr><td height="16"></td></tr></table>
          </td>
        </tr>

        <multiple name="bugs">
          <tr>
            <td valign=top>
              <font face="tahoma,verdana,arial,helvetica,sans-serif">
              <font color="#6f6f6f">#</font>@bugs.bug_number@<font color="#6f6f6f">. </font><a href="@bugs.bug_url@" title="View bug details">@bugs.summary@</a><br>
              <font size="-1">
                <if @bugs.description_short@ not nil><font size="-1">@bugs.description_short@<br></if>
                <font color="#6f6f6f">Component:</font> @bugs.component_name@ 
                <font color="#6f6f6f">- Opened</font> @bugs.creation_date_pretty@
                  <font color="#6f6f6f">By</font> <a href="@bugs.submitter_url@" title="Email: @bugs.submitter_email@">@bugs.submitter_first_names@ @bugs.submitter_last_name@</a><br>
                <font color="#6f6f6f">Priority:</font> @bugs.priority_pretty@ 
                <font color="#6f6f6f">- Severity:</font> @bugs.severity_pretty@
                <font color="#6f6f6f">- Type:</font> @bugs.bug_type_pretty@
                <br>
                <font color="#6f6f6f">Assigned to:</font>
                <if @bugs.assignee_user_id@ not nil>
                  <a href="@bugs.assignee_url@" title="Eamil: @bugs.assignee_email@">@bugs.assignee_first_names@ @bugs.assignee_last_name@</a>
                </if>
                <else>
                  <i>Unassigned</i>
                </else>
                <br>
                <font color="#6f6f6f">Status:</font>
                <font color="#008000"><b>@bugs.status_pretty@</b>
                <if @bugs.status@ eq "open">
                  <if @bugs.fix_for_version@ not nil>
                    (fix for version @bugs.fix_for_version_name@)
                  </if>
                </if>
                <else>
                  <if @bugs.resolution@ not nil> - @bugs.resolution_pretty@</if>
                  <if @bugs.fixed_in_version@ not nil>
                    in version @bugs.fixed_in_version_name@
                  </if>
                </else>
                <if @bugs.latest_estimate_minutes@ not nil>
                  <b>Est: @bugs.latest_estimate_minutes@</b></font></font>
                </if>
              </font>
              <p>
            </td>
          </tr>
        </multiple>
        <if @bugs:rowcount@ eq 0>
          <tr>
            <td colspan="2">
              <p>&nbsp;<p>
              <i>No bugs match these criteria.</i>
            </td>
          </tr>
        </if>
      </table>
    </td>
  </tr>
</table>
