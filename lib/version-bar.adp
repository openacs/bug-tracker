<table border=0" cellspacing="0" cellpadding="4" bgcolor="#41329c" align="right">
  <tr>      
    <td align="center">
      <if @user_id@ ne 0><span class="bt_navbar">@user_first_names@ @user_last_name@</span></if>
      <else><span class="bt_navbar">Not logged in (</span><a href="@login_url@" class="bt_navbar">log in</a><span class="bt_navbar">)</span></else>
    </td>
  </tr>
  <if @versions_p@ true>
    <tr>      
      <td align="center">
        <span class="bt_navbar">
          <if @user_id@ ne 0>
            Your version: </span><a href="@user_version_url@" class="bt_navbar">@user_version_name@</a><span class="bt_navbar">
            <if @user_version_id@ ne @current_version_id@>
              | Current: @current_version_name@
            </if>
            <else>
              (current)
            </else>
          </if>
          <else>
            Current version: @current_version_name@
          </else>
        </span>
      </td>
    </tr>
  </if>
</table>

