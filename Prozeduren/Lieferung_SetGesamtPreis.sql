
DELIMITER $$
CREATE OR REPLACE PROCEDURE p_SetGesamtPreisLieferung(IN inLieferungID int)
BEGIN
DECLARE noZahlungFound CONDITION for SQLSTATE '45000';
DECLARE vGesamtPreis decimal(6,2);
DECLARE vStückZahl int;
DECLARE vStückpreis decimal(6,2);

SELECT Anzahl into vStückZahl
from lieferung l join lieferdetails ld on l.lieferdetailsID = ld.lieferdetailsID
where l.LieferungID = inLieferungID;

SELECT Stueckpreis into vStückpreis 
from lieferung l join lieferdetails ld on l.lieferdetailsID = ld.lieferdetailsID
where l.LieferungID = inLieferungID;

IF ROW_COUNT()=0
		then SIGNAL noZahlungFound
		set MESSAGE_TEXT = 'Es wurde keine Lieferung mit dieser ID gefunden!';
ELSE
	UPDATE Lieferung Set GesamtPreis = (vStückZahl * vStückpreis)
	where LieferungID = inLieferungID;

	END if;
END$$
DELIMITER ;

-- Test
call p_SetGesamtPreisLieferung(1); 


DELIMITER $$
create or replace procedure p_SetAllGesamtPreisLieferung()
BEGIN
	DECLARE vID int;
	DECLARE vDone BOOLEAN DEFAULT FALSE;
	
	DECLARE vLieferungCur CURSOR
	FOR 
	select LieferungID
	from Lieferung;

	DECLARE CONTINUE HANDLER FOR 1329 SET vDone = TRUE;
	
	OPEN vLieferungCur;
	
	FETCH vLieferungCur into vID;	
	
	setGesamtPreisLoop:LOOP
	call p_SetGesamtPreisLieferung(vID);	
	
		FETCH vLieferungCur into vID;
			IF vDone
				THEN LEAVE setGesamtPreisLoop;
			END IF;			
		END LOOP;
		CLOSE vLieferungCur;			
END $$
DELIMITER ;
-- Test
call p_SetAllGesamtPreisLieferung(); -- ok

