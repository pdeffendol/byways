--
-- Clean up the schema of the original NSBO PostgreSQL database, to make it
-- more usable by third parties.
--
-- This retains only public byway and place data.
--

-- Remove secondary data schema
drop schema forums cascade;
drop schema funded cascade;
drop schema geoip cascade;
drop schema grants cascade;
drop schema nom2008 cascade;
drop schema verification cascade;

-- Remove CMS data
drop table workbins;
drop table workbins_workflows;
drop table workflows;
drop table working_activity_links;
drop table working_asset_alternate_files;
drop table working_asset_properties;
drop table working_asset_request_reviewers;
drop table working_assets;
drop table working_blm_road_types_byways;
drop table working_byway_aliases;
drop table working_byway_itinerary_links;
drop table working_byway_place_links;
drop table working_byways;
drop table working_byways_states;
drop table working_collection_memberships;
drop table working_collections;
drop table working_contact_role_assignments;
drop table working_designated_intrinsic_qualities;
drop table working_designations;
drop table working_directions;
drop table working_extended_descriptions;
drop table working_feature_schedules;
drop table working_illustrations;
drop table working_itineraries;
drop table working_itinerary_entries;
drop table working_places;
drop table working_season_descriptions;
drop table working_states;
drop table working_static_maps;
drop table working_stories;
drop table working_story_byway_links;
drop table working_story_illustrations;
drop table working_story_series_memberships;
drop table working_visitor_service_links;
drop table working_website_link_categories;
drop table working_website_links;
drop table content_notes;
drop table content_log_entries;
drop table content_role_assignments;
drop table content_role_privileges;
drop table content_roles;
drop table managed_content_types;
drop table metacontents;
drop table notes;
drop table auth_roles_assignments;
drop table auth_roles_privileges;
drop table auth_roles;
drop table download_request_items;
drop table download_requests;
drop table byway_page_views;
drop table offsite_link_stats;
drop table map_request;
drop table asset_location_statuses;
drop table asset_request_reviewers;
drop table feature_images;
drop table feature_schedules;
drop table feature_slots;
drop table map_regions;
drop table map_symbols;

-- Remove personal information (probably obsolete)
drop table contact_list_memberships;
drop table contact_lists;
drop table email_list_member;
drop table email_list;
drop table contact_role_assignments;
drop table contact_role_contexts;
drop table contact_roles;
drop view contact_details_view;
drop table addresses;
drop table program_staff_roles;
drop table other_contact_points;
drop table phones;
drop table contacts;
drop table dashboard_file_comments;
drop table dashboard_file_permissions;
drop table dashboard_files;
drop table user_dashboard_panel_preferences;
drop table dashboard_panels;
drop table user_group_memberships;
drop table user_groups;
drop table privileges;

-- Remove extra implementation-specific stuff
drop table schema_migrations;
drop table wishlist_item;
drop table wishlist;
drop table traveler_experience_links;
drop table traveler_experience;
drop table senators;
drop table congressional_districts;
drop table map_placements;
drop table indian_tribes;

-- Remove news
drop table news_post_object_links;
drop table news_post_attachment;
drop table news_post;
drop table news_clipping;
drop table news_category;

-- Remove events
drop table event_occurrence;
drop table event;
drop table timezone;

-- Remove other CMS stuff
drop table storage_space;
drop table file_space;
drop table users;
drop table object_type;

-- Remove content likely to be obsolete or unused
drop table activity_links;
drop table activities;
drop table itinerary_entries;
drop table byway_itinerary_links;
drop table itineraries;
drop table story_series_memberships;
drop table story_series;
drop table story_illustrations;
drop table story_byway_links;
drop table stories;
drop table website_link_categories;
drop table website_links;
drop table websites;
drop table website_categories;
drop table collection_memberships;
drop table collections;
drop table asset_alternate_files;

drop table static_maps;
drop table static_map_legends;
drop table static_map_types;

