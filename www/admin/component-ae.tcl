ad_page_contract {
    @author Lars Pind (lars@pinds.com)
    @date 2002-03-26
    @cvs-id $Id$
} {
    cancel:optional
    component_id:integer,optional
    {return_url ""}
}

if { [exists_and_not_null cancel] } {
    ad_returnredirect $return_url
    ad_script_abort
}

set project_name [bug_tracker::conn project_name]
set package_id [ad_conn package_id]
set package_key [ad_conn package_key]

if { [info exists component_id] } {
    set page_title "Edit Component"
} else {
    set page_title "Add Component"
}
set context_bar [ad_context_bar $page_title]

form create component

element create component return_url -datatype text -widget hidden -value $return_url

element create component name \
        -datatype text \
        -html { size 50 } \
        -label "Component Name"

element create component description \
        -datatype text \
        -widget textarea \
        -label "Description" \
        -optional \
        -html { cols 50 rows 8 }

element create component url_name \
        -datatype text \
        -html { size 50 } \
        -label "Name in shortcut URL" \
        -optional

element create component maintainer \
        -datatype integer \
        -widget select \
        -label "Maintainer" \
        -options [concat {{ "--None--" "" }} [db_list_of_lists users { select first_names || ' ' || last_name, user_id from cc_users }]]         -optional

element create component component_id \
        -datatype integer \
        -widget hidden

if { [form is_request component] } {
    if { ![info exists component_id] } {
        element set_properties component component_id -value [db_nextval "acs_object_id_seq"]
    } else {
        db_1row component_info {
            select component_id, 
                   component_name as name, 
                   description, 
                   maintainer,
                   url_name
            from   bt_components
            where  component_id = :component_id
        } -column_array component_info
        form set_values component component_info
    }
}

if { [form is_valid component] } {
    form get_values component name description maintainer url_name

    set count [db_0or1row num_components { select 1 from bt_components where component_id = :component_id }]
    
    if { $count == 0 } {
        db_dml component_create {
            insert into bt_components
            (component_id, project_id, component_name, description, url_name, maintainer)
            values
            (:component_id, :package_id, :name, :description, :url_name, :maintainer)
        }
    } else {
        db_dml component_update {
            update bt_components
            set    component_name = :name,
                   description = :description,
                   maintainer = :maintainer,
                   url_name = :url_name
            where component_id = :component_id
        }
    }

    ad_returnredirect $return_url
    ad_script_abort
}

ad_return_template