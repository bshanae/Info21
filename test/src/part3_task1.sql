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
        where peer1 = 'edijkstra' and peer2 = 'ltorvalds'
        into _points_amount;
        assert (_points_amount = 2);

        select pointsamount
        from aggregate_transferred_points()
        where peer1 = 'ltorvalds' and peer2 = 'edijkstra'
        into _points_amount;
        assert (_points_amount = -2);

        select pointsamount
        from aggregate_transferred_points()
        where peer1 = 'bgates' and peer2 = 'bmartin'
        into _points_amount;
        assert (_points_amount = 1);

        select pointsamount
        from aggregate_transferred_points()
        where peer1 = 'bmartin' and peer2 = 'bgates'
        into _points_amount;
        assert (_points_amount = -1);

        rollback;
    end;
$$;