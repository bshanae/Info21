do language plpgsql
$$
    declare
    begin
        truncate checks cascade;
        truncate p2p cascade;
        truncate verter cascade;
        truncate xp cascade;

--      1: successful check

        call register_p2p_check('ltorvalds', 'bstroustrup', 'CPP1_s21_matrix+', 'Start', time '10:00');
        call register_p2p_check('ltorvalds', 'bstroustrup', 'CPP1_s21_matrix+', 'Success', time '10:01');
        call complete_project('ltorvalds', 'CPP1_s21_matrix+', 1.0);

        assert (exists(select day from find_lucky_days(1) where day = current_date));

--      2: unsuccessful check (p2p fail)

        call register_p2p_check('ltorvalds', 'bstroustrup', 'CPP2_s21_containers', 'Start', time '11:00');
        call register_p2p_check('ltorvalds', 'bstroustrup', 'CPP2_s21_containers', 'Failure', time '11:01');

        assert (exists(select day from find_lucky_days(1) where day = current_date));
        assert (not exists(select day from find_lucky_days(2) where day = current_date));

--      3: unsuccessful check (bad xp rate)

        call register_p2p_check('ltorvalds', 'bstroustrup', 'CPP2_s21_containers', 'Start', time '12:00');
        call register_p2p_check('ltorvalds', 'bstroustrup', 'CPP2_s21_containers', 'Failure', time '12:01');
        call complete_project('ltorvalds', 'CPP2_s21_containers', 0.5);

        assert (exists(select day from find_lucky_days(1) where day = current_date));
        assert (not exists(select day from find_lucky_days(2) where day = current_date));
        assert (not exists(select day from find_lucky_days(3) where day = current_date));

--      4: successful check

        call register_p2p_check('ltorvalds', 'bstroustrup', 'A1_Maze', 'Start', time '13:00');
        call register_p2p_check('ltorvalds', 'bstroustrup', 'A1_Maze', 'Success', time '13:01');
        call complete_project('ltorvalds', 'A1_Maze', 1.0);

        assert (exists(select day from find_lucky_days(1) where day = current_date));
        assert (not exists(select day from find_lucky_days(2) where day = current_date));
        assert (not exists(select day from find_lucky_days(3) where day = current_date));

--      5: successful check

        call register_p2p_check('ltorvalds', 'bstroustrup', 'A2_SimpleNavigator_v1.0', 'Start', time '14:00');
        call register_p2p_check('ltorvalds', 'bstroustrup', 'A2_SimpleNavigator_v1.0', 'Success', time '14:01');
        call complete_project('ltorvalds', 'A2_SimpleNavigator_v1.0', 1.0);

        assert (exists(select day from find_lucky_days(1) where day = current_date));
        assert (exists(select day from find_lucky_days(2) where day = current_date));
        assert (not exists(select day from find_lucky_days(3) where day = current_date));
        assert (not exists(select day from find_lucky_days(4) where day = current_date));

        rollback;
    end;
$$;