<master src="../lib/master">
<property name="title">@project_name;noquote@</property>
<property name="context_bar">@context_bar;noquote@</property>

<table border="0" cellpadding="0" cellspacing="0" width="100%">
  <tr>
    <td valign="top" width="200" style="border: solid 1px gray;" bgcolor="#ccccff" class="bt_summary_bold">

      <multiple name="stats">
        <if @stats.header@ not nil>
          <p class="bt_summary_section">@stats.header@</p>
        </if>
        <group column="header">
          <p style="margin-top: 0px; margin-bottom: 12px;">
            <table border="0" cellspacing="0" cellpadding="2" width="100%">
              <tr>
                <td colspan="2" class="bt_summary_header">
                 @stats.stat_name@
                </td>
              </tr>
              <group column="stat_name">
                <if @stats.selected_p@ true>
                  <tr bgcolor="#eeeeff">
                </if>
                <else>
                  <tr>
                </else>
                  <td width="75%" class="bt_summary">
                    <a href="@stats.name_url@">@stats.name;noquote@</a>
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

      <div  style="border: solid 1px gray; background-color: #ccccff; padding: 4px;">
        <b>Showing:</b> @human_readable_filter@
        (<if @bugs:rowcount@ eq 0><i>none</i></if><if @bugs:rowcount@ eq 1>1 bug</if><if @bugs:rowcount@ gt 1>@bugs_count@ <if @bugs_count@ eq 1>@pretty_names.bug@</if><else>@pretty_names.bugs@</else></if>)
        <if @clear_url@ not nil>(<a href="@clear_url@">show default listing</a>)</if>
      </div>

      <form action="." method="get" name="displaymode_form">
        @displaymode_form_export_vars;noquote@

        <div style="background-color: #eeeeff; padding: 4px; margin-top: 8px; margin-bottom: 16px; border: solid 1px #cccccc;">

         <div style="float: right;">

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
           </div>

          <span style="align: left;">
              Opened in the last: [ 
              <multiple name="options_n_days">
                <if @options_n_days.rownum@ ne 1> | </if>
                <if @options_n_days.selected_p@ true><b>@options_n_days.label@</b></if>
                <else><a href="@options_n_days.url@">@options_n_days.label@</a></else>
              </multiple>
              ] days
          </span>


      </div>

      </form>

        <multiple name="bugs">
          <p class="bt">

            <span style="font-size: 115%;">
              <span class="bt_douce">#</span>@bugs.bug_number@<span class="bt_douce">. </span>
              <a href="@bugs.bug_url@" title="View bug details">@bugs.summary@</a><br>
            </span>

            <if @bugs.comment_short@ not nil>@bugs.comment_short@<br></if>
            <span class="bt_douce">@pretty_names.Component@:</span> @bugs.component_name@ 
            <span class="bt_douce">- Opened</span> @bugs.creation_date_pretty@
              <span class="bt_douce">By</span> <a href="@bugs.submitter_url@" title="Email: @bugs.submitter_email@">@bugs.submitter_first_names@ @bugs.submitter_last_name@</a><br>
            <if @bugs.category_name@ not nil>
              <group column="bug_id">
                <span class="bt_douce">@bugs.category_name@:</span> @bugs.category_value@
                <if @bugs.groupnum_last_p@ false> - </if>
              </group>
              <br>
            </if>
            <span class="bt_douce">Assigned to:</span>
            <if @bugs.assignee_party_id@ not nil>
              <a href="@bugs.assignee_url@" title="Email: @bugs.assignee_email@">@bugs.assignee_name@</a>
            </if>
            <else>
              <i>Unassigned</i>
            </else>
            <br>

            <span class="bt_douce">Status:</span>
            <span style="color: #008000;"><b>@bugs.pretty_state@</b>
              <if @bugs.fix_for_version@ not nil>
                (fix for version @bugs.fix_for_version_name@)
              </if>
              <else>
                <if @bugs.resolution@ not nil> - @bugs.resolution_pretty@</if>
                <if @bugs.fixed_in_version@ not nil>
                  in version @bugs.fixed_in_version_name@
                </if>
              </else>
            </span>

          </p>
        </multiple>
        <if @bugs:rowcount@ eq 0>
              <p>&nbsp;<p>
              <i>No @pretty_names.bugs@ match these criteria.</i>
        </if>

    </td>
  </tr>
</table>
