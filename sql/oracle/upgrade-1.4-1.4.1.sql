-- adds the component_keyword_id

alter table bt_projects add (component_keyword_id integer constraint bt_component_keyword_fk references cr_keywords(keyword_id));

create table bt_keyword_component_map (
	keyword_id      integer
		        constraint bt_component_keyword_fk
                        references cr_keywords(keyword_id),
	component_id    integer
                        constraint bt_patches_components_fk
                        references bt_components(component_id),
	constraint bt_keyword_component_map_pk
	primary key (keyword_id, component_id)
);

create index bt_keyword_component_map_keyword_idx on bt_keyword_component_map(keyword_id);
create index bt_keyword_component_map_component_idx on bt_keyword_component_map(component_id);
