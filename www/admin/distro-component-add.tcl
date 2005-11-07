ad_page_contract {
    Add or edit a distribution.
} {
    parent_id:integer,notnull
}

set project_name [bug_tracker::conn project_name]

set page_title "Add a Component"
set context_bar [ad_context_bar [list distros "Manage Distributions"] $page_title]

set package_id [ad_conn package_id]

set components_options [db_list_of_lists get_components {
    select component_name, component_id from bt_components 
    where project_id = :package_id
    and component_id not in (select bkcm.component_id from bt_keyword_component_map bkcm, cr_keywords ck where bkcm.keyword_id = ck.keyword_id and ck.parent_id = :parent_id)
    order by component_name
}]

ad_form -name keyword -cancel_url distros -form {
    {component_id:integer(select),optional
	{label "[bug_tracker::conn Component]"}
	{options {$components_options}}
    }
    {parent_id:integer(hidden) {value $parent_id}}
} -on_submit {
    set heading [bug_tracker::component_get_name -component_id $component_id]
    set keyword_id [cr::keyword::new \
			-heading $heading \
			-parent_id $parent_id]
    db_dml insert_keyword_component_map {insert into bt_keyword_component_map (keyword_id, component_id) values (:keyword_id, :component_id)}
} -after_submit {
#    bug_tracker::get_keywords_flush
    ad_returnredirect distros
    ad_script_abort
}
