<table border=0" cellspacing="0" cellpadding="2" bgcolor="#41329c" width="100%">
  <form action="@form_action_url@" method="get" name="navbar_form_@bt_nav_bar_count@">
    <tr>
      <td align="right">
        <table border="0" cellspacing="0" cellpadding="0">
          <tr>
            <td>
              <multiple name="links">
                <a href="@links.url@" class="bt_navbar">@links.name@</a><span class="bt_navbar">&nbsp;|&nbsp;</span>
              </multiple>
              <input name="bug_number" type="text" size="5" class="bt_navbar" value="Bug #" 
                onFocus="javascript:document.navbar_form_@bt_nav_bar_count@.bug_number.value='';">
              <input type="submit" value="Go" class="bt_navbar">
            </td>
          </tr>
        </table>
      </td>
    </tr>
  </form>
</table>
