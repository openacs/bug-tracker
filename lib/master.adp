<master>
<property name="title">@title;noquote@</property>
<property name="header_stuff">
  <style>
  a.bt_navbar { 
    color: white; 
  }
  a.bt_navbar:visited { 
    color: white; 
  }
  a.bt_navbar:hover { 
    color: white; 
    text-decoration: underline;
  }
  input.bt_navbar { 
    font-family: tahoma,verdana,arial,helvetica; 
    font-weight: bold; 
    font-size: 70%; 
    color: black; 
  }

  .bt_navbar { 
    font-family: tahoma,verdana,arial,helvetica; 
    font-size: 70%; 
    font-weight: bold; 
    color: #ccccff; 
    text-decoration: none; 
  }

  .bt_summary { 
    font-size: 70%; 
    font-family: verdana,arial,helvetica; 
  }
  .bt_summary_header { 
    font-size: 70%; 
    font-family: verdana,arial,helvetica; 
    font-weight: bold; 
  }
  .bt_summary_section { 
    font-size: 70%; 
    font-family: verdana,arial,helvetica; 
    font-weight: bold; 
    background-color: #bbbbff; 
    padding-left: 4px; 
    padding-top: 4px; 
    padding-bottom: 4px; 
    margin-top: 0px; 
    margin-bottom: 8px;
  }

  .bt_header {
    font-family: verdana, helvetica; 
  }

  .bt_douce {
    color: #6f6f6f;
  }


  table.bt_listing {
    font-family: tahoma, verdana, helvetica; 
    font-size: 85%;
  }
  tr.bt_listing_header {
    background-color: #cccccc; 
  }
  tr.bt_listing_subheader {
    background-color: #bbbbbb; 
    font-weight: bold;
  }
  tr.bt_listing_even {
    background-color: #f0f0f0;
  }
  tr.bt_listing_spacer {
    background-color: #f9f9f9;
  }
  tr.bt_listing_odd {
    background-color: #e0e0e0;
  }
  td.bt_listing_narrow {
    padding-left: 4px; 
    padding-right: 4px;
  }
  td.bt_listing {
    padding-left: 16px; 
    padding-right: 16px;
  }
  th.bt_listing_narrow {
    padding-left: 4px; 
    padding-right: 4px;
  }
  th.bt_listing {
    padding-left: 16px; 
    padding-right: 16px;
  }
  
  p.bt {
    font-family: tahoma, verdana, helvetica; 
    font-size: 85%;
  }

  pre { 
    font-family: Courier; 
    font-size: 10pt; 
  }
  </style>
</property>
<if @signatory@ not nil><property name="signatory">@signatory;noquote@</property></if>
<if @focus@ not nil><property name="focus">@focus;noquote@</property></if>
<property name="body_start_include">/packages/bug-tracker/lib/version-bar</property>
<if @context_bar@ not nil>
  <property name="context_bar">@context_bar;noquote@</property>
</if>
<if @context@ not nil>
  <property name="context">@context;noquote@</property>
</if>

<include src="nav-bar" notification_link="@notification_link;noquote@">

<p>

<slave>

<p>

<include src="nav-bar" notification_link="@notification_link;noquote@">

