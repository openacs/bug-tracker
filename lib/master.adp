<master>
<property name="title">@title@</property>
<property name="header_stuff">
  <style>
  .bt_navbar { font-family: tahoma,verdana,arial,helvetica; font-size: 70%; font-weight: bold; color: #ccccff; text-decoration: none; }
  A.bt_navbar { color: white; }
  .bt_navbar:hover { color: white; text-decoration: underline;  }
  INPUT.bt_navbar { font-family: tahoma,verdana,arial,helvetica; font-weight: bold; font-size: 70%; color: black; }
  .bt_summary { font-size: 70%; font-family: verdana,arial,helvetica; }
  .bt_summary_bold { font-size: 70%; font-family: verdana,arial,helvetica; font-weight: bold; }
  pre { font-family: Courier; font-size: 10pt; }
  </style>
</property>
<if @signatory@ not nil><property name="signatory">@signatory</property></if>
<if @focus@ not nil><property name="focus">@focus@</property></if>
<property name="body_start_include">/packages/bug-tracker/lib/version-bar</property>
<property name="context_bar">@context_bar@</property>

<include src="nav-bar" notification_link="@notification_link@">

<p>

<slave>

<p>

<include src="nav-bar" notification_link="@notification_link@">
