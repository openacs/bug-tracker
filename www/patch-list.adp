<master src="../lib/master">
<property name="title">@page_title@</property>
<property name="context">@context@</property>

<p>
Component: [
<multiple name="components">
  <if @components.rownum@ gt 1> | </if>
  <if @components.selected_p@ true><b>@components.label@</b></if>
  <else><a href="@components.url@">@components.label@</a></else>
</multiple>
]
</p>
<p>
Apply to version: [ @version_filter@ ]
</p>
<p>
Display states: [ @state_filter@ ]
<blockquote>
<table>
<if @patch_list:rowcount@ not eq 0>
<tr>
  <th>Patch Summary</th>
  <th>Status</th>
  <th>Creation Date</th>
</tr>
</if>

<multiple name="patch_list">
<tr>
  <td align="left"><a href="patch?patch_number=@patch_list.patch_number@">@patch_list.summary@</a></td>
  <td align="center">@patch_list.status@</td>
  <td align="center">@patch_list.creation_date_pretty@</td>
</tr>
</multiple>
</table>

<if @patch_list:rowcount@ eq 0>
<i>No patches match these criteria.</i>
</if>

</blockquote>
