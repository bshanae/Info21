do language plpgsql
$$
    declare
        _points_amount int;
    begin
        truncate table transferredpoints;

        insert into transferredpoints (checkingpeer, checkedpeer, pointsamount)
        values ('edijkstra', 'ltorvalds', 2),
               ('bgates', 'bmartin', 1),
               ('bgates', 'bmartin', 1),
               ('bmartin', 'bgates', 1);

        select pointsamount
        from aggregate_transferred_points()
        where checkingpeer = 'edijkstra' and checkedpeer = 'ltorvalds'
        into _points_amount;
        assert (_points_amount = 2);

        select pointsamount
        from aggregate_transferred_points()
        where checkingpeer = 'ltorvalds' and checkedpeer = 'edijkstra'
        into _points_amount;
        assert (_points_amount = -2);

        select pointsamount
        from aggregate_transferred_points()
        where checkingpeer = 'bgates' and checkedpeer = 'bmartin'
        into _points_amount;
        assert (_points_amount = 1);

        select pointsamount
        from aggregate_transferred_points()
        where checkingpeer = 'bmartin' and checkedpeer = 'bgates'
        into _points_amount;
        assert (_points_amount = -1);

        rollback;
    end;
$$;