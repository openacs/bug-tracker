ad_page_contract {
    Pick a project maintainer

    @author Lars Pind (lars@pinds.com)
    @date 2002-03-26
    @cvs-id $Id$
} {
    cancel:optional
    maintainer:integer,optional
    {return_url ""}
}

if { [exists_and_not_null cancel] } {
    ad_returnredirect $return_url
    return
}

set project_name [bt_conn project_name]
set package_id [ad_conn package_id]
set package_key [ad_conn package_key]

set page_title "Edit Project Maintainer"

set context_bar [ad_context_bar $page_title]

template::form create project_maintainer

template::element create project_maintainer return_url -datatype text -widget hidden -value $return_url

template::element create project_maintainer maintainer \
        -datatype integer \
        -widget select \
        -label "Project Maintainer" \
        -optional

if { ![template::form is_valid project_maintainer] } {
    template::element set_properties project_maintainer maintainer \
            -options [concat {{ "--None--" "" }} [db_list_of_lists users { select first_names || ' ' || last_name, user_id from cc_users }]] 
}

if { [template::form is_request project_maintainer] } {
    template::element set_properties project_maintainer maintainer \
            -value [db_string maintainer { select maintainer from bt_projects where project_id = :package_id }]
}

if { [template::form is_valid project_maintainer] } {
    db_dml project_maintainer_update {
        update bt_projects
        set    maintainer = :maintainer
        where  project_id = :package_id
    }

    ad_returnredirect $return_url
    return
}

ad_return_template