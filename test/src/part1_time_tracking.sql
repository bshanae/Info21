do language plpgsql
$$
    declare
        _r_count int;
    begin
        raise info 'test: ok';

        insert into TimeTracking (Peer, Date, Time, State)
        values ('edijkstra', date '2024-01-01', time '10:00', 1);

        insert into TimeTracking (Peer, Date, Time, State)
        values ('edijkstra', date '2024-01-01', time '10:05', 2);

        get diagnostics _r_count = row_count;
        assert (_r_count = 1);

        rollback;
    end;
$$;

do language plpgsql
$$
    declare
        _r_count int;
    begin
        raise info 'test: ko';

        insert into TimeTracking (Peer, Date, Time, State)
        values ('edijkstra', date '2024-01-01', time '10:00', 1);

        insert into TimeTracking (Peer, Date, Time, State)
        values ('edijkstra', date '2024-01-01', time '10:05', 1);

        get diagnostics _r_count = row_count;
        assert (_r_count = 0);

        rollback;
    end;
$$;
