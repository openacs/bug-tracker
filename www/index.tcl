ad_page_contract {
    Bug listing page.
    
    @author Lars Pind (lars@pinds.com)
    @creation-date 2002-03-20
    @cvs-id $Id$
} [bug_tracker::get_page_variables]

set page_title [ad_conn instance_name]
set context [list]
set admin_p [permission::permission_p -object_id [ad_conn package_id] -privilege admin]
set user_id [ad_conn user_id]
bug_tracker::get_pretty_names -array pretty_names

if { [llength [bug_tracker::components_get_options]] == 0 } {
    ad_return_template "no-components"
    return
}

if { ![bug_tracker::bugs_exist_p] } {
    ad_return_template "no-bugs"
    return
}

set project_id [ad_conn package_id]

#####
#
# Get bug list
#
#####


# TODO: Get /com/* URLs working again
# TODO: Other important suggestions from threads, etc.
# TODO: Bulk actions (set fix for version, reassign, etc.)
# TODO: the input validity checking should be improved.

if {[catch {
    bug_tracker::bug::get_list -user_id $user_id
} errorMsg]} {
    if {[ns_conn isconnected]} {
        ad_page_contract_handle_datasource_error "invalid input: $errorMsg"
    }
    ad_script_abort
} else {
    bug_tracker::bug::get_multirow -user_id $user_id
}


