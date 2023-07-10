-- 
-- Datenbank: ew_db 
-- erstellt am 05.07.2023
-- durch Jakob Roch Projektgruppe C5
-- Datenbank mit Tabellen für EcoWheels Verwaltungssystem



/********************************************************************************************************/
-- /F 40.1.2.11./

DELIMITER $$
create or replace function fn_GetRollerStandort (inRollerID int)
returns int
BEGIN
    declare outStandortID int;

    set outStandortID = (select standortID from EROLLER where ERollerID = inRollerID);

    return outStandortID;
end $$
DELIMITER ;

-- SELECT fn_GetRollerStandort (1);

/********************************************************************************************************/
-- /F 40.1.2.9./
-- Uberprüft ob ein E-Roller von einem Mitarbeiter eingesammelt wurde
-- Wenn ein Haltepunkt des vorhanden ist gib die Fuktion diesen zurück sonst -1

DELIMITER $$
create or replace function fn_CheckRollerStatusH (inRollerID int)
returns int
BEGIN
    declare outHaltepunkt int;

    select HaltepunktID into outHaltepunkt from ERoller where ERollerID = inRollerID;

    return IFNUll(outHaltepunkt,-1);
end $$
DELIMITER ;

-- SELECT fn_CheckRollerStatusH(1);

/********************************************************************************************************/
-- /F 40.1.2.8./

DELIMITER $$
create or replace function fn_CalculateFahrtdauer (inFahrtenbuchID int)
returns time
BEGIN
    declare outFahrtdauer time;

    select from_unixtime(((UNIX_TIMESTAMP(Fahrtstart) - UNIX_TIMESTAMP(Fahrtende)) * (-1)), '%h:%i:%s')
    into outFahrtdauer 
    from fahrtenbuch 
    where FahrtenbuchID = inFahrtenbuchID;

    return outFahrtdauer;
end $$
DELIMITER ;

-- SELECT fn_CalculateFahrtdauer(1)

/********************************************************************************************************/
-- /F 40.1.2.7./

DELIMITER $$
create or replace function fn_GetMitarbeiterStandort (inMitarbeiterID int)
returns int
BEGIN
    declare outMStandort int;

    select ArbeitsortID into outMStandort from Mitarbeiter where MitarbeiterID = inMitarbeiterID;

    return outMStandort;
end $$
DELIMITER ;

-- SELECT fn_GetMitarbeiterStandort(1)

/********************************************************************************************************/
-- /F 40.1.2.4.
-- inBuisnessEmail ist halt der einzige Unique key um eine Mitarbeiter Auserhalt von Seiner ID oder von Zusammegesetzten werten zu indentifizieren
-- wenn nicht vorhanden gib -1 zurück

DELIMITER $$
create or replace function fn_GetMitarbeiterID (inBusinessEmail varchar(100))
returns int
BEGIN
    declare outMitarbeiterID int;
        
    select MitarbeiterID into outMitarbeiterID from Mitarbeiter where lower(BusinessEmail) = lower(inBusinessEmail);

    return IFNUll(outMitarbeiterID,-1);
end $$
DELIMITER ;

-- SELECT fn_GetMitarbeiterID('y.koch@EcoWheels.com')
-- retruns 25

/********************************************************************************************************/
-- /F 40.1.2.6./

DELIMITER $$
create or replace function fn_GetFirmenwagenStandort (inFirmenwagenID int)
returns int
BEGIN
    declare outFStandort int;

    select standortID into outFStandort 
    from Lager 
    join fuhrpark on fuhrpark.LagerID = lager.LagerID 
    where FirmenwagenID = inFirmenwagenID;

    return outFStandort;
end $$
DELIMITER ;

-- SELECT fn_GetFirmenwagenStandort(1)

/********************************************************************************************************/
-- /F 40.1.2.5./

