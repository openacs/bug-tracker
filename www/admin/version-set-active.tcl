ad_page_contract { 
    Bug-Tracker set active version function.
    
    @author Christian Hvid (chvid@acm.org)
    @date 2002-03-28

} {
    { version_id "" }
    { return_url "" }
}

db_exec_plsql set_active_version {
    select bt_version__set_active(:version_id)
}

ad_returnredirect $return_url
