create table bt_code_types (
  code_type_id                  integer
                                constraint bt_code_types_pk
                                primary key,
  code_type_key                 varchar(50)
                                constraint bt_code_types_code_type_key_un
                                unique,
  -- leave project_id null if this code type applies to all 
  project_id                    integer
                                constraint bt_components_projects_fk
                                references bt_projects(project_id),
  code_type_name                varchar(500),
  description                   text,
  system_required_p             char(1)
                                constraint bt_code_types_system_req_ck
                                check (system_required_p in ('t','f'))
);

-- Helper function to get code type id from code type key

create function bt_code_type_id_by_key(varchar) returns integer as '
declare
    p_code_type_key alias for $1;
    v_code_type_id integer;
begin
    select code_type_id 
    into   v_code_type_id
    from   bt_code_types
    where  code_type_key = p_code_type_key;
  
    return v_code_type_id;
end;' language 'plpgsql';


create table bt_code_values (
  value_id                      integer 
                                constraint bt_code_values_pk 
                                primary key,
  code_type_id                  integer
                                constraint bt_code_values_code_types_fk
                                references bt_code_types(,
  value_name                    varchar,
  description                   varchar,
  order_key                     integer
);


-- Status codes

Status: 
-------
BugZilla: 
OPEN:   unconfirmed, new, assigned, reopened
CLOSED: resolved, verified, closed

insert into bt_code_types (code_type_key, project_id, code_type_name, description, system_required_p)
values (nextval('t_acs_object_id_seq'), 'status', null, 'Status', 'Overall status of the bug', 't');

insert into bt_code_values (value_id, code_type_id, value_name, description, order_key)
values (nextval('t_acs_object_id_seq'), bt_code_type_id_by_key('status'), 'New', 1);

insert into bt_code_values (value_id, code_type_id, value_name, description, order_key)
values (nextval('t_acs_object_id_seq'), bt_code_type_id_by_key('status'), 'Open', 2);

insert into bt_code_values (value_id, code_type_id, value_name, description, order_key)
values (nextval('t_acs_object_id_seq'), bt_code_type_id_by_key('status'), 'Resolved', 3);

insert into bt_code_values (value_id, code_type_id, value_name, description, order_key)
values (nextval('t_acs_object_id_seq'), bt_code_type_id_by_key('status'), 'Closed', 4);


-- Resolution codes

Resolution:
-----------
BugZilla: fixed, invalid,   wontfix,   later,     remind, duplicate, worksforme
FogBUGZ:  fixed, by design, won't fix, postponed,         duplicate, not reproducible

insert into bt_code_types (code_type_key, project_id, code_type_name, description, system_required_p)
values (nextval('t_acs_object_id_seq'), 'resolution', null, 'Resolution', 'Identifies how the bug was resolved', 't');

insert into bt_code_values (value_id, code_type_id, value_name, description, order_key)
values (nextval('t_acs_object_id_seq'), bt_code_type_id_by_key('resolution'), 'Fixed', 1);

insert into bt_code_values (value_id, code_type_id, value_name, description, order_key)
values (nextval('t_acs_object_id_seq'), bt_code_type_id_by_key('resolution'), 'fixed', 1);



insert into bt_code_types (code_type_key, project_id, code_type_name, description, system_required_p)
values (nextval('t_acs_object_id_seq'), 'priority', null, 'Priority', 'How important is it to fix this bug relative to other bugs', 't');

insert into bt_code_types (code_type_key, project_id, code_type_name, description, system_required_p)
values (nextval('t_acs_object_id_seq'), 'bug_type', null, 'Type of bug', 'What type of bug is this', 't');

insert into bt_code_types (code_type_key, project_id, code_type_name, description, system_required_p)
values (nextval('t_acs_object_id_seq'), 'severity', null, 'Severity', 'How much harm does this bug do', 'f');

-- Other possible code types: Platform, Operating system





Type of bug:
------------
BugHost: annoyance, data loss, functional problem, reminder/to-do, suggestion

SDM: bug, feature request

Severity:
---------





