<?xml version="1.0"?>

<queryset>
   <rdbms><type>oracle</type><version>8.1.6</version></rdbms>

<fullquery name="select_states">      
      <querytext>
                select distinct upper(substr(p.status, 1, 1)) || substr(p.status, 2),
                       p.status,
                       (select count(*) 
                        from   bt_patches p2
                        where  p2.project_id = p.project_id 
                        and    p2.status = p.status
                       ) as count,
                       decode(p.status, 'open', 1, 'accepted', 2, 'refused', 3, 4) as order_num
                from   bt_patches p
                where  p.project_id = :package_id
                order  by order_num

      </querytext>
</fullquery>

</queryset>
