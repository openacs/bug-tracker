ad_page_contract {
    @author Lars Pind (lars@pinds.com)
    @creation-date 2002-03-26
    @cvs-id $Id$
} {
    component_id:integer,optional
    {return_url "."}
}

set package_id [ad_conn package_id]
set Component_name [bug_tracker::conn Component]
set component_name [bug_tracker::conn component]

if { [info exists component_id] } {
    set page_title [_ bug-tracker.Edit_1]
} else {
    set page_title [_ bug-tracker.Add]
}
set context [list $page_title]

# LARS:
# I've hidden the description, because we don't use it anywhere
set filter_url_string "[ad_conn package_url]com/this-name/"

ad_form -name component -cancel_url $return_url -form {
    {component_id:key(acs_object_id_seq)}
    {return_url:text(hidden) {value $return_url}}
    {name:text {html { size 50 }} {label "[_ bug-tracker.Component]"}}
    {description:text(hidden),optional {label {Description}} {html { cols 50 rows 8 }}}
    {url_name:text,optional {html { size 50 }} {label {[_ bug-tracker.Name_in_shortcut_URL]}}
        {help_text "[_ bug-tracker.You]"}
    }
    {maintainer:search,optional
        {result_datatype integer}
        {label "[_ bug-tracker.Maintainer]"}
        {options [bug_tracker::users_get_options]}
        {search_query {[db_map user_search]}}
    }
} -select_query {
    select component_id, 
           component_name as name, 
           description, 
           maintainer,
           url_name
    from   bt_components
    where  component_id = :component_id
} -new_data {
    db_dml component_create {}
} -edit_data {
    db_dml component_update {}
} -after_submit {
    bug_tracker::components_flush

    ad_returnredirect $return_url
    ad_script_abort
}
