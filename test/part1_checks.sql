do language plpgsql
$$
    declare
        _r_count int;
    begin
        raise info 'test: new check';

        insert into Checks (Peer, Task, Date)
        values ('edijkstra', 'DO1_Linux', date '2024-01-01');

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
        raise info 'test: no previous project';

        insert into Checks (Peer, Task, Date)
        values ('edijkstra', 'DO2_Linux_Network', date '2024-01-02');

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
        raise info 'test: no p2p';

        insert into Checks (Peer, Task, Date)
        values ('edijkstra', 'DO1_Linux', date '2024-01-01');

        insert into Checks (Peer, Task, Date)
        values ('edijkstra', 'DO2_Linux_Network', date '2024-01-02');

        get diagnostics _r_count = row_count;
        assert (_r_count = 0);

        rollback;
    end;
$$;

do language plpgsql
$$
    declare
        _r_count int;
        _check   int;
    begin
        raise info 'test: unifished p2p';

        insert into Checks (Peer, Task, Date)
        values ('edijkstra', 'DO1_Linux', date '2024-01-01')
        returning ID into _check;

        insert into P2P (CheckID, CheckingPeer, State, Time)
        values (_check, 'bmartin', 'Start', date '2024-01-02');

        insert into Checks (Peer, Task, Date)
        values ('edijkstra', 'DO2_Linux_Network', date '2024-01-03');

        get diagnostics _r_count = row_count;
        assert (_r_count = 0);

        rollback;
    end;
$$;

do language plpgsql
$$
    declare
        _r_count int;
        _check   int;
    begin
        raise info 'test: failed p2p';

        insert into Checks (Peer, Task, Date)
        values ('edijkstra', 'DO1_Linux', timestamp '2024-01-01')
        returning ID into _check;

        insert into P2P (CheckID, CheckingPeer, State, Time)
        values (_check, 'bmartin', 'Start', timestamp '2024-01-02');

        insert into P2P (CheckID, CheckingPeer, State, Time)
        values (_check, 'bmartin', 'Failure', timestamp '2024-01-03');

        insert into Checks (Peer, Task, Date)
        values ('edijkstra', 'DO2_Linux_Network', timestamp '2024-01-04');

        get diagnostics _r_count = row_count;
        assert (_r_count = 0);

        rollback;
    end;
$$;

do language plpgsql
$$
    declare
        _r_count int;
        _check   int;
    begin
        raise info 'test: unfinished verter';

        insert into Checks (Peer, Task, Date)
        values ('edijkstra', 'DO1_Linux', timestamp '2024-01-01')
        returning ID into _check;

        insert into P2P (CheckID, CheckingPeer, State, Time)
        values (_check, 'bmartin', 'Start', timestamp '2024-01-02');

        insert into P2P (CheckID, CheckingPeer, State, Time)
        values (_check, 'bmartin', 'Success', timestamp '2024-01-03');

        insert into Verter (CheckID, State, Time)
        values (_check, 'Start', timestamp '2024-01-04');

        insert into Checks (Peer, Task, Date)
        values ('edijkstra', 'DO2_Linux_Network', timestamp '2024-01-05');

        get diagnostics _r_count = row_count;
        assert (_r_count = 0);

        rollback;
    end;
$$;

do language plpgsql
$$
    declare
        _r_count int;
        _check   int;
    begin
        raise info 'test: failed verter';

        insert into Checks (Peer, Task, Date)
        values ('edijkstra', 'DO1_Linux', timestamp '2024-01-01')
        returning ID into _check;

        insert into P2P (CheckID, CheckingPeer, State, Time)
        values (_check, 'bmartin', 'Start', timestamp '2024-01-02');

        insert into P2P (CheckID, CheckingPeer, State, Time)
        values (_check, 'bmartin', 'Success', timestamp '2024-01-03');

        insert into Verter (CheckID, State, Time)
        values (_check, 'Start', timestamp '2024-01-04');

        insert into Verter (CheckID, State, Time)
        values (_check, 'Failure', timestamp '2024-01-05');

        insert into Checks (Peer, Task, Date)
        values ('edijkstra', 'DO2_Linux_Network', timestamp '2024-01-06');

        get diagnostics _r_count = row_count;
        assert (_r_count = 0);

        rollback;
    end;
$$;

do language plpgsql
$$
    declare
        _r_count int;
        _check   int;
    begin
        raise info 'test: ok (p2p)';

        insert into Checks (Peer, Task, Date)
        values ('edijkstra', 'DO1_Linux', timestamp '2024-01-01')
        returning ID into _check;

        insert into P2P (CheckID, CheckingPeer, State, Time)
        values (_check, 'bmartin', 'Start', timestamp '2024-01-02');

        insert into P2P (CheckID, CheckingPeer, State, Time)
        values (_check, 'bmartin', 'Success', timestamp '2024-01-03');

        insert into Checks (Peer, Task, Date)
        values ('edijkstra', 'DO2_Linux_Network', timestamp '2024-01-06');

        get diagnostics _r_count = row_count;
        assert (_r_count = 1);

        rollback;
    end;
$$;

do language plpgsql
$$
    declare
        _r_count int;
        _check   int;
    begin
        raise info 'test: ok (p2p + verter)';

        insert into Checks (Peer, Task, Date)
        values ('edijkstra', 'DO1_Linux', timestamp '2024-01-01')
        returning ID into _check;

        insert into P2P (CheckID, CheckingPeer, State, Time)
        values (_check, 'bmartin', 'Start', timestamp '2024-01-02');

        insert into P2P (CheckID, CheckingPeer, State, Time)
        values (_check, 'bmartin', 'Success', timestamp '2024-01-03');

        insert into Verter (CheckID, State, Time)
        values (_check, 'Start', timestamp '2024-01-04');

        insert into Verter (CheckID, State, Time)
        values (_check, 'Success', timestamp '2024-01-05');

        insert into Checks (Peer, Task, Date)
        values ('edijkstra', 'DO2_Linux_Network', timestamp '2024-01-06');

        get diagnostics _r_count = row_count;
        assert (_r_count = 1);

        rollback;
    end;
$$;