ad_page_contract {
    Add or edit a category.
} {
    keyword_id:naturalnum,optional
    parent_id:naturalnum,optional
    {type_p:boolean "f"}
}

set project_name [bug_tracker::conn project_name]

if { (![info exists keyword_id] && ![info exists parent_id]) || $type_p == "t" } {
    set object_type_name [_ bug-tracker.Category_Type]
} else {
    set object_type_name [_ bug-tracker.Category]
}

if { [info exists keyword_id] } {
    set function [_ acs-kernel.common_edit]
} else {
    set function [_ acs-kernel.common_add]
}

set page_title "[string totitle $function] $object_type_name"
set context_bar [ad_context_bar [list categories [_ bug-tracker.Manage_Categories]] $page_title]


ad_form -name keyword -cancel_url categories -form {
    {keyword_id:key(acs_object_id_seq)}
    {parent_id:integer(hidden)}
    {heading:text {label $object_type_name}}
} -new_request {
    if { ![info exists parent_id] || $parent_id eq "" } {
        set parent_id [bug_tracker::conn project_root_keyword_id]
    }
} -select_query {
    select child.parent_id,
           child.heading
    from   cr_keywords child
    where  child.keyword_id = :keyword_id
} -edit_data {
    content::keyword::set_heading \
        -keyword_id $keyword_id \
        -heading $heading
} -new_data {
    content::keyword::new \
        -heading $heading \
        -parent_id $parent_id \
        -keyword_id $keyword_id
} -after_submit {
    bug_tracker::get_keywords_flush
    ad_returnredirect categories
    ad_script_abort
}

# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
