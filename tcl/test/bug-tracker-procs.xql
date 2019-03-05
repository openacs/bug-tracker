<?xml version="1.0"?>
<queryset>

<fullquery name="_bug-tracker__project_new.count_projects">
    <querytext>
        select count(*)
        from bt_projects
    </querytext>
</fullquery>

<fullquery name="_bug-tracker__project_new.new_component">
    <querytext>
        insert into bt_components
        (component_id, project_id, component_name, maintainer)
        values
        (:component_id, :package_id, 'Foo', :user_id)
    </querytext>
</fullquery>

</queryset>

