ad_page_contract {
    Release version
} {
    version_id:integer
}

set page_title [_ bug-tracker.Release_1]

set context [list [list versions [_ bug-tracker.Versions]] $page_title]

ad_form -name version -cancel_url versions -form {
    version_id:key
    {version_name:text {mode display} {label "[_ bug-tracker.Version_2]"}}
    {anticipated_release_date:date,to_sql(sql_date),to_html(sql_date),optional
        {mode display} {label "[_ bug-tracker.Anticipated_2]"}
    }
    {actual_release_date:date,to_sql(sql_date),to_html(sql_date)
        {label "[_ bug-tracker.Actual_2]"}
    }
} -select_query_name version_select -edit_data {
    db_dml update_version {}
} -after_submit {
    bug_tracker::versions_flush
    
    ad_returnredirect versions
    ad_script_abort
}
