do language plpgsql
$$
    declare
        _crazy_peer varchar;
    begin
        select peer
        from find_crazy_peer(date '2023-02-15')
        into _crazy_peer;
        assert (_crazy_peer = 'bstroustrup');

        select peer
        from find_crazy_peer(date '2023-01-10')
        into _crazy_peer;
        assert (_crazy_peer is null);

        truncate table timetracking;

        select peer
        from find_crazy_peer(date '2023-02-15')
        into _crazy_peer;
        assert (_crazy_peer is null);

        rollback;
    end;
$$;