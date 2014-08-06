ad_page_contract {
    Set default category
} {
    parent_id:naturalnum,notnull
    keyword_id:naturalnum,notnull
}

bug_tracker::set_default_keyword \
    -parent_id $parent_id \
    -keyword_id $keyword_id

ad_returnredirect categories
