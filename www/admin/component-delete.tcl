ad_page_contract {
    Delete component
} {
    component_id:integer
}

db_dml delete_component {
    delete from bt_components where component_id = :component_id
}

ad_returnredirect .