DELIMITER $$
create or replace function fn_CheckIntegritaet(inFirmenwagenID int, inMitarbeiterID int)
returns tinyint(1)
begin
    declare vIntegritaet tinyint(1);

    DECLARE AbbruchJobName CONDITION FOR SQLSTATE '45000';
    DECLARE AbbruchMitarbeiterStandort CONDITION FOR SQLSTATE '45000';
    DECLARE NichtAbgeschlossenerEintrag CONDITION FOR SQLSTATE '45000';
    DECLARE AutoIstNochInBenutzung CONDITION FOR SQLSTATE '45000';

    if fn_GetFirmenwagenStandort(inFirmenwagenID) = fn_GetMitarbeiterStandort(inMitarbeiterID)
        then

        if STRCMP((select JobName from mitarbeiter where MitarbeiterID = inMitarbeiterID), 'KFZ-WH') = 0
            then

                if IFNUll((select Fahrtende from Fahrtenbuch where MitarbeiterID = inMitarbeiterID having max(Fahrtstart) < Fahrtende),-1) != -1
                    then

                        if IFNUll((select Fahrtende from Fahrtenbuch where FirmenwagenID = inFirmenwagenID having max(Fahrtstart) < Fahrtende),-1) != -1
                            then
                            set vIntegritaet = 1;
                        
                        else
                            SIGNAL AutoIstNochInBenutzung SET MESSAGE_TEXT ='Das Ausgewealte Firmenfahrzeug ist noch in Benutztung';
                        end if;

                else
                    SIGNAL NichtAbgeschlossenerEintrag SET MESSAGE_TEXT ='Mitarbeiter hat noch einen nicht abgeschlossen Fahrtenbucheintrag';
                end if; 

        else
            SIGNAL AbbruchJobName SET MESSAGE_TEXT = 'Nicht passender JobName';
        end if;

    else
        SIGNAL AbbruchMitarbeiterStandort SET MESSAGE_TEXT = 'Mitarbeiter und Lager/Fahrzeug sind nicht an Selben Standort/Region';
    end if;


    return IFNUll(vIntegritaet, -1);
end $$
DELIMITER ;



-- SELECT fn_CheckIntegritaet(1 , 1)
-- > -1 nicht passender JobName
-- SELECT fn_CheckIntegritaet(1 , 15)
-- > -1 nicht zusammen passender Standort
-- SELECT fn_CheckIntegritaet(1 , 9)
-- > 1 alles geht
-- SELECT fn_CheckIntegritaet(17 , 25)
-- wenn neu erstell und nicht abgeschlossen geht nicht
-- SELECT fn_CheckIntegritaet(17 , 43)
-- geht nich weil Fahrzeug von Arbeiter 25 benutzt

/********************************************************************************************************/
/********************************************************************************************************/
/********************************************************************************************************/
-- /F 40.1.2.1./

DELIMITER $$
create or replace procedure p_CreateFahrtenbuch
(inFirmenwagenID int, inMitarbeiterEmail varchar(100))
begin
    declare vMitarbeiterID int;
    
    declare MitarbeiterGibtEsNicht CONDITION FOR SQLSTATE '45000';

    set vMitarbeiterID = (select fn_GetMitarbeiterID(inMitarbeiterEmail));

    if vMitarbeiterID = -1
        then
        SIGNAL MitarbeiterGibtEsNicht SET MESSAGE_TEXT = 'Kein Mitarbeiter unter dieser E-Mail zu finden';
    end IF;

select fn_CheckIntegritaet(inFirmenwagenID ,vMitarbeiterID);


Insert Into fahrtenbuch(Fahrtstart, FirmenwagenID, MitarbeiterID)
values (CURRENT_TIMESTAMP(), inFirmenwagenID, vMitarbeiterID);

end$$
DELIMITER ;

-- CALL p_CreateFahrtenbuch(11,'y.koch@EcoWheels.com')
-- geht nicht Intigrität
-- CALL p_CreateFahrtenbuch(17,'y.koch@yahoomail.com')
-- geht nicht email unbekannt
-- CALL p_CreateFahrtenbuch(17,'y.koch@EcoWheelz.com')
-- geht nicht schreibfehler
-- CALL p_CreateFahrtenbuch(17,'X.koch@EcoWheels.com')
-- geht nicht kein solcher Mitarbeiter
-- CALL p_CreateFahrtenbuch(17,'y.koch@EcoWheels.com')
-- geht
-- CALL p_CreateFahrtenbuch(17, 'y.koch@EcoWheels.com')
-- geht nicht Fahrtenbucheintrag noch nicht Abgeschlossen
-- CALL p_CreateFahrtenbuch(17, 'r.kaiser@EcoWheels.com')
-- geht nicht weil Fahrzeug noch in Benutzung

-- warum geht das nur über die Konsole bzw als SQL Begehl und nicht die Abgespeicherte Routine????
-- also es geht halt trotzdem nicht spuckt aber keine Fehler aus

