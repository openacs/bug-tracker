<master src="../../lib/master">
<property name="title">@project_name@ Project Admin</property>
<property name="context_bar">@context_bar@</property>

<table cellspacing="0" cellpadding="4" border="0">
  <tr>
    <td colspan="3">
    </td>
    <th>
      Edit
    </th>
    <th>
      Delete
    </th>
  </tr>
  <tr bgcolor="#666666">
    <td colspan="3">
      <font color=white><b>@project_name@</b></font>
    </td>
    <td align="center">
      <a href="@project_edit_url@"><img src="../graphics/Edit16.gif" width="16" height="16" border="0" alt="Edit"></a>
    </td>
    <td align="center">
      &nbsp;
    </td>
  </tr>
  <tr bgcolor="#cccccc">
    <td colspan="2">
      Maintainer: 
      <if @project.maintainer@ not nil>
        <a href="@project.maintainer_url@" title="Email: @project.maintainer_email@">@project.maintainer_first_names@ @project.maintainer_last_name@</a>
      </if>
      <else>
        <i>No Maintainer</i> 
      </else>
    </td>
    <td align="center">
      &nbsp;
    </td>
    <td align="center">
      <a href="@project_maintainer_edit_url@"><img src="../graphics/Edit16.gif" width="16" height="16" border="0" alt="Edit"></a>
    </td>
    <td align="center">
      &nbsp;
    </td>
  </tr>
  <tr bgcolor="#cccccc">
    <td colspan="3">
      Project versions
    </td>
    <td align="center">
      <a href="@versions_edit_url@"><img src="../graphics/Edit16.gif" width="16" height="16" border="0" alt="Edit"></a>
    </td>
    <td align="center">
      &nbsp;
    </td>
  </tr>
  <tr bgcolor="#cccccc">
    <td colspan="3">
      Project permissions
    </td>
    <td align="center">
      <a href="@permissions_edit_url@"><img src="../graphics/Edit16.gif" width="16" height="16" border="0" alt="Edit"></a>
    </td>
    <td align="center">
      &nbsp;
    </td>
  </tr>


<!--
  <tr bgcolor="#cccccc">
    <td colspan="3">
      Priority codes
    </td>
    <td align="center">
      <a href="@priority_codes_edit_url@"><img src="../graphics/Edit16.gif" width="16" height="16" border="0" alt="Edit"></a>
    </td>
    <td align="center">
      &nbsp;
    </td>
  </tr>
  <tr bgcolor="#cccccc">
    <td colspan="2">
      Severity codes
    </td>
    <td align="center">
      <a href="@severity_codes_edit_url@"><img src="../graphics/Edit16.gif" width="16" height="16" border="0" alt="Edit"></a>
    </td>
    <td align="center">
      &nbsp;
    </td>
  </tr>
-->

  <tr bgcolor="#999999">
    <td colspan="5" align="center">
      <font color=white><b>Components</b></font>
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
          <a href="@components.maintainer_url@" title="Email: @components.maintainer_email@">@components.maintainer_first_names@ @components.maintainer_last_name@</a>
        </if>
        <else><i>No maintainer</i></else>
      </td>
      <td align="right">
        <if @components.view_bugs_url@ not nil><a href="@components.view_bugs_url@" title="View the bugs for this component"></if>@components.num_bugs@ <if @components.num_bugs@ eq 1>bug</if><else>bugs</else><if @components.view_bugs_url@ not nil></a></if>
      </td>
      <td align="center">
        <a href="@components.edit_url@"><img src="../graphics/Edit16.gif" width="16" height="16" border="0" alt="Edit"></a>
      </td>
      <td align="center">
        <if @components.delete_url@ not nil>
          <a href="@components.delete_url@"><img src="../graphics/Delete16.gif" width="16" height="16" border="0" alt="Delete"></a>
        </if>
      </td>
    </tr>
  </multiple>
  <if @components:rowcount@ eq 0>
    <tr bgcolor="#cccccc">
      <td colspan="5"><i>No components</i></td>
    </tr>
  </if>
  <tr bgcolor="#bbbbbb">
    <td colspan="5"><a href="@component_add_url@">Create New Component</a></td>
  </tr>
</table>

<p>
    
