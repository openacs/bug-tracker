<?xml version="1.0"?>

<queryset>
  <rdbms><type>postgresql</type><version>7.1</version></rdbms>

  <fullquery name="bug_tracker::bug::update.update_bug">
    <querytext>
        select bt_bug_revision__new (
            null,
            :bug_id,
            :component_id,
            :found_in_version,
            :fix_for_version,
            :fixed_in_version,
            :resolution,
            :user_agent,
            :summary,
            now(),
            :creation_user,
            :creation_ip
        );
    </querytext>
  </fullquery>

  <fullquery name="bug_tracker::bug::delete.delete_bug_case">
    <querytext> 
      select workflow_case_pkg__delete(:case_id);
    </querytext>
  </fullquery>
 
  <partialquery name="bug_tracker::bug::get_list.category_where_clause">
    <querytext>
      content_keyword__is_assigned(b.bug_id, :f_category_$parent_id, 'none') = 't'
    </querytext>
  </partialquery>

  <partialquery name="bug_tracker::user_bugs_only_where_clause.user_bugs_only">
    <querytext>
      and acs_permission__permission_p(b.bug_id, :user_id, 'read')
    </querytext>
  </partialquery>
  
</queryset>
