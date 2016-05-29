# packages/bug-tracker/www/related-file-properties.tcl

ad_page_contract {
    
    shows versions of a related file for one bug
    
    @author Deds Castillo (deds@i-manila.com.ph)
    @creation-date 2007-01-22
    @cvs-id $Id$
} {
    bug_id:naturalnum,notnull
    related_object_id:naturalnum,notnull
} -properties {
} -validate {
} -errors {
}

set package_id [ad_conn package_id]

# Get the bug_number
if { ![db_0or1row get_bug_number {}] } {
    ad_return_complaint 1 [_ bug-tracker.Bug_not_found_2]
    ad_script_abort
}

set return_url [export_vars -base "bug" {bug_number}]

set bug_title "[bug_tracker::conn Bug] #$bug_number"

set page_title "[_ bug-tracker.Related_file_properties]"
set context [list [list "$return_url" "$bug_title"] $page_title]

template::list::create \
    -name related_file_revisions \
    -multirow related_file_revisions \
    -elements {
        filename {
            label "[_ bug-tracker.Related_file_filename]"
        }
        description {
            label "[_ bug-tracker.Related_File_Description]"
        }
        actions {
            label ""
            display_template {
                <a href="@related_file_revisions.download_url;noquote@">\#bug-tracker.download\#</a>
            }
        }
    }

db_multirow -extend { download_url } related_file_revisions related_file_revisions {} {
    set download_url [export_vars -base "related-file-download" {bug_id related_object_id revision_id}]
}
