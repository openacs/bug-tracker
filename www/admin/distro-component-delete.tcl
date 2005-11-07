ad_page_contract {
    Delete distribution component association
} {
    keyword_id:integer
}

db_dml delete_keyword_component_map {delete from bt_keyword_component_map where keyword_id = :keyword_id}

cr::keyword::delete \
    -keyword_id $keyword_id

#bug_tracker::get_keywords_flush

ad_returnredirect distros
