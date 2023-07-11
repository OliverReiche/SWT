-- 
-- Datenbank: ew_db 
-- erstellt am 05.07.2023
-- durch Jakob Roch Projektgruppe C5
-- Datenbank mit Tabellen für EcoWheels Verwaltungssystem

/********************************************************************************************************/
-- /F 40.1.2.11./ E-Roller Standort ermitteln
-- Diese Helper-Funktion ermittelt aus der Eingabe (RollerID) die zugehörige ID des Standort (StandortID). 

DELIMITER $$
create or replace function fn_GetRollerStandort (inRollerID int)
returns int
BEGIN
    declare outStandortID int;

    set outStandortID = (select standortID from EROLLER where ERollerID = inRollerID);

    return outStandortID;
end $$
DELIMITER ;

SELECT fn_GetRollerStandort (1);
-- Ergebnis: 148

/********************************************************************************************************/
-- /F 40.1.2.9./ E-Roller Status ermitteln für Haltepunkte
-- Uberprüft ob ein E-Roller von einem Mitarbeiter eingesammelt wurde
-- Wenn ein Haltepunkt vorhanden wird dieser zurückgegeben sonst -1

DELIMITER $$
create or replace function fn_CheckRollerStatusH (inRollerID int)
returns int
BEGIN
    declare outHaltepunkt int;

    select HaltepunktID into outHaltepunkt from ERoller where ERollerID = inRollerID;

    return IFNUll(outHaltepunkt,-1);
end $$
DELIMITER ;

SELECT fn_CheckRollerStatusH(1);
-- Ergebnis: -1

/********************************************************************************************************/
-- /F 40.1.2.8./ Fahrtdauer berechnen
-- Diese Funktion Konveriert die Positive differnez von Unix zeit in einen Time type 
-->  dies wird dann zurück gegeben

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

SELECT fn_CalculateFahrtdauer(1);
-- Ergebnis: 05:44:39

/********************************************************************************************************/
-- /F 40.1.2.7./ Mitarbeiter Standort ermitteln
-- Diese Helper-Funktion ermittelt aus der Eingabe (MitarbeiterID), die zugehörige ID des Standort (StandortID).

DELIMITER $$
create or replace function fn_GetMitarbeiterStandort (inMitarbeiterID int)
returns int
BEGIN
    declare outMStandort int;

    select ArbeitsortID into outMStandort from Mitarbeiter where MitarbeiterID = inMitarbeiterID;

    return outMStandort;
end $$
DELIMITER ;

SELECT fn_GetMitarbeiterStandort(1);
-- Ergebnis: 101

/********************************************************************************************************/
-- /F 40.1.2.4. MitarbeiterID ermitteln
-- Diese Helper-Funktion ermittelt aus der Eingabe (BusinessMail) die zugehörige ID des Mitarbeites (MitarbeiterID)
-- wenn die Email nicht vorhanden der Mitarbeiter Tabelle vorhanden ist wird -1 zurückgegeben

DELIMITER $$
create or replace function fn_GetMitarbeiterID (inBusinessEmail varchar(100))
returns int
BEGIN
    declare outMitarbeiterID int;
        
    select MitarbeiterID into outMitarbeiterID from Mitarbeiter where lower(BusinessEmail) = lower(inBusinessEmail);

    return IFNUll(outMitarbeiterID,-1);
end $$
DELIMITER ;

SELECT fn_GetMitarbeiterID('y.koch@EcoWheels.com');
-- Ergebnis: 25

/********************************************************************************************************/
-- /F 40.1.2.6./ Firmenwagen Standort ermitteln
-- Diese Helper-Funktion ermittelt aus der Eingabe (FirmenwagenID), die zugehörige ID des Standort (StandortID).

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

SELECT fn_GetFirmenwagenStandort(1);
-- Ergebnis: 101
SELECT fn_GetFirmenwagenStandort(20);
-- Ergebnis: 1

