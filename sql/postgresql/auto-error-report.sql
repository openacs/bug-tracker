-- 
-- 
-- 
-- @author Victor Guerra (guerra@galileo.edu)
-- @creation-date 2005-02-14
-- @arch-tag: 93a2a978-df17-4639-977d-6962e8c87e3c
-- @cvs-id $Id$
--

create table bt_auto_bugs (
		bug_id	integer	constraint bt_auto_bugs_bug_id_fk
			references bt_bugs(bug_id)
			constraint bt_auto_bugs_pk
			primary key,
		package_id	integer constraint bt_auto_package_id_fk
			references apm_packages(package_id),
		error_file	varchar(300),
		times_reported	integer default 0
);
		
create index bt_auto_bugs_bug_idx on bt_auto_bugs(bug_id);				
