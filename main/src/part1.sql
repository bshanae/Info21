-- TYPES --------------------------------------------------------------------------------------------------------------

drop type if exists CheckStatus cascade;
create type CheckStatus as enum ( 'Start', 'Success', 'Failure' );

-- PROCEDURES ----------------------------------------------------------------------------------------------------------

drop procedure if exists read_csv;
create procedure read_csv(_tablename text, _filename text, _separator text) as
$$
declare
    dir constant varchar := '/Users/v.belchenko/Workspace/Info21/main/data/init/';
begin
    execute format('copy %s from ''%s'' delimiter ''%s'' csv header',
                   _tablename, dir || _filename, _separator);
end;
$$ language 'plpgsql';

drop procedure if exists fix_sequence;
create procedure fix_sequence(_tablename text, _sequence_column text) as
$$
declare
begin
    execute format('select setval(pg_get_serial_sequence(''%s'', ''%s''), (select max(%s) from %s))', _tablename,
                   _sequence_column, _sequence_column, _tablename);
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

drop function if exists task_completed(int);
create function task_completed(_check int) returns BOOLEAN as
$$
declare
begin
    if last_p2p_status(_check) is distinct from 'Success' then
        raise warning '[DEBUG] %: failed p2p', _check;
        return false;
    end if;

    if last_verter_status(_check) in ('Start', 'Failure') then
        raise warning '[DEBUG] %: failed verter', _check;
        return false;
    end if;

    return true;
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

    return task_completed(_last_check);
end;
$$ language 'plpgsql';

-- TABLES : PEERS ------------------------------------------------------------------------------------------------------

drop table if exists Peers cascade;
create table Peers
(
    Nickname varchar primary key,
    Birthday DATE
);

call read_csv('Peers', 'peers.csv', ',');

-- TABLES : TASKS ------------------------------------------------------------------------------------------------------

drop table if exists Tasks cascade;
create table Tasks
(
    Title      varchar primary key,
    ParentTask varchar references Tasks (Title),
    MaxXP      int not null
);

call read_csv('Tasks', 'tasks.csv', ',');

-- TABLES : CHECKS -----------------------------------------------------------------------------------------------------

drop table if exists Checks cascade;
create table Checks
(
    ID   serial primary key,
    Peer varchar not null references Peers (Nickname),
    Task varchar not null references Tasks (Title),
    Date DATE    not null
);

call read_csv('Checks', 'checks.csv', ',');
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

call read_csv('P2P', 'p2p.csv', ',');
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

call read_csv('Verter', 'verter.csv', ',');
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

call read_csv('TransferredPoints', 'transferred_points.csv', ',');
call fix_sequence('TransferredPoints', 'id');

-- TABLES : FRIENDS ----------------------------------------------------------------------------------------------------

drop table if exists Friends cascade;
create table Friends
(
    ID    serial primary key,
    Peer1 varchar not null references Peers (Nickname),
    Peer2 varchar not null references Peers (Nickname)
);

call read_csv('Friends', 'friends.csv', ',');
call fix_sequence('Friends', 'id');

-- TABLES : RECOMMENDATIONS --------------------------------------------------------------------------------------------

drop table if exists Recommendations cascade;
create table Recommendations
(
    ID              serial primary key,
    Peer            varchar not null references Peers (Nickname),
    RecommendedPeer varchar not null references Peers (Nickname)
);

call read_csv('Recommendations', 'recommendations.csv', ',');
call fix_sequence('Recommendations', 'id');

-- TABLES : XP ---------------------------------------------------------------------------------------------------------

drop table if exists XP cascade;
create table XP
(
    ID       serial primary key,
    CheckID  int unique not null references Checks (ID),
    XPAmount int        not null
);

call read_csv('XP', 'xp.csv', ',');
call fix_sequence('XP', 'id');

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

call read_csv('TimeTracking', 'time_tracking.csv', ',');
call fix_sequence('TimeTracking', 'id');

-- TRIGGERS : CHECKS ---------------------------------------------------------------------------------------------------

drop function if exists validate_checks_insertion;
create function validate_checks_insertion() returns TRIGGER as
$$
declare
    _parent_task varchar;
begin
    select Tasks.ParentTask
    into _parent_task
    from Tasks
    where Title = new.Task;

    if _parent_task is not null and task_completed(new.Peer, _parent_task) = false then
        raise warning 'Can''t insert into checks: required task "%" is not completed', _parent_task;
        return old;
    end if;

    return new;
end;
$$ language 'plpgsql';

drop trigger if exists before_checks_insertion on Checks;
create trigger before_checks_insertion
    before insert
    on Checks
    for each row
execute procedure validate_checks_insertion();

-- TRIGGERS : P2P ------------------------------------------------------------------------------------------------------

drop function if exists validate_p2p_insertion;
create function validate_p2p_insertion() returns TRIGGER as
$$
declare
    _is_last_start bool;
    _is_new_start  bool;
begin
    _is_last_start = last_p2p_status(new.CheckID) is not distinct from 'Start';
    _is_new_start = new.State = 'Start';

    if _is_last_start != _is_new_start then
        return new;
    else
        raise warning 'Can''t insert into p2p: unexpected state of previous check';
        return old;
    end if;
end;
$$ language 'plpgsql';

drop trigger if exists before_p2p_insertion on Checks;
create trigger before_p2p_insertion
    before insert
    on P2P
    for each row
execute procedure validate_p2p_insertion();

-- TRIGGERS : VERTER ---------------------------------------------------------------------------------------------------

drop function if exists validate_verter_insertion;
create function validate_verter_insertion() returns TRIGGER as
$$
declare
    _is_last_start bool;
    _is_new_start  bool;
begin
    _is_last_start = last_verter_status(new.CheckID) is not distinct from 'Start';
    _is_new_start = new.State = 'Start';

    if _is_last_start != _is_new_start then
        return new;
    else
        raise warning 'Can''t insert into verter: unexpected state of previous check';
        return old;
    end if;
end;
$$ language 'plpgsql';

drop trigger if exists before_verter_insertion on Checks;
create trigger before_verter_insertion
    before insert
    on Verter
    for each row
execute procedure validate_verter_insertion();

-- TRIGGERS : TIME TRACKING --------------------------------------------------------------------------------------------

drop function if exists validate_time_tracking_insertion;
create function validate_time_tracking_insertion() returns TRIGGER as
$$
declare
    _last_state int;
begin
    select TimeTracking.State
    from TimeTracking
    where TimeTracking.Peer = new.Peer
    order by id desc
    limit 1
    into _last_state;

    if _last_state = new.State then
        raise warning 'Can''t insert into time tracking: unexpected previous state';
        return old;
    end if;

    return new;
end;
$$ language 'plpgsql';

drop trigger if exists before_time_tracking_insertion on Checks;
create trigger before_time_tracking_insertion
    before insert
    on TimeTracking
    for each row
execute procedure validate_time_tracking_insertion();