ad_page_contract {
    @author Lars Pind (lars@pinds.com)
    @date 2002-03-26
    @cvs-id $Id$
} {
    cancel:optional
    component_id:integer,optional
    name:optional
    description:optional
    maintainer:integer,optional
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

template::form create component

template::element create component return_url -datatype text -widget hidden -value $return_url

template::element create component name \
        -datatype text \
        -html { size 50 } \
        -label "Component Name"

template::element create component description \
        -datatype text \
        -widget textarea \
        -label "Description" \
        -optional \
        -html { cols 50 rows 8 }

template::element create component maintainer \
        -datatype integer \
        -widget select \
        -label "Maintainer" \
        -options [concat {{ "--None--" "" }} [db_list_of_lists users { select first_names || ' ' || last_name, user_id from cc_users }]]         -optional

template::element create component component_id \
        -datatype integer \
        -widget hidden

if { [template::form is_request component] } {
    if { ![info exists component_id] } {
        template::element set_properties component component_id -value [db_nextval "acs_object_id_seq"]
    } else {
        db_1row component_info {
            select component_name as name, description, maintainer
            from   bt_components
            where  component_id = :component_id
        }
        template::element set_properties component component_id -value $component_id
        template::element set_properties component name -value $name
        template::element set_properties component description -value $description
        template::element set_properties component maintainer -value $maintainer
        
    }
}

if { [template::form is_valid component] } {
    set count [db_0or1row num_components { select 1 from bt_components where component_id = :component_id }]
    
    if { $count == 0 } {
        db_dml component_create {
            insert into bt_components
            (component_id, project_id, component_name, description, maintainer)
            values
            (:component_id, :package_id, :name, :description, :maintainer)
        }
    } else {
        db_dml component_update {
            update bt_components
            set component_name = :name,
            description = :description,
            maintainer = :maintainer
            where component_id = :component_id
        }
    }

    ad_returnredirect $return_url
    ad_script_abort
}

ad_return_template