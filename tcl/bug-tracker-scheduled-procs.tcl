ad_library {
    
    
    
    @author Victor Guerra (guerra@galileo.edu)
    @creation-date 2005-02-07
    @cvs-id $Id$
}

namespace eval bug_tracker {}
namespace eval bug_tracker::scheduled {}

ad_proc -public bug_tracker::scheduled::close_bugs {
} {
} {
    set bt_instance [parameter::get -parameter BugTrackerInstance -package_id [ad_acs_kernel_id] -default {}]
    if {$bt_instance ne ""} {
	array set community_info [site_node::get -url "${bt_instance}/bug-tracker"]
	set bt_package_id $community_info(package_id)
	db_foreach open_bug { *SQL* } {
	    set case_id [workflow::case::get_id \
			     -object_id $bug_id \
			     -workflow_short_name [bug_tracker::bug::workflow_short_name]]
	    workflow::case::fsm::get -case_id $case_id -array case
	    set time_to_compare_with [parameter::get -parameter TimeToLive -package_id $bt_package_id -default 0]
	    if { $case(state_short_name) eq "open" && $time_to_compare_with > 0 && [db_string too_old {} -default 0] } {
		foreach available_enabled_action_id [workflow::case::get_available_enabled_action_ids -case_id $case_id] {
		    workflow::case::enabled_action_get -enabled_action_id $available_enabled_action_id -array enabled_action
		    workflow::action::get -action_id $enabled_action(action_id) -array available_action
		    if {$available_action(short_name) eq "resolve"} {
			set action_id $enabled_action(action_id)
			array set row [list]
			foreach field [workflow::action::get_element -action_id $action_id -element edit_fields] {
			    set row($field) ""
			}
			foreach {category_id category_name} [bug_tracker::category_types] {
			    set row($category_id) ""
			}
			bug_tracker::bug::edit \
			    -bug_id $bug_id \
			    -enabled_action_id $available_enabled_action_id \
			    -description descripcion \
			    -desc_format text/html \
			    -array row
		    }
		}
		foreach available_enabled_action_id [workflow::case::get_available_enabled_action_ids -case_id $case_id] {
		    workflow::case::enabled_action_get -enabled_action_id $available_enabled_action_id -array enabled_action
		    workflow::action::get -action_id $enabled_action(action_id) -array available_action
		    if {$available_action(short_name) eq "close"} {
			set action_id $enabled_action(action_id)
			array set row [list]
			foreach field [workflow::action::get_element -action_id $action_id -element edit_fields] {
			    set row($field) ""
			}
			foreach {category_id category_name} [bug_tracker::category_types] {
			    set row($category_id) ""
			}
			
			bug_tracker::bug::edit \
			    -bug_id $bug_id \
			    -enabled_action_id $available_enabled_action_id \
			    -description descripcion \
			    -desc_format text/html \
			    -array row
		    }
		}
	    }
	}
    }
}
