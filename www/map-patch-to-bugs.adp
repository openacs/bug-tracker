<master src="../lib/master">
<property name="title">@page_title@</property>
<property name="context_bar">@context_bar@</property>

<if @open_bugs:rowcount@ not eq 0>
Select one or more of the following bugs for patch "@patch_summary@" (you may select more bugs later):
</if>

<p>
Components: @component_filter@
</p>

<p>
Bug status: [ @open_filter@ ]
</p>

<p>
<include src="../lib/pagination" row_count="@bug_count@" offset="@offset@" interval_size="@interval_size@" variable_set_to_export="@pagination_export_var_set@" pretty_plural="bugs">
</p>

<blockquote>

<form method="POST" action="map-patch-to-bugs">
  <input type="hidden" name="patch_number" value="@patch_number@" />
  <table>
    <if @open_bugs:rowcount@ not eq 0>
      <tr>
        <th>&nbsp;</th>
        <th>Bug Number</th>
        <th>Summary</th>
        <th>Creation Date</th>
      </tr>
    </if>

    <multiple name="open_bugs">
      <tr>
        <td><input type="checkbox" value="@open_bugs.bug_number@" name="bug_number"></td>
        <td align="center">@open_bugs.bug_number@</td>
        <td><a href="bug?bug_number=@open_bugs.bug_number@">@open_bugs.summary@</a></td>
        <td align="center">@open_bugs.creation_date_pretty@</td>
      </tr>
    </multiple>
  </table>

   <if @open_bugs:rowcount@ eq 0>
     <i>There are no open bugs to map the patch to. Try changing the component filter above.</i>

     <p>
     <center>
       <input type="submit" name="cancel" value="Ok" />
     </center>
     </p>
   </if>
   <else>
     <p>
       <center>
          <input type="submit" name="do_map" value="Map Bugs" /> &nbsp; &nbsp;
          <input type="submit" name="cancel" value="Cancel" />
       </center>
     </p>
   </else>
</form>
</blockquote>