/********************************************************************************************************/
-- /F 40.1.2.5./ Fahrtenbucheintrag auf Integrität prüfen
-- Diese Funktion prüft ob man einen neuen Datensatz in Fahrtenbuch Tabelle einfügen kann ohne Geschäftsregeln oder die Intigrität zu verletzten
-- Die 4 Problemfälle sind:
-- > StandortRoller != StandortMitarbeiter  | Räumliche ungleichheit
-- > der Mitarbeiter gehört einer andern Abteilung an 
-- > der Mitarbeiter hat noch einen Fahrtenbucheintrag offen | Geschäftsregel war beim losfahren vom Lager 
--          erstellen beim wiederankommen beenden --> d.h. kein Mitarbeiter kann zwei gleichzeitig offen haben
-- > der Firmenwagen kann solange ein Zugehörige Fahrtenbucheintrag offen ist nicht wiederverwendet werdern
--          = keine zwei Mitarbeiter pro Fahrzeug erlaubt

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
        SIGNAL AbbruchMitarbeiterStandort SET MESSAGE_TEXT = 'Mitarbeiter und Lager/Fahrzeug sind nicht an Selben Standort/Region';
    end if;


    if STRCMP((select JobName from mitarbeiter where MitarbeiterID = inMitarbeiterID), 'KFZ-WH') = 0
        then
        SIGNAL AbbruchJobName SET MESSAGE_TEXT = 'Nicht passender JobName';
    end if;


-- es wird hier immer nur der Letzte Eintrag des Mitarbeiter/Fahrzeugs betrachte, 
--  weil der Rest wenn alles so wie geplannt funktioniert schon geprüft wurde

    if IFNUll((select Fahrtende from Fahrtenbuch where MitarbeiterID = inMitarbeiterID having max(Fahrtstart) < Fahrtende),-1) != -1
        then
        SIGNAL NichtAbgeschlossenerEintrag SET MESSAGE_TEXT ='Mitarbeiter hat noch einen nicht abgeschlossen Fahrtenbucheintrag';
    end if;


    if IFNUll((select Fahrtende from Fahrtenbuch where FirmenwagenID = inFirmenwagenID having max(Fahrtstart) < Fahrtende),-1) != -1
        then
        SIGNAL AutoIstNochInBenutzung SET MESSAGE_TEXT ='Das Ausgewealte Firmenfahrzeug ist noch in Benutztung';
    end if;
                        
    set vIntegritaet = 1;


    return IFNUll(vIntegritaet, -1);
end $$
DELIMITER ;



SELECT fn_CheckIntegritaet(1 , 1);
-- Ergebnis: FEHLER, -1, nicht passender JobName
SELECT fn_CheckIntegritaet(1 , 15);
-- Ergebnis: FEHLER, -1, Mitarbeiter und Lager/Fahrzeug sind nicht an Selben Standort/Region


-- Testfall
Insert Into Fahrtenbuch(Fahrtstart, FirmenwagenID, MitarbeiterID)
values(CURRENT_TIMESTAMP, 17, 25);

SELECT fn_CheckIntegritaet(18 , 25);
-- Ergebnis: FEHLER, Mitarbeiter hat noch einen offenen Eintrag
SELECT fn_CheckIntegritaet(17 , 43);
-- Ergebnis: FEHLER, geht nich weil Fahrzeug von Arbeiter 25 benutzt

SELECT fn_CheckIntegritaet(1 , 9);
-- Ergebnis: 1 alles geht

/********************************************************************************************************/
/********************************************************************************************************/
/********************************************************************************************************/
-- /F 40.1.2.1./ Fahrtenbucheintrag erstellen
-- Dies Funktion erstelt einen Fahrtenbucheintrag mit den gegebenen Parameter d.h. FirmenwagenID und (Mitarbeiter) BusinessEMail
-- Wenn der von die zurück gegebene E-Mail falsch war wir ein Fehler Ausgewurfen
-- der Eintrag in die Fahrtenbuch Tabelle wird erst erstellt wenn die Intigriätsprüfung positiv war

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

