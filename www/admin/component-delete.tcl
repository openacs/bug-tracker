ad_page_contract {
    Delete component
} {
    component_id:naturalnum,notnull
}

db_dml delete_component {}

ad_returnredirect .
