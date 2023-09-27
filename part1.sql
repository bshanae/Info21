-- TYPES --------------------------------------------------------------------------------------------------------------

drop type if exists CheckStatus cascade;
create type CheckStatus as ENUM ( 'Start', 'Success', 'Failure' );

drop type if exists UserNickname cascade;
create domain UserNickname as VARCHAR(30);

drop type if exists TaskName cascade;
create domain TaskName as VARCHAR(100);

-- PROCEDURES ----------------------------------------------------------------------------------------------------------

drop procedure if exists LoadCsv;
create procedure LoadCsv(tablename text, filename text, separator text) as
$$
declare
    dir constant varchar := '/Users/v.belchenko/Workspace/Info21/data/';
begin
    execute format('COPY %s FROM ''%s'' DELIMITER ''%s'' CSV HEADER', tablename, dir || filename, separator);
end;
$$ language 'plpgsql';

-- TABLES : PEERS ------------------------------------------------------------------------------------------------------

drop table if exists Peers cascade;
create table Peers
(
    Nickname UserNickname primary key,
    Birthday DATE
);

call LoadCsv('Peers', 'peers.csv', ',');

-- TABLES : TASKS ------------------------------------------------------------------------------------------------------

drop table if exists Tasks cascade;
create table Tasks
(
    Title      TaskName primary key,
    ParentTask TaskName references Tasks (Title),
    MaxXP      INT not null
);

call LoadCsv('Tasks', 'tasks.csv', ',');

-- TABLES : CHECKS -----------------------------------------------------------------------------------------------------

drop table if exists Checks cascade;
create table Checks
(
    ID   SERIAL primary key,
    Peer UserNickname not null references Peers (Nickname),
    Task TaskName     not null references Tasks (Title),
    Date DATE         not null
);

call LoadCsv('Checks', 'checks.csv', ',');

-- TABLES : P2P --------------------------------------------------------------------------------------------------------

drop table if exists P2P cascade;
create table P2P
(
    ID           SERIAL primary key,
    CheckID      INT          not null references Checks (ID),
    CheckingPeer UserNickname not null references Peers (Nickname),
    State        CheckStatus  not null,
    Time         TIMESTAMP    not null
);

call LoadCsv('P2P', 'p2p.csv', ',');

-- TABLES : VERTER -----------------------------------------------------------------------------------------------------

drop table if exists Verter cascade;
create table Verter
(
    ID      SERIAL primary key,
    CheckID INT         not null references Checks (ID),
    State   CheckStatus not null,
    Time    TIMESTAMP   not null
);

call LoadCsv('Verter', 'verter.csv', ',');

-- TABLES : TRANSFERRED POINTS -----------------------------------------------------------------------------------------

drop table if exists TransferredPoints cascade;
create table TransferredPoints
(
    ID           SERIAL primary key,
    CheckingPeer UserNickname not null references Peers (Nickname),
    CheckedPeer  UserNickname not null references Peers (Nickname),
    PointsAmount INT          not null
);

call LoadCsv('TransferredPoints', 'transferred_points.csv', ',');

-- TABLES : FRIENDS ----------------------------------------------------------------------------------------------------

drop table if exists Friends cascade;
create table Friends
(
    ID    SERIAL primary key,
    Peer1 UserNickname not null references Peers (Nickname),
    Peer2 UserNickname not null references Peers (Nickname)
);

call LoadCsv('Friends', 'friends.csv', ',');

-- TABLES : RECOMMENDATIONS --------------------------------------------------------------------------------------------

drop table if exists Recommendations cascade;
create table Recommendations
(
    ID              SERIAL primary key,
    Peer            UserNickname not null references Peers (Nickname),
    RecommendedPeer UserNickname not null references Peers (Nickname)
);

call LoadCsv('Recommendations', 'recommendations.csv', ',');

-- TABLES : XP ---------------------------------------------------------------------------------------------------------

drop table if exists XP cascade;
create table XP
(
    ID       SERIAL primary key,
    CheckID  INT not null references Checks (ID),
    XPAmount INT not null
);

call LoadCsv('XP', 'xp.csv', ',');

-- TABLES : TIME TRACKING ----------------------------------------------------------------------------------------------

drop table if exists TimeTracking cascade;
create table TimeTracking
(
    ID    SERIAL primary key,
    Peer  UserNickname not null references Peers (Nickname),
    Date  DATE         not null,
    Time  TIME         not null,
    State INT          not null
);

call LoadCsv('TimeTracking', 'time_tracking.csv', ',');