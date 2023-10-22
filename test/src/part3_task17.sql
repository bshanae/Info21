do language plpgsql
$$
    declare
    begin
        truncate timetracking cascade;

        call register_peer('p1', date '2000-01-01');
        call register_peer('p2', date '2000-02-01');
        call register_peer('p3', date '2000-03-01');

        call enter_and_leave_campus('p1', timestamp '2024-01-01 10:00');
        call enter_and_leave_campus('p1', timestamp '2024-01-01 11:00');
        call enter_and_leave_campus('p1', timestamp '2024-01-01 15:00');
        call enter_and_leave_campus('p2', timestamp '2024-01-01 10:00');

        call enter_and_leave_campus('p1', timestamp '2024-02-01 10:00');
        call enter_and_leave_campus('p2', timestamp '2024-02-01 09:00');
        call enter_and_leave_campus('p2', timestamp '2024-02-01 10:00');
        call enter_and_leave_campus('p2', timestamp '2024-02-01 11:00');

        call enter_and_leave_campus('p1', timestamp '2024-03-01 10:00');
        call enter_and_leave_campus('p2', timestamp '2024-03-01 09:00');
        call enter_and_leave_campus('p2', timestamp '2024-03-01 10:00');
        call enter_and_leave_campus('p2', timestamp '2024-03-01 11:00');
        call enter_and_leave_campus('p3', timestamp '2024-03-01 18:00');

        assert ((select earlyentries from find_percentage_of_early_entries() where month like 'January%') = 66);
        assert ((select earlyentries from find_percentage_of_early_entries() where month like 'February%') = 100);
        assert ((select earlyentries from find_percentage_of_early_entries() where month like 'March%') = 0);

        rollback;
    end ;
$$;