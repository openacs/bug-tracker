--
-- This script drops all notifications setup
-- by the Bug Tracker application
--
-- FIXME TODO: This code was copied and pasted from the forums package
--             and I don't fully understand it.
--             Much of this code should probably be moved into the
--             Notifications package, i.e. there should be a method
--             to fully drop a notification type with all associated
--             service contract data.
--
-- @author Peter Marklund (peter@collaboraid.biz)

-- Delete the notification data
create function inline_0 ()
 returns integer as '
 declare
     row                             record;
 begin
     for row in select nt.type_id
                from notification_types nt
                where nt.short_name in (''bug_tracker_project_notif'', ''bug_tracker_bug_notif'')
     loop
         perform notification_type__delete(row.type_id);
         delete from notifications where type_id = row.type_id;
         delete from notification_types where type_id = row.type_id;
         delete from notification_types_intervals where type_id = row.type_id;
         delete from notification_types_del_methods where type_id = row.type_id;
     end loop;

     return null;
 end;' language 'plpgsql';

 select inline_0();
 drop function inline_0 ();

-- Delete the service contract data
create function bt_service_contract_delete(varchar,varchar)
returns integer as '
declare
        p_impl_name             alias for $1;
        p_impl_short_name       alias for $2;
        impl_id integer;
        v_foo   integer;
begin        

        -- the notification type impl
        impl_id := acs_sc_impl__get_id (
                      ''NotificationType'',		-- impl_contract_name
                      p_impl_name	-- impl_name
        );

        PERFORM acs_sc_binding__delete (
                    ''NotificationType'',
                    p_impl_name
        );

        v_foo := acs_sc_impl_alias__delete (
                    ''NotificationType'',		-- impl_contract_name	
                    p_impl_name,	-- impl_name
                    ''GetURL''				-- impl_operation_name
        );

        v_foo := acs_sc_impl_alias__delete (
                    ''NotificationType'',		-- impl_contract_name	
                    p_impl_name,                        -- impl_name
                    ''ProcessReply''			-- impl_operation_name
        );

    return 0;
end;
' language 'plpgsql';

select bt_service_contract_delete('bug_tracker_project_notif_type','but_tracker_project_notif');
select bt_service_contract_delete('bug_tracker_bug_notif_type','but_tracker_bug_notif');
drop function bt_service_contract_delete(varchar,varchar);
