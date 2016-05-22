<html>
<head>
<title>Bug-Tracker</title>
<style>
.bt_navbar { font-family: tahoma,verdana,arial,helvetica; font-size: 70%; font-weight: bold; color: #ccccff; text-decoration: none; }
a.bt_navbar { color: white; }
.bt_navbar:hover { color: white; text-decoration: underline;  }
INPUT.bt_navbar { font-family: tahoma,verdana,arial,helvetica; font-weight: bold; font-size: 70%; color: black; }
.bt_summary { font-size: 70%; font-family: verdana,arial,helvetica; }
.bt_summary_bold { font-size: 70%; font-family: verdana,arial,helvetica; font-weight: bold; }

</style>
</head>
<body>

<h2>OpenACS Bug-Tracker</h2>
<a href="/">Home</a> : OpenACS Bug-Tracker
<hr>

<form action="#" method="get" name="navbar1">
  <table border="0" cellspacing="0" cellpadding="2" bgcolor="#41329c" width="100%">
    <tr>
      <td align="left">
        <span class="bt_navbar">Your version: </span><a href="#" class="bt_navbar">4.3</a><span class="bt_navbar"> | Latest: 4.5</span>
      </td>
      <td align="right">
        <table border="0" cellspacing="0" cellpadding="0">
          <tr>
            <td>
              <a href="#" class="bt_navbar">List</a><span class="bt_navbar">&nbsp;|&nbsp;</span>
              <a href="#" class="bt_navbar">New Bug</a><span class="bt_navbar">&nbsp;|&nbsp;</span>
              <a href="#" class="bt_navbar">Search</a><span class="bt_navbar">&nbsp;|&nbsp;</span>
              <a href="#" class="bt_navbar">Filters</a><span class="bt_navbar">&nbsp;|&nbsp;</span>
              <a href="#" class="bt_navbar">Patches</a><span class="bt_navbar">&nbsp;|&nbsp;</span>
              <a href="#" class="bt_navbar">Prefs</a><span class="bt_navbar">&nbsp;|&nbsp;</span>
              <a href="#" class="bt_navbar">Project admin</a><span class="bt_navbar">&nbsp;|&nbsp;</span>
              <input name="bug_no" type="text" size="5"
  class="bt_navbar" value="Bug #"
  onFocus="javascript:document.navbar1.bug_no.value='';"> <input
	      type="submit" value="Go" class="bt_navbar">
	       <if @::__csrf_token@ defined><input type="hidden" name="__csrf_token" value="@::__csrf_token;literal@"></if>
            </td>
          </tr>
        </table>
      </td>
    </tr>
  </table>
</form>
<p>


<table border="0" cellpadding="0" cellspacing="0" width="100%">
  <tr>
    <td valign="top" width="200" style="border: solid 1px gray;" bgcolor="#ccccff" class="bt_summary_bold">
      210 <a href="#">Open Bugs</a><br>
      1398 <a href="#">Closed Bugs</a>
      <p>
      Open bugs summary:
      <p>
      <table border="0" width="100%">
        <tr>
          <td colspan="2" class="bt_summary_bold">
            Fix for
          </td>
        </tr>
        <tr>
          <td width="75%" class="bt_summary">
            <a href="#">Undecided</a>
          </td>
          <td align="right" class="bt_summary">
            15
          </td>
        </tr>
        <tr>
          <td width="75%" class="bt_summary">
            <a href="#">4.5</a>
          </td>
          <td align="right" class="bt_summary">
            92
          </td>
        </tr>
      </table>
      <p>
      <table border="0" width="100%">
        <tr>
          <td colspan="2" class="bt_summary_bold">
            Priority
          </td>
        </tr>
        <tr>
          <td width="75%" class="bt_summary">
            <a href="#">1-Must fix</a>
          </td>
          <td align="right" class="bt_summary">
            15
          </td>
        </tr>
        <tr>
          <td width="75%" class="bt_summary">
            <a href="#">4-Fix If Time</a>
          </td>
          <td align="right" class="bt_summary">
            92
          </td>
        </tr>
      </table>
      <p>
      <table border="0" width="100%">
        <tr>
          <td colspan="2" class="bt_summary_bold">
            Assigned To
          </td>
        </tr>
        <tr>
          <td width="75%" class="bt_summary">
            <a href="#">Don Baccus</a>
          </td>
          <td align="right" class="bt_summary">
            823
          </td>
        </tr>
        <tr>
          <td width="75%" class="bt_summary">
            <a href="#">Jack Cameleo</a>
          </td>
          <td align="right" class="bt_summary">
            2
          </td>
        </tr>
      </table>
      <p>
      <table border="0" width="100%">
        <tr>
          <td colspan="2" class="bt_summary_bold">
            My Filters
          </td>
        </tr>
        <tr>
          <td width="75%" class="bt_summary">
            <a href="#">My Bugs</a>
          </td>
          <td align="right" class="bt_summary">
            13
          </td>
        </tr>
        <tr>
          <td width="75%" class="bt_summary">
            <a href="#">Open bugs my version</a>
          </td>
          <td align="right" class="bt_summary">
            12
          </td>
        </tr>
        <tr>
          <td width="75%" class="bt_summary">
            <a href="#">Open bugs latest version</a>
          </td>
          <td align="right" class="bt_summary">
            2
          </td>
        </tr>
        <tr>
          <td width="75%" class="bt_summary">
            <a href="#">Open bugs my components</a>
          </td>
          <td align="right" class="bt_summary">
            8
          </td>
        </tr>
      </table>
      <p>
      
    </td>
    <td width="25">&nbsp;</td>
    <td valign="top">
      <table border=0 width="100%" cellspacing="0" bgcolor=white>
        <tr>
          <td colspan="2">
            <b><a href="#">Filter</a>:</b> All open bugs assigned to Jack Cameleo
            <hr>
            Result Page: <b>1</b>&nbsp;&nbsp;<a href="#">2</a>&nbsp;&nbsp;<a href="#">3</a>&nbsp;&nbsp;<a href="#">4</a>&nbsp;&nbsp;<a href="#">5</a>&nbsp;&nbsp;<a href="#">Next&nbsp;&gt;</a>
            <hr>
            <p>
          </td>
        </tr>
        <tr>
          <td valign=top><input type=checkbox>&nbsp;</td>
          <td valign=top>
            <a href="#">#1932. This is the bug summary line</a><br>
            <font size="-1">Here's the more complete description, which can at times be very long, so it'll
            be abbreviated, cut off after a certain number of characters (HTML stripped ...<br>
            <font color="#6f6f6f">Component:</font> Rendering engine - opened 3/15/2002<br>
            <font color="#6f6f6f">Priority:</font> 1 - Must fix / <font color="#6f6f6f">Severity:</font> 3 - major<br>
            <font color="#6f6f6f">Assigned to:</font> <a href="#">Jack</a><br>
            <font color="#008000">OPEN <i>(fix for version 4.5 (4/1/2002))</i> <b>Est: 6 hrs</b></font></font>
            <p>
          </td>
        </tr>
        <tr>
          <td valign=top><input type=checkbox>&nbsp;</td>
          <td valign=top>
            <a href="#">#1932. This is the bug summary line</a><br>
            <font size="-1">Here's the more complete description, which can at times be very long, so it'll
            be abbreviated, cut off after a certain number of characters (HTML stripped ...<br>
            <font color="#6f6f6f">Component:</font> Rendering engine - opened 3/15/2002<br>
            <font color="#6f6f6f">Priority:</font> 1 - Must fix / <font color="#6f6f6f">Severity:</font> 3 - major<br>
            <font color="#6f6f6f">Assigned to:</font> <a href="#">Jack</a><br>
            <font color="#008000">OPEN <i>(fix for version 4.5 (4/1/2002))</i> <b>Est: 6 hrs</b></font></font>
            <p>
          </td>
        </tr>
        <tr>
          <td valign=top><input type=checkbox>&nbsp;</td>
          <td valign=top>
            <a href="#">#1932. This is the bug summary line</a><br>
            <font size="-1">Here's the more complete description, which can at times be very long, so it'll
            be abbreviated, cut off after a certain number of characters (HTML stripped ...<br>
            <font color="#6f6f6f">Component:</font> Rendering engine - opened 3/15/2002<br>
            <font color="#6f6f6f">Priority:</font> 1 - Must fix / <font color="#6f6f6f">Severity:</font> 3 - major<br>
            <font color="#6f6f6f">Assigned to:</font> <a href="#">Jack</a><br>
            <font color="#008000">OPEN <i>(fix for version 4.5 (4/1/2002))</i> <b>Est: 6 hrs</b></font></font>
            <p>
          </td>
        </tr>
        <tr>
          <td valign=top><input type=checkbox>&nbsp;</td>
          <td valign=top>
            <a href="#">#1932. This is the bug summary line</a><br>
            <font size="-1">Here's the more complete description, which can at times be very long, so it'll
            be abbreviated, cut off after a certain number of characters (HTML stripped ...<br>
            <font color="#6f6f6f">Component:</font> Rendering engine - opened 3/15/2002<br>
            <font color="#6f6f6f">Priority:</font> 1 - Must fix / <font color="#6f6f6f">Severity:</font> 3 - major<br>
            <font color="#6f6f6f">Assigned to:</font> <a href="#">Jack</a><br>
            <font color="#008000">OPEN <i>(fix for version 4.5 (4/1/2002))</i> <b>Est: 6 hrs</b></font></font>
            <p>
          </td>
        </tr>
        <tr>
          <td valign=top><input type=checkbox>&nbsp;</td>
          <td valign=top>
            <a href="#">#1932. This is the bug summary line</a><br>
            <font size="-1">Here's the more complete description, which can at times be very long, so it'll
            be abbreviated, cut off after a certain number of characters (HTML stripped ...<br>
            <font color="#6f6f6f">Component:</font> Rendering engine - opened 3/15/2002<br>
            <font color="#6f6f6f">Priority:</font> 1 - Must fix / <font color="#6f6f6f">Severity:</font> 3 - major<br>
            <font color="#6f6f6f">Assigned to:</font> <a href="#">Jack</a><br>
            <font color="#008000">OPEN <i>(fix for version 4.5 (4/1/2002))</i> <b>Est: 6 hrs</b></font></font>
            <p>
          </td>
        </tr>
        <tr>
          <td valign=top><input type=checkbox>&nbsp;</td>
          <td valign=top>
            <a href="#">#1932. This is the bug summary line</a><br>
            <font size="-1">Here's the more complete description, which can at times be very long, so it'll
            be abbreviated, cut off after a certain number of characters (HTML stripped ...<br>
            <font color="#6f6f6f">Component:</font> Rendering engine - opened 3/15/2002<br>
            <font color="#6f6f6f">Priority:</font> 1 - Must fix / <font color="#6f6f6f">Severity:</font> 3 - major<br>
            <font color="#6f6f6f">Assigned to:</font> <a href="#">Jack</a><br>
            <font color="#008000">OPEN <i>(fix for version 4.5 (4/1/2002))</i> <b>Est: 6 hrs</b></font></font>
            <p>
          </td>
        </tr>
        <tr>
          <td valign=top><input type=checkbox>&nbsp;</td>
          <td valign=top>
            <a href="#">#1932. This is the bug summary line</a><br>
            <font size="-1">Here's the more complete description, which can at times be very long, so it'll
            be abbreviated, cut off after a certain number of characters (HTML stripped ...<br>
            <font color="#6f6f6f">Component:</font> Rendering engine - opened 3/15/2002<br>
            <font color="#6f6f6f">Priority:</font> 1 - Must fix / <font color="#6f6f6f">Severity:</font> 3 - major<br>
            <font color="#6f6f6f">Assigned to:</font> <a href="#">Jack</a><br>
            <font color="#008000">OPEN <i>(fix for version 4.5 (4/1/2002))</i> <b>Est: 6 hrs</b></font></font>
            <p>
          </td>
        </tr>
        <tr>
          <td valign=top><input type=checkbox>&nbsp;</td>
          <td valign=top>
            <a href="#">#1932. This is the bug summary line</a><br>
            <font size="-1">Here's the more complete description, which can at times be very long, so it'll
            be abbreviated, cut off after a certain number of characters (HTML stripped ...<br>
            <font color="#6f6f6f">Component:</font> Rendering engine - opened 3/15/2002<br>
            <font color="#6f6f6f">Priority:</font> 1 - Must fix / <font color="#6f6f6f">Severity:</font> 3 - major<br>
            <font color="#6f6f6f">Assigned to:</font> <a href="#">Jack</a><br>
            <font color="#008000">OPEN <i>(fix for version 4.5 (4/1/2002))</i> <b>Est: 6 hrs</b></font></font>
            <p>
          </td>
        </tr>
        <tr>
          <td colspan="2">
            <hr>
            <input type=checkbox> Assign selected bugs to <select><option><option>Don Baccus<option>Jack Cameleo</select><br>
            <input type=checkbox> Mark selected bugs for fixing in version <select><option><option>4.5<option>4.5<option>Undecided</select><br>
            <input type=checkbox> Set priority of selected bugs to <select><option><option>1-Must fix<option>2-Must fix<option>3-Mus fix<option>4-Maybe<option>...</select><br>
            <input type=checkbox> Set severity of selected bugs to <select><option><option>1-Showstopper<option>2-Blocker<option>3-Pretty bad<option>4-Annoying<option>...</select><br>
            <input type="submit" value="Update selected bugs">
            <hr>
            Result Page: <b>1</b>&nbsp;&nbsp;<a href="#">2</a>&nbsp;&nbsp;<a href="#">3</a>&nbsp;&nbsp;<a href="#">4</a>&nbsp;&nbsp;<a href="#">5</a>&nbsp;&nbsp;<a href="#">Next&nbsp;&gt;</a>
          </td>
        </tr>
      </table>
    </td>
  </tr>
</table>

<p>

<table border=0" cellspacing="0" cellpadding="2" bgcolor="#41329c" width="100%">
  <form action="#" method="get" name="navbar1">
    <tr>
      <td align="left">
        <span class="bt_navbar">Your version: </span><a href="#" class="bt_navbar">4.3</a><span class="bt_navbar"> | Latest: 4.5</span>
      </td>
      <td align="right">
        <table border="0" cellspacing="0" cellpadding="0">
          <tr>
            <td>
              <a href="#" class="bt_navbar">List</a><span class="bt_navbar">&nbsp;|&nbsp;</span>
              <a href="#" class="bt_navbar">New Bug</a><span class="bt_navbar">&nbsp;|&nbsp;</span>
              <a href="#" class="bt_navbar">Search</a><span class="bt_navbar">&nbsp;|&nbsp;</span>
              <a href="#" class="bt_navbar">Filters</a><span class="bt_navbar">&nbsp;|&nbsp;</span>
              <a href="#" class="bt_navbar">Patches</a><span class="bt_navbar">&nbsp;|&nbsp;</span>
              <a href="#" class="bt_navbar">Prefs</a><span class="bt_navbar">&nbsp;|&nbsp;</span>
              <a href="#" class="bt_navbar">Project admin</a><span class="bt_navbar">&nbsp;|&nbsp;</span>
              <input name="bug_no" type="text" size="5" class="bt_navbar" value="Bug #" onFocus="javascript:document.navbar1.bug_no.value='';"> <input type="submit" value="Go" class="bt_navbar">
            </td>
          </tr>
        </table>
      </td>
    </tr>
  </form>
</table>

<hr>

<a href="mailto:admin@yourdomain.com"><address>admin@yourdomain.com</address></a>
</body>