ad_page_contract {
    Redirect page for adding users to the permissions list.
    
    @author Lars Pind (lars@collaboraid.biz)
    @creation-date 2003-06-13
    @cvs-id $Id$
}

set object_id [ad_conn package_id]

set page_title [_ bug-tracker.Add_1]

set context [list [list "permissions" "[_ bug-tracker.Permissions]"] $page_title]

