drop procedure if exists register_p2p_check;
create procedure register_p2p_check(_checkee varchar,
                                    _checker varchar,
                                    _task varchar,
                                    _check_status CheckStatus,
                                    _time time) as
$$
declare
    _timestamp constant timestamp = (select current_date + _time as timestamp);
    _check              int;
begin
    if _check_status = 'Start' then
        insert into checks (peer, task, date)
        values (_checkee, _task, _timestamp)
        returning id into _check;
    else
        select id
        from checks
        where peer = _checkee and task = _task
        order by date desc
        limit 1
        into _check;

        if _check is null then
            raise exception 'check not found';
        end if;
    end if;

    insert into p2p (checkid, checkingpeer, state, time)
    values (_check, _checker, _check_status, _timestamp);
end;
$$ language 'plpgsql';