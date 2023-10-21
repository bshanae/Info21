do language plpgsql
$$
    declare
        _started_block1        int;
        _started_block2        int;
        _started_both_blocks   int;
        _didnt_start_any_block int;
    begin
        select startedblock1, startedblock2, startedbothblocks, didntstartanyblock
        from get_analytics_on_two_blocks('CPP', 'A')
        into _started_block1, _started_block2, _started_both_blocks, _didnt_start_any_block;
        assert (_started_block1 = 60);
        assert (_started_block2 = 20);
        assert (_started_both_blocks = 20);
        assert (_didnt_start_any_block = 40);

        select startedblock1, startedblock2, startedbothblocks, didntstartanyblock
        from get_analytics_on_two_blocks('DO', 'A')
        into _started_block1, _started_block2, _started_both_blocks, _didnt_start_any_block;
        assert (_started_block1 = 40);
        assert (_started_block2 = 20);
        assert (_started_both_blocks = 0);
        assert (_didnt_start_any_block = 40);

        rollback;
    end;
$$;