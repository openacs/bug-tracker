# /packages/bug-tracker/tcl/bug-tracker-scheduled-init.tcl


ad_library {
    
    Scheduled procs for closing bugs that have not been
    treated. 
    
    @author Victor Guerra (guerra@galileo.edu)
    @creation-date 2005-02-07
    @arch-tag: 0a081603-3a9e-449f-a6d5-d5962c7f681f
    @cvs-id $Id$
}

ad_schedule_proc -thread t -schedule_proc ns_schedule_daily [list 03 20] bug_tracker::scheduled::close_bugs
