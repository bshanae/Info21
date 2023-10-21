do language plpgsql
$$
    declare
        _peer  varchar;
        _check int;
    begin
        select get_peers_with_completed_task_block('CPP')
        into _peer;
        assert (_peer = 'bmartin');

--      complete A1

        insert into Checks (Peer, Task, Date)
        values ('bmartin', 'A1_Maze', timestamp '2024-01-01')
        returning ID into _check;

        insert into P2P (CheckID, CheckingPeer, State, Time)
        values (_check, 'bstroustrup', 'Start', timestamp '2024-01-02');

        insert into P2P (CheckID, CheckingPeer, State, Time)
        values (_check, 'bstroustrup', 'Success', timestamp '2024-01-03');

        select get_peers_with_completed_task_block('A')
        into _peer;
        assert (_peer is null);

--      complete A2

        insert into Checks (Peer, Task, Date)
        values ('bmartin', 'A2_SimpleNavigator_v1.0', timestamp '2024-02-01')
        returning ID into _check;

        insert into P2P (CheckID, CheckingPeer, State, Time)
        values (_check, 'bstroustrup', 'Start', timestamp '2024-02-02');

        insert into P2P (CheckID, CheckingPeer, State, Time)
        values (_check, 'bstroustrup', 'Success', timestamp '2024-02-03');

        select get_peers_with_completed_task_block('A')
        into _peer;
        assert (_peer = 'bmartin');

        rollback;
    end;
$$;