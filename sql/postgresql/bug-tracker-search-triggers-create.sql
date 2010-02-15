-- Bug tracker search triggers
--
-- @author Don Baccus (dhogaza@pacifier.com)
-- @cvs-id $Id$

-- Triggers for the bug item table.

create or replace function bt_bug_search__itrg ()
returns trigger as '
begin
  perform search_observer__enqueue(new.bug_id,''INSERT'');
  return new;
end;' language 'plpgsql';

create or replace function bt_bug_search__utrg ()
returns trigger as '
begin
  perform search_observer__enqueue(new.bug_id,''UPDATE'');
  return old;
end;' language 'plpgsql';

create or replace function bt_bug_search__dtrg ()
returns trigger as '
begin
  perform search_observer__enqueue(new.bug_id,''DELETE'');
  return old;
end;' language 'plpgsql';

create trigger bt_bug_search__itrg after insert on bt_bugs
for each row execute procedure bt_bug_search__itrg (); 

create trigger bt_bug_search__utrg after update on bt_bugs
for each row execute procedure bt_bug_search__utrg (); 

create trigger bt_bug_search__dtrg after delete on bt_bugs
for each row execute procedure bt_bug_search__dtrg (); 
