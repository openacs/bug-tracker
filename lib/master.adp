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
  </style>
</property>
<if @signatory@ not nil><property name="signatory">@signatory</property></if>
<if @focus@ not nil><property name="focus">@focus@</property></if>

<include src="version-bar">
<h2>@header@</h2>
@context_bar@
<hr>

<include src="nav-bar">

<p>

<slave>

<p>

<include src="nav-bar">
