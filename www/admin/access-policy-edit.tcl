set package_id [ad_conn package_id]

set access_policy_options [list [list [_ bug-tracker.Show_all_bugs] all_bugs] \
			        [list [_ bug-tracker.Show_user_bugs_only] user_bugs]]

ad_form -name access_policy_form -form {
    {access_policy:text(select)
        {label #bug-tracker.Access_policy#}
        {options $access_policy_options}
    }
} -on_request {
    set access_policy [lindex [bug_tracker::access_policy] 1]
} -on_submit {
    bug_tracker::set_access_policy -$access_policy
    ad_returnredirect index
}