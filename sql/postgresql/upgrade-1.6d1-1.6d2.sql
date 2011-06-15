create or replace function bt_bug_search__dtrg ()
returns trigger as '
begin
  perform search_observer__enqueue(old.bug_id,''DELETE'');
  return old;
end;' language 'plpgsql';
