<master src="../lib/master">
<property name="doc(title)">@page_title;literal@</property>
<property name="context">@context;literal@</property>
<if @patch.patch_id@ defined><property name="displayed_object_id">@patch.patch_id;literal@</property></if>

<formtemplate id="patch"></formtemplate>

<p>
<if @button_form_export_vars@ not nil>
  <blockquote>
    <form method="GET" action="patch">
      @button_form_export_vars;literal@
      <multiple name="button">
        <input type="submit" name="@button.name@" value="     @button.label@     ">
      </multiple>
    </form>
  </blockquote>
</if>
</p>

<if @mode;literal@ eq "view" and @deleted_p@ defined and @deleted_p;literal@ false>
<center>
<p>
<a href="patch?patch_number=@patch_number;noi18n@&download=1">#bug-tracker.Download_patch_content#</a>
</p>
</center>
<p>
<table border="0" cellspacing="0" cellpadding="2" bgcolor="lightgrey" width="100%">
  <tr>
    <td>
      <pre>@patch.content;noi18n@</pre>
    </td>
  </tr>
</table>
</p>
<center>
<p>
<a href="patch?patch_number=@patch_number;noi18n@&download=1">#bug-tracker.Download_patch_content#</a>
</p>
</center>
</if>