-- Remove unused sequences
drop sequence activities_id_seq;
drop sequence address_id;
drop sequence change_approval_id_seq;
drop sequence change_transaction_id_seq;
drop sequence dashboard_file_comment_id;
drop sequence dashboard_file_id;
drop sequence dashboard_file_permission_id;
drop sequence experience_id;
drop sequence file_space_id;
drop sequence goal_id;
drop sequence iteration_id;
drop sequence itinerary_entry_id;
drop sequence map_regions_id_seq;
drop sequence map_request_id;
drop sequence news_clipping_id;
drop sequence news_post_id;
drop sequence object_id;
drop sequence occurrence_id;
drop sequence other_contact_id;
drop sequence phone_id;
drop sequence query_id;
drop sequence role_id;
drop sequence source_id;
drop sequence status_id;
drop sequence storage_space_id;
drop sequence story_links_id;
drop sequence tag_id;
drop sequence task_id;
drop sequence unit_id;
drop sequence user_groups_id_seq;
drop sequence view_id;
drop sequence website_id;

drop sequence static_map_legend_id;
drop sequence static_map_type_id;
drop sequence static_maps_id_seq;

-- Remove non-public data (we don't have permission to distribute copyrighted assets)

delete from assets a where copyrighted or not exists (select * from illustrations where asset_id=a.id);
delete from illustrations where asset_id not in (select id from assets);
delete from asset_files where id not in (select file_id from assets);
update byways set primary_photo_id = null where primary_photo_id not in (select id from assets);
update byways set logo_id = null where logo_id not in (select id from assets);
update byways set roadsign_id = null where roadsign_id not in (select id from assets);

-- Remove columns we won't use anymore

alter table assets drop column copyright_holder;
alter table assets drop column copyright_date;
alter table assets drop column copyrighted;
alter table assets drop column usage_rights;
alter table assets drop column usage_conditions;
alter table assets drop column download_restriction;
alter table assets drop column external_url;
alter table assets drop column creative_commons_license_id;
alter table assets drop column delta;
alter table assets drop column permission_notes;
alter table assets drop column permission_status;
drop table creative_commons_licenses;

alter table byways drop column display_type;

--
-- Clean up schema for better referential integrity, etc.
--

-- Split illustrations (EF Core requires primary keys on join tables)

create table byway_assets (
  id serial primary key,
  byway_id int not null references byways(id) on delete cascade,
  asset_id int not null references assets(id) on delete cascade
);
SELECT setval('byway_assets_id_seq', COALESCE((SELECT MAX(id)+1 FROM byway_assets), 1), false);

create table place_assets (
  id serial primary key,
  place_id int not null references places(id) on delete cascade,
  asset_id int not null references assets(id) on delete cascade
);
SELECT setval('place_assets_id_seq', COALESCE((SELECT MAX(id)+1 FROM place_assets), 1), false);

insert into byway_assets select id, illustratable_id, asset_id from illustrations where illustratable_type='Byway' and illustratable_id in (select id from byways);
insert into place_assets select id, illustratable_id, asset_id from illustrations where illustratable_type='Place' and illustratable_id in (select id from places);

drop table illustrations;

-- Remove implementation-specific columns from asset_files

alter table asset_files drop column remote_file_name;
alter table asset_files drop column remote_file_size;
alter table asset_files drop column remote_content_type;
alter table asset_files drop column remote_updated_at;
alter table asset_files rename column local_content_type to file_content_type;
alter table asset_files rename column local_file_name to file_file_name;
alter table asset_files rename column local_file_size to file_file_size;
alter table asset_files rename column local_updated_at to file_updated_at;

-- Clean up routes

alter table routes rename to byway_routes;
alter table byway_routes drop column resource_type;
alter table byway_routes rename column resource_id to byway_id;
delete from byway_routes where byway_id not in (select id from byways);
alter table byway_routes add constraint byway_routes_byway_id_fkey foreign key (byway_id) references byways(id) on delete cascade;

-- Referential integrity for other assets related to byways

alter table byways add constraint byways_primary_photo_id_fkey  foreign key (primary_photo_id) references assets(id) on delete set null;
alter table byways add constraint byways_logo_id_fkey  foreign key (logo_id) references assets(id) on delete set null;
alter table byways add constraint byways_roadsign_id_fkey  foreign key (roadsign_id) references assets(id) on delete set null;

-- Split Visitor Services

alter table visitor_services rename to visitor_service_types;
alter sequence visitor_services_id_seq rename to visitor_service_types_id_seq;
create table byway_visitor_services (
  id serial primary key,
  byway_id int not null references byways(id) on delete cascade,
  type_id int not null references visitor_service_types(id),
  available boolean,
  description text,
  created_at timestamp,
  updated_at timestamp
);
insert into byway_visitor_services
  select id, location_id, service_id, available, description, created_at, updated_at
  from visitor_service_links
  where location_type='Byway' and location_id in (select id from byways);
SELECT setval('byway_visitor_services_id_seq', COALESCE((SELECT MAX(id)+1 FROM byway_visitor_services), 1), false);

create table place_visitor_services (
  id serial primary key,
  place_id int not null references places(id) on delete cascade,
  type_id int not null references visitor_service_types(id),
  available boolean,
  description text,
  created_at timestamp,
  updated_at timestamp
);
insert into place_visitor_services
  select id, location_id, service_id, available, description, created_at, updated_at
  from visitor_service_links
  where location_type='Place' and location_id in (select id from places);
SELECT setval('place_visitor_services_id_seq', COALESCE((SELECT MAX(id)+1 FROM place_visitor_services), 1), false);

drop table visitor_service_links;

-- Split seasonal information

create table byway_seasons (
  id serial primary key,
  byway_id int not null references byways(id) on delete cascade,
  season varchar(50) not null,
  body text,
  created_at timestamp,
  updated_at timestamp
);
insert into byway_seasons
  select id, location_id, season, body, created_at, updated_at
  from season_descriptions
  where location_type='Byway' and location_id in (select id from byways);
SELECT setval('byway_seasons_id_seq', COALESCE((SELECT MAX(id)+1 FROM byway_seasons), 1), false);

create table place_seasons (
  id serial primary key,
  place_id int not null references places(id) on delete cascade,
  season varchar(50) not null,
  body text,
  created_at timestamp,
  updated_at timestamp
);
insert into place_seasons
  select id, location_id, season, body, created_at, updated_at
  from season_descriptions
  where location_type='Place' and location_id in (select id from places);
SELECT setval('place_seasons_id_seq', COALESCE((SELECT MAX(id)+1 FROM place_seasons), 1), false);

drop table season_descriptions;

-- Split extended descriptions

create table byway_extended_descriptions (
  id serial primary key,
  byway_id int not null references byways(id) on delete cascade,
  type varchar(50) not null,
  body text,
  created_at timestamp,
  updated_at timestamp
);
insert into byway_extended_descriptions
  select id, location_id, type, body, created_at, updated_at
  from extended_descriptions
  where location_type='Byway' and location_id in (select id from byways);
SELECT setval('byway_extended_descriptions_id_seq', COALESCE((SELECT MAX(id)+1 FROM byway_extended_descriptions), 1), false);

create table place_extended_descriptions (
  id serial primary key,
  place_id int not null references places(id) on delete cascade,
  type varchar(50) not null,
  body text,
  created_at timestamp,
  updated_at timestamp
);
insert into place_extended_descriptions
  select id, location_id, type, body, created_at, updated_at
  from extended_descriptions
  where location_type='Place' and location_id in (select id from places);
SELECT setval('place_extended_descriptions_id_seq', COALESCE((SELECT MAX(id)+1 FROM place_extended_descriptions), 1), false);

create table state_extended_descriptions (
  id serial primary key,
  state_id int not null references states(id) on delete cascade,
  type varchar(50) not null,
  body text,
  created_at timestamp,
  updated_at timestamp
);
insert into state_extended_descriptions
  select id, location_id, type, body, created_at, updated_at
  from extended_descriptions
  where location_type='State' and location_id in (select id from states);
SELECT setval('state_extended_descriptions_id_seq', COALESCE((SELECT MAX(id)+1 FROM state_extended_descriptions), 1), false);

drop table extended_descriptions;

-- Filter taggings and add FK

create table asset_taggings (
  id serial primary key,
  asset_id int not null references assets(id) on delete cascade,
  tag_id int not null references tags(id) on delete cascade,
  created_at timestamp
);
insert into asset_taggings
  select id, taggable_id, tag_id, created_at
  from taggings
  where taggable_type='Asset' and taggable_id in (select id from assets);
SELECT setval('asset_taggings_id_seq', COALESCE((SELECT MAX(id)+1 FROM asset_taggings), 1), false);
drop table taggings;

-- Adjust some data types

alter table byways alter column length type decimal;
alter table directions alter column travel_distance type decimal;
