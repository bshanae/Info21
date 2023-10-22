-- TASK 1 --------------------------------------------------------------------------------------------------------------

drop function if exists aggregate_transferred_points cascade;
create function aggregate_transferred_points()
    returns table
            (
                Peer1        varchar,
                Peer2        varchar,
                PointsAmount int
            )
as
$$
declare
begin
    return query with reversed_points as (select checkedpeer as checkingpeer,
                                                 checkingpeer as checkedpeer,
                                                 transferredpoints.pointsamount * -1 as pointsamount
                                          from transferredpoints),
                      merged_points as (select rp.checkingpeer,
                                               rp.checkedpeer,
                                               rp.pointsamount
                                        from reversed_points as rp
                                        union all
                                        select tp.checkingpeer,
                                               tp.checkedpeer,
                                               tp.pointsamount
                                        from transferredpoints as tp)
                 select checkingpeer as Peer1,
                        checkedpeer as Peer2,
                        cast(sum(merged_points.pointsamount) as int) as PointsAmount
                 from merged_points
                 group by checkedpeer, checkingpeer;
end;
$$ language 'plpgsql';

-- TASK 3 --------------------------------------------------------------------------------------------------------------

drop function if exists find_crazy_peer cascade;
create function find_crazy_peer(_date date)
    returns table
            (
                Peer varchar
            )
as
$$
declare
begin
    return query with durations as (select tt1.peer,
                                           (select (tt2.date + tt2.time)
                                            from timetracking tt2
                                            where tt2.id > tt1.id and tt2.peer = tt1.peer and tt2.state = 2
                                            order by tt2.id
                                            limit 1) - (tt1.date + tt1.time) as duration
                                    from timetracking tt1
                                    where tt1.state = 1 and tt1.date = _date)
                 select d.peer
                 from durations d
                 where (select d.duration as days) > interval '1 day';
end;
$$ language 'plpgsql';

-- TASK 5 --------------------------------------------------------------------------------------------------------------

drop function if exists get_points_change cascade;
create function get_points_change()
    returns table
            (
                Peer         varchar,
                PointsChange int
            )
as
$$
declare
begin
    return query select Peer1 as Peer, cast(sum(PointsAmount) as int) as PointsChange
                 from aggregate_transferred_points()
                 group by Peer1;
end;
$$ language 'plpgsql';

-- TASK 7 --------------------------------------------------------------------------------------------------------------

drop function if exists get_peers_with_completed_task_block cascade;
create function get_peers_with_completed_task_block(_block varchar)
    returns table
            (
                Peer varchar
            )
as
$$
declare
    _last_block_task varchar;
begin
    with target_block_tasks as (select title, parenttask
                                from tasks
                                where starts_with(title, _block)),
         child_tasks as (select t1.title, t2.title as childtask
                         from target_block_tasks t1
                                  left join target_block_tasks t2 on t1.title = t2.parenttask)
    select title
    from child_tasks
    where childtask is null
    into _last_block_task;

    return query select nickname as Peer
                 from peers
                 where task_completed(nickname, _last_block_task);
end;
$$ language 'plpgsql';

-- TASK 9 --------------------------------------------------------------------------------------------------------------

drop function if exists block_started(varchar, varchar);
create function block_started(_peer varchar, _block varchar) returns BOOLEAN as
$$
declare
begin
    return (select count(*)
            from checks
            where peer = _peer and starts_with(task, _block)) > 0;
end;
$$ language 'plpgsql';

drop function if exists get_analytics_on_two_blocks cascade;
create function get_analytics_on_two_blocks(_block1 varchar, _block2 varchar)
    returns table
            (
                StartedBlock1      int,
                StartedBlock2      int,
                StartedBothBlocks  int,
                DidntStartAnyBlock int
            )
as
$$
declare
begin
    return query with blocks_started as (select nickname,
                                                cast(block_started(nickname, _block1) as int) as started1,
                                                cast(block_started(nickname, _block2) as int) as started2
                                         from peers)
                 select cast((sum(started1) * 100 / count(*)) as int) as StartedBlock1,
                        cast((sum(started2) * 100 / count(*)) as int) as StartedBlock2,
                        cast((sum(least(started1, started2)) * 100 / count(*)) as int) as StartedBothBlocks,
                        cast((sum(1 - greatest(started1, started2)) * 100 / count(*)) as int) as DidntStartAnyBlock
                 from blocks_started;
