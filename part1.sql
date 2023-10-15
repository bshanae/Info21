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
    CheckID  int unique not null references Checks (ID),
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
    _parent_task varchar;
begin
    select Tasks.ParentTask
    into _parent_task
    from Tasks
    where Title = new.Task;

    if _parent_task is not null and task_completed(new.Peer, _parent_task) = false then
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

-- TRIGGERS : P2P ------------------------------------------------------------------------------------------------------

drop function if exists validate_p2p_insertion;
create function validate_p2p_insertion() returns TRIGGER as
$$
declare
    _is_last_start bool;
    _is_new_start bool;
begin
    _is_last_start = last_p2p_status(new.CheckID) is not distinct from 'Start';
    _is_new_start = new.State = 'Start';

    if _is_last_start != _is_new_start then
        return new;
    else
        return old;
    end if;
end;
$$ language 'plpgsql';

drop trigger if exists p2p_insertion on Checks;
create trigger p2p_insertion
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
    _is_new_start bool;
begin
    _is_last_start = last_verter_status(new.CheckID) is not distinct from 'Start';
    _is_new_start = new.State = 'Start';

    if _is_last_start != _is_new_start then
        return new;
    else
        return old;
    end if;
end;
$$ language 'plpgsql';

drop trigger if exists verter_insertion on Checks;
create trigger verter_insertion
    before insert
    on Verter
    for each row
execute procedure validate_verter_insertion();

-- TRIGGERS : XP -------------------------------------------------------------------------------------------------------

drop function if exists validate_xp_insertion;
create function validate_xp_insertion() returns TRIGGER as
$$
declare
    _peer varchar;
    _task varchar;
    _max_xp int;
begin
    select Checks.Peer
    into _peer
    from Checks
    where Checks.ID = new.CheckID;

    select Checks.Task
    into _task
    from Checks
    where Checks.ID = new.CheckID;

    if task_completed(_peer, _task) = false then
        return old;
    end if;

    select Tasks.MaxXP
    into _max_xp
    from Tasks
    where Tasks.Title = _task;

    if new.XPAmount > _max_xp then
        return old;
    end if;

    return new;
end;
$$ language 'plpgsql';

drop trigger if exists xp_insertion on Checks;
create trigger xp_insertion
    before insert
    on XP
    for each row
execute procedure validate_xp_insertion();