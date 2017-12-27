--
-- Dump the results of this query on the transformed database, strip
-- out the PostgreSQL header and footer, then ensure that no whitespace is
-- at the beginning of each row:
--
-- psql -A -t nsbo -o rsync_includes.txt -f create_asset_rsync.sql
--
-- Use the resulting list of folders to filter the original "attachments"
-- directory structure using rsync:
--
-- rsync -avzC --files-from=rsync_includes.txt /path/to/attachments/asset_files/ /path/to/filtered_asset_files/
--
select substr(padded_id, 1, 3) || '/'
    || substr(padded_id, 4, 3) || '/'
    || substr(padded_id, 7, 3) || '/'
    from (select lpad(id::text, 9, '0') as padded_id from asset_files) as padded;
