<master src="../../lib/master">
<property name="title">@page_title;noquote@</property>
<property name="context_bar">@context_bar;noquote@</property>

<blockquote>

<if @bugs_exist_p@ false>
  <div style="background-color: #ccccff; padding: 12px; border: dashed 1px #6666ff;">
    <p>
      <b>#bug-tracker.This_is_a_new_project#</b>
    </p>
    <p>  
      <b>&raquo;</b> <a href="initial-setup">#bug-tracker.Initial_project_config#</a>
    </p>
  </div>
</if>

<table cellspacing="0" cellpadding="4" border="0">
  <tr>
    <td colspan="3">
    </td>
    <th>
      #acs-kernel.common_edit#
    </th>
    <th>
      #acs-kernel.common_delete#
    </th>
  </tr>
  <tr bgcolor="#666666">
    <td colspan="3">
      <font color=white><b>@project_name@</b></font>
    </td>
    <td align="center">
      <a href="@project_edit_url@"><img src="../graphics/Edit16.gif" width="16" height="16" border="0" alt="#acs-kernel.common_edit#"></a>
    </td>
    <td align="center">
      &nbsp;
    </td>
  </tr>
  <tr bgcolor="#cccccc">
    <td colspan="2">
      #bug-tracker.Maintainer#
      <if @project.maintainer@ not nil>
        <a href="@project.maintainer_url@" title="Email: @project.maintainer_email@">@project.maintainer_first_names@ @project.maintainer_last_name@</a>
      </if>
      <else>
        <i>#bug-tracker.No_Maintainer#</i> 
      </else>
    </td>
    <td align="center">
      &nbsp;
    </td>
    <td align="center">
      <a href="@project_maintainer_edit_url@"><img src="../graphics/Edit16.gif" width="16" height="16" border="0" alt="#acs-kernel.common_edit#"></a>
    </td>
    <td align="center">
      &nbsp;
    </td>
  </tr>

  <if @versions_p@ true>
    <tr bgcolor="#cccccc">
      <td colspan="3">
        #bug-tracker.Versions#
      </td>
      <td align="center">
        <a href="@versions_edit_url@"><img src="../graphics/Edit16.gif" width="16" height="16" border="0" alt="#acs-kernel.common_edit#"></a>
      </td>
      <td align="center">
        &nbsp;
      </td>
    </tr>
  </if>

  <tr bgcolor="#cccccc">
    <td colspan="3">
      #bug-tracker.Categories#
    </td>
    <td align="center">
      <a href="@categories_edit_url@"><img src="../graphics/Edit16.gif" width="16" height="16" border="0" alt="#acs-kernel.common_edit#"></a>
    </td>
    <td align="center">
      &nbsp;
    </td>
  </tr>
  <tr bgcolor="#cccccc">
    <td colspan="3">
      Distributions
    </td>
    <td align="center">
      <a href="distros"><img src="../graphics/Edit16.gif" width="16" height="16" border="0" alt="Edit"></a>
    </td>
    <td align="center">
      &nbsp;
    </td>
  </tr>
  <tr bgcolor="#cccccc">
    <td colspan="3">
     #bug-tracker.Permissions#
    </td>
    <td align="center">
      <a href="@permissions_edit_url@"><img src="../graphics/Edit16.gif" width="16" height="16" border="0" alt="#acs-kernel.common_edit#"></a>
    </td>
    <td align="center">
      &nbsp;
    </td>
  </tr>
  <tr bgcolor="#cccccc">
    <td colspan="3">
     #bug-tracker.Parameters#
    </td>
    <td align="center">
      <a href="@parameters_edit_url@"><img src="../graphics/Edit16.gif" width="16" height="16" border="0" alt="#acs-kernel.common_edit#"></a>
    </td>
    <td align="center">
      &nbsp;
    </td>
  </tr>


<!--
  <tr bgcolor="#cccccc">
    <td colspan="3">
     #bug-tracker.Priority_codes#
    </td>
    <td align="center">
      <a href="@priority_codes_edit_url@"><img src="../graphics/Edit16.gif" width="16" height="16" border="0" alt="#acs-kernel.common_edit#"></a>
    </td>
    <td align="center">
      &nbsp;
    </td>
  </tr>
  <tr bgcolor="#cccccc">
    <td colspan="2">
     #bug-tracker.Severity_Codes#
    </td>
    <td align="center">
      <a href="@severity_codes_edit_url@"><img src="../graphics/Edit16.gif" width="16" height="16" border="0" alt="#acs-kernel.common_edit#"></a>
    </td>
    <td align="center">
      &nbsp;
    </td>
  </tr>
-->

  <tr bgcolor="#999999">
    <td colspan="5" align="center">
      <font color=white><b>@pretty_names.Components@</b></font>
    </td>
  </tr>

  <multiple name="components">
    <if @components.rownum@ odd>
      <tr bgcolor="#cccccc">
    </if>
    <else>
      <tr bgcolor="#dddddd">
    </else>
      <td>@components.component_name@</td>
      <td>
        <if @components.maintainer@ not nil>
          <a href="@components.maintainer_url@" title="#bug-tracker.Email# @components.maintainer_email@">@components.maintainer_first_names@ @components.maintainer_last_name@</a>
        </if>
        <else><i>#bug-tracker.No_Maintainer#</i></else>
      </td>
      <td align="right">
        <if @components.view_bugs_url@ not nil><a href="@components.view_bugs_url@" title="#bug-tracker.View_the_bug_fo_component#"></if>@components.num_bugs@ <if @components.num_bugs@ eq 1>@pretty_names.bug@</if><else>@pretty_names.bugs@</else><if @components.view_bugs_url@ not nil></a></if>
      </td>
      <td align="center">
        <a href="@components.edit_url@"><img src="../graphics/Edit16.gif" width="16" height="16" border="0" alt="#acs-kernel.common_edit#"></a>
      </td>
      <td align="center">
        <if @components.delete_url@ not nil>
          <a href="@components.delete_url@"><img src="../graphics/Delete16.gif" width="16" height="16" border="0" alt="#acs-kernel.common_delete#"></a>
        </if>
      </td>
    </tr>
  </multiple>
  <if @components:rowcount@ eq 0>
    <tr bgcolor="#cccccc">
      <td colspan="5"><i>#bug-tracker.No_components#</i></td>
    </tr>
  </if>
  <tr bgcolor="#bbbbbb">
    <td colspan="5"><b>&raquo;</b> <a href="@component_add_url@">#bug-tracker.Create_new# @pretty_names.component@</a></td>
  </tr>
</table>
</blockquote>


