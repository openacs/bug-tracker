ad_page_contract {
    Manage bug-tracker notifications
} {
    bug_number:integer,optional
}

set page_title [_ bug-tracker.Notifications]
set context [list $page_title]
set package_id [ad_conn package_id]

set workflow_id [bug_tracker::bug::get_instance_workflow_id]
if { [info exists bug_number] && $bug_number ne "" } {
    set bug_id [bug_tracker::get_bug_id \
                    -bug_number $bug_number \
                    -project_id [ad_conn package_id]]

    set case_id [workflow::case::get_id \
                     -object_id $bug_id \
                     -workflow_short_name [bug_tracker::bug::workflow_short_name]]
} else {
    set case_id {}
}

set user_id [ad_conn user_id]
set return_url [ad_return_url]

multirow create notifications url label title subscribed_p

set bugs_name [bug_tracker::conn bugs]

if {[bug_tracker::user_bugs_only_p]} {
    set notification_types {workflow_assignee workflow_my_cases}
} else {
    set notification_types {workflow_assignee workflow_my_cases workflow}
}


foreach type $notification_types {
    set object_id [workflow::case::get_notification_object \
                       -type $type \
                       -workflow_id $workflow_id \
                       -case_id $case_id]

    if { $object_id ne "" } {
        switch $type {
            workflow_assignee {
                set pretty_name [_ bug-tracker.All_2]
            }
            workflow_my_cases {
                set pretty_name [_ bug-tracker.All_3]
            }
            workflow {
                set pretty_name [_ bug-tracker.All_4]
            }
            default {
                error "[_ bug-tracker.Unknown_1]"
            }
        }

        # Get the type id
        set type_id [notification::type::get_type_id -short_name $type]

        # Check if subscribed
        set request_id [notification::request::get_request_id \
                            -type_id $type_id \
                            -object_id $object_id \
                            -user_id $user_id]

        set subscribed_p [expr {$request_id ne ""}]

        if { $subscribed_p } {
            set url [notification::display::unsubscribe_url -request_id $request_id -url $return_url]
        } else {
            set url [notification::display::subscribe_url \
                         -type $type \
                         -object_id $object_id \
                         -url $return_url \
                         -user_id $user_id \
                         -pretty_name $pretty_name]
        }

        if { $url ne "" } {
            multirow append notifications \
                $url \
                [string totitle $pretty_name] \
                [ad_decode $subscribed_p 1 "[_ bug-tracker.Unsubscribe_1]" "[_ bug-tracker.Subscribe_1]"] \
                $subscribed_p
        }
    }
}

set manage_url "[apm_package_url_from_key [notification::package_key]]manage"

# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
