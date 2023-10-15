do language plpgsql
$$
    declare
        _r_count int;
    begin
        raise info 'test: invalid check';

        insert into XP (CheckID, XPAmount)
        values (-1, 1);

        get diagnostics _r_count = row_count;
        assert (_r_count = 0);

        rollback;
    end;
$$;

do language plpgsql
$$
    declare
        _r_count int;
        _check_id int;
    begin
        raise info 'test: incomplete project';

        insert into Checks (Peer, Task, Date)
        values ('edijkstra', 'DO1_Linux', timestamp '2024-01-01')
        returning ID into _check_id;

        insert into XP (CheckID, XPAmount)
        values (_check_id, 1);

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
        raise info 'test: ok';

        insert into Checks (Peer, Task, Date)
        values ('edijkstra', 'DO1_Linux', timestamp '2024-01-01')
        returning ID into _check;

        insert into P2P (CheckID, CheckingPeer, State, Time)
        values (_check, 'bmartin', 'Start', timestamp '2024-01-02');

        insert into P2P (CheckID, CheckingPeer, State, Time)
        values (_check, 'bmartin', 'Success', timestamp '2024-01-03');

        insert into XP (CheckID, XPAmount)
        values (_check, 1);

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
        raise info 'test: too big xp value';

        insert into Checks (Peer, Task, Date)
        values ('edijkstra', 'DO1_Linux', timestamp '2024-01-01')
        returning ID into _check;

        insert into P2P (CheckID, CheckingPeer, State, Time)
        values (_check, 'bmartin', 'Start', timestamp '2024-01-02');

        insert into P2P (CheckID, CheckingPeer, State, Time)
        values (_check, 'bmartin', 'Success', timestamp '2024-01-03');

        insert into XP (CheckID, XPAmount)
        values (_check, 99999999);

        get diagnostics _r_count = row_count;
        assert (_r_count = 0);

        rollback;
    end;
$$;