do language plpgsql
$$
    declare
        _checkee constant varchar = 'edijkstra';
        _checker constant varchar = 'ltorvalds';
        _task    constant varchar = 'A1_Maze';
        _time    constant time    = time '10:00';
        _new_check        checks%rowtype;
        _new_p2p          p2p%rowtype;
    begin
        raise info 'test: p2p (start)';

        call register_p2p_check(_checkee, _checker, _task, 'Start', _time);

        select *
        from checks
        order by id desc
        into _new_check;

        assert (_new_check.date = (select current_date));
        assert (_new_check.task = _task);
        assert (_new_check.peer = _checkee);

        select *
        from p2p
        order by id desc
        into _new_p2p;

        assert (_new_p2p.checkid = _new_check.id);
        assert (_new_p2p.checkingpeer = _checker);
        assert (_new_p2p.state = 'Start');
        assert (_new_p2p.time = (select current_date + _time as timestamp));

        rollback;
    end;
$$;

do language plpgsql
$$
    declare
        _checkee     constant varchar = 'edijkstra';
        _checker     constant varchar = 'ltorvalds';
        _task        constant varchar = 'A1_Maze';
        _start_time  constant time    = time '10:00';
        _finish_time constant time    = time '10:10';
        _second_p2p           p2p%rowtype;
    begin
        raise info 'test: p2p (success)';

        call register_p2p_check(_checkee, _checker, _task, 'Start', _start_time);
        call register_p2p_check(_checkee, _checker, _task, 'Success', _finish_time);

        select *
        from p2p
        order by id desc
        into _second_p2p;

        assert (_second_p2p.checkingpeer = _checker);
        assert (_second_p2p.state = 'Success');
        assert (_second_p2p.time = (select current_date + _finish_time as timestamp));

        rollback;
    end;
$$;