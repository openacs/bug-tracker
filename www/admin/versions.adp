<master src="../../lib/master">
<property name="title">@project_name@ Versions</property>
<property name="context_bar">@context_bar@</property>

<h3>Current Version (The one currently being developed)</h3>

<if @current_version:rowcount@ eq 0>
  <i>None</i>
</if>
<else>
  <table cellspacing="2" cellpadding="4" border="0">
    <tr bgcolor="#cccccc">
      <th>Edit</th>
      <th>Version</th>
      <th>Planned Freeze</th>
      <th>Planned Release</th>
      <th>Maintainer</th>
      <th>Supported Platforms</th>
      <th>Assignable?</th>
    </tr>
    <multiple name="current_version">
      <tr>
        <td><a href="@current_version.edit_url@"><img src="../graphics/Edit16.gif" width="16" height="16" alt="Edit" border="0"></a></td>
        <td>@current_version.version_name@</td>
        <td>@current_version.anticipated_freeze_date@</td>
        <td>@current_version.anticipated_release_date@</td>
        <td>
          <if @current_version.maintainer@ not nil>
            <a href="@current_version.maintainer_url@" title="Email: @current_version.maintainer_email@">@current_version.maintainer_first_names@ 
            @current_version.maintainer_last_name@</a>
          </if>
          <else><i>None</i></else>
        </td>
        <td>@current_version.supported_platforms@</td>
        <td>@current_version.assignable_p_pretty@</td>
      </tr>
    </multiple>
  </table>
</else>


<h3>Future Versions</h3>

<if @future_version:rowcount@ eq 0>
  <i>None</i>
</if>
<else>
  <table cellspacing="2" cellpadding="4" border="0">
    <tr bgcolor="#cccccc">
      <th>Edit</th>
      <th>Make Active</th>
      <th>Version</th>
      <th>Planned Freeze</th>
      <th>Planned Release</th>
      <th>Maintainer</th>
      <th>Supported Platforms</th>
      <th>Assignable?</th>
    </tr>
    <multiple name="future_version">
      <tr>
        <td><a href="@future_version.edit_url@"><img src="../graphics/Edit16.gif" width="16" height="16" alt="Edit" border="0"></a></td>
        <td><a href="@future_version.set_active_url@">Make Active</a></td>
        <td>@future_version.version_name@</td>
        <td>@future_version.anticipated_freeze_date@</td>
        <td>@future_version.anticipated_release_date@</td>
        <td>
          <if @future_version.maintainer@ not nil>
            <a href="@future_version.maintainer_url@" title="Email: @future_version.maintainer_email@">@future_version.maintainer_first_names@ 
            @future_version.maintainer_last_name@</a>
          </if>
          <else><i>None</i></else>
        </td>
        <td>@future_version.supported_platforms@</td>
        <td>@future_version.assignable_p_pretty@</td>
      </tr>
    </multiple>
  </table>
</else>

<p>

<a href="@version_add_url@">Add new version</a>

<h3>Past Versions</h3>

<if @past_version:rowcount@ eq 0>
  <i>None</i>
</if>
<else>
  <table cellspacing="2" cellpadding="4" border="0">
    <tr bgcolor="#cccccc">
      <th>Edit</th>
      <th>Version</th>
      <th>Actual Freeze</th>
      <th>Actual Release</th>
      <th>Supported Platforms</th>
    </tr>
    <multiple name="past_version">
      <tr>
        <td><a href="@past_version.edit_url@"><img src="../graphics/Edit16.gif" width="16" height="16" alt="Edit" border="0"></a></td>
        <td>@past_version.version_name@</td>
        <td>@past_version.actual_freeze_date@</td>
        <td>@past_version.actual_release_date@</td>
        <td>
          <if @past_version.maintainer@ not nil>
            <a href="@past_version.maintainer_url@" title="Email: @past_version.maintainer_email@">@past_version.maintainer_first_names@ 
            @past_version.maintainer_last_name@</a>
          </if>
          <else><i>None</i></else>
        </td>
        <td>@past_version.supported_platforms@</td>
      </tr>
    </multiple>
  </table>
</else>
