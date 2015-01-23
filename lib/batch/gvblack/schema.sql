
-- Used by ead_fx.rb class Fx_file_info

create table file_info (
       fi_pk integer primary key autoincrement,
       cpath text,
       fname text,
       test_name text,
       format text,
       mime text,
       size text,
       md5 text,
       sha1 text,
       url text
);

