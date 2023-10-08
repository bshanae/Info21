-- TYPES --------------------------------------------------------------------------------------------------------------

drop type if exists CheckStatus cascade;
create type CheckStatus as enum ( 'Start', 'Success', 'Failure' );

-- PROCEDURES ----------------------------------------------------------------------------------------------------------

drop procedure if exists load_csv;
create procedure load_csv(tablename text, filename text, separator text) as
$$
declare
    dir constant varchar := '/Users/v.belchenko/Workspace/Info21/data/init/';
begin
    execute format('copy %s from ''%s'' delimiter ''%s'' csv header',
                   tablename, dir || filename, separator);
end;
$$ language 'plpgsql';

drop procedure if exists fix_sequence;
create procedure fix_sequence(tablename text, sequence_column text) as
$$
declare
begin
    execute format('select setval(pg_get_serial_sequence(''%s'', ''%s''), (select max(%s) from %s))', tablename,
                   sequence_column, sequence_column, tablename);
end;
$$ language 'plpgsql';

drop function if exists last_p2p_status();
create function last_p2p_status(_check int) returns CheckStatus as
$$
declare
    _result CheckStatus;
begin
    select State
    into _result
    from P2P
    where CheckID = _check
    order by Time desc
    limit 1;

    return _result;
end;
$$ language 'plpgsql';

drop function if exists last_verter_status();
create function last_verter_status(_check int) returns CheckStatus as
$$
declare
    _result CheckStatus;
begin
    select State
    into _result
    from Verter
    where CheckID = _check
    order by Time desc
    limit 1;

    return _result;
end;
$$ language 'plpgsql';

drop function if exists task_completed(varchar, varchar);
create function task_completed(_peer varchar, _task varchar) returns BOOLEAN as
$$
declare
    _last_check int;
begin

    select ID
    into _last_check
    from Checks
    where Peer = _peer and Task = _task
    order by Date desc
    limit 1;

    if _last_check is null then
        return false;
    end if;

    if last_p2p_status(_last_check) is distinct from 'Success' then
        return false;
    end if;

    if last_verter_status(_last_check) in ('Start', 'Failure') then
        return false;
    end if;

    return true;
end;
$$ language 'plpgsql';

-- TABLES : PEERS ------------------------------------------------------------------------------------------------------

drop table if exists Peers cascade;
create table Peers
(
    Nickname varchar primary key,
    Birthday DATE
);

call load_csv('Peers', 'peers.csv', ',');

-- TABLES : TASKS ------------------------------------------------------------------------------------------------------

drop table if exists Tasks cascade;
create table Tasks
(
    Title      varchar primary key,
    ParentTask varchar references Tasks (Title),
    MaxXP      int not null
);

call load_csv('Tasks', 'tasks.csv', ',');

-- TABLES : CHECKS -----------------------------------------------------------------------------------------------------

drop table if exists Checks cascade;
create table Checks
(
    ID   serial primary key,
    Peer varchar not null references Peers (Nickname),
    Task varchar not null references Tasks (Title),
    Date DATE    not null
);

call load_csv('Checks', 'checks.csv', ',');
call fix_sequence('Checks', 'id');

-- TABLES : P2P --------------------------------------------------------------------------------------------------------

drop table if exists P2P cascade;
create table P2P
(
    ID           serial primary key,
    CheckID      int         not null references Checks (ID),
    CheckingPeer varchar     not null references Peers (Nickname),
    State        CheckStatus not null,
    Time         TIMESTAMP   not null
);

call load_csv('P2P', 'p2p.csv', ',');
call fix_sequence('P2P', 'id');

-- TABLES : VERTER -----------------------------------------------------------------------------------------------------

drop table if exists Verter cascade;
create table Verter
(
    ID      serial primary key,
    CheckID int         not null references Checks (ID),
    State   CheckStatus not null,
    Time    TIMESTAMP   not null
);

call load_csv('Verter', 'verter.csv', ',');
call fix_sequence('Verter', 'id');

-- TABLES : TRANSFERRED POINTS -----------------------------------------------------------------------------------------

drop table if exists TransferredPoints cascade;
create table TransferredPoints
(
    ID           serial primary key,
    CheckingPeer varchar not null references Peers (Nickname),
    CheckedPeer  varchar not null references Peers (Nickname),
    PointsAmount int     not null
);

call load_csv('TransferredPoints', 'transferred_points.csv', ',');

-- TABLES : FRIENDS ----------------------------------------------------------------------------------------------------

drop table if exists Friends cascade;
create table Friends
(
    ID    serial primary key,
    Peer1 varchar not null references Peers (Nickname),
    Peer2 varchar not null references Peers (Nickname)
);

call load_csv('Friends', 'friends.csv', ',');

-- TABLES : RECOMMENDATIONS --------------------------------------------------------------------------------------------

drop table if exists Recommendations cascade;
create table Recommendations
(
    ID              serial primary key,
    Peer            varchar not null references Peers (Nickname),
    RecommendedPeer varchar not null references Peers (Nickname)
);

call load_csv('Recommendations', 'recommendations.csv', ',');

-- TABLES : XP ---------------------------------------------------------------------------------------------------------

drop table if exists XP cascade;
create table XP
(
    ID       serial primary key,
    CheckID  int not null references Checks (ID),
    XPAmount int not null
);

call load_csv('XP', 'xp.csv', ',');

-- TABLES : TIME TRACKING ----------------------------------------------------------------------------------------------

drop table if exists TimeTracking cascade;
create table TimeTracking
(
    ID    serial primary key,
    Peer  varchar not null references Peers (Nickname),
    Date  DATE    not null,
    Time  TIME    not null,
    State int     not null
);

call load_csv('TimeTracking', 'time_tracking.csv', ',');

-- TRIGGERS : CHECKS ---------------------------------------------------------------------------------------------------

drop function if exists validate_checks_insertion;
create function validate_checks_insertion() returns TRIGGER as
$$
declare
    parentTask varchar;
begin
    select Tasks.ParentTask
    into parentTask
    from Tasks
    where Title = new.Task;


    if parentTask is not null and task_completed(new.Peer, parentTask) = false then
        return old;
    end if;

    return new;
end;
$$ language 'plpgsql';

drop trigger if exists checks_insertion on Checks;
create trigger checks_insertion
    before insert
    on Checks
    for each row
execute procedure validate_checks_insertion();