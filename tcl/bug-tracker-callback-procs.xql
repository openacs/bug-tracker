<?xml version="1.0"?>

<queryset>

<fullquery name="callback::acs_mail_lite::incoming_email::impl::bug-tracker.get_package_ids">
    <querytext>
        select v.package_id
        from apm_parameters p,
             apm_parameter_values v
        where p.package_key = :package_key
              and p.parameter_name = 'EmailPostID'
              and p.parameter_id = v.parameter_id
              and v.attr_value = :email_post_id
    </querytext>
</fullquery>

  
</queryset>