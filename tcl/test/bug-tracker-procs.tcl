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
            if { [catch {array set site_node [site_node::get -url /bug-tracker]} errmsg] } {
                aa_error "Can't find bug-tracker at /bug-tracker: $errmsg"
            } else {
                set package_id $site_node(package_id)
                array set default_configs [bug_tracker::get_default_configurations]
                if { ![info exists default_configs(Bug-Tracker)] } {
                    aa_error "Can't find default bug-tracker configuration"
                } else {
                    array set config $default_configs(Bug-Tracker)
                    bug_tracker::delete_all_project_keywords -package_id $package_id
                    bug_tracker::install_keywords_setup \
                        -package_id $package_id \
                        -spec $config(categories)
                    bug_tracker::install_parameters_setup \
                        -package_id $package_id \
                        -spec $config(parameters)
                    aa_equals "Bug tracker project creation test" [db_string count_projects {}] 1
                }
            }
        }
}
