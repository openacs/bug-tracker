update acs_object_types set name_method = 'bt_bug__name' where object_type = 'bt_bug' and name_method is null;

create or replace function bt_bug__name(
   integer                      -- bug_id
) returns varchar
as '
declare
   p_bug_id                 alias for $1;
   v_name                     varchar;
begin
   select ''Bug #''||bug_number||'': ''||summary 
          into v_name 
   from bt_bugs 
   where bug_id = p_bug_id;

   return v_name;
end;
' language 'plpgsql';

create or replace function bt_patch__new(
    integer,     -- patch_id
    integer,     -- project_id
    integer,     -- component_id
    text,        -- summary
    text,        -- description
    text,        -- description_format
    text,        -- content
    integer,     -- generated_from_version
    integer,     -- creation_user
    varchar      -- creation_ip
) returns int
as '
declare
    p_patch_id                    alias for $1;
    p_project_id                  alias for $2;
    p_component_id                alias for $3;
    p_summary                     alias for $4;
    p_description                 alias for $5;
    p_description_format          alias for $6;
    p_content                     alias for $7;
    p_generated_from_version      alias for $8;
    p_creation_user               alias for $9;
    p_creation_ip                 alias for $10;

    v_patch_id                    integer;
    v_patch_number                integer;
    v_action_id                 integer;
begin

    v_patch_id := acs_object__new(
        p_patch_id,             -- object_id
        ''bt_patch'',           -- object_type
        current_timestamp,      -- creation_date
        p_creation_user,        -- creation_user
        p_creation_ip,          -- creation_ip
        p_project_id,           -- context_id
        null,                   -- title 
        p_project_id            -- package_id
    );

    select coalesce(max(patch_number),0) + 1
    into   v_patch_number
    from   bt_patches
    where  project_id = p_project_id;

    insert into bt_patches
        (patch_id, 
         project_id, 
         component_id, 
         summary, 
         content, 
         generated_from_version,
         patch_number)
    values
        (v_patch_id, 
         p_project_id, 
         p_component_id, 
         p_summary, 
         p_content, 
         p_generated_from_version,
         v_patch_number);

    update acs_objects set title = bt_patch__name(v_patch_id) where object_id = v_patch_id;

    select nextval(''t_acs_object_id_seq'') 
    into   v_action_id;

    insert into bt_patch_actions
        (action_id, patch_id, action, actor, comment_text, comment_format)
     values
        (v_action_id, v_patch_id, ''open'', p_creation_user, p_description, p_description_format);

    return v_patch_id;
end;
' language 'plpgsql';


create or replace function bt_bug_revision__new(
    integer,        -- bug_revision_id
    integer,        -- bug_id
    integer,        -- component_id
    integer,        -- found_in_version
    integer,        -- fix_for_version
    integer,        -- fixed_in_version
    varchar,        -- resolution
    varchar,        -- user_agent
    varchar,        -- summary
    timestamptz,    -- creation_date
    integer,        -- creation_user
    varchar         -- creation_ip
) returns int
as '
declare
    p_bug_revision_id       alias for $1;
    p_bug_id                alias for $2;
    p_component_id          alias for $3;
    p_found_in_version      alias for $4;
    p_fix_for_version       alias for $5;
    p_fixed_in_version      alias for $6;
    p_resolution            alias for $7;
    p_user_agent            alias for $8;
    p_summary               alias for $9;
    p_creation_date         alias for $10;
    p_creation_user         alias for $11;
    p_creation_ip           alias for $12;

    v_revision_id               integer;
begin
    -- create the initial revision
    v_revision_id := content_revision__new(
        p_summary,              -- title
        null,                   -- description
        current_timestamp,      -- publish_date
        null,                   -- mime_type
        null,                   -- nls_language        
        null,                   -- new_data
        p_bug_id,               -- item_id
        p_bug_revision_id,      -- revision_id
        p_creation_date,        -- creation_date
        p_creation_user,        -- creation_user
        p_creation_ip           -- creation_ip
    );

    -- insert into the bug-specific revision table
    insert into bt_bug_revisions 
        (bug_revision_id, component_id, resolution, user_agent, found_in_version, fix_for_version, fixed_in_version)
    values
        (v_revision_id, p_component_id, p_resolution, p_user_agent, p_found_in_version, p_fix_for_version, p_fixed_in_version);

    -- make this revision live
    PERFORM content_item__set_live_revision(v_revision_id);

    -- update the cache
    update bt_bugs
    set    live_revision_id = v_revision_id,
           summary = p_summary,
           component_id = p_component_id,
           resolution = p_resolution,
           user_agent = p_user_agent,
           found_in_version = p_found_in_version,
           fix_for_version = p_fix_for_version,
           fixed_in_version = p_fixed_in_version
    where  bug_id = p_bug_id;

    -- update the title in acs_objects
    update acs_objects set title = bt_bug__name(p_bug_id) where object_id = p_bug_id;

    return v_revision_id;
end;
' language 'plpgsql';


create or replace function bt_patch__new(
    integer,     -- patch_id
    integer,     -- project_id
    integer,     -- component_id
    text,        -- summary
    text,        -- description
    text,        -- description_format
    text,        -- content
    integer,     -- generated_from_version
    integer,     -- creation_user
    varchar      -- creation_ip
) returns int
as '
declare
    p_patch_id                    alias for $1;
    p_project_id                  alias for $2;
    p_component_id                alias for $3;
    p_summary                     alias for $4;
    p_description                 alias for $5;
    p_description_format          alias for $6;
    p_content                     alias for $7;
    p_generated_from_version      alias for $8;
    p_creation_user               alias for $9;
    p_creation_ip                 alias for $10;

    v_patch_id                    integer;
    v_patch_number                integer;
    v_action_id                 integer;
begin

    v_patch_id := acs_object__new(
        p_patch_id,             -- object_id
        ''bt_patch'',           -- object_type
        current_timestamp,      -- creation_date
        p_creation_user,        -- creation_user
        p_creation_ip,          -- creation_ip
        p_project_id,           -- context_id
        null,                   -- title 
        p_project_id            -- package_id
    );

    select coalesce(max(patch_number),0) + 1
    into   v_patch_number
    from   bt_patches
    where  project_id = p_project_id;

    insert into bt_patches
        (patch_id, 
         project_id, 
         component_id, 
         summary, 
         content, 
         generated_from_version,
         patch_number)
    values
        (v_patch_id, 
         p_project_id, 
         p_component_id, 
         p_summary, 
         p_content, 
         p_generated_from_version,
         v_patch_number);

    update acs_objects set title = bt_patch__name(v_patch_id) where object_id = v_patch_id;

    select nextval(''t_acs_object_id_seq'') 
    into   v_action_id;

    insert into bt_patch_actions
        (action_id, patch_id, action, actor, comment_text, comment_format)
     values
        (v_action_id, v_patch_id, ''open'', p_creation_user, p_description, p_description_format);

    return v_patch_id;
end;
' language 'plpgsql';

create or replace function bt_patch__name(
   integer                      -- patch_id
) returns varchar
as '
declare
   p_patch_id                 alias for $1;
   v_name                     varchar;
begin
   select ''Patch #''||patch_number||'': ''||summary
   into   v_name
   from   bt_patches
   where  patch_id = p_patch_id;

   return v_name;
end;
' language 'plpgsql';

