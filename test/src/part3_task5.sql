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

        select pointschange
        from get_points_change()
        where peer = 'edijkstra'
        into _points_amount;
        assert (_points_amount = 2);

        select pointschange
        from get_points_change()
        where peer = 'bgates'
        into _points_amount;
        assert (_points_amount = 1);

        select pointschange
        from get_points_change()
        where peer = 'bmartin'
        into _points_amount;
        assert (_points_amount = -1);

        rollback;
    end;
$$;