/********************************************************************************************************/
-- /F 40.1.2.2./

DELIMITER $$
create or replace procedure p_FinishFahrtenbuch
(inFahrtenbuchID int)
begin

    declare SchonBeendet CONDITION FOR SQLSTATE '45000';
    declare vHilfMir int;


    if IFNUll((select Fahrtdauer from fahrtenbuch where FahrtenbuchID = inFahrtenbuchID), -1) != -1
        then
        SIGNAL SchonBeendet SET MESSAGE_TEXT = 'Dieser Fahrtenbucheintrag ist schon Abgeschlossen';
    end if;


    update fahrtenbuch
    set Fahrtende = CURRENT_TIMESTAMP()
    where FahrtenbuchID = inFahrtenbuchID;

    update fahrtenbuch
    set Fahrtdauer = (select fn_CalculateFahrtdauer(inFahrtenbuchID))
    where FahrtenbuchID = inFahrtenbuchID;


    select count(HaltepunktID) into vHilfMir from ERoller 
    where HaltepunktID 
    between 
    (select min(HaltepunktID) from Haltepunkt where FahrtenbuchID = inFahrtenbuchID) 
    and 
    (select max(HaltepunktID) from Haltepunkt where FahrtenbuchID = inFahrtenbuchID);

    update fahrtenbuch
    set RollerEingesamelt   = vHilfMir
    where FahrtenbuchID     = inFahrtenbuchID;

	CALL p_RollerInLager(inFahrtenbuchID);
	-- nochmal Testen
	
	
end$$
DELIMITER ;

-- call p_FinishFahrtenbuch(1)
-- schon Abgeschlossen

/********************************************************************************************************/
-- /F 40.2.2/

DELIMITER $$
create or replace procedure p_UpdateWartung
(inFirmenwagenID int, inNewWartung date)
begin
    declare WartungUnguelig CONDITION FOR SQLSTATE '45000';

    if (select NaechsteWartung from fuhrpark where FirmenwagenID = inFirmenwagenID) >= inNewWartung
        then
        SIGNAL WartungUnguelig SET MESSAGE_TEXT = 'vorherige Wartung wartung noch nicht vollzogen';
    else
        update fuhrpark
        set NaechsteWartung  = inNewWartung
        where FirmenwagenID = inFirmenwagenID;
    end if;

end$$
DELIMITER ;

-- CALL p_UpdateWartung(1,'2023-11-13')
-- FEHLER vorherige Wartung wartung noch nicht vollzogen
-- CALL p_UpdateWartung(1,'2023-11-17')
-- geht 2023-11-17 in tabelle eingetragen

/********************************************************************************************************/
-- /F 40.1.2.3./ 
-- nimmt Standort vom Roller weil die Halt nur bei Rollern anhalten sollen

DELIMITER $$
create or replace procedure p_CreateHaltepunkt
(inFahrtenbuchID int, inRollerID int)
begin
    declare RollerSchonInEinenWagen CONDITION FOR SQLSTATE '45000';
    declare RollerGibtEsNicht CONDITION FOR SQLSTATE '45000';


    declare exit Handler 
    for 1452 
    begin
        SIGNAL SQLSTATE '23000' SET
        MESSAGE_TEXT = 'Es ist kein zugehöriger Fahrtenbucheintrag zufinden';
    end;

    if (inRollerID >= (select max(ERollerID) from eroller) <= 0)
        then
        SIGNAL RollerGibtEsNicht SET MESSAGE_TEXT = 'Der Angegebene ERoller existiert nicht';
    end if;

    if (fn_CheckRollerStatusH(inRollerID)) != -1
        then
        SIGNAL RollerSchonInEinenWagen SET MESSAGE_TEXT = 'Roller ist schon in einem andern Wagen';
    end if;

    Insert Into Haltepunkt(Zeitpunkt, FahrtenbuchID, StandortID)
    values (CURRENT_TIMESTAMP(), inFahrtenbuchID, fn_GetRollerStandort(inRollerID));

    update eroller
    set HaltepunktID = (select Max(HaltepunktID) from Haltepunkt where FahrtenbuchID = inFahrtenbuchID and StandortID = fn_GetRollerStandort(inRollerID))
    where ERollerID = inRollerID;

end$$
DELIMITER ;

