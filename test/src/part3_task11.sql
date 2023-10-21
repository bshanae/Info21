do language plpgsql
$$
    declare
        _peer varchar;
    begin
        select *
        from get_peers_who_completed_12_but_not_3('CPP1_s21_matrix+', 'CPP2_s21_containers', 'DO1_Linux')
        into _peer;
        assert (_peer = 'bmartin');

        select *
        from get_peers_who_completed_12_but_not_3('DO1_Linux', 'DO1_Linux', 'CPP1_s21_matrix+')
        into _peer;
        assert (_peer = 'ltorvalds');

        rollback;
    end;
$$;