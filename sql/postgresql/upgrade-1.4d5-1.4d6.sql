alter table bt_projects add column workflow_id integer
                                constraint bt_projects_workflow_id_fk
                                references workflows(workflow_id) 
                                on delete cascade;

create or replace function bt_project__new(
    integer                      -- package_id
) returns integer 
as '
declare
    p_package_id                alias for $1;
    v_count                     integer;
    v_instance_name             varchar;
    v_creation_user             integer;
    v_creation_ip               varchar;
    v_folder_id                 integer;
    v_keyword_id                integer;
begin
    select count(*)
    into   v_count
    from   bt_projects
    where  project_id = p_package_id;

    if v_count > 0 then
        return 0;
    end if;

    -- get instance name for the content folder
    select p.instance_name, o.creation_user, o.creation_ip
    into   v_instance_name, v_creation_user, v_creation_ip
    from   apm_packages p join acs_objects o on (p.package_id = o.object_id)
    where  p.package_id = p_package_id;

    -- create a root CR folder
    v_folder_id := content_folder__new(
        ''bug_tracker_''||p_package_id,        -- name
        v_instance_name,                       -- label
        null,                                  -- description
        content_item_globals.c_root_folder_id, -- parent_id
        p_package_id,                          -- context_id
        null,                                  -- folder_id
        now(),                                 -- creation_date
        v_creation_user,                       -- creation_user
        v_creation_ip,                         -- creation_ip,
        ''t'',                                 -- security_inherit_p
        p_package_id                           -- package_id
    );

    -- Set package_id column. Oddly enoguh, there is no API to set it
    update cr_folders set package_id = p_package_id where folder_id = v_folder_id;

    -- register our content type
    PERFORM content_folder__register_content_type (
        v_folder_id,          -- folder_id
        ''bt_bug_revision'',  -- content_type
        ''t''                 -- include_subtypes
    );

    -- create the instance root keyword
    v_keyword_id := content_keyword__new(
        v_instance_name,                -- heading
        null,                           -- description
        null,                           -- parent_id
        null,                           -- keyword_id
        current_timestamp,              -- creation_date
        v_creation_user,                -- creation_user
        v_creation_ip,                  -- creation_ip
        ''content_keyword''             -- object_type
    );

    -- insert the row into bt_projects
    insert into bt_projects 
        (project_id, folder_id, root_keyword_id) 
    values 
        (p_package_id, v_folder_id, v_keyword_id);

    -- Create a General component to start with
    insert into bt_components (component_id, project_id, component_name)
    select acs_object_id_seq.nextval, p_package_id, ''General'';

    return 0;
end;
' language 'plpgsql';


create or replace function bt_project__delete(
    integer                 -- project_id
) returns integer
as '
declare
    p_project_id          alias for $1;
    v_folder_id           integer;
    v_root_keyword_id     integer;
    v_workflow_id         integer;
    rec                   record;
begin
    -- get the content folder and workflow_id for this instance
    select folder_id, root_keyword_id, workflow_id
    into   v_folder_id, v_root_keyword_id, v_workflow_id
    from   bt_projects
    where  project_id = p_project_id;

    perform workflow__delete(v_workflow_id);

    -- This gets done in tcl before we are called ... for now
    --  Delete the bugs
    -- for rec in select item_id from cr_items where parent_id = v_folder_id
    -- loop
    --     perform bt_bug__delete(rec.item_id);
    -- end loop;

    -- Delete the patches
    for rec in select patch_id from bt_patches where project_id = p_project_id
    loop
         perform bt_patch__delete(rec.patch_id);
    end loop;

    -- delete the content folder
    raise notice ''about to delete content_folder.'';
    perform content_folder__delete(v_folder_id);

    -- delete the projects keywords
    perform bt_project__keywords_delete(p_project_id, ''t'');

    -- These tables should really be set up to cascade
    delete from bt_versions where project_id = p_project_id;
    delete from bt_components where project_id = p_project_id;
    delete from bt_user_prefs where project_id = p_project_id;      

    delete from bt_projects where project_id = p_project_id;   

    return 0;
end;
' language 'plpgsql';

