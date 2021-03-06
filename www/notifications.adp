<master src="../lib/master">
<property name="doc(title)">@page_title;literal@</property>
<property name="context">@context;literal@</property>

<table cellspacing="1" cellpadding="3" class="bt_listing">
  <tr class="bt_listing_header">
    <th colspan="2">#bug-tracker.Notifications_for#</th>
    <th>#bug-tracker.Subscribe#</th>
    <th>#bug-tracker.Unsubscribe#</th>
  </tr>
  <multiple name="notifications">
    <if @notifications.rownum@ odd>
      <tr class="bt_listing_odd">
    </if>
    <else>
      <tr class="bt_listing_even">
    </else>
      <td align="center" class="bt_listing_narrow">
        <if @notifications.subscribed_p;literal@ true>
          <b>&raquo;</b>
        </if>
        <else>
          &nbsp;
        </else>
      </td>
      <td class="bt_listing">
        @notifications.label@
      </td>
      <td class="bt_listing">
        <if @notifications.subscribed_p;literal@ false>
          <a href="@notifications.url@" title="@notifications.title@">#bug-tracker.Subscribe#</a>
        </if>
      </td>
      <td class="bt_listing">
        <if @notifications.subscribed_p;literal@ true>
          <a href="@notifications.url@" title="@notifications.title@">#bug-tracker.Unsubscribe#</a>
        </if>
      </td>
    </tr>
  </multiple>
</table>

<p>
  <a href="@manage_url@">#bug-tracker.Manage_your_notification#</a>
</p>

