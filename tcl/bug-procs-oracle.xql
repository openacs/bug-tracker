<?xml version="1.0"?>

<queryset>
   <rdbms><type>oracle</type><version>8.1.6</version></rdbms>

  <fullquery name="bug_tracker::bug::get.select_bug_data">
    <querytext>
      select b.bug_id,
             b.project_id,
             b.bug_number,
             b.summary,
             b.component_id,
             b.creation_date,
             to_char(b.creation_date, 'fmMM/DDfm/YYYY') as creation_date_pretty,
             b.resolution,
             b.user_agent,
             b.found_in_version,
             b.found_in_version,
             b.fix_for_version,
             b.fixed_in_version,
             to_char(sysdate, 'fmMM/DDfm/YYYY') as now_pretty
      from   bt_bugs b
      where  b.bug_id = :bug_id
    </querytext>
  </fullquery>

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

  <fullquery name="bug_tracker::bug::insert.select_sysdate">
    <querytext>
        select sysdate from dual
    </querytext>
  </fullquery>


</queryset>