call p_CreateFahrtenbuch(11,'y.koch@EcoWheels.com');
-- Ergebnis: FEHLER, Mitarbeiter und Lager/Fahrzeug sind nicht an Selben Standort/Region
call p_CreateFahrtenbuch(17,'y.koch@yahoomail.com');
-- Ergebnis: FEHLER, geht nicht email unbekannt
call p_CreateFahrtenbuch(17,'y.koch@EcoWheelz.com');
-- Ergebnis: FEHLER, geht nicht schreibfehler
call p_CreateFahrtenbuch(17,'X.koch@EcoWheels.com');
-- Ergebnis: FEHLER, geht nicht kein solcher Mitarbeiter

-- Ist der Selbe Tesfall wie in /F 40.1.2.5./ Fahrtenbucheintrag auf Integrität prüfen
call p_CreateFahrtenbuch(17, 'y.koch@EcoWheels.com');
-- Ergebnis: FEHLER, geht nicht Fahrtenbucheintrag noch nicht Abgeschlossen
call p_CreateFahrtenbuch(17, 'r.kaiser@EcoWheels.com');
-- Ergebnis: FEHLER, geht nicht weil Fahrzeug noch in Benutzung

call p_CreateFahrtenbuch(19, 't.vogel@EcoWheels.com');
-- Ergebnis: geht

/********************************************************************************************************/
-- /F 40.1.2.10./ Aktualisierung wenn E-Roller in Lager ankommt
-- Diese Prozedur setzt alle Haltepunkte von alle eingesammelten E-Rollern eines Fahrtenbucheintrags auf NULL

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


-- Testfall
-- bitte nicht beachten das für den Test am Anfang Haltepunkt und Roller StandortID nicht zusammmenpassen
update ERoller
set HaltepunktID =(RAND()*(76-72)+72)
where ERollerID between 1 and 5;

-- Haltepunkte 72-76 gehören zu Fahrtenbucheintrag 21
-- das passende Lager hat den Standort 101

call p_RollerInLager(21);
-- Ergebnis: geht

/********************************************************************************************************/
-- /F 40.1.2.3./ Haltepunkt anlegen
-- Diese Prozedur erstellt einen Haltepunkt in der Haltepunkt Tabelle und fügt den FK bei dem Zugehörigen ERoller hinzu
-- Abbruchbedingungen sind der Roller ist schon einen Haltepunkt zu geordnet und das Personal hat einen Falschen Roller angegeben
-- der Haltepunkt erhält den Standort des ERoller beim erstellen 

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

    if inRollerID >= (select max(ERollerID) from eroller)
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

-- ab auf erfolgreichen /F 40.1.2.1./ Fahrtenbucheintrag erstellen auf
call p_CreateHaltepunkt(101, 22);
-- Ergebnis: ohne Fehler 
call p_CreateHaltepunkt(10, 20);
-- Ergebnis: FEHLER wiederholung geht nicht
call p_CreateHaltepunkt(1000, 20);
-- Ergebnis: FEHLER, Es ist kein zugehöriger Fahrtenbucheintrag zufinden
call p_CreateHaltepunkt(10, 300);
-- Ergebnis: FEHLER, Roller Existiert nicht

/********************************************************************************************************/
-- /F 40.1.2.2./ Fahrtenbucheintrag abschließen 
-- Diese Prozedur schließt einen von /F 40.1.2.1./ p_CreateFahrtenbuch Fahrtenbucheintrag ab
-- zuerst wird geprüft ob der Fahrtenbucheintrag schon abgeschlossen ist --> wenn ja abbruch

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

	call p_RollerInLager(inFahrtenbuchID);
	
	
end$$
DELIMITER ;

-- baut auf /F 40.1.2.3./ Haltepunkt anlegen auf
call p_FinishFahrtenbuch(101);
-- Ergebnis: ohne Fehler 
call p_FinishFahrtenbuch(101);
-- Ergebnis: FEHLER Eintrag schon abgeschlossen

