--
-- A "project" is one instance of the bug-tracker.
--

create table bt_projects (
  project_id                    integer not null
                                constraint bt_projects_apm_packages_fk
                                references apm_packages(package_id) 
                                constraint bt_projects_pk 
                                primary key,
  description                   text,
  maintainer                    integer 
                                constraint bt_projects_maintainer_fk
                                references users(user_id)
);

create function bt_project__new(
    integer                      -- package_id
) returns integer 
as '
declare
    new__package_id              alias for $1;
    rec                          record;
    v_count                      integer;
begin
    select count(*)
    into   v_count
    from   bt_projects
    where  project_id = new__package_id;

    if v_count > 0 then
        return 0;
    end if;

    -- insert the row into bt_projects
    insert into bt_projects (project_id) values (new__package_id);

    -- copy over the default severity/priority codes
    for rec in select * from bt_severity_codes where project_id is null loop
        insert into bt_severity_codes 
               (severity_id, project_id, severity_name, sort_order, default_p) 
        select acs_object_id_seq.nextval, new__package_id, rec.severity_name, rec.sort_order, rec.default_p;
    end loop;

    for rec in select * from bt_priority_codes where project_id is null loop
        insert into bt_priority_codes 
               (priority_id, project_id, priority_name, sort_order, default_p) 
        select acs_object_id_seq.nextval, new__package_id, rec.priority_name, rec.sort_order, rec.default_p;
    end loop;

    -- Create a General component to start with
    insert into bt_components (component_id, project_id, component_name)
    select acs_object_id_seq.nextval, new__package_id, ''General'';

    return 0;
end;
' language 'plpgsql';

create function bt_project__delete(
    integer                      -- package_id
) returns integer 
as '
declare
    delete__package_id           alias for $1;
begin
    -- delete severity/priority codes
    delete from bt_severity_codes where project_id = delete__package_id;
    delete from bt_priority_codes where project_id = delete__package_id;

    -- delete the  row from bt_projects
    delete from bt_projects where project_id = delete__package_id;

    return 0;
end;
' language 'plpgsql';

       

    

create table bt_versions (
  version_id                    integer not null
                                constraint bt_versions_pk
                                primary key,
  project_id                    integer not null
                                constraint bt_versions_projects_fk
                                references bt_projects(project_id),
  -- Like apm_package_versions.version_name
  -- But can also be a human-readable name like "Future", "Milestone 3", etc.
  version_name                  varchar(500) not null,
  description                   text,
  anticipated_freeze_date       date,
  actual_freeze_date            date,
  anticipated_release_date      date,
  actual_release_date           date,
  maintainer                    integer 
                                constraint bt_versions_maintainer_fk
                                references users(user_id),
  supported_platforms           varchar(1000),
  active_version_p              char(1) not null
                                constraint bt_versions_active_version_p_ck
                                check (active_version_p in ('t','f'))
                                default 'f',
  -- Can we assign bugs to be fixed for this version?
  assignable_p                  char(1)
                                constraint bt_versions_assignable_p_ck
                                check (assignable_p in ('t','f'))
);

-- should probably have a trigger to ensure that there's only one active version.

-- but we just make a stored function that alters the active version

create function bt_version__set_active (
   integer                       -- active_version_id
) returns integer 
as '
declare
    new__active_version_id alias for $1;
    v_project_id integer;
begin
    select project_id
    into   v_project_id
    from   bt_versions 
    where  version_id = new__active_version_id;

    if found then
        update bt_versions set active_version_p=''f'' where project_id = v_project_id;
    end if;
    update bt_versions set active_version_p=''t'' where version_id = new__active_version_id;
    return 0;
end;
' language 'plpgsql';

create table bt_components (
  component_id                  integer not null
                                constraint bt_components_pk
                                primary key,
  project_id                    integer not null
                                constraint bt_components_projects_fk 
                                references bt_projects(project_id),
  component_name                varchar(500) not null,
  description                   text,
  -- a component can be without maintainer, in which case we just default to the project maintainer
  maintainer                    integer 
                                constraint bt_components_maintainer_fk
                                references users(user_id)
);


