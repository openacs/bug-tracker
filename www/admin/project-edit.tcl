ad_page_contract {
    Pick a project maintainer

    @author Lars Pind (lars@pinds.com)
    @creation-date 2002-03-26
    @cvs-id $Id$
} {
    cancel:optional
    {return_url ""}
}

if { [exists_and_not_null cancel] } {
    ad_returnredirect $return_url
    ad_script_abort
}

set project_name [bug_tracker::conn project_name]
set package_id [ad_conn package_id]
set package_key [ad_conn package_key]

set page_title "Edit Project"
set context_bar [ad_context_bar $page_title]

form create project_info

element create project_info return_url -datatype text -widget hidden -value $return_url

element create project_info name \
        -datatype text \
        -html { size 50 } \
        -label "Project Name"

element create project_info description \
        -datatype text \
        -widget textarea \
        -label "Description" \
        -optional \
        -html { cols 50 rows 8 }

element create project_info email_subject_name  \
        -datatype text \
        -html { size 50 } \
        -label "Email subject tag" 

if { [form is_request project_info] } {
    db_1row project_info { 
        select description, email_subject_name 
        from   bt_projects 
        where  project_id = :package_id
    } -column_array project_info

    form set_values project_info project_info

    element set_properties project_info name \
            -value [bug_tracker::conn project_name]

}

if { [form is_valid project_info] } {
    form get_values project_info description email_subject_name name

    db_transaction {
        db_dml project_info_update {
            update bt_projects
            set    description = :description,
                   email_subject_name = :email_subject_name
            where  project_id = :package_id
        }

        bug_tracker::set_project_name $name
    }
    
    ad_returnredirect $return_url
    ad_script_abort
}

ad_return_template