/********************************************************************************************************/
-- /F 40.2.2/ Wartung aktualisieren
-- Diese Prozedur aktualisiert die das Wartungsdatum eines Firmenwagens so lang die letzt Wartung schon stattgefunden hat

DELIMITER $$
create or replace procedure p_UpdateWartung
(inFirmenwagenID int, inNewWartung date)
begin
    declare WartungUnguelig CONDITION FOR SQLSTATE '45000';

    if (select NaechsteWartung from fuhrpark where FirmenwagenID = inFirmenwagenID) >= now()
        then
        SIGNAL WartungUnguelig SET MESSAGE_TEXT = 'vorherige Wartung wartung noch nicht vollzogen';
    else
        update fuhrpark
        set NaechsteWartung  = inNewWartung
        where FirmenwagenID = inFirmenwagenID;
    end if;

end$$
DELIMITER ;

call p_UpdateWartung(1,'2023-11-13');
-- Ergebnis: FEHLER vorherige Wartung wartung noch nicht vollzogen

-- für Test
update fuhrpark
set NaechsteWartung = '2000-04-05'
where FirmenwagenID = 1;

call p_UpdateWartung(1,'2023-11-13');
-- Ergebnis: ohne Fehler 

/********************************************************************************************************/
-- /F 40.1.1./
-- Diese Prozedur erzeugt eine View über Fahrtenbuchdaten und gibt dies dann aus
-- Die View zeigt alle Fahrtenbucheinträge der letzten 30 Tage aus Erfurt mit vollständigem Namen, Fahrtstart/-ende/-dauer, 
--   Anzahl eingesammelter E-Roller und welcher Firmenwagen jeweils dafür benutzt wurde, geordnet nach dem Abfahrtsdatum.

DELIMITER $$
create or replace procedure p_FahrtenbuchView
()
begin

    create or replace view FahrtenbuchView(MitarbeiterName,Standort ,Fahrtstart_Ende, Fahrtdauer, AnzahlRollerEingesamelt, FirmenwagenNummer)
    as
    select  Concat(p.Nachname,' ' , p.Vorname),
            S.Stadt,
            Concat(F.Fahrtstart,' | ' ,F.Fahrtende), 
            F.Fahrtdauer, 
            F.RollerEingesamelt, 
            F.FirmenwagenID
    from Fahrtenbuch F
    join Mitarbeiter M on F.MitarbeiterID = M.MitarbeiterID
    join Privatinfo P on M.PrivatinfoID = P.PrivatinfoID
    join Standort S on S.StandortID = M.ArbeitsortID
    where S.Stadt = 'Erfurt'
    and DATEDIFF(now(),F.Fahrtstart) < 30
    order by F.Fahrtstart;

    select * from FahrtenbuchView;

end$$
DELIMITER ;

call p_FahrtenbuchView();
-- Ergebnis: zeigt View

/********************************************************************************************************/
-- /F 40.2.3/ neues Firmenfahrzeug hinzufügen
-- Dies Prozedur erzeugt einen neuen Eintrag in der Firmenwagen Tabele

DELIMITER $$
create or replace procedure p_CreateFirmenwagen
(inFirmenwagenID int, inAutoType varchar(50), inNaechsteWartung Date, inLagerID int)
begin

    insert into fuhrpark
    values (inFirmenwagenID, inAutoType, inNaechsteWartung, inLagerID);

end$$
DELIMITER ;

call p_CreateFirmenwagen(1067, 'VW Crafter 2019', '2025-11-11', 1);
-- Ergebnis: ohne Fehler

/********************************************************************************************************/
-- /F 40.2.1/ Nächste Wartung Anzeigen
-- Dies Prozedur zeigt das nächste Wartungsdatum

DELIMITER $$
create or replace procedure p_ShowWartung
(inFirmenwagenID int)
begin

    select NaechsteWartung
    from fuhrpark
    where FirmenwagenID = inFirmenwagenID;

