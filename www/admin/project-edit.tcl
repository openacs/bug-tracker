ad_page_contract {
    Pick a project maintainer

    @author Lars Pind (lars@pinds.com)
    @date 2002-03-26
    @cvs-id $Id$
} {
    cancel:optional
    name:optional
    description:optional
    {return_url ""}
}

if { [exists_and_not_null cancel] } {
    ad_returnredirect $return_url
    return
}

set project_name [bt_conn project_name]
set package_id [ad_conn package_id]
set package_key [ad_conn package_key]

set page_title "Edit Project"
set context_bar [ad_context_bar $page_title]

template::form create project_info

template::element create project_info return_url -datatype text -widget hidden -value $return_url

template::element create project_info name \
        -datatype text \
        -html { size 50 } \
        -label "Project Name"

template::element create project_info description \
        -datatype text \
        -widget textarea \
        -label "Description" \
        -optional \
        -html { cols 50 rows 8 }

if { [template::form is_request project_info] } {
    template::element set_properties project_info name \
            -value [bt_conn project_name]
    
    template::element set_properties project_info description \
            -value [db_string project_description { select description from bt_projects where project_id = :package_id }]
}

if { [template::form is_valid project_info] } {
    db_transaction {
        db_dml project_info_update {
            update bt_projects
            set    description = :description
            where  project_id = :package_id
        }

        bt_set_project_name $name
    }
    
    ad_returnredirect $return_url
    return
}

ad_return_template
