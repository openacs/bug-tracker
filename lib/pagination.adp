<form action="map-patch-to-bugs" method="POST"> 
@pagination_form_export_vars@
<table>
<tr>
<td>
Page with @pretty_plural@: [ @pagination_filter@ ] &nbsp; &nbsp; Show <input type="text" name="interval_size" value="@interval_size@" /> @pretty_plural@ per page <input type="submit" value="Go" />
</td>
</tr>
</table>
</form>
