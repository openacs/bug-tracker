# packages/bug-tracker/www/related-file-download.tcl

ad_page_contract {
    
    downloads a related file
    
    @author Deds Castillo (deds@i-manila.com.ph)
    @creation-date 2007-01-16
    @cvs-id $Id$
} {
    bug_id:notnull
    related_object_id:notnull
    revision_id:optional,naturalnum
} -properties {
} -validate {
} -errors {
}

# make sure this object is related to this bug
if {([info exists revision_id] && $revision_id ne "")} {
    if { ![db_0or1row get_related_revision {}] } {
        ad_return_complaint 1 [_ bug-tracker.Related_file_not_found]
        ad_script_abort
    }
} elseif { ![db_0or1row get_related_file {}] } {
    ad_return_complaint 1 [_ bug-tracker.Related_file_not_found]
    ad_script_abort
}

ns_set put [ns_conn outputheaders] "Content-Disposition" "attachment; filename=$filename"

cr_write_content -revision_id $revision_id
ad_script_abort

