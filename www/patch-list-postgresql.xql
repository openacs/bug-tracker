<?xml version="1.0"?>

<queryset>
   <rdbms><type>postgresql</type><version>7.1</version></rdbms>

<fullquery name="select_states">      
      <querytext>
                select distinct upper(substring(p.status from 1 for 1)) || substring(p.status from 2),
                       p.status,
                       (select count(*) 
                        from   bt_patches p2
                        where  p2.project_id = p.project_id 
                        and    p2.status = p.status
                       ) as count,
                       (case p.status when 'open' then 1 when 'accepted' then 2 when 'refused' then 3 else 4 end) as order_num
                from   bt_patches p
                where  p.project_id = :package_id
                order  by order_num

      </querytext>
</fullquery>

<fullquery name="select_versions">
      <querytext>

                select v.version_name,
                       v.version_id,
                       (select count(*) 
                        from   bt_patches p 
                        where  p.project_id = :package_id 
                        and    p.apply_to_version = v.version_id
                       ) as count
                from   bt_versions v
                where  exists (select 1 from bt_patches p2
                               where p2.apply_to_version = v.version_id)
                order  by v.version_name

      </querytext>
</fullquery>


</queryset>
