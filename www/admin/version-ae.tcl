ad_page_contract {
    Add/Edit form for table "bt_versions"
    @author Generated by formwizard.tcl
    @creation-date March 26, 2002
    @cvs-id $Id$
} {
    version_id:integer,optional
    {return_url "."}
}

set package_id [ad_conn package_id]

if { [info exists version_id] } {
    set page_title "Edit Version"
} else {
    set page_title "Add Version"
}
set context [list [list $return_url "Versions"] $page_title]

ad_form -name version -cancel_url $return_url -form {
    {version_id:key(acs_object_id_seq)}
    {version_name:text {label "Version name"} {html { size 50 }}}
    {description:text(textarea) {label "Description"} optional {html { cols 50 rows 8 }}}
    {supported_platforms:text {label "Supported platforms"} {html { size 50 }} optional}
    {maintainer:search
        {result_datatype integer}
        {label "Maintainer"}
        {options {[bug_tracker::users_get_options]}}
        optional
        {search_query {[db_map user_search]}}
    }
    {anticipated_freeze_date:date,to_sql(sql_date),to_html(sql_date),optional
        {label "Anticipated freeze"} optional
    }
    {actual_freeze_date:date,to_sql(sql_date),to_html(sql_date),optional
        {label "Actual freeze"} optional
    }
    {anticipated_release_date:date,to_sql(sql_date),to_html(sql_date) ,optional
        {label "Anticipated release"} optional
    }
    {actual_release_date:date,to_sql(sql_date),to_html(sql_date),optional
        {label "Actual release"} optional
    }
    {assignable_p:text(radio) {label "Assignable?"} optional {options {{Yes t} {No f}}}}
    {return_url:text(hidden) {value $return_url}}
} -select_query_name version_select  -new_request {
    set assignable_p "t"
} -new_data {
    if { [db_0or1row check_exists {}] } {
        # detected a double form submission - you can return
        # an error if you want, but it's not really necessary
    } else {
        db_dml insert_row ""
    }
} -edit_data {
    db_dml update_row ""
} -after_submit {
    bug_tracker::versions_flush
    
    ad_returnredirect $return_url
    ad_script_abort
}

