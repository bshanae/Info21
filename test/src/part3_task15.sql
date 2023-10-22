do language plpgsql
$$
    declare
    begin
        call enter_campus('bgates', timestamp '2024-01-01 10:00');
        call leave_campus('bgates', timestamp '2024-01-01 10:01');

        assert (exists(select *
                       from find_peers_who_came_before_time_t_at_least_n_times('12:00', 1)
                       where peer = 'bgates'));

        assert (not exists(select *
                           from find_peers_who_came_before_time_t_at_least_n_times('12:00', 2)
                           where peer = 'bgates'));

        call enter_campus('bgates', timestamp '2024-01-01 11:00');
        call leave_campus('bgates', timestamp '2024-01-01 11:01');

        assert (exists(select *
                       from find_peers_who_came_before_time_t_at_least_n_times('12:00', 2)
                       where peer = 'bgates'));

        rollback;
    end ;
$$;