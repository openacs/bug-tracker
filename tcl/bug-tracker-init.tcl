# /packages/bug-tracker/tcl/bug-tracker-init.tcl


ad_library {
    
    Generic init procs for bug tracker 
    
    @author Ryan Gallimore (rgallimore@viscousmedia.com)
    @creation-date 2010-04-07
    @cvs-id $Id$
}

# Is search mounted and associated driver installed?
set search_mounted_p 1
set search_driver [parameter::get -package_id [apm_package_id_from_key search] \
                                  -parameter FtsEngineDriver]

if { [site_node::get_package_url -package_key search] eq "" } { 
    ns_log Warning Bug Tracker: Search package is not mounted.
    set search_mounted_p 0
} elseif { $search_driver eq ""} {
    ns_log Warning Bug Tracker: FtsEngineDriver parameter in package search is empty.
    set search_mounted_p 0
} elseif { [apm_package_id_from_key $search_driver] == 0} { 
    ns_log Warning Bug Tracker: Search driver $search_driver is not installed.
    set search_mounted_p 0
}

eval "ad_proc -public bug_tracker::search_mounted_p {} {} {
    return $search_mounted_p
}"

