
DELIMITER $$
CREATE OR REPLACE PROCEDURE p_SetGesamtPreis(IN inZahlungID int)
BEGIN
DECLARE noZahlungFound CONDITION for SQLSTATE '45000';
DECLARE vGesamtPreis decimal(6,2);
DECLARE vNutzungsDauer int;
DECLARE vMinutzenSatz int;

SELECT MINUTE(Nutzdauer) into vNutzungsDauer
from zahlung z join bestellung_eroller be on z.BestellERID = be.BestellERID
where z.ZahlungID = inZahlungID;

SELECT MinutenSatz into vMinutzenSatz
from zahlung z join Zahlungsmethode zm on z.ZMethodID = zm.ZMethodID
where z.ZahlungID = inZahlungID;

IF ROW_COUNT()=0
		then SIGNAL noZahlungFound
		set MESSAGE_TEXT = 'Es wurde keine Zahlung mit dieser ID gefunden!';
ELSE
	UPDATE Zahlung Set GesamtPreis = ((vNutzungsDauer * vMinutzenSatz) / 100)
	where ZahlungID = inZahlungID;

	END if;
END$$
DELIMITER ;

-- Test
call p_SetGesamtPreis(1); -- setzt GesamtPreis auf 5,2 € bei ZahlungsID 1
                          -- Fahrtdauer 26min - Preis App = 20Cent/Minute 20*26 = 520 Cent / 100 = 5,2€


DELIMITER $$
create or replace procedure p_SetAllGesamtPreis()
BEGIN
	DECLARE vID int;
	DECLARE vDone BOOLEAN DEFAULT FALSE;
	
	DECLARE vZahlungCur CURSOR
	FOR 
	select ZahlungID
	from Zahlung;

	DECLARE CONTINUE HANDLER FOR 1329 SET vDone = TRUE;
	
	OPEN vZahlungCur;
	
	FETCH vZahlungCur into vID;	
	
	setGesamtPreisLoop:LOOP
	call p_SetAllGesamtPreis(vID);	
	
		FETCH vZahlungCur into vID;
			IF vDone
				THEN LEAVE setGesamtPreisLoop;
			END IF;			
		END LOOP;
		CLOSE vZahlungCur;			
END $$
DELIMITER ;
-- Test
call p_SetAllGesamtPreis(); -- ok

