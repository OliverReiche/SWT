

DELIMITER $$
CREATE OR REPLACE PROCEDURE p_SetLetzteZahlung(IN inKundeID int)
BEGIN
DECLARE noKundeFound CONDITION for SQLSTATE '45000';
DECLARE vNutzung date;

SELECT LetzteNutzung into vNutzung
from kunde
where KundeID=inKundeID;
IF ROW_COUNT()=0
		then SIGNAL noKundeFound
		set MESSAGE_TEXT = 'Es wurde kein Kunde mit dieser ID gefunden!';
ELSE
	UPDATE Kundenkonto Set LetzteZahlung = vNutzung
	where KKontoID=inKundeID;

	END if;
END$$
DELIMITER ;

--
-- Testcase
--
call p_SetLetzteZahlung(1); --> Setzt LetzteZahlung auf 2022-07-07


DELIMITER $$
create or replace procedure p_SetAllLetzteZahlung()
BEGIN
	DECLARE vID int;
	DECLARE vDone BOOLEAN DEFAULT FALSE;
	
	DECLARE vKundeCur CURSOR
	FOR 
	select KundeID
	from Kunde;

	DECLARE CONTINUE HANDLER FOR 1329 SET vDone = TRUE;
	
	OPEN vKundeCur;
	
	FETCH vKundeCur into vID;	
	
	setNutzungLoop:LOOP
	call p_SetLetzteZahlung(vID);	
	
		FETCH vKundeCur into vID;
			IF vDone
				THEN LEAVE setNutzungLoop;
			END IF;			
		END LOOP;
		CLOSE vKundeCur;			
END $$
DELIMITER ;

-- Test
call p_SetAllLetzteZahlung();