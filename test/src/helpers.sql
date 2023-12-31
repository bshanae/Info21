drop procedure if exists register_peer cascade;
create procedure register_peer(_nickname varchar, _birthday date) as
$$
declare
begin
    insert into peers(nickname, birthday)
    values (_nickname, _birthday);
end;
$$ language 'plpgsql';

drop procedure if exists complete_project cascade;
create procedure complete_project(_peer varchar, _task varchar, _xp_rate real) as
$$
declare
    _check  int;
    _max_xp int;
begin
    select id
    from checks
    where peer = _peer and task = _task
    order by date desc
    limit 1
    into _check;

    if _check is null then
        raise exception 'check not found';
    end if;

    select maxxp
    from tasks
    where title = _task
    into _max_xp;

    insert into xp (checkid, xpamount)
    values (_check, (_max_xp * _xp_rate)::int);
end;
$$ language 'plpgsql';

drop procedure if exists enter_campus cascade;
create procedure enter_campus(_peer varchar, _time timestamp) as
$$
declare
begin
    insert into timetracking(peer, date, time, state)
    values (_peer, date(_time), _time::time, 1);
end;
$$ language 'plpgsql';

drop procedure if exists leave_campus cascade;
create procedure leave_campus(_peer varchar, _time timestamp) as
$$
declare
begin
    insert into timetracking(peer, date, time, state)
    values (_peer, date(_time), _time::time, 2);
end;
$$ language 'plpgsql';

drop procedure if exists enter_and_leave_campus cascade;
create procedure enter_and_leave_campus(_peer varchar, _enter_time timestamp) as
$$
declare
begin
    call enter_campus(_peer, _enter_time);
    call leave_campus(_peer, _enter_time + interval '00:10');
end;
$$ language 'plpgsql';