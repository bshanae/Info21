-- SETUP ---------------------------------------------------------------------------------------------------------------

drop table if exists TableName1 cascade;
create table TableName1
(
    ID    serial primary key,
    Value int
);

drop table if exists TableName2 cascade;
create table TableName2
(
    ID    serial primary key,
    Value int
);

drop table if exists NotTableName3 cascade;
create table NotTableName3
(
    ID    serial primary key,
    Value int
);

drop function if exists dummy_trigger cascade;
create function dummy_trigger() returns trigger as
$$
declare
begin
    return null;
end;
$$ language 'plpgsql';

drop trigger if exists trigger_on_delete on tablename1;
create trigger trigger_on_delete
    after delete
    on tablename1
    for each row
execute function dummy_trigger();

drop trigger if exists trigger_on_insert on tablename1;
create trigger trigger_on_insert
    after insert
    on tablename1
    for each row
execute function dummy_trigger();

drop trigger if exists trigger_on_update on tablename1;
create trigger trigger_on_update
    after update
    on tablename1
    for each row
execute function dummy_trigger();

drop trigger if exists trigger_on_insert_or_update on tablename1;
create trigger trigger_on_insert_or_update
    after insert or update
    on tablename1
    for each row
execute function dummy_trigger();

drop trigger if exists trigger_on_column_update on tablename1;
create trigger trigger_on_column_update
    after update of value
    on tablename1
    for each row
execute function dummy_trigger();

drop trigger if exists trigger_on_delete on tablename1;
create trigger trigger_on_delete
    after delete
    on tablename1
    for statement
execute function dummy_trigger();

drop function if exists dummy_event_trigger cascade;
create function dummy_event_trigger() returns event_trigger as
$$
declare
begin
end;
$$ language 'plpgsql';

create event trigger trigger_on_ddl ON ddl_command_start
execute function dummy_event_trigger();

-- TASK 1 --------------------------------------------------------------------------------------------------------------

drop procedure if exists delete_tables cascade;
create procedure delete_tables() as
$$
declare
    _table varchar;
begin
    for _table in
        select table_name
        from information_schema.tables
        where table_name like 'tablename%'
          and table_schema not in ('information_schema', 'pg_catalog')
          and table_type = 'BASE TABLE'
        loop
            execute format('drop table %s', _table);
        end loop;
end;
$$ language 'plpgsql';

-- TASK 3 --------------------------------------------------------------------------------------------------------------

drop procedure if exists delete_dml_triggers cascade;
create procedure delete_dml_triggers(_n_triggers out int) as
$$
declare
    _row record;
begin
    _n_triggers = 0;
    for _row in
        select distinct on (trigger_name) *
        from information_schema.triggers
        loop
            execute format('drop trigger %s on %s cascade', _row.trigger_name, _row.event_object_table);
            _n_triggers = _n_triggers + 1;
        end loop;
end;
$$ language 'plpgsql';