end$$
DELIMITER ;

call p_ShowWartung(1);
-- Ergebnis: ohne Fehler

/********************************************************************************************************/
-- /F 40.1.2./ Fahrtenbucheintrag anlegen
-- Dies Prozedur ist die Mantelprozedur für das Fahrtenbucheintraganlegen d.h. sie vereinigt das erstellen und Abschließen
-- Die FahrtenbuchID sollte Optional sein(habe trotz hilfe die Syntax nicht gefunden)
-- > beim jetzigen Stand gibt der Mitarebeiter an der Stelle inFahrtenbuchID (0) wenn er einen Eintrag erstellen möchte

DELIMITER $$
create or replace procedure p_Fahrtenbuch
(inFirmenwagenID int, inMitarbeiterEmail varchar(100), inFahrtenbuchID int)
begin
    declare FirmenwagenUnbekannt CONDITION FOR SQLSTATE '45000';

    if inFirmenwagenID >= (select max(FirmenwagenID) from fuhrpark) and inFirmenwagenID >=0
        then
        SIGNAL FirmenwagenUnbekannt SET MESSAGE_TEXT = 'Firmenwagennummer nicht innerhalb der Firma vorhanden';
    end if;


    if inFahrtenbuchID != 0
        then
        call p_FinishFahrtenbuch(inFahrtenbuchID);
    else
        call p_CreateFahrtenbuch(inFirmenwagenID, inMitarbeiterEmail);
    end if;

end$$
DELIMITER ;


call p_Fahrtenbuch(17,'y.koch@EcoWheels.com', 0);
-- Ergebnis: ohne Fehler
call p_Fahrtenbuch(17,'y.koch@EcoWheels.com', 102);
-- Ergebnis: ohne Fehler

/********************************************************************************************************/
-- /F 50.2./ Buchungsstatistiken für APP käufe erstellen
-- Die Prozedur erzeugt eine gleichnamige View über eine mögliche Buchungstatistik und ruft dies auf. 
-- Diese Sicht zeigt die Durchschnittszahlung aller Nutzer pro Stadt geteilt in APP und Karte für die letzten 120 Tagen. 
-- Dazu wird gezeigt, wie viele Prozent von allen Zahlungen wo und wie getätigt wurden 
-- (Der Prozentsatz bezieht sich nicht auf den Anteil des Gesamtgewinns, sondern auf die Häufigkeit der Zahlung)


DELIMITER $$
create or replace procedure p_BuchungsStatView
()
begin

    create or replace view BuchungsStatView(Stadt, Durchschnittszahlung, ZahlungsType, Verkaufsanteil)
    as
    select  
            S.Stadt,
            Concat(Format(AVG(Z.GesamtPreis), 2, 'de_DE'),' Euro'),
            replace(replace(ZahlungsType,'A','APP'),'K','Kundenkarte'),
            Concat(Format(
                    count(Z.ZMethodID) * 100.0 / 
            	    (select count(*) from Zahlung Z
                    join Bestellung_ERoller BER on BER.BestellERID = Z.BestellERID
                    join Kunde K on K.KundeID = BER.KundeID
                    where DATEDIFF(now(),K.LetzteNutzung) < 120)
            , 2), '%')

    from Kunde K
    join Standort S on S.StandortID = K.WohnortID
    join Kundenkonto KK on KK.KKontoID = K.KKontoID
    join Bestellung_ERoller BER on BER.KundeID = K.KundeID
    join Zahlung Z on Z.BestellERID = BER.BestellERID
    join Zahlungsmethode ZM on ZM.ZMethodID = Z.ZMethodID
    where DATEDIFF(now(),K.LetzteNutzung) < 120
    group by S.Stadt ,ZM.ZahlungsType;

    SELECT * from  BuchungsStatView;

end$$
DELIMITER ;


call p_BuchungsStatView();
-- Ergebnis: zeigt View


/********************************************************************************************************/