ad_page_contract {
    Shows one bug.

    @author Lars Pind (lars@pinds.com)
    @creation-date 2002-03-20
    @cvs-id $Id$
} {
    bug_number:integer,notnull
    {user_agent_p:boolean 0}
    {show_patch_status "open"}
    filter:array,optional
}

#####
#
# Setup
#
#####

set return_url "[ad_conn url]?[export_vars -url { bug_number filter:array }]"

set project_name [bug_tracker::conn project_name]
set package_id [ad_conn package_id]
set package_key [ad_conn package_key]

set user_id [ad_conn user_id]

permission::require_permission -object_id $package_id -privilege read

set page_title "[bug_tracker::conn Bug] #$bug_number"

set context_bar [bug_tracker::context_bar $page_title]

# Is this project using multiple versions?
set versions_p [bug_tracker::versions_p]

# Paches enabled for this project?
set patches_p [bug_tracker::patches_p]


#####
#
# Get basic info
#
#####

# Get the bug_id
db_1row permission_info {} -column_array bug

set case_id [workflow::case::get_id \
        -object_id $bug(bug_id) \
        -workflow_short_name [bug_tracker::bug::workflow_short_name]]

set workflow_id [bug_tracker::bug::get_instance_workflow_id]

set role_ids [workflow::get_roles -workflow_id $workflow_id]


#####
#
# Action
#
#####

set action_id [form get_action bug]

if { ![empty_string_p $action_id] } {
    set action_short_name [workflow::action::get_element -action_id $action_id -element short_name]
} else {
    set action_short_name {}
}

# Registration required for all actions
if { ![empty_string_p $action_id] } {
    ad_maybe_redirect_for_registration
}

# Check permissions
if { ![workflow::case::action::available_p -case_id $case_id -action_id $action_id] } {
    bug_tracker::security_violation -user_id $user_id -bug_id $bug(bug_id) -action $action_id
}


# Buttons
set actions [list]
if { [empty_string_p $action_id] } {
    foreach available_action_id [workflow::case::get_available_actions -case_id $case_id] {
        workflow::action::get -action_id $available_action_id -array available_action
        lappend actions [list "     $available_action(pretty_name)     " $available_action(action_id)]
    }
}


#####
#
# Create the form
#
#####

# Set the variable that we need for the elements below


# set patch label
set patch_label [ad_decode $show_patch_status "open" "Open Patches (<a href=\"$return_url&show_patch_status=all\">show all</a>)" "all" "All Patches (<a href=\"$return_url&show_patch_status=open\">show only open)" "Patches"]

ad_form -name bug -cancel_url $return_url -mode display -has_edit 1 -actions $actions -form  {
    {bug_number_display:integer(inform)
	{label "[bug_tracker::conn Bug] \#"}
        {mode display}
    }
    {component_id:integer(select)
	{label "[bug_tracker::conn Component]"}
	{options {[bug_tracker::components_get_options]}}
	{mode display}
        optional
    }
    {summary:text(text)
	{label "Summary"}
	{after_html "<b>"}
	{before_html "</b>"}
	{mode display}
	{html {size 50}}
    }
}


ad_form -extend -name bug -form {
    {pretty_state:text(inform)
	{label "Status"}
	{before_html "<b>"}
	{after_html  "</b>"}
	{mode display}
    }
    {resolution:text(select)
	{label "Resolution"}
	{options {[bug_tracker::resolution_get_options]}}
	{mode display}
	optional
    }
}

foreach {category_id category_name} [bug_tracker::category_types] {
    ad_form -extend -name bug -form [list \
        [list "${category_id}:integer(select)" \
            [list label $category_name] \
            [list options [bug_tracker::category_get_options -parent_id $category_id]] \
            [list mode display] \
        ] \
    ]
}


ad_form -extend -name bug -form {
    {found_in_version:text(select)
	{label "Found in Version"}
	{options {[bug_tracker::version_get_options -include_unknown]}}
	{mode display}
	optional
    }
}

workflow::case::role::add_assignee_widgets -case_id $case_id -form_name bug

