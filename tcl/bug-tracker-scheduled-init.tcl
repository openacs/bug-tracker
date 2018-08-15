ad_library {
    
    Scheduled procs for closing bugs that have not been
    treated. 
    
    @author Victor Guerra (guerra@galileo.edu)
    @creation-date 2005-02-07
    @cvs-id $Id$
}

ad_schedule_proc -thread t -schedule_proc ns_schedule_daily [list 03 20] bug_tracker::scheduled::close_bugs
