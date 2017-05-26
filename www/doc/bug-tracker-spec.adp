
<property name="context">{/doc/bug-tracker {Bug Tracker}} {Bug-tracker Specification}</property>
<property name="doc(title)">Bug-tracker Specification</property>
<master>
<h2>Bug-tracker Specification</h2>

By <a href="http://pinds.com/lars/">Lars Pind</a>
.
<h3>Overview</h3>

The bug-tracker will be a software tool for tracking bugs and
feature requests for software projects. It will be based on the
existing SDM (don&#39;t throw a good thing out), but it will also
incorporate great ideas from BugZilla, Bughost.com, and FogBUGZ.
<p>Development will focus on getting a working version up and
running within about a week and a half, and then have a product
that we can incrementally improve on as we have the time and
need.</p>
<h3>Scenarios</h3>
<h4>Scenario 1: Tom finds a bug</h4>

Tom is using the software and it&#39;s not behaving like he thought
it would. He visits the bug-tracker and is greeted with a list of
known bugs in his version of the software (he&#39;s previously told
the bug-tracker what version he&#39;s using, and this version is
being shown clearly on each page, along with what version is the
latest released version, and which is the current development
version). (Had he had any bugs assigned to him, he would&#39;ve
been greeted with the list of bugs assigned to him instead.) He
drills down the list of known bugs by clicking on the name of the
component that&#39;s causing him trouble. Nope, still not there. He
clicks the "new bug" link and enters the info on the new
bug: What he did, what he expected to happen, what happened
instead. His version and the component has already been filled in.
He can upload a file right here, and he can also upload more files
later. There&#39;s a checkbox letting Tom choose whether to get
email alerts on all activity on this bug.
<h4>Scenario 2: Jack maintains a package</h4>

Jack gets an email alert saying there&#39;s a new bug. He checks
out the bug description in the email and decides that this is worth
looking at. He visits the page, sets the priority to High, assigns
it to one of his trusted slaves, and goes back to the beach.
<p>Later, he visits bug-tracker, and is greeted with a list of bugs
he&#39;s assigned to. Phew. Then he checks the activity report for
the past week for the bugs he&#39;s the maintainer of, whether
assigned to them or not, to see if bugs are getting closed or if
they&#39;re piling up. He decides it&#39;s time to go squash some
bugs. He goes back to the "my bugs" list, which is
already sorted by priority, then user rating (user rating is going
to be in a later version), then date of entry (descending). Clicks
the first, fixes, then hits "Next", fixes, then hits
"Next", fixes ...</p>
<h4>Other Scenarios</h4>
<ul><li>Janis is looking at a CVS log entry, which contains a reference
to ticket #819. She visits the bug-tracker for the project and
enters the number in the "look up by #" input field to
view the bug.</li></ul>
<h3>Differences from SDM</h3>
<ul>
<li>Different terminology: The bug-tracker will say
"project" for the top-level, releasable chunk of code,
what is now called a "package" in the SDM. The unit below
that is today called a "module" in the SDM, but will be
called a "component" in the bug-tracker. Why? Project
definitely makes more sense than "package", especially
given that package is also used about APM packages. Maybe
there&#39;s no good reason to change module to component, but
component is what BugZilla uses, and it sounds more appropriate to
me. Feedback is in order.</li><li>One SDM instance per project: The front page of the bug-tracker
will show the list of open bugs for this project, not just a list
of projects to choose from.</li><li>More status codes: A bug can be resolved in many ways: Not a
bug, not reproducible, by design, etc.</li><li>More types of relationships between bugs: Duplicates, depends
on/blocks, side-effect of fix to other bug (not in initial
version)</li><li>Filters: Filters a' la FogBUGZ that lets you define and
save your own views (deferred to a later version).</li><li>Estimates: Original estimate, latest estimate, time spent so
far. (not in initial version)</li><li>Severity, type of ticket, and other status codes are fully
configurable, and you can even add your own types of codes.</li>
</ul>
<h3>Deferred features</h3>
<ul>
<li>One system-wide "my tasks" list: We&#39;ll build a
separate "task list" application at some later point, and
see how the two should be naturally integrated.</li><li>Ratings: They&#39;re not really used today. When we do
reintroduce them, we&#39;re going to make sure they have impact
over how bugs are prioritized.</li><li>Custom-defined filters: We&#39;ll try to get the
"engine" in place, but we won&#39;t bother with
implementing the UI for defining new ones just now. Soon,
though.</li><li>Patches: This is a must-have, but not for the initial
release.</li><li>We&#39;re not going to use workflow. We want the UI to be just
right, so we won&#39;t let workflow get in the way. We do want to
use this bug-tracker as a prime driver for getting ACS workflow
finsihed, the way it was originally intended to.</li><li>We&#39;re not going to let you define your own status,
resolution, or other codes, because integrating custom codes with
the UI is hard, and we emphasize usability over flexibility in this
release.</li><li>We&#39;re not going to include triage (before-resolution) or QA
(after-resolution) steps in the workflow.</li>
</ul>
<h3>Non goals</h3>
<ul><li>It&#39;s not going to be a general-purpose ticket-tracker.
We&#39;ll write a separate instrument for that later, but hopefully
we can reuse key ideas, and factor out some common
underpinnings.</li></ul>
<h3>Page Flowchart</h3>

This is the pages there are and how they&#39;re related:
<p><img src="flowchart.jpg" width="482" height="276" alt="Bug-tracker page flowchart" border="0"></p>
<h3>Workflow (A Bug&#39;s Life)</h3>

We have separate STATUS and RESOLUTION codes. Possible STATUS codes
are:
<ul>
<li>Open</li><li>Resolved</li><li>Closed</li>
</ul>

Here&#39;s what the workflow looks like in ACS Workflow Petri Net
style:
<p><img src="workflow.jpg" width="338" height="218" alt="Workflow for bug-tracker" border="0"></p>
<p>We will not, in this version, bother with triage and QA steps.
The submitter of a bug is also the person to close that bug. The
maintainer of the project or component is the first assignee, and
takes it from there. There is no unassigned state.</p>
<p>BugZilla has <a href="http://bugzilla.mozilla.org/bug_status.html">many more status
codes</a>. For example they have a confirmation step, in which
it&#39;s checked that the bug is "a true bug". They have
a status to say that the bug has been assigned. They have a special
"reopened" step. And they have a "Verified"
step, and only allow the bug in "Closed" when the release
in which the bug has been fixed has actually shipped. We won&#39;t
go there in this version of the bug-tracker.</p>
<p>The RESOLUTION code to one of the following:</p>
<ul>
<li>Fixed</li><li>By design</li><li>Won&#39;t fix</li><li>Postponed</li><li>Duplicate</li><li>Not reproducible</li>
</ul>

Again, BugZilla is more rigorous than most: They have an
"invalid" resolution step, with the comment "the
problem described is not a bug". I don&#39;t think we need
this -- if it&#39;s not a bug, tell us what it is: By design, not
reproducible, or some other reason?
<h3>Other Bug Classifications</h3>
<h4>Type of bug (hard-coded)</h4>
<ul>
<li>Bug</li><li>Suggestion (coming from the outside)</li><li>To do (a developer to himself)</li>
</ul>
<h4>Severity (can be modified)</h4>
<ul>
<li>Critical</li><li>Major</li><li>Normal</li><li>Minor</li><li>Trivial</li><li>Enhancement</li>
</ul>
<h4>Priority (can be modified)</h4>
<ul>
<li>High</li><li>Medium</li><li>Low</li>
</ul>
<h3>Pages</h3>
<h4>Main Navigation</h4>

There&#39;s a navigation bar which is present on all pages in the
bug-tracker, and contains links to:
<ul>
<li>List: Defaults to the last list shown this session, or to
"My Bugs")</li><li>New Bug: Submit a new bug report</li><li>Search: Opens up a search form</li><li>Filters: Define filters</li><li>Patches: List patches, review and approve.</li><li>Prefs: User preferences, e.g. notification, etc.</li><li>Project admin: Setup the project (if you&#39;re an
administrator)</li><li>Go to bug #</li>
</ul>
<h4>Index page: Ticket list</h4>

(<a href="mockup-index">Mock-up</a>
)
<p>The index page of the package is the ticket list page. The
ticket list page displays a list of tickets in a combination of
<a href="http://www.google.com/search?q=ticket%20list">Google
style</a> and webmail style, i.e., each bug is displayed like
this:</p>
<table border="0" cellpadding="1" cellspacing="0" bgcolor="#0000EE" width="400" align="center"><tr><td><table border="0" width="100%" cellspacing="0" bgcolor="white"><tr>
<td valign="top">
<input type="checkbox"> </td><td valign="top">
<a href="#">#1932. This is the bug summary
line</a><br><font size="-1">Here&#39;s the more complete description, which can
at times be very long, so it&#39;ll be abbreviated, cut off after a
certain number of characters (HTML stripped ...<br><font color="#6F6F6F">Component:</font> Rendering engine - opened
3/15/2002<br><font color="#6F6F6F">Priority:</font> 1 - Must fix / <font color="#6F6F6F">Severity:</font> 3 - major<br><font color="#6F6F6F">Assigned to:</font><a href="#">Jack</a><br><font color="#008000">OPEN <em>(fix for version 4.5
(4/1/2002))</em><strong>Est: 6 hrs</strong>
</font>
</font>
</td>
</tr></table></td></tr></table>
<p>It&#39;s Google, because each bug takes up several lines, and
information is shown "organically" for each bug. It&#39;s
webmail, because each bug has a checkbox next to it, which can be
used for bulk operations.</p>
<p>Tickets are shown 20/50/100/200 per page, and you can page
browse through them like in a typical web mail interface.</p>
<p>Predefined filters include: "My bugs", "Open bugs
in the current version", "All bugs in my version",
"Open bugs that I&#39;m the maintainer of", etc.</p>
<p>You can enter what version you&#39;re using, so that it defaults
to that version when you&#39;re entering bugs and searching for
known bugs. The version you&#39;ve selected will be displayed very
clearly on each page.</p>
<p>The ticket list page can be scoped to one component. The
contents will look just the same and you can use the same filters,
only everything will be scoped to the component you selected. When
you submit a bug from inside a component level, the component name
is already filled out and cannot be changed.</p>
<h4>Enter New Ticket</h4>
<h4>View Ticket</h4>

When viewing a ticket, you have the usual webmail operators:
First/Last/Next/Prev.
<h4>Upload Patch</h4>
<h4>Patch List</h4>
<h4>Search</h4>
<h4>User Preferences</h4>
<h4>Project Administration</h4>
<h4>Define Filters</h4>

A later version will allow users to define their own filters. It
would be cool if users could also exchange filters with each other,
and perhaps an administrator can manage the set of predefined
filters available to everyone.
<hr>
<a href="mailto:lars\@pinds.com"></a>
<address>lars\@pinds.com</address>
