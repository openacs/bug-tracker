# Nav bar, to be included on all pages

global bt_nav_bar_count
if { ![info exists bt_nav_bar_count] } {
    set bt_nav_bar_count 1
} else {
    incr bt_nav_bar_count
}

set package_id [ad_conn package_id]
set package_url [ad_conn package_url]
set component_id [bug_tracker::conn component_id]

set admin_p [ad_permission_p $package_id admin]

multirow create links name url

multirow append links "List" "[ad_conn package_url]"

if { [ad_permission_p [ad_conn package_id] create] } {
    multirow append links "New Bug" "[ad_conn package_url]bug-add[ad_decode $component_id "" "" "?[export_vars { component_id }]"]"
}

if { [ad_conn user_id] != 0 } {
    multirow append links "My Bugs" "[ad_conn package_url]?[export_vars -url { { assignee {[ad_conn user_id]} } }]"
}
multirow append links "Prefs" "[ad_conn package_url]prefs"
if { $admin_p } {
    multirow append links "Project Admin" "[ad_conn package_url]admin/"
}

set form_action_url "[ad_conn package_url]bug"

ad_return_template
