--
-- Replace deprecated call to content_revision__new/11 by call to content_revision__new/13
--

--
-- procedure bt_bug_revision__new/12
--
CREATE OR REPLACE FUNCTION bt_bug_revision__new(
   p_bug_revision_id integer,
   p_bug_id integer,
   p_component_id integer,
   p_found_in_version integer,
   p_fix_for_version integer,
   p_fixed_in_version integer,
   p_resolution varchar,
   p_user_agent varchar,
   p_summary varchar,
   p_creation_date timestamptz,
   p_creation_user integer,
   p_creation_ip varchar
) RETURNS int AS $$
DECLARE

    v_revision_id               integer;
BEGIN
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
        p_creation_ip,          -- creation_ip
        null,                   -- content_length
        null                    -- package_id
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
END;

$$ LANGUAGE plpgsql;
