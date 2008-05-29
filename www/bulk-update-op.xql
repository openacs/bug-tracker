<?xml version="1.0"?>

<queryset>

<fullquery name="check_exists">
    <querytext>
        select 1
        from   bt_bugs b
        where  b.bug_id = :one_bug_id
        and    b.project_id = :package_id
    </querytext>
</fullquery>

<fullquery name="get_resolver_role_id">
    <querytext>
        select role_id
        from workflow_roles
        where workflow_id = :workflow_id
          and short_name = 'resolver'
    </querytext>
</fullquery>
  
</queryset>