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

set notification_url [lindex $notification_link 0]
set notification_label [lindex $notification_link 1]
set notification_title [lindex $notification_link 2]

regexp {/([^/]+)/[^/]*$} [ad_conn url] match last_dir

if { [string equal $last_dir "admin"] } {
    set url_prefix [ad_conn package_url]
} else {
    set url_prefix ""
}


multirow create links name url

array set filter [bug_tracker::conn filter]

multirow append links "Bugs" "${url_prefix}.?[export_vars { filter:array }]"

if { [ad_permission_p [ad_conn package_id] create] } {
    multirow append links "New Bug" "${url_prefix}bug-add"
}

if { [ad_conn user_id] != 0 } {
    multirow append links "My Bugs" "${url_prefix}.?[export_vars -url { { filter.actionby {[ad_conn user_id]} } }]"
}

multirow append links "Patches" "[ad_conn package_url]patch-list"

if { [ad_permission_p [ad_conn package_id] create] } {
    multirow append links "New Patch" "[ad_conn package_url]patch-add"
}

multirow append links "Prefs" "[ad_conn package_url]prefs"
if { $admin_p } {
    multirow append links "Admin" "[ad_conn package_url]admin/"
}

set form_action_url "[ad_conn package_url]bug"

ad_return_template
