ad_page_contract {
    Add/Edit form for table "bt_versions"
    @author Generated by formwizard.tcl
    @creation-date March 26, 2002
    @cvs-id $Id$
} {
    version_id:naturalnum,optional
    {return_url "."}
}

set package_id [ad_conn package_id]

if { [info exists version_id] } {
    set page_title [_ bug-tracker.Edit_4]
} else {
    set page_title [_ bug-tracker.Add_2]
}
set context [list [list $return_url "[_ bug-tracker.Versions]"] $page_title]

ad_form -name version -cancel_url $return_url -form {
    {version_id:key(acs_object_id_seq)}
    {version_name:text {label "[_ bug-tracker.Version_1]"} {html { size 50 }}}
    {description:text(textarea),optional {label "[_ bug-tracker.Description]"} {html { cols 50 rows 8 }}}
    {supported_platforms:text,optional {label "[_ bug-tracker.Supported]"} {html { size 50 }}}
    {maintainer:search,optional
        {result_datatype integer}
        {label "[_ bug-tracker.Maintainer]"}
        {options {[bug_tracker::users_get_options]}}
        {search_query {[db_map user_search]}}
    }
    {anticipated_freeze_date:date,to_sql(sql_date),to_html(sql_date),optional
        {label "[_ bug-tracker.Anticipated]"} optional
    }
    {actual_freeze_date:date,to_sql(sql_date),to_html(sql_date),optional
        {label "[_ bug-tracker.Actual]"} optional
    }
    {anticipated_release_date:date,to_sql(sql_date),to_html(sql_date) ,optional
        {label "[_ bug-tracker.Anticipated_1]"} optional
    }
    {actual_release_date:date,to_sql(sql_date),to_html(sql_date),optional
        {label "[_ bug-tracker.Actual_1]"} optional
    }
    {assignable_p:text(radio),optional {label "[_ bug-tracker.Assignable?]"} {options {{Yes t} {No f}}}}
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

