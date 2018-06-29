ad_page_contract {
    Unmapping a patch from a bug.

    @author Peter Marklund (peter@collaboraid.biz)
    @creation-date 2002-09-06
    @cvs-id $Id$
} {
    patch_number:integer,notnull
    bug_number:integer,notnull
}

set package_id [ad_conn package_id]
set user_id [ad_conn user_id]

set write_p [permission::permission_p -object_id $package_id -privilege write]
set user_is_submitter_p [expr {$user_id == [bug_tracker::get_patch_submitter -patch_number $patch_number]}]

if { !($user_is_submitter_p || $write_p) } {            
    ad_return_forbidden "[_ bug-tracker.Permission]" "[_ bug-tracker.You_7]"            
    ad_script_abort
}

bug_tracker::unmap_patch_from_bug -patch_number $patch_number -bug_number $bug_number

ad_returnredirect "patch?patch_number=$patch_number"
