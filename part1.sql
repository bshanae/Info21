-- TYPES -------------------------------------------------------------------------------------------

DROP TYPE IF EXISTS CheckStatus CASCADE;
CREATE TYPE CheckStatus AS ENUM (
	'Start',
	'Success',
	'Failure'
);

DROP TYPE IF EXISTS UserNickname CASCADE;
CREATE DOMAIN UserNickname AS VARCHAR(30);

DROP TYPE IF EXISTS TaskName CASCADE;
CREATE DOMAIN TaskName AS VARCHAR(100);

-- PROCEDURES ---------------------------------------------------------------------------------------

DROP PROCEDURE IF EXISTS LoadCsv;
CREATE PROCEDURE LoadCsv(tablename text, filename text, separator text)
AS $$
DECLARE
BEGIN
	EXECUTE FORMAT(
    'COPY %s FROM ''%s'' DELIMITER ''%s'' NULL AS ''null''',
		tablename,
		filename,
		separator);
END;
$$
LANGUAGE 'plpgsql';

-- TABLES : PEERS -----------------------------------------------------------------------------------

DROP TABLE IF EXISTS Peers CASCADE;
CREATE TABLE Peers (
  Nickname UserNickname PRIMARY KEY,
  Birthday DATE
);

-- TABLES : TASKS -----------------------------------------------------------------------------------

DROP TABLE IF EXISTS Tasks CASCADE;
CREATE TABLE Tasks (
  Title TaskName PRIMARY KEY,
	ParentTask TaskName REFERENCES Tasks(Title),
  MaxXP INT NOT NULL
);

CALL LoadCsv('Tasks', '/Users/v.belchenko/Desktop/tasks.csv', ',');

-- TABLES : CHECKS ----------------------------------------------------------------------------------

DROP TABLE IF EXISTS Checks CASCADE;
CREATE TABLE Checks (
  ID SERIAL PRIMARY KEY,
  Peer UserNickname NOT NULL REFERENCES Peers(Nickname),
  Task TaskName NOT NULL REFERENCES Tasks(Title),
  Date DATE NOT NULL
);

-- TABLES : P2P -------------------------------------------------------------------------------------

DROP TABLE IF EXISTS P2P CASCADE;
CREATE TABLE P2P (
  ID SERIAL PRIMARY KEY,
  CheckID INT NOT NULL REFERENCES Checks(ID),
  CheckingPeer UserNickname NOT NULL REFERENCES Peers(Nickname),
  State CheckStatus NOT NULL,
  Time TIMESTAMP NOT NULL
);

-- TABLES : VERTER ----------------------------------------------------------------------------------

DROP TABLE IF EXISTS Verter CASCADE;
CREATE TABLE Verter (
  ID SERIAL PRIMARY KEY,
  CheckID INT NOT NULL REFERENCES Checks(ID),
  State CheckStatus NOT NULL,
  Time TIMESTAMP NOT NULL
);

-- TABLES : TRANSFERRED POINTS ----------------------------------------------------------------------

DROP TABLE IF EXISTS TransferredPoints CASCADE;
CREATE TABLE TransferredPoints (
  ID SERIAL PRIMARY KEY,
  CheckingPeer UserNickname NOT NULL REFERENCES Peers(Nickname),
  CheckedPeer UserNickname NOT NULL REFERENCES Peers(Nickname),
  PointsAmount INT NOT NULL
);

-- TABLES : FRIENDS ---------------------------------------------------------------------------------

DROP TABLE IF EXISTS Friends CASCADE;
CREATE TABLE Friends (
  ID SERIAL PRIMARY KEY,
  Peer1 UserNickname NOT NULL REFERENCES Peers(Nickname),
  Peer2 UserNickname NOT NULL REFERENCES Peers(Nickname)
);

-- TABLES : RECOMMENDATIONS -------------------------------------------------------------------------

DROP TABLE IF EXISTS Recommendations CASCADE;
CREATE TABLE Recommendations (
  ID SERIAL PRIMARY KEY,
  Peer UserNickname NOT NULL REFERENCES Peers(Nickname),
  RecommendedPeer UserNickname NOT NULL REFERENCES Peers(Nickname)
);

-- TABLES : XP --------------------------------------------------------------------------------------

DROP TABLE IF EXISTS XP CASCADE;
CREATE TABLE XP (
  ID SERIAL PRIMARY KEY,
  CheckID INT NOT NULL REFERENCES Checks(ID),
  XPAmount INT NOT NULL
);


-- TABLES : TIME TRACKING ---------------------------------------------------------------------------

DROP TABLE IF EXISTS TimeTracking CASCADE;
CREATE TABLE TimeTracking (
  ID SERIAL PRIMARY KEY,
  Peer UserNickname NOT NULL REFERENCES Peers(Nickname),
  Date DATE NOT NULL,
  Time TIME NOT NULL,
	State INT NOT NULL
);

