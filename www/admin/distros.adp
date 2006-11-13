<master src="../../lib/master">
<property name="title">@page_title;noquote@</property>
<property name="context_bar">@context_bar;noquote@</property>


<blockquote>

<table cellspacing="1" cellpadding="3" class="bt_listing">
  <tr class="bt_listing_header">
    <th class="bt_listing">Distribution Type</th>
    <th class="bt_listing">Component</th>
    <th class="bt_listing"># @pretty_names.Bugs@</th>
    <th class="bt_listing">Delete</th>
  </tr>
  <if @distributions:rowcount@ gt 0>
    <multiple name="distributions">
      <tr class="bt_listing_spacer">
        <td class="bt_listing" colspan="4">
          &nbsp;
        </td>
      </tr>
      <tr class="bt_listing_subheader">
        <td class="bt_listing">
          @distributions.parent_heading@
        </td>
        <td class="bt_listing" align="center">
          <if @distributions.type_edit_url@ not nil>
            <a href="@distributions.type_edit_url@"><img src="../graphics/Edit16.gif" width="16" height="16" border="0" alt="Edit"></a>
          </if>
        </td>
        <td class="bt_listing">
          &nbsp;
        </td>
        <td class="bt_listing" align="center">
          <if @distributions.type_delete_url@ not nil>
            <a href="@distributions.type_delete_url@"><img src="../graphics/Delete16.gif" width="16" height="16" border="0" alt="Delete"></a>
          </if>
        </td>
      </tr>

      <if @distributions.child_id@ not nil>
        <group column="parent_id">
          <if @distributions.rownum@ odd>
            <tr class="bt_listing_odd">
          </if>
          <else>
            <tr class="bt_listing_even">
          </else>
            <td>&nbsp;</td>
            <td class="bt_listing">
              @distributions.child_heading@
            </td>
            <td class="bt_listing">
              <if @distributions.num_bugs@ gt 0>
                <a href="@distributions.bugs_url@">@distributions.num_bugs@ <if @distributions.num_bugs@ eq 1>@pretty_names.bug@</if><else>@pretty_names.bugs@</else></a>
              </if>
              <else>
                &nbsp;
              </else>
            </td>
            <td class="bt_listing" align="center">
              <if @distributions.delete_url@ not nil>
                <a href="@distributions.delete_url@"><img src="../graphics/Delete16.gif" width="16" height="16" border="0" alt="Delete"></a>
              </if>
            </td>
          </tr>
	  <if @distributions.groupnum_last_p@ true and @distributions.groupnum@ lt @distro_components@>
      	    <tr class="bt_listing_even">
             <td class="bt_listing">&nbsp;</td>
             <td class="bt_listing">
              <b>&raquo;</b>
              <a href="@distributions.new_url@">Add component to the distribution</a>
             </td>
             <td class="bt_listing">&nbsp;</td>
             <td class="bt_listing">&nbsp;</td>
            </tr>      
	  </if>
        </group>
      </if>

      <else>
        <tr class="bt_listing_even">
          <td class="bt_listing">&nbsp;</td>
          <td class="bt_listing" colspan="3">
            <i>No components in this distribution.</i>
          </td>
        </tr>
      	    <tr class="bt_listing_even">
             <td class="bt_listing">&nbsp;</td>
             <td class="bt_listing">
              <b>&raquo;</b>
              <a href="@distributions.new_url@">Add component to the distribution</a>
             </td>
             <td class="bt_listing">&nbsp;</td>
             <td class="bt_listing">&nbsp;</td>
            </tr>      
      </else>

    </multiple>
  </if>
  <else>
  </else>


  <tr class="bt_listing_spacer">
    <td class="bt_listing" colspan="4">
      &nbsp;
    </td>
  </tr>
  <tr class="bt_listing_even">
    <td class="bt_listing" colspan="4">
      <b>&raquo;</b>
      <a href="@type_new_url@">Create new distribution type</a>
    </td>
  </tr>

</table>

</blockquote>