# More fixed form elements
ad_form -extend -name bug -form {
    {patches:text(inform)
	{label $patch_label}
	{mode display}
    }
    {user_agent:text(inform)
	{label "User Agent"}
	{mode display}
    }
    {fix_for_version:text(select)
	{label "Fix for Version"}
	{options {[bug_tracker::version_get_options -include_undecided]}}
	{mode display}
	optional
    }
    {fixed_in_version:text(select)
	{label "Fixed in Version"}
	{options {[bug_tracker::version_get_options -include_undecided]}}
	{mode display}
	optional
    }
    {description:richtext(richtext) 
	{label "Description"} 
	{html {cols 60 rows 13}} 
	optional
    }
    {return_url:text(hidden) 
	{value $return_url}
    }
    {bug_number:key}
    {entry_id:integer(hidden)
	optional
    }
}

# Export filters
if { [llength [array names filter]] > 0 } {
    set filters [list]
    foreach name [array names filter] { 
        lappend filters [list "filter.${name}:text(hidden)" [list value $filter($name)]]
    }
    ad_form -extend -name bug -form $filters
}

# Set editable fields
if { ![empty_string_p $action_id] } {
    foreach field [workflow::action::get_element -action_id $action_id -element edit_fields] { 
	element set_properties bug $field -mode edit 
    }
    if {[string compare $action_short_name "edit"] == 0} {
        foreach {category_id category_name} [bug_tracker::category_types] {
            element set_properties bug $category_id -mode edit
        }
    }
} 
    

# on_submit block
ad_form -extend -name bug -on_submit {

    array set row [list] 
    
    if { ![empty_string_p $action_id] } { 
        foreach field [workflow::action::get_element -action_id $action_id -element edit_fields] {
            set row($field) [element get_value bug $field]
        }
        foreach {category_id category_name} [bug_tracker::category_types] {
            set row($category_id) [element get_value bug $category_id]
        }
    }
    
    set description [element get_value bug description]
    
    bug_tracker::bug::edit \
            -bug_id $bug(bug_id) \
            -action_id $action_id \
            -description [template::util::richtext::get_property contents $description] \
            -desc_format [template::util::richtext::get_property format $description] \
            -array row \
            -entry_id [element get_value bug entry_id]    

    ad_returnredirect $return_url
    ad_script_abort

} -edit_request {
    # Dummy
    # If we don't have this, ad_form complains
    # Unfortunately, ad_form doesn't let us do what we want, namely have a block that executes
    # whenever the form is displayed, whether initially or because of a validation error.
}

