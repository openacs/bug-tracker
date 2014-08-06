ad_page_contract {
    Delete version
} {
    version_id:naturalnum,notnull
}

db_dml delete_version {}

bug_tracker::versions_flush
    
ad_returnredirect versions
