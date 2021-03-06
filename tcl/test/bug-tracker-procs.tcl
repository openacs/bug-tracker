ad_library {
    Automated tests.

    @author Don Baccus
    @cvs-id $Id$
}

aa_register_case -cats {api smoke} project_new {
    Test our ability to generate a new project and some bugs.
} {    

    aa_run_with_teardown \
        -rollback \
        -test_code {
            set bt_package_id [lindex [apm_package_ids_from_key -package_key bug-tracker -mounted] 0]
            if { $bt_package_id eq "" } {
                aa_error "Can't find bug-tracker instance."
            } else {

                # Don't believe the bug-tracker Tcl API that misleads you into
                # thinking that you can explicitly pass package_id as a parameter to
                # various procs.  The vile bug_tracker::conn proc guarantees this
                # does not work.
                set old_package_id [ad_conn package_id]
                ad_conn -set package_id $bt_package_id
                set package_id [ad_conn package_id]
                set user_id [ad_conn user_id]

                array set default_configs [bug_tracker::get_default_configurations]
                
                if { ![info exists "default_configs(Bug Tracker)"] } {
                    aa_error "Can't find default bug-tracker configuration"                    
                } else {
                    array set config "$default_configs(Bug Tracker)"
                    bug_tracker::delete_all_project_keywords 
                    bug_tracker::install_keywords_setup -spec $config(categories)
                    bug_tracker::install_parameters_setup -spec $config(parameters)
                    aa_equals "Bug tracker project creation test" [db_string count_projects {}] 1
                }

                # Create a dummy component
                bug_tracker::components_flush
                set component_id [db_nextval acs_object_id_seq]
                db_dml new_component {}

                set bug_id [db_nextval acs_object_id_seq]
                bug_tracker::bug::new \
                    -bug_id $bug_id \
                    -package_id $package_id \
	            -component_id $component_id \
	            -found_in_version [bug_tracker::conn user_version_id] \
	            -summary summary \
	            -description description \
	            -desc_format text/html \
                    -keyword_ids {}
                aa_log_result pass "Successfully created a bug"

                ad_conn -set package_id $old_package_id
            }
        }
}
