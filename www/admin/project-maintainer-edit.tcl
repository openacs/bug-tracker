ad_page_contract {
    Pick a project maintainer

    @author Lars Pind (lars@pinds.com)
    @creation-date 2002-03-26
    @cvs-id $Id$
} {
    {return_url "."}
}

set project_name [bug_tracker::conn project_name]
set package_id [ad_conn package_id]
set package_key [ad_conn package_key]

set page_title "Edit Project Maintainer"

set context_bar [ad_context_bar $page_title]

form create project_maintainer -cancel_url $return_url

element create project_maintainer return_url -datatype text -widget hidden -value $return_url

element create project_maintainer maintainer \
        -datatype search \
        -widget search \
        -result_datatype integer \
        -label "Project Maintainer" \
        -options [bug_tracker::users_get_options] \
        -optional \
        -search_query {
    select distinct u.first_names || ' ' || u.last_name || ' (' || u.email || ')' as name, u.user_id
    from   cc_users u
    where  upper(coalesce(u.first_names || ' ', '')  || coalesce(u.last_name || ' ', '') || u.email || ' ' || coalesce(u.screen_name, '')) like upper('%'||:value||'%')
    order  by name
} 

if { [form is_request project_maintainer] } {
    element set_properties project_maintainer maintainer \
            -value [db_string maintainer { select maintainer from bt_projects where project_id = :package_id }]
}

if { [form is_valid project_maintainer] } {
    form get_values project_maintainer maintainer
    
    db_dml project_maintainer_update {
        update bt_projects
        set    maintainer = :maintainer
        where  project_id = :package_id
    }

    ad_returnredirect $return_url
    ad_script_abort
}

ad_return_template