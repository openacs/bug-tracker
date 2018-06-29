ad_page_contract {
    Page that lists patches in this Bug Tracker
    project.

    @author Peter Marklund (peter@collaboraid.biz)
    @creation-date 2002-09-10
    @cvs-id $Id$
} {
    {component_id:naturalnum,optional}
    {apply_to_version:integer,optional}
    {status:word,trim,optional}
}

set package_id [ad_conn package_id]
set user_id [ad_conn user_id]

set Patches_name [bug_tracker::conn Patches]
set Patch_name [bug_tracker::conn Patch]

set page_title "$Patches_name" 
set context [list $page_title]

# TODO: Use bug_tracker::patch_status_pretty for pretty state (problem with the filter, but it can be done)

template::list::create \
    -name patches \
    -multirow patches \
    -elements {
        patch_number {
            label "[bug_tracker::conn Patch]"
            display_template {\#@patches.patch_number@}
            html { align right }
        }
        summary {
            label "[_ bug-tracker.Summary]"
            link_url_eval {[export_vars -base patch { patch_number }]}
        }
        status {
            label "[_ bug-tracker.Status]"
            display_eval {[string totitle $status]}
        }
        apply_to_version_name {
            label "[_ bug-tracker.Apply]"
            display_template {
                <if @patches.apply_to_version_name@ not nil>@patches.apply_to_version_name@</if>
                <else><i>Undecided</i></else>
            }
        }
        component_name {
            label "[_ bug-tracker.Component]"
        }
        creation_date_pretty {
            label "[_ bug-tracker.Submitted]"
        }
    } -filters {
        status {
            label "[_ bug-tracker.Status]"
            values {[db_list_of_lists select_states {}]}
            where_clause {[db_map states_where_clause]}
        }
        apply_to_version {
            label "[_ bug-tracker.Apply_1]"
            values {[db_list_of_lists select_versions {}]}
            where_clause {[db_map apply_to_version_where_clause]}
            null_where_clause {[db_map apply_to_version_null_where_clause]}
            null_label {Undecided}
        }
        component_id {
            label "[_ bug-tracker.Component]"
            values {[db_list_of_lists select_components {
            }]}
            where_clause {[db_map component_where_clause]}
        }
    }


db_multirow patches select_patches {} 