create function bt_component__default_assignee(
   integer                      -- component_id
) returns integer
as '
declare
    p_component_id              alias for $1;
    v_assignee                  integer;
begin
    select maintainer
    into   v_assignee
    from   bt_components
    where  component_id = p_component_id;

    if v_assignee is null then
        select p.maintainer
        into   v_assignee
        from   bt_projects p, bt_components c
        where  p.project_id = c.project_id
        and    c.component_id = p_component_id;
    end if;

    return v_assignee;
end;
' language 'plpgsql';


create table bt_severity_codes (
  severity_id                   integer not null
                                constraint bt_severity_codes_pk
                                primary key,
  project_id                    integer 
                                constraint bt_severity_codes_projects_fk
                                references bt_projects(project_id),
  severity_name                 varchar(500) not null,
  sort_order                    integer not null,
  default_p                     char(1) not null
                                constraint bt_severity_codes_default_p_ck
                                check (default_p in ('t','f'))
                                default 'f',
  constraint bt_severity_codes_name_un
  unique(project_id, severity_name),
  constraint bt_severity_codes_sort_order_un
  unique(project_id, sort_order)
);

insert into bt_severity_codes (severity_id, project_id, severity_name, sort_order, default_p)
select acs_object_id_seq.nextval, null, 'Critical', 1, 'f';

insert into bt_severity_codes (severity_id, project_id, severity_name, sort_order, default_p) 
select acs_object_id_seq.nextval, null, 'Major', 2, 'f';

insert into bt_severity_codes (severity_id, project_id, severity_name, sort_order, default_p) 
select acs_object_id_seq.nextval, null, 'Normal', 3, 't';

insert into bt_severity_codes (severity_id, project_id, severity_name, sort_order, default_p) 
select acs_object_id_seq.nextval, null, 'Minor', 4, 'f';

insert into bt_severity_codes (severity_id, project_id, severity_name, sort_order, default_p) 
select acs_object_id_seq.nextval, null, 'Trivial', 5, 'f';

insert into bt_severity_codes (severity_id, project_id, severity_name, sort_order, default_p) 
select acs_object_id_seq.nextval, null, 'Enhancement', 6, 'f';


create table bt_priority_codes (
  priority_id                   integer not null
                                constraint bt_priority_codes_pk
                                primary key,
  project_id                    integer 
                                constraint bt_priority_codes_projects_fk
                                references bt_projects(project_id),
  priority_name                 varchar(500) not null,
  sort_order                    integer not null,
  default_p                     char(1) not null
                                constraint bt_priority_codes_default_p_ck
                                check (default_p in ('t','f'))
                                default 'f',
  constraint bt_priority_codes_name_un
  unique(project_id, priority_name),
  constraint bt_priority_codes_sort_order_un
  unique(project_id, sort_order)
);

insert into bt_priority_codes (priority_id, project_id, priority_name, sort_order, default_p) 
select acs_object_id_seq.nextval, null, 'High', 1, 'f';

insert into bt_priority_codes (priority_id, project_id, priority_name, sort_order, default_p) 
select acs_object_id_seq.nextval, null, 'Normal', 2, 't';

insert into bt_priority_codes (priority_id, project_id, priority_name, sort_order, default_p) 
select acs_object_id_seq.nextval, null, 'Low', 3, 'f';



-- We maintain a public bug number, different from the 
-- bug_id, because bug_id is drawn on the acs_objects sequence
-- which is used for tons of other things. This gives us cleaner
-- bug numbers.

create sequence t_bt_bug_number_seq;
create view bt_bug_number_seq as
select nextval('t_bt_bug_number_seq') as nextval;