-- CALL p_CreateHaltepunkt(10, 20)
-- geht
-- CALL p_CreateHaltepunkt(10, 20)
-- wiederholung geht nicht
-- CALL p_CreateHaltepunkt(1000, 20)
-- Fehler "Es ist kein zugehöriger Fahrtenbucheintrag zufinden"
-- CALL p_CreateHaltepunkt(10, 0)
-- CALL p_CreateHaltepunkt(10, 300) 
-- Fehler Roller Existiert nicht

/********************************************************************************************************/
-- /F 40.1.2.10./

DELIMITER $$
create or replace procedure p_RollerInLager
(inFahrtenbuchID int)
begin
    
    update ERoller
    set HaltepunktID = NULL, StandortID = fn_GetFirmenwagenStandort(inFahrtenbuchID)
    where ERollerID IN 
    (
        select ERollerID from ERoller 
        where HaltepunktID 
        between 
        (select min(HaltepunktID) from Haltepunkt where FahrtenbuchID = inFahrtenbuchID) 
        and 
        (select max(HaltepunktID) from Haltepunkt where FahrtenbuchID = inFahrtenbuchID)
    );

end$$
DELIMITER ;

-- call p_RollerInLager(1)
/********************************************************************************************************/
-- /F 40.1.1./

DELIMITER $$
create or replace procedure p_FahrtenbuchAnzeigen
(inFahrtenbuchID int)
begin

    select Concat(p.Nachname,' ' , p.Vorname) AS MitarbeiterName ,Fahrtstart, Fahrtende, Fahrtdauer, RollerEingesamelt, FirmenwagenID
    From Fahrtenbuch F
    Join Mitarbeiter M on F.MitarbeiterID = M.MitarbeiterID
    Join Privatinfo P on M.PrivatinfoID = P.PrivatinfoID
    where FahrtenbuchID = inFahrtenbuchID;

    Select Sleep(1);

    select Zeitpunkt, Concat(S.PLZ, ' ', lower(S.Stadt), ' ', S.Strasse) AS Abholpunkt, ERollerID
    From Fahrtenbuch F
    Join Haltepunkt H on H.FahrtenbuchID = F.FahrtenbuchID
    Join Standort S on S.StandortID = H.StandortID
    Join ERoller ER on ER.HaltepunktID = H.HaltepunktID
    where F.FahrtenbuchID = inFahrtenbuchID;

end$$
DELIMITER ;

-- call p_FahrtenbuchAnzeigen(1)
-- Commands out of sync; you can't run this command now

/********************************************************************************************************/
-- /F 40.2.3/

DELIMITER $$
create or replace procedure p_CreateFirmenwagen
(inFirmenwagenID int, inAutoType varchar(50), inNaechsteWartung Date, inLagerID int)
begin

    insert into fuhrpark
    values (inFirmenwagenID, inAutoType, inNaechsteWartung, inLagerID);

end$$
DELIMITER ;

-- call p_CreateFirmenwagen(1067, 'VW Crafter 2019', '2025-11-11', 1);


/********************************************************************************************************/
-- /F 40.2.1/

DELIMITER $$
create or replace procedure p_ShowWartung
(inFirmenwagenID int)
begin

    select NaechsteWartung
    from fuhrpark
    where FirmenwagenID = inFirmenwagenID;

end$$
DELIMITER ;

-- call p_ShowWartung(1)


/********************************************************************************************************/
-- /F 40.1.2./

DELIMITER $$
create or replace procedure p_Fahrtenbuch
(inFirmenwagenID int, inMitarbeiterEmail varchar(100), inFahrtenbuchID int)
begin
    declare FirmenwagenUnbekannt CONDITION FOR SQLSTATE '45000';

    if inFirmenwagenID >= (select max(FirmenwagenID) from fuhrpark) and inFirmenwagenID >=0
        then
        SIGNAL FirmenwagenUnbekannt SET MESSAGE_TEXT = 'Firmenwagennummer nicht innerhalb der Firma vorhanden';
    end if;


    if inFahrtenbuchID = 0
        then
        call p_FinishFahrtenbuch(inFahrtenbuchID);

        else
        call p_CreateFahrtenbuch(inFirmenwagenID, inMitarbeiterEmail);

    end if;

end$$
DELIMITER ;

-- call p_Fahrtenbuch(10, 'y.koch@EcoWheels.com', 0)
-- call p_Fahrtenbuch(17,'y.koch@EcoWheels.com', 0)


/********************************************************************************************************/


-- Random Haltepunkt einfügen zum Testen in CSV???
