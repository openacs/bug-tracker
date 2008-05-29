# packages/bug-tracker/tcl/bug-tracker-callback-procs.tcl

ad_library {
    
    callback implementations for bug-tracker
    
    @author Deds Castillo (deds@i-manila.com.ph)
    @creation-date 2007-07-09
}

ad_proc -public -callback acs_mail_lite::incoming_email -impl bug-tracker {
    {-array:required}
    {-package_id ""}
} {
    a callback that posts a new ticket to a bug-tracker instance
} {
    upvar $array email

    ns_log Debug "acs_mail_lite::incoming_email -impl bug-tracker called. Recipient $email(to)"

    set regexp_str "^notification-bug-(\[0-9a-zA-Z\]+)\@"

    # check the format and extract necessary info
    if {![regexp $regexp_str $email(to) match email_post_id]} {
        set regexp_str "^tt-(\[0-9a-zA-Z\]+)\@"
        if {![regexp $regexp_str $email(to) match email_post_id]} {
            return ""
        }
    }

    set package_key [bug_tracker::package_key]

    set package_id_list [db_list get_package_ids {}]
    
    if {[llength $package_id_list] > 1} {
        ns_log Error "acs_mail_lite::incoming_email -impl bug-tracker found two bug tracker instances that has EmailPostID ${email_post_id}.  These are ${package_id_list}.  Bug entry creation failed."
        return ""
    } elseif {[llength $package_id_list] == 0} {
        ns_log Warning "acs_mail_lite::incoming_email -impl bug-tracker did not find any bug tracker instance with EmailPostID ${email_post_id}.  Bug entry creation failed."
        return ""
    } else {
        set package_id [lindex $package_id_list 0]
        
        set user_id [party::get_by_email -email $email(from)]
        if {[string equal $user_id ""]} {
            # spam control
            return ""
        } elseif {![permission::permission_p -party_id $user_id -object_id $package_id -privilege create -no_login]} {
            # no rights
            return ""
        }

        template::util::list_of_lists_to_array $email(bodies) email_body
        
        if {[exists_and_not_null email_body(text/html)]} {
            set body [ad_html_to_text -- $email_body(text/html)]
        } else {
            set body $email_body(text/plain)
        }

        # default mostly to blanks
        # improve on this later if we want to include
        # bug settings on the email

        set bug_id [db_nextval acs_object_id_seq]
        set components_list [bug_tracker::components_get_options -package_id $package_id]
        if {[llength $components_list] == 0} {
            set component_id {}
        } else {
            set component_id [lindex [lindex $components_list 0] 1]
        }
        set found_in_version {}
        if {[llength $email(subject)] == 1} {
            set summary [lindex $email(subject) 0]
        } else {
            set summary $email(subject)
        }
        set keyword_ids {}
        foreach {category_id category_name} [bug_tracker::category_types -package_id $package_id] {
            lappend keyword_ids [bug_tracker::get_default_keyword -package_id $package_id -parent_id $category_id]
        }
        set fix_for_version {}
        set assign_to ""

        bug_tracker::bug::new \
            -bug_id $bug_id \
            -package_id $package_id \
            -component_id $component_id \
            -found_in_version $found_in_version \
            -summary $summary \
            -description $body \
            -desc_format text/plain \
            -keyword_ids $keyword_ids \
            -fix_for_version $fix_for_version \
            -assign_to $assign_to \
            -user_id $user_id
    }
    
}