end;
$$ language 'plpgsql';

-- TASK 11 -------------------------------------------------------------------------------------------------------------

drop function if exists get_peers_who_completed_12_but_not_3 cascade;
create function get_peers_who_completed_12_but_not_3(_task1 varchar, _task2 varchar, _task3 varchar)
    returns table
            (
                Peer varchar
            )
as
$$
declare
begin
    return query select nickname as Peer
                 from peers
                 where task_completed(nickname, _task1)
                   and task_completed(nickname, _task2)
                   and not task_completed(nickname, _task3);
end;
$$ language 'plpgsql';

-- TASK 13 -------------------------------------------------------------------------------------------------------------

drop function if exists find_lucky_days cascade;
create function find_lucky_days(_n int)
    returns table
            (
                day date
            )
as
$$
declare
begin
    return query with checks_xp_info as (select checks.id as check_id,
                                                xp.xpamount as xp_actual,
                                                (select maxxp from tasks where tasks.title = checks.task) as xp_map
                                         from checks
                                                  left join xp on checks.id = xp.checkid),
                      checks_x_success as (select check_id,
                                                  (xp_actual::real / xp_map >= 0.8) as check_success
                                           from checks_xp_info),
                      checks_x_dates as (select checks.id as check_id,
                                                date((select p2p.time
                                                      from p2p
                                                      where p2p.checkid = checks.id
                                                      order by p2p.time
                                                      limit 1)) as check_date
                                         from checks),
                      checks_x_dates_x_success as (select checks_x_dates.check_id,
                                                          checks_x_dates.check_date,
                                                          checks_x_success.check_success
                                                   from checks_x_dates
                                                            left join checks_x_success using (check_id)),
                      checks_x_dates_x_status_count as (select check_date,
                                                               check_success,
                                                               count(*) as status_count
                                                        from (select checks_x_dates_x_success.*,
                                                                     (row_number() over (partition by check_date order by check_id) -
                                                                      row_number() over (partition by check_date, check_success order by check_id)) as sequence_id
                                                              from checks_x_dates_x_success) with_sequence_id
                                                        group by check_date, check_success, sequence_id),
                      checks_x_dates_x_max_success_count as (select check_date,
                                                                    max(status_count) as max_success_count
                                                             from checks_x_dates_x_status_count
                                                             where check_success = true
                                                             group by check_date)
                 select check_date as day
                 from checks_x_dates_x_max_success_count
                 where max_success_count >= _n;
end;
$$ language 'plpgsql';

-- TASK 15 -------------------------------------------------------------------------------------------------------------

drop function if exists find_peers_who_came_before_time_t_at_least_n_times cascade;
create function find_peers_who_came_before_time_t_at_least_n_times(_t time, _n int)
    returns table
            (
                Peer varchar
            )
as
$$
declare
begin
    return query select peers_x_enter_count.peer
                 from (select timetracking.peer, count(*) as enter_count
                       from timetracking
                       where state = 1 and time < _t
                       group by timetracking.peer) peers_x_enter_count
                 where peers_x_enter_count.enter_count >= _n;
end;
$$ language 'plpgsql';

-- TASK 17 -------------------------------------------------------------------------------------------------------------

drop function if exists find_percentage_of_early_entries cascade;
create function find_percentage_of_early_entries()
    returns table
            (
                Month        text,
                EarlyEntries int
            )
as
$$
declare
begin
    return query with entries_x_birth_month as (select timetracking.peer,
                                                       timetracking.date as enter_date,
                                                       extract(month from timetracking.date)::int as enter_month,
                                                       timetracking.time,
                                                       extract(month from peers.birthday) as birthday_month
                                                from timetracking
                                                         left join peers on timetracking.peer = peers.nickname
                                                where state = 1),
                      entries_info as (select enter_month,
                                              (time < time '12:00') as early
                                       from entries_x_birth_month
                                       where enter_month = birthday_month)
                 select to_char(make_date(1, enter_month, 1), 'Month') as month, (sum(early::int) * 100 / count(*))::int as EarlyEntries
                 from entries_info
                 group by enter_month;
end;
$$ language 'plpgsql';