<?xml version="1.0"?>

<queryset>
   <rdbms><type>oracle</type><version>8.1.6</version></rdbms>

   <fullquery name="bug_tracker::bug::update.update_bug">
     <querytext>
        begin
            :1 := bt_bug_revision.new (
                bug_revision_id =>  null,
                bug_id =>           :bug_id,
                component_id =>     :component_id,
                found_in_version => :found_in_version,
                fix_for_version =>  :fix_for_version,
                fixed_in_version => :fixed_in_version,
                resolution =>       :resolution,
                user_agent =>       :user_agent,
                summary =>          :summary,
                creation_date =>    sysdate,
                creation_user =>    :creation_user,
                creation_ip =>      :creation_ip
            );
        end;
     </querytext>
   </fullquery>

   <fullquery name="bug_tracker::bug::delete.delete_bug_case">
     <querytext> 
        begin
             workflow_case_pkg.delete(:case_id);
        end;
     </querytext>
   </fullquery>
 
   <partialquery name="bug_tracker::bug::get_list.category_where_clause">
     <querytext>
         content_keyword.is_assigned(b.bug_id, :f_category_$parent_id, 'none') = 't'
     </querytext>
   </partialquery>

   <partialquery name="bug_tracker::user_bugs_only_where_clause.user_bugs_only">
     <querytext>
       and exists (select 1
                     from acs_object_party_privilege_map
                    where object_id = b.bug_id
                      and party_id = :user_id
                      and privilege = 'read')
     </querytext>
   </partialquery>
</queryset>
