#TODO: JCD: EXTRACT QUERIES for patch (or really refactor patch.tcl so they both call patch::get)

ad_library {
    Bug tracker - Search Service Contracts

    @creation-date 2004-04-20
    @author Jeff Davis davis@xarg.net
    @cvs-id $Id$
}

namespace eval bug_tracker::search {}
namespace eval bug_tracker::search::bug {}
namespace eval bug_tracker::search::patch {}

ad_proc -private bug_tracker::search::bug::datasource { bug_id } {
    returns a datasource for the search package this is the content 
    that will be indexed by the full text search engine.

    @param bug_id

    @author Jeff Davis davis@xarg.net
} {
    bug_tracker::bug::get -bug_id $bug_id -array row
    set case_id [workflow::case::get_id \
                     -object_id $bug_id \
                     -workflow_short_name [bug_tracker::bug::workflow_short_name]]
    set comments [workflow::case::get_activity_text -case_id $case_id]
    set title "Bug $row(bug_number_display) - $row(summary) \[$row(component_name)\]"
    set content [lang::util::localize "Bug $row(bug_number_display) - $row(summary) \[$row(component_name)\]
Created: $row(creation_date_pretty)
Fix for: $row(fix_for_version_name)
Fixed in: $row(fixed_in_version_name) $row(fixed_in_version)
Resolution: $row(resolution)
Found in: $row(found_in_version_name)
State: $row(pretty_state)
User agent: $row(user_agent)\n\n$comments"]

    return [list object_id $bug_id \
                title $title \
                content $content \
                keywords $row(component_name) \
                storage_type text \
                mime text/plain ]
}

ad_proc -private bug_tracker::search::bug::url { bug_id } {
    returns a url for a given bug_id

    @param bug_id
    @author Jeff Davis davis@xarg.net
} {
    if {[db_0or1row get {select project_id, bug_number from bt_bugs where bug_id = :bug_id}]} {
        return "[ad_url][apm_package_url_from_id $project_id]bug?bug_number=$bug_number"
    } else {
        error "bug_id $bug_id not found"
    }
}


ad_proc -private bug_tracker::search::patch::datasource { patch_id } {
    returns a datasource for the search package this is the content 
    that will be indexed by the full text search engine.

    @param patch_id

    @author Jeff Davis davis@xarg.net
} {
    db_1row patch {
        select bt_patches.patch_id,
            bt_patches.patch_number,
            bt_patches.project_id,
            bt_patches.component_id,
            bt_patches.summary,
            bt_patches.content,
            bt_patches.generated_from_version,
            bt_patches.apply_to_version,
            bt_patches.applied_to_version,
            bt_patches.status,
            bt_components.component_name,
            acs_objects.creation_user as submitter_user_id,
            submitter.first_names as submitter_first_names,
            submitter.last_name as submitter_last_name,
            submitter.email as submitter_email,
            acs_objects.creation_date,
            to_char(acs_objects.creation_date, 'fmMM/DDfm/YYYY') as creation_date_pretty,
            to_char(now(), 'fmMM/DDfm/YYYY') as now_pretty
     from bt_patches,
          acs_objects,
          cc_users submitter,
          bt_components
     where bt_patches.patch_id = :patch_id
       and bt_patches.patch_id = acs_objects.object_id
       and bt_patches.component_id = bt_components.component_id
       and submitter.user_id = acs_objects.creation_user
    } -column_array patch

    set title "Patch $patch(patch_number) - $patch(summary) \[$patch(component_name)\]"
    set content "Patch $patch(patch_number) - $patch(summary) \[$patch(component_name)\]
 submitted by $patch(submitter_first_names) $patch(submitter_last_name) $patch(submitter_email)
 Created $patch(creation_date_pretty) 
 Applies to $patch(generated_from_version) - $patch(apply_to_version)
 Status $patch(status)

"
    # Description/Actions/History
    db_foreach actions { 
        select bt_patch_actions.action_id,
               bt_patch_actions.action,
               bt_patch_actions.actor as actor_user_id,
               actor.first_names as actor_first_names,
               actor.last_name as actor_last_name,
               actor.email as actor_email,
               bt_patch_actions.action_date,
               to_char(bt_patch_actions.action_date, 'fmMM/DDfm/YYYY') as action_date_pretty,
               bt_patch_actions.comment_text,
               bt_patch_actions.comment_format
        from   bt_patch_actions,
               cc_users actor
        where  bt_patch_actions.patch_id = :patch_id
        and    actor.user_id = bt_patch_actions.actor
        order  by action_date
    } {
        append content "$action_date_pretty [bug_tracker::patch_action_pretty $action] by $actor_first_names $actor_last_name
 [bug_tracker::bug_convert_comment_to_text -comment $comment_text -format $comment_format]\n"
    }

    append content "PATCH CONTENT:\n\n$patch(content)\n"

    return [list object_id $patch_id \
                title $title \
                content $content \
                keywords $patch(component_name) \
                storage_type text \
                mime text/plain ]
}


ad_proc -private bug_tracker::search::patch::url { patch_id } {
    returns a url for a given patch_id

    @param patch_id
    @author Jeff Davis davis@xarg.net
} {
    if {[db_0or1row get {select project_id, patch_number from bt_patches where patch_id = :patch_id}]} {
        return "[ad_url][apm_package_url_from_id $project_id]patch?patch_number=$patch_number"
    } else {
        error "bug_id $bug_id not found"
    }
}

ad_proc -private bug_tracker::search::register_implementations {} {
    Register the forum_forum and forum_message content type fts contract
} {
    db_transaction {
        bug_tracker::search::register_bug_fts_impl
        bug_tracker::search::register_patch_fts_impl
    }
}

ad_proc -private bug_tracker::search::unregister_implementations {} {
    db_transaction { 
        acs_sc::impl::delete -contract_name FtsContentProvider -impl_name bt_bug
        acs_sc::impl::delete -contract_name FtsContentProvider -impl_name bt_patch
    }
}

ad_proc -private bug_tracker::search::register_bug_fts_impl {} {
    set spec {
        name "bt_bug"
        aliases {
            datasource bug_tracker::search::bug::datasource
            url bug_tracker::search::bug::url
        }
        contract_name FtsContentProvider
        owner bug-tracker
    }

    acs_sc::impl::new_from_spec -spec $spec
}

ad_proc -private bug_tracker::search::register_patch_fts_impl {} {
    set spec {
        name "bt_patch"
        aliases {
            datasource bug_tracker::search::patch::datasource
            url bug_tracker::search::patch::url
        }
        contract_name FtsContentProvider
        owner bug-tracker
    }

    acs_sc::impl::new_from_spec -spec $spec
}


