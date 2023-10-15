do language plpgsql
$$
    declare
        _checkee constant varchar = 'edijkstra';
        _checker constant varchar = 'ltorvalds';
        _task    constant varchar = 'A1_Maze';
        _time    constant time    = time '10:00';
        _last_transfer    transferredpoints%rowtype;
    begin
        raise info 'test: point transfer';

        call register_p2p_check(_checkee, _checker, _task, 'Start', _time);

        select *
        from transferredpoints
        order by id desc
        limit 1
        into _last_transfer;

        assert (_last_transfer.checkingpeer = _checker);
        assert (_last_transfer.checkedpeer = _checkee);
        assert (_last_transfer.pointsamount = 1);

        rollback;
    end;
$$;