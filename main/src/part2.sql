-- TASK 1 --------------------------------------------------------------------------------------------------------------

drop procedure if exists register_p2p_check cascade;
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

-- TASK 3 --------------------------------------------------------------------------------------------------------------

drop function if exists process_p2p_insertion cascade;
create function process_p2p_insertion() returns TRIGGER as
$$
declare
    _checked_peer varchar;
begin
    if new.state = 'Start' then
        select peer
        from checks
        where id = new.checkid
        into _checked_peer;

        if _checked_peer is null then
            raise exception 'Checked peer not found';
        end if;

        insert into transferredpoints (checkingpeer, checkedpeer, pointsamount)
        values (new.checkingpeer, _checked_peer, 1);
    end if;

    return null;
end;
$$ language 'plpgsql';

drop trigger if exists after_p2p_insertion on Checks;
create trigger after_p2p_insertion
    after insert
    on p2p
    for each row
execute procedure process_p2p_insertion();

-- TASK 4 --------------------------------------------------------------------------------------------------------------

drop function if exists validate_xp_insertion cascade;
create function validate_xp_insertion() returns TRIGGER as
$$
declare
    _peer   varchar;
    _task   varchar;
    _max_xp int;
begin
    select Checks.Peer
    into _peer
    from Checks
    where Checks.ID = new.CheckID;

    select Checks.Task
    into _task
    from Checks
    where Checks.ID = new.CheckID;

    if task_completed(_peer, _task) = false then
        raise warning 'Can''t insert into xp: task is not completed';
        return old;
    end if;

    select Tasks.MaxXP
    into _max_xp
    from Tasks
    where Tasks.Title = _task;

    if new.XPAmount > _max_xp then
        raise warning 'Can''t insert into xp: invalid xp amount';
        return old;
    end if;

    return new;
end;
$$ language 'plpgsql';

drop trigger if exists before_xp_insertion on Checks cascade;
create trigger before_xp_insertion
    before insert
    on XP
    for each row
execute procedure validate_xp_insertion();