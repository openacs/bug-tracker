<master src="../lib/master">
<property name="title">@page_title;noquote@</property>
<property name="context">@context;noquote@</property>

<if @open_bugs:rowcount@ not eq 0>
#bug-tracker.Select_one_or_more_of#
</if>

<p>
#bug-tracker.Components_component_filter#
</p>

<p>
#bug-tracker.Bug_status_open_filter#
</p>

<p>
<include src="../lib/pagination" row_count="@bug_count;noquote@" offset="@offset;noquote@" interval_size="@interval_size;noquote@" variable_set_to_export="@pagination_export_var_set;noquote@" pretty_plural="@pretty_names.bugs;noquote@">
</p>

<blockquote>

<form method="POST" action="map-patch-to-bugs">
  <input type="hidden" name="patch_number" value="@patch_number@" />
  <table>
    <if @open_bugs:rowcount@ not eq 0>
      <tr>
        <th>&nbsp;</th>
        <th>#bug-tracker.Bug_Number#</th>
        <th>#bug-tracker.Summary#</th>
        <th>#bug-tracker.Creation_Date#</th>
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
     <i>#bug-tracker.There_are_no_open_to_map#</i>

     <p>
     <center>
       <input type="submit" name="cancel" value="Ok" />
     </center>
     </p>
   </if>
   <else>
     <p>
       <center>
          <input type="submit" name="do_map" value="Map @pretty_names.bugs@" /> &nbsp; &nbsp;
          <input type="submit" name="cancel" value="Cancel" />
       </center>
     </p>
   </else>
</form>
</blockquote>