create table bt_bugs (
  bug_id                        integer 
                                constraint bt_bugs_pk
                                primary key
                                constraint bt_bugs_bug_id_fk
                                references acs_objects(object_id),
  project_id                    integer 
                                constraint bt_bugs_projects_fk
                                references bt_projects(project_id),

  component_id                  integer 
                                constraint bt_bugs_components_fk
                                references bt_components(component_id),
  bug_number                    integer not null,
  status                        varchar(50) not null
                                constraint bt_bugs_status_ck
                                check (status in ('open', 'resolved', 'closed'))
                                default 'open',
  resolution                    varchar(50)
                                constraint bt_bugs_resolution_ck
                                check (resolution is null or 
                                       resolution in ('fixed','bydesign','wontfix','postponed','duplicate','norepro')),
  bug_type                      varchar(50) not null
                                constraint bt_bugs_bug_type_ck
                                check (bug_type in ('bug', 'suggestion','todo')),
  severity                      integer not null
                                constraint bt_bugs_severity_fk
                                references bt_severity_codes(severity_id),
  priority                      integer not null
                                constraint bt_bugs_priority_fk
                                references bt_priority_codes(priority_id),
  user_agent                    varchar(500),
  original_estimate_minutes     integer,
  latest_estimate_minutes       integer,
  elapsed_time_minutes          integer,
  found_in_version              integer
                                constraint bt_bugs_found_in_version_fk   
                                references bt_versions(version_id), 
  fix_for_version               integer
                                constraint bt_bugs_fix_for_version_fk   
                                references bt_versions(version_id), 
  fixed_in_version              integer
                                constraint bt_bugs_fixed_in_version_fk   
                                references bt_versions(version_id), 
  summary                       varchar(500) not null,                                
  assignee                      integer
                                constraint bt_bug_assignee_fk
                                references users(user_id),
  constraint bt_bugs_bug_number_un
  unique (project_id, bug_number)
);

create table bt_bug_actions (
  action_id                     integer not null
                                constraint bt_bug_actions_pk
                                primary key,
  bug_id                        integer not null
                                constraint bt_bug_actions_bug_fk
                                references bt_bugs(bug_id)
                                on delete cascade,
  action                        varchar(50)
                                constraint bt_bug_actions_action_ck
                                check (action in ('open','edit','comment','reassign','resolve','reopen','close')),
  resolution                    varchar(50)
                                constraint bt_bugs_actions_resolution_ck
                                check (resolution is null or 
                                       resolution in ('fixed','bydesign','wontfix','postponed','duplicate','norepro')),
  actor                         integer not null
                                constraint bt_bug_actions_actor_fk
                                references users(user_id),
  action_date                   timestamp not null
                                default now(),
  comment                       text,
  comment_format                varchar(30) default 'plain' not null
                                constraint  bt_bug_actions_comment_format_ck
                                check (comment_format in ('html', 'plain', 'pre'))
);

  



-- Create the bt_bug object type

create function inline_0 ()
returns integer as '
begin
    PERFORM acs_object_type__create_type (
	''bt_bug'',
	''Bug'',
	''Bugs'',
	''acs_object'',
	''bt_bugs'',
	''bug_id'',
	null,
	''f'',
	null,
	''bt_bug__name''
	);

    return 0;
end;' language 'plpgsql';

select inline_0 ();

drop function inline_0 ();


create function bt_bug__new(
    integer,     -- bug_id
    integer,     -- project_id
    integer,     -- component_id
    varchar,     -- bug_type 
    integer,     -- severity
    integer,     -- priority
    integer,     -- found_in_version
    varchar,     -- summary
    text,        -- description
    varchar,     -- desc_format
    varchar,     -- user_agent
    integer,     -- creation_user
    varchar      -- creation_ip
) returns int
as '
declare
    p_bug_id                    alias for $1;
    p_project_id                alias for $2;
    p_component_id              alias for $3;
    p_bug_type                  alias for $4;
    p_severity                  alias for $5;
    p_priority                  alias for $6;
    p_found_in_version          alias for $7;
    p_summary                   alias for $8;
    p_description               alias for $9;
    p_desc_format               alias for $10;
    p_user_agent                alias for $11;
    p_creation_user             alias for $12;
    p_creation_ip               alias for $13;
    v_bug_id                    integer;
    v_bug_number                integer;
    v_assignee                  integer;
    v_action_id                 integer;
