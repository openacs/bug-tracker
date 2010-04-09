<div class="bt_navbar" style="background: #41329c; text-align: right; padding: 3px;">
  <div style="float: left; padding: .25em; 1em 0em 1em;"><a href="@notification_url@" class="bt_navbar" title="@notification_title@">@notification_label@</a></div>
  <multiple name="links"><a href="@links.url@" class="bt_navbar">@links.name@</a>&nbsp;|&nbsp;</multiple>
  <form style="display: inline" action="@form_action_url@" method="get" name="navbar_form_@bt_nav_bar_count@">
    <input name="bug_number" type="text" size="5" class="bt_navbar" value="@pretty_names.Bug@ #" 
      onFocus="javascript:this.value='';">
      <input type="submit" value="Go" class="bt_navbar">
  </form>
  <if @search_mounted_p@>
      <form style="display: inline" action="@form_search_url@" method="get" name="search">
        <input name="q" type="text" size="15" class="bt_navbar" value="#bug-tracker.Search#" 
          onFocus="javascript:this.value='';">
        <input name="search_package_id" type="hidden" value="@package_id@">
          <input type="submit" value="#bug-tracker.Search#" class="bt_navbar">
      </form>
  </if>

</div>
