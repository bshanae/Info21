-- TASK 1 --------------------------------------------------------------------------------------------------------------

drop function if exists aggregate_transferred_points cascade;
create function aggregate_transferred_points()
    returns table
            (
                CheckingPeer varchar,
                CheckedPeer  varchar,
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
                 select merged_points.checkingpeer,
                        merged_points.checkedpeer,
                        cast(sum(merged_points.pointsamount) as int)
                 from merged_points
                 group by merged_points.checkedpeer, merged_points.checkingpeer;
end;
$$ language 'plpgsql';