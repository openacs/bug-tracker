/* Delete all bugs */

create function inline_0 ()
returns integer as '
declare
    v_bug_id    integer;
begin
    loop        
        select min(bug_id) into v_bug_id from bt_bugs;
        exit when not found or v_bug_id is null;
        perform bt_bug__delete(v_bug_id);
    end loop;

    return 0;
end;' language 'plpgsql';

select inline_0 ();

drop function inline_0 ();


drop function bt_bug__new
     (integer, integer, integer, varchar, integer, integer, integer, varchar, text, varchar, varchar, integer, varchar);
drop function bt_bug__name (integer);
drop function bt_bug__delete (integer);
drop function bt_bug__status_sort_order(varchar);
drop function bt_bug__bug_type_sort_order(varchar);
drop function bt_version__set_active (integer);
drop function bt_component__default_assignee(integer);
drop function bt_project__new(integer);
drop function bt_project__delete(integer);

drop table bt_user_prefs;
drop table bt_bug_actions;
drop table bt_bugs;
drop view bt_bug_number_seq;
drop sequence t_bt_bug_number_seq;
drop table bt_priority_codes;
drop table bt_severity_codes;
drop table bt_components;
drop table bt_versions;
drop table bt_projects;

delete from acs_objects where object_type = 'bt_bug';

select acs_object_type__drop_type('bt_bug', 't');

drop table bt_patch_bug_map;
drop function bt_patch__delete(integer);
drop function bt_patch__name(integer);
drop function bt_patch__new(integer,integer,integer,text,text,text,text,integer,integer,varchar);
drop table bt_patch_actions;
drop table bt_patches;
drop sequence t_bt_patch_number_seq;

delete from acs_objects where object_type = 'bt_patch';

select acs_object_type__drop_type('bt_patch', 't');

\i bug-tracker-notifications-drop.sql
