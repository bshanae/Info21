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
    return query with recursive
                     reversed_points as (select transferredpoints.checkedpeer       as checkingpeer,
                                                transferredpoints.checkingpeer      as checkedpeer,
                                                transferredpoints.pointsamount * -1 as pointsamount
                                         from transferredpoints),
                     merged_points as (select reversed_points.checkingpeer,
                                              reversed_points.checkedpeer,
                                              reversed_points.pointsamount
                                       from reversed_points
                                       union all
                                       select transferredpoints.checkingpeer,
                                              transferredpoints.checkedpeer,
                                              transferredpoints.pointsamount
                                       from transferredpoints)
                 select merged_points.checkingpeer                   as Peer1,
                        merged_points.checkedpeer                    as Peer2,
                        cast(sum(merged_points.pointsamount) as int) as PointsAmount
                 from merged_points
                 group by merged_points.checkedpeer, merged_points.checkingpeer;
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