begin
    v_assignee := bt_component__default_assignee(p_component_id);

    v_bug_id := acs_object__new(
        p_bug_id,               -- object_id
        ''bt_bug'',             -- object_type
        now(),                  -- creation_date
        p_creation_user,        -- creation_user
        p_creation_ip,          -- creation_ip
        p_project_id,           -- context_id
        ''t''                   -- security_inherit_p
    );

    select coalesce(max(bug_number),0) + 1
    into   v_bug_number
    from   bt_bugs
    where  project_id = p_project_id;

    insert into bt_bugs
        (bug_id, project_id, component_id,  bug_number, bug_type, severity, assignee,
         priority, found_in_version, summary, user_agent)
    values
        (v_bug_id, p_project_id, p_component_id, v_bug_number, p_bug_type, p_severity, v_assignee,
        p_priority, p_found_in_version, p_summary, p_user_agent);

    select nextval(''t_acs_object_id_seq'') 
    into   v_action_id;

    insert into bt_bug_actions
        (action_id, bug_id, action, actor, comment, comment_format)
    values
        (v_action_id, v_bug_id, ''open'', p_creation_user, p_description, p_desc_format);
        
    return 0;
end;
' language 'plpgsql';


create function bt_bug__name(
   integer                      -- bug_id
) returns varchar
as '
declare
   name__bug_id                 alias for $1;
   v_name                       varchar;
begin
   select summary
   into   v_name
   from   bt_bugs
   where  bug_id = name__bug_id;

   return v_name;
end;
' language 'plpgsql';


create function bt_bug__delete(
   integer                      -- bug_id
) returns integer
as '
declare
    delete__bug_id              alias for $1;
begin
    perform acs_object__delete(delete__bug_id);

    return 0;
end;
' language 'plpgsql';


create function bt_bug__status_sort_order(
    varchar                     -- status
) returns integer
as '
declare
    p_status                    alias for $1;
    v_sort_order                integer;
begin
    v_sort_order := case p_status
        when ''open''     then 1
        when ''resolved'' then 2
        when ''closed''   then 3
                          else 4
    end;
    
    return v_sort_order;
end;
' language 'plpgsql';


create function bt_bug__bug_type_sort_order(
    varchar                     -- bug_type
) returns integer
as '
declare
    p_bug_type                  alias for $1;
    v_sort_order                integer;
begin
    v_sort_order := case p_bug_type
        when ''bug''        then 1
        when ''suggestion'' then 2
        when ''todo''       then 3
                            else 4
    end;

    return v_sort_order;
end;
' language 'plpgsql';


-- In SDM: sdm_patches
-- In SDM, this is a relationship between a general comment and a ticket
--         supposedly the patch itself is stored as a special comment
-- In BT: Probably something similar, not sure.

-- In SDM: sdm_ticket_ratings
-- In BT: We'll leave that out for now, but supposedly we could use a modified 
--        version of my ratings package from pinds.com

-- All of the following should be doable with acs_rels of some sort
-- (I'm not too strong in that data model, but I suppose I'll learn over the next few days)

-- sdm_ticket_assignments
-- sdm_bug_release_maps
-- sdm_user_ticket_interest_map
-- sdm_user_module_interest_map
-- sdm_user_package_interest_map
-- sdm_related_tickets_map


-- In SDM: sdm_notifications
--         This seems to be a table to hold notifications until they're actually sent out in batch
--         depending on the user's preferences
-- In BT: We'd probably do something similar.

-- In SDM: sdm_notification_prefs
-- In BT: 
create table bt_user_prefs (
  user_id                       integer not null
                                constraint bt_user_prefs_user_id_fk
                                references users(user_id),
  project_id                    integer not null
                                constraint bt_user_prefs_project_fk
                                references bt_projects(project_id),
  user_version                  integer
                                constraint bt_user_prefs_current_version_fk
                                references bt_versions(version_id),
  constraint bt_user_prefs_pk
  primary key (user_id, project_id)
);

