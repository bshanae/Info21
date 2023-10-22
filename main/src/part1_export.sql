drop procedure if exists write_csv;
create procedure write_csv(_tablename text, _filename text, _separator text) as
$$
declare
    dir constant varchar := '/Users/v.belchenko/Workspace/Info21/main/data/temp/';
begin
    execute format('copy %s to ''%s'' delimiter ''%s'' csv header',
                   _tablename, dir || _filename, _separator);
end;
$$ language 'plpgsql';

call write_csv('Peers', 'peers.csv', ',');
call write_csv('Tasks', 'tasks.csv', ',');
call write_csv('Checks', 'checks.csv', ',');
call write_csv('P2P', 'p2p.csv', ',');
call write_csv('Verter', 'verter.csv', ',');
call write_csv('TransferredPoints', 'transferred_points.csv', ',');
call write_csv('Friends', 'friends.csv', ',');
call write_csv('Recommendations', 'recommendations.csv', ',');
call write_csv('XP', 'xp.csv', ',');
call write_csv('TimeTracking', 'time_tracking.csv', ',');