# Not-valid block (request, error)
if { ![form is_valid bug] } {

    # Get the bug data
    bug_tracker::bug::get -bug_id $bug(bug_id) -array bug -action_id $action_id


    # Make list of form fields
    set element_names {
        bug_number component_id summary pretty_state resolution 
        found_in_version user_agent fix_for_version fixed_in_version 
        bug_number_display entry_id
    }

    # update the element_name list and bug array with category stuff
    foreach {category_id category_name} [bug_tracker::category_types] {
        lappend element_names $category_id
        set bug($category_id) [cr::keyword::item_get_assigned -item_id $bug(bug_id) -parent_id $category_id]
        if {[string compare $bug($category_id) ""] == 0} {
            set bug($category_id) [bug_tracker::get_default_keyword -parent_id $category_id]
        }
    }
    
    # Display value for patches
    set bug(patches_display) "[bug_tracker::get_patch_links -bug_id $bug(bug_id) -show_patch_status $show_patch_status] &nbsp; \[ <a href=\"patch-add?[export_vars { { bug_number $bug(bug_number) } { component_id $bug(component_id) } }]\">Upload a patch</a> \]"

    # Hide elements that should be hidden depending on the bug status
    foreach element $bug(hide_fields) {
        element set_properties bug $element -widget hidden
    }

    if { !$versions_p } {
        foreach element { found_in_version fix_for_version fixed_in_version } {
            if { [info exists bug:$element] } {
                element set_properties bug $element -widget hidden
            }
        }
    }

    if { !$patches_p } {
        foreach element { patches } {
            if { [info exists bug:$element] } {
                element set_properties bug $element -widget hidden
            }
        }
    }

    # Optionally hide user agent
    if { !$user_agent_p } {
        element set_properties bug user_agent -widget hidden
    }


    # Set regular element values
    foreach element $element_names { 

        # check that the element exists
        if { [info exists bug:$element] && [info exists bug($element)] } {
            if { [form is_request bug] || [string equal [element get_property bug $element mode] "display"] } {
                element set_value bug $element $bug($element)
            }
        }
    }

    # Add empty option to resolution code
    if { ![empty_string_p $action_id] } {
        if { [lsearch [workflow::action::get_element -action_id $action_id -element edit_fields] "resolution"] == -1 } {
            element set_properties bug resolution -options [concat {{{} {}}} [element get_property bug resolution options]]
        }
    } else {
        element set_properties bug resolution -widget hidden
    }

    # Get values for the role assignment widgets
    workflow::case::role::set_assignee_values -case_id $case_id -form_name bug
    
    # Set values for elements with separate display value
    foreach element { 
        patches
    } {
        # check that the element exists
        if { [info exists bug:$element] } {
            element set_properties bug $element -display_value $bug(${element}_display)
        }
    }

    # Set values for description field
    element set_properties bug description \
            -before_html "[workflow::case::get_activity_html -case_id $case_id][ad_decode $action_id "" "" "<p><b>$bug(now_pretty) [bug_tracker::bug_action_pretty $action_short_name] by [bug_tracker::conn user_first_names] [bug_tracker::conn user_last_name]</b></p>"]"

    # Set page title
    set page_title "[bug_tracker::conn Bug] #$bug_number: $bug(summary)"

    # Context bar
    if { [info exists filter] } {
        if { [array names filter] == [list "actionby"] && $filter(actionby) == $user_id } {
            set context_bar [bug_tracker::context_bar [list ".?[export_vars { filter:array }]" "My bugs"] $page_title]
        } else {
            set context_bar [bug_tracker::context_bar [list ".?[export_vars { filter:array }]" "Filtered bug list"] $page_title]
        }
    } else {
        set context_bar [bug_tracker::context_bar $page_title]
    }
    
    # User agent show/hide URLs
    set show_user_agent_url "bug?[export_vars { bug_number { user_agent_p 1 }}]"
    set hide_user_agent_url "bug?[export_vars { bug_number }]"
    
    # Login
    set login_url "/register/?[export_vars { return_url }]"
    
    # Single-bug notifications 
    if { [empty_string_p $action_id]  } {
        set notification_link [bug_tracker::bug::get_watch_link -bug_id $bug(bug_id)]
    }


    # Filter management
    set filter_parsed [bug_tracker::parse_filters filter]
    
    if { [empty_string_p $action_id] } {
    
        set human_readable_filter [bug_tracker::conn filter_human_readable]
        set where_clauses [bug_tracker::conn filter_where_clauses]
        set from_bug_clause [bug_tracker::conn filter_from_bug_clause]
        set order_by_clause [bug_tracker::conn filter_order_by_clause]
        
        lappend where_clauses "b.project_id = :package_id"

        set workflow_id [bug_tracker::bug::get_instance_workflow_id]
        set initial_state [workflow::fsm::get_initial_state -workflow_id $workflow_id]

        set action_role [db_string select_resolve_role {}]
    
        set filter_bug_numbers [db_list filter_bug_numbers {}]
    
        set filter_bug_index [lsearch -exact $filter_bug_numbers $bug_number]
    
        multirow create navlinks url label
        
        if { $filter_bug_index != -1 } {
            
            if { $filter_bug_index > 0 } {
                multirow append navlinks "bug?[export_vars { { bug_number {[lindex $filter_bug_numbers [expr $filter_bug_index -1]]} } filter:array }]" "&lt;"
            } else {
                multirow append navlinks "" "&lt;"
            }
            
            multirow append navlinks "" "[expr $filter_bug_index+1] of [llength $filter_bug_numbers]"
            
            if { $filter_bug_index < [expr [llength $filter_bug_numbers]-1] } {
                multirow append navlinks "bug?[export_vars { { bug_number {[lindex $filter_bug_numbers [expr $filter_bug_index +1]]} } filter:array }]" "&gt;"
            } else {
                multirow append navlinks "" "&gt;"
            }
        }
    }  
}

ad_return_template

