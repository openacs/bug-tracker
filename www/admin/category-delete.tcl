ad_page_contract {
    Delete category
} {
    keyword_id:integer
}

db_exec_plsql delete_keyword { }

ad_returnredirect categories
