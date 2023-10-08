do language plpgsql
$$
    declare
        _r_count int;
    begin
        raise info 'test: null -> start';

        insert into Verter (CheckID, State, Time)
        values (7, 'Start', timestamp '2024-01-01');

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
        raise info 'test: start -> start';

        insert into Verter (CheckID, State, Time)
        values (7, 'Start', timestamp '2024-01-01');

        insert into Verter (CheckID, State, Time)
        values (7, 'Start', timestamp '2024-01-02');

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

        insert into Verter (CheckID, State, Time)
        values (7, 'Start', timestamp '2024-01-01');

        insert into Verter (CheckID, State, Time)
        values (7, 'Success', timestamp '2024-01-02');

        get diagnostics _r_count = row_count;
        assert (_r_count = 1);

        rollback;
    end;
$$;