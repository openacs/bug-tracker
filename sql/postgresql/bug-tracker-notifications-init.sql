--
-- This script registers the notifications of the
-- Bug Tracker with the Notifications service. It also
-- implements the NotificationType service contract.
--
-- @author Peter Marklund (peter@collaboraid.biz)

create function inline_0() returns integer as '
declare
        impl_id integer;
        v_foo   integer;
begin
        -- Project level notifications START

        -- Create a project level implementation of the NotificationType
        -- service contract
        impl_id := acs_sc_impl__new (
                      ''NotificationType'',
                      ''bug_tracker_project_notif_type'',
                      ''bug_tracker''
        );

        -- Note: all operations of a service contract *must* be
        -- implemented before we can bind the implementation
        -- to the service contract
        
        -- Implement the GetURL operation
        v_foo := acs_sc_impl_alias__new (
                    ''NotificationType'',
                    ''bug_tracker_project_notif_type'',
                    ''GetURL'',
                    ''bug_tracker::notification::get_url'',
                    ''TCL''
        );

        -- Implement the ProcessReply operation        
        v_foo := acs_sc_impl_alias__new (
                    ''NotificationType'',
                    ''bug_tracker_project_notif_type'',
                    ''ProcessReply'',
                    ''bug_tracker::notification::process_reply'',
                    ''TCL''
        );

        -- Bind the project level implementation to 
        -- the NotificationType service contract
          PERFORM acs_sc_binding__new (
                      ''NotificationType'',
                      ''bug_tracker_project_notif_type''
          );

        -- Create the project notification type        
        v_foo:= notification_type__new (
	        NULL,
                impl_id,
                ''bug_tracker_project_notif'',
                ''Bug Tracker Project Notification'',
                ''Notifications for entire project (package) in the Bug Tracker'',
		now(),
                NULL,
                NULL,
		NULL
        );

        -- Project notification intervals
        insert into notification_types_intervals
        (type_id, interval_id)
        select v_foo, interval_id
        from notification_intervals where name in (''instant'',''hourly'',''daily'');

        -- Project delivery type
        insert into notification_types_del_methods
        (type_id, delivery_method_id)
        select v_foo, delivery_method_id
        from notification_delivery_methods where short_name in (''email'');        

        -- Project level notifications END

        -- Bug level notifications START

        -- The bug service contract implementation
        impl_id := acs_sc_impl__new (
                ''NotificationType'',
                ''bug_tracker_bug_notif_type'',
                ''bug_tracker''
        );

        -- Bug level implementation of GetURL operation
        v_foo := acs_sc_impl_alias__new (
                    ''NotificationType'',
                    ''bug_tracker_bug_notif_type'',
                    ''GetURL'',
                    ''bug_tracker::notification::get_url'',
                    ''TCL''
        );

        -- Bug level implementation of ProcessReply operation
        v_foo := acs_sc_impl_alias__new (
                    ''NotificationType'',
                    ''bug_tracker_bug_notif_type'',
                    ''ProcessReply'',
                    ''bug_tracker::notification::process_reply'',
                    ''TCL''
        );

        -- Bind the bug level implementation to the NotificationType contract
        PERFORM acs_sc_binding__new (
                    ''NotificationType'',
                    ''bug_tracker_bug_notif_type''
        );

        -- Create the bug notification type
        v_foo:= notification_type__new (
		NULL,
                impl_id,
                ''bug_tracker_bug_notif'',
                ''Bug Tracker Bug Notification'',
                ''Notifications for a bug in the Bug Tracker'',
		now(),
                NULL,
                NULL,
		NULL
        );

        -- Enable all notification intervals for bug notifications
        insert into notification_types_intervals
        (type_id, interval_id)
        select v_foo, interval_id
        from notification_intervals where name in (''instant'',''hourly'',''daily'');

        -- Bug notification are per email
        insert into notification_types_del_methods
        (type_id, delivery_method_id)
        select v_foo, delivery_method_id
        from notification_delivery_methods where short_name in (''email'');

        -- Bug level notifications END
        
	return (0);
end;
' language 'plpgsql';

select inline_0();
drop function inline_0();
