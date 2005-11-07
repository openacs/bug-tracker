ad_page_contract {
    Distributions for the bug-tracker instance
    @author Rocael Hernandez (roc@viaro.net)
}

set project_name [bug_tracker::conn project_name]
set page_title "Manage Distributions"
set context_bar [ad_context_bar $page_title]

set package_id [ad_conn package_id]

bug_tracker::get_pretty_names -array pretty_names

set component_keyword_id [bug_tracker::get_component_keyword -package_id $package_id]

db_multirow -extend { 
    edit_url
    delete_url
    new_url
    type_edit_url
    type_delete_url
    bugs_url
    set_default_url
} distributions select_distributions {} {
    # set all the URLs
    set delete_url "distro-component-delete?[export_vars { { keyword_id $child_id } }]"
    set new_url "distro-component-add?[export_vars { parent_id }]"
    
    set type_edit_url "distro-edit?[export_vars { { keyword_id $parent_id } { type_p t } }]"
    if { $is_leaf } {
        set type_delete_url "distro-delete?[export_vars { { keyword_id $parent_id } }]"
    } else {
        set type_delete_url {}
    }

    set bugs_url "../?[export_vars { { f_component $component_id } { f_distribution $parent_id } { filter.status any } }]"
}

set type_new_url "distro-edit"



set distro_components [db_string get_distro_components  {select count(*) from bt_components where project_id = :package_id}]
#set distro_components [db_string get_distro_components  {select (select count(*) from bt_components where project_id = :package_id) - (select count(*) from cr_keywords where parent_id = :component_keyword_id}