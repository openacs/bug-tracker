-- Bug tracker search triggers
--
-- @author Don Baccus (dhogaza@pacifier.com)
-- @cvs-id $Id$

-- Triggers for the bug item table.

CREATE OR REPLACE FUNCTION bt_bug_search__itrg () RETURNS trigger AS $$
BEGIN
  perform search_observer__enqueue(new.bug_id,'INSERT');
  return new;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION bt_bug_search__utrg () RETURNS trigger AS $$
BEGIN
  perform search_observer__enqueue(new.bug_id,'UPDATE');
  return old;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION bt_bug_search__dtrg () RETURNS trigger AS $$
BEGIN
  perform search_observer__enqueue(old.bug_id,'DELETE');
  return old;
END;
$$ LANGUAGE plpgsql;

create trigger bt_bug_search__itrg after insert on bt_bugs
for each row execute procedure bt_bug_search__itrg (); 

create trigger bt_bug_search__utrg after update on bt_bugs
for each row execute procedure bt_bug_search__utrg (); 

create trigger bt_bug_search__dtrg after delete on bt_bugs
for each row execute procedure bt_bug_search__dtrg (); 
