<master src="../lib/master">
<property name="title">@page_title@</property>
<property name="context_bar">@context_bar@</property>

<p>
Component: [ @component_filter@ ]
</p>

<p>
Apply to version: [ @version_filter@ ]
</p>

<p>
<include src="../lib/pagination" row_count="@patch_count@" offset="@offset@" interval_size="@interval_size@" variable_set_to_export="@pagination_export_var_set@" pretty_plural="patches">
</p>

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
