do language plpgsql
$$
    declare
        _r_count int;
    begin
        raise info 'test: null -> start';

        insert into P2P (CheckID, CheckingPeer, State, Time)
        values (7, 'edijkstra', 'Start', timestamp '2024-01-01');

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
        raise info 'test: null -> success';

        insert into P2P (CheckID, CheckingPeer, State, Time)
        values (7, 'edijkstra', 'Success', timestamp '2024-01-01');

        get diagnostics _r_count = row_count;
        assert (_r_count = 0);

        rollback;
    end;
$$;

do language plpgsql
$$
    declare
        _r_count int;
    begin
        raise info 'test: null -> failure';

        insert into P2P (CheckID, CheckingPeer, State, Time)
        values (7, 'edijkstra', 'Failure', timestamp '2024-01-01');

        get diagnostics _r_count = row_count;
        assert (_r_count = 0);

        rollback;
    end;
$$;

do language plpgsql
$$
    declare
        _r_count int;
    begin
        raise info 'test: start -> start';

        insert into P2P (CheckID, CheckingPeer, State, Time)
        values (7, 'edijkstra', 'Start', timestamp '2024-01-01');

        insert into P2P (CheckID, CheckingPeer, State, Time)
        values (7, 'edijkstra', 'Start', timestamp '2024-01-02');

        get diagnostics _r_count = row_count;
        assert (_r_count = 0);

        rollback;
    end;
$$;

do language plpgsql
$$
    declare
        _r_count int;
    begin
        raise info 'test: start -> success';

        insert into P2P (CheckID, CheckingPeer, State, Time)
        values (7, 'edijkstra', 'Start', timestamp '2024-01-01');

        insert into P2P (CheckID, CheckingPeer, State, Time)
        values (7, 'edijkstra', 'Success', timestamp '2024-01-02');

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
        raise info 'test: success -> success';

        insert into P2P (CheckID, CheckingPeer, State, Time)
        values (7, 'edijkstra', 'Start', timestamp '2024-01-01');

        insert into P2P (CheckID, CheckingPeer, State, Time)
        values (7, 'edijkstra', 'Success', timestamp '2024-01-02');

        insert into P2P (CheckID, CheckingPeer, State, Time)
        values (7, 'edijkstra', 'Success', timestamp '2024-01-03');

        get diagnostics _r_count = row_count;
        assert (_r_count = 0);

        rollback;
    end;
$$;