-- 
-- Datenbank: ew_db 
-- erstellt am 02.07.2023
-- durch Richard Prax Projektgruppe C5
-- Datenbank mit Tabellen für EcoWheels Verwaltungssystem

-- --------------------------------------------------------

/********************************************************************************************************/

-- /F20.1.2.1./ Lager suchen - fn_GetLagerId
-- Diese Funktion sucht mittels der Eingabe (Stadtnamen) die jeweilige LagerId aus der Tabelle Lager
-- wenn die Funktion kein Lager in der Stadt finden kann, wird -1 zurückgegeben

DELIMITER $$
CREATE OR REPLACE function fn_GetLagerId(inStadt varchar(30))
returns int
BEGIN
    declare vOutLagerId int;

    select l.LagerID into vOutLagerId
    from standort s join lager l on s.StandortId = l.StandortId
    where s.Stadt = UPPER(inStadt);

    return ifnull(vOutLagerId, -1);
END $$
DELIMITER ;

-- Testfälle
-- 1. Fall erwartet als Rückgabe 1
select fn_GetLagerID('Erfurt');

-- 2. Fall erwartet als Rückgabe -1, da in London kein Lager ist
select fn_GetLagerID('London');

/********************************************************************************************************/

-- /F20.1.2.2./ Einzelteil suchen - fn_GetEinzelteilId
-- Diese Funktion sucht mittels der Eingabe (Einzelteilbezeichnung) die jeweilige EinzelteilId aus der Tabelle Einzelteile 
-- wenn die Funktion kein Einzelteil mit dieser BEschreibung finden kann, wird -1 zurückgegeben

DELIMITER $$
CREATE OR REPLACE function fn_GetEinzelteilId(inEinzeilteilbezeichnung varchar(30))
returns int
BEGIN
    declare vOutEinzelteilId int;

    select EinzelteileId into vOutEinzelteilId
    from einzelteile
    where EName = inEinzeilteilbezeichnung;

    return ifnull(vOutEinzelteilId,-1);
END $$
DELIMITER ;

-- Testfälle
-- 1. Fall erwartet als Rückgabe 3
select fn_GetEinzelteilId('Luftreifen');

-- 2. Fall erwartet als Rückgabe -1, da es in diesem System keine Fahradklingel gibt
select fn_GetEinzelteilId('Fahradklingel');

/********************************************************************************************************/

-- /F20.1.2.3./ Einzelteil-Eintrag anlegen - p_NewEinzelteil
-- diese Prozedur erwartet als Übergabe Einzelteiltyp, Einzelteilname sowie das Gewicht in Gramm
-- die Prozedur fügt einen neuen Datensatz in der Tabelle Einzelteile ein, sofern das jeweilige Einzelteil noch nicht im System registriert ist
-- dies wird über die Funktion fn_GetEinzelteileID überprüft

DELIMITER $$
CREATE OR REPLACE procedure p_NewEinzelteil(inEinzelteilTyp varchar(50), inEinzeilteilBezeichnung varchar(100), inGewicht decimal(8,2))
BEGIN
    if (fn_GetEinzelteilID(inEinzeilteilBezeichnung)) = -1
        then INSERT Into einzelteile (EType, EName, Gewicht)
        VALUES (inEinzelteilTyp, inEinzeilteilBezeichnung, inGewicht);
    else
         SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT ='Ein Einzelteil mit diesem Namen ist schon im System registriert!';
    end if;
END $$
DELIMITER ;

-- Testfälle
-- 1. Fall erwartet einen Neuen Eintrag in der Einzelteile Tabelle (53, Reflektor, Hinterrad Reflektoren, 10.00)
call p_NewEinzelteil('Reflektor', 'Hinterrad Reflektoren', 10.00);

-- 2. Fall erwartet eine Fehlermeldung, da schon ein Rollerschaltwerk im System registriert ist
call p_NewEinzelteil('Schaltwerk','Rollerschaltwerk', 100.00);

/********************************************************************************************************/

-- /F20.1.2.4./ Einzelteil im Lager suchen - fn_GetLagerEinzelteileID
-- Diese Funktion sucht mittels der Eingabe (Stadtname, Einzelteilbezeichnung) die jeweilige Lager_EteileId aus der Tabelle lager_einzelteile
-- innerhalb der Funktion werden durch den Aufruf der Funktionen fn_GetLagerId sowie fn_GetEinzelteilId die Werte für LagerId und EinzelteilId ermittelt
-- wenn die Funktion kein Einzelteil mit dieser Beschreibung in dem jeweiligen Lager finden, wird -1 zurückgegeben

DELIMITER $$
CREATE OR REPLACE function fn_GetLagerEinzelteileID(inStadt varchar(30), inEinzeilteilbezeichnung varchar(30))
returns int
BEGIN
    declare vOutLagerEteileId int;
    declare vLagerId int;
    declare vEinzelteilId int;
    declare noLagerFound CONDITION for SQLSTATE '45000';
    declare noEinzelteilFound CONDITION for SQLSTATE '45000';

    set vLagerId = fn_GetLagerId(inStadt); 
    set vEinzelteilId = fn_GetEinzelteilId(inEinzeilteilbezeichnung);

    if vLagerId = -1
        then SIGNAL noLagerFound SET MESSAGE_TEXT = 'Kein Lager in dieser Stadt!';

        elseif vEinzelteilId = -1
            then SIGNAL noEinzelteilFound SET MESSAGE_TEXT = 'Kein Einzelteil mit dieser Bezeichnung!';

            else
                select Lager_EteileId into vOutLagerEteileId
                from lager_einzelteile
                where LagerId = vLagerId and EinzelteileId = vEinzelteilId;
    end if;
    return ifnull(vOutLagerEteileId,-1);
END $$
DELIMITER ;

-- Testfälle
-- 1. Fall erwartet als Rückgabe den Wert 10
select fn_GetLagerEinzelteileID('Erfurt', 'Metallkettenschutz');

-- 2. Fall erwartet Fehlermeldung, da es kein Lager in London gibt
select fn_GetLagerEinzelteileID('London', 'Metallkettenschutz');

-- 3. Fall Fehlermeldung, da es im System keine Fahradklingel 
select fn_GetLagerEinzelteileID('Erfurt', 'Fahradklingel');

-- 4. Fall erwartet -1, da es im Lager in Hamburg keine OLED-Displays gibt 
select fn_GetLagerEinzelteileID('Hamburg', 'OLED-Display');

/********************************************************************************************************/

-- /F20.1.2.5./ Einzelteil im Lager registrieren - p_NewLagerEinzelteil
-- diese Prozedur erwartet als Übergabe den Mindestbestand, Maximalbestand, einen Stadtnamen sowie eine Einzelteilbezeichnung
-- Innerhalb der Prozedur wird durch die Aufrufe der Funktionen fn_GetLagerId und fn_GetEinzelteilId werden die Werte für die LagerId sowie EinzelteilId ermittelt
-- Da diese Prozedur nur aufgerufen werden kann, sofern ein Artikel neu im Lager ist, wird der aktuelle Bestand automatisch auf den Wert 0 gesetzt, welcher später durch die Prozedur p_UpdateBestand aktualisiert wird
-- die Prozedur fügt einen neuen Datensatz in die Tabelle LAGER_EINZELTEILE ein, sofern das Einzelteil noch nicht im Lager registriert ist. Dies wird mit der Funktion fn_GetLagerEinzelteileID überprüft.

DELIMITER $$
CREATE OR REPLACE procedure p_NewLagerEinzelteil(inMindestBestand int, inMaximalBestand int, inStadt varchar(30), inEinzeilteilBezeichnung varchar(100))
BEGIN
    if (fn_GetLagerEinzelteileID(inStadt, inEinzeilteilBezeichnung)) = -1
        then INSERT into lager_einzelteile (MinBestand, MaxBestand, Bestand, LagerID, EinzelteileId)
        VALUES (inMindestBestand, inMaximalBestand, 0, fn_GetLagerID(inStadt), fn_GetEinzelteilID(inEinzeilteilBezeichnung));
    else
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Das Einzelteil ist schon in diesem Lager registriert!';
    end if;
END $$
DELIMITER ;

-- Testfälle
-- 1. Fall erwartet einen Neuen Eintrag in der Lager Einzelteile Tabelle(257, 200, 400, 0, 5, 52)
call p_NewLagerEinzelteil(200,400,'Hamburg','OLED-Display');

-- 2. Fall erwartet eine Fehlermeldung, da das OLED-Display in Erfurt schon registriert ist
call p_NewLagerEinzelteil(200,400,'Erfurt','OLED-Display');

-- 3. Fall erwartet eine Fehlermeldung, da im System kein Bremsverstrker registriert ist
call p_NewLagerEinzelteil(200,400,'Erfurt','Bremsverstärker');

-- 4. Fall erwartet eine Fehlermeldung, da es in London kein Lager gibt
call p_NewLagerEinzelteil(200,400,'London','OLED-Display');

/********************************************************************************************************/

-- /F20.1.2.6./ Lieferanten ermitteln - fn_GetLieferantID
-- Diese Funktion sucht mittels der Eingabe (Lieferantennamen) die jeweilige LieferantID aus der Tabelle lieferant
-- wenn die Funktion keinen Lieferanten mit diesem Namen finden kann, wird -1 zurückgegeben

DELIMITER $$
CREATE OR REPLACE function fn_GetLieferantID(inLieferantName varchar(50))
returns int
BEGIN
    declare vOutLieferantenId int;

    select LieferantID into vOutLieferantenId
    from lieferant
    where LieferantName = inLieferantName;

    return ifnull(vOutLieferantenId,-1);
END $$
DELIMITER ;

-- Testfälle
-- 1. Fall erwartet als Rückgabe 15
select fn_GetLieferantID('Express Solutions');

-- 2. Fall erwartet als Rückgabe -1, da es keinen Lieferanten mit dem Namen "DHL" gibt
select fn_GetLieferantID('DHL');

/********************************************************************************************************/

-- /F20.1.2.7./ Lieferanten-Eintrag anlegen - p_NewLieferant
-- diese Prozedur erwartet als Übergabe einen Lieferantennamen
-- die Prozedur fügt einen neuen Datensatz in der Tabelle Lieferant ein, sofern der Lieferant noch nicht existiert, dies wird mit der Funktion fn_GetLieferantID überprüft
-- da diese Funktion nur aufgerufen werden kann wenn ein Lieferant neu registriert wird, wird das LetzteLieferungsdatum automatisch auf den Wert 2015-01-01 gesetzt und später überschrieben

DELIMITER $$
CREATE OR REPLACE procedure p_NewLieferant(inLieferantName varchar(50))
BEGIN
    if (fn_GetLieferantID(inLieferantName)) = -1
        then INSERT Into Lieferant (LieferantName, LetzteLieferung)
        VALUES (inLieferantName, '2015-01-01');
    else
         SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT ='Lieferant existiert schon im System!';
    end if;
END $$
DELIMITER ;

-- Testfälle
-- 1. Fall erwartet einen Neuen Eintrag in der Lieferanten Tabelle (77, Amazon, 2015-01-01)
call p_NewLieferant('Amazon');

-- 2. Fall erwartet eine Fehlermeldung, da der Lieferant Elite Logistics schon registriert ist
call p_NewLieferant('Elite Logistics');

/********************************************************************************************************/

-- /F20.1.2.8./ Lieferant für Lager ermitteln - fn_GetLagerLieferantID
-- Diese Funktion sucht mittels der Eingabe (Stadtname, Lieferantename) die jeweilige Lager_LieferID aus der Tabelle lager_lieferant 
-- innerhalb der Funktion werden durch den Aufruf der Funktionen fn_GetLagerId sowie fn_GetLieferantID die Werte für LagerId und LieferantID ermittelt
-- wenn die Funktion kein Lieferanten mit diesem Namen in dem jeweiligen Lager finden, wird -1 zurückgegeben 

DELIMITER $$
CREATE OR REPLACE function fn_GetLagerLieferantID(inStadt varchar(30), inLieferantName varchar(30))
returns int
BEGIN
    declare vOutLagerLieferId int;
    declare vLagerId int;
    declare vLieferantId int;
    declare noLagerFound CONDITION for SQLSTATE '45000';
    declare noLieferantFound CONDITION for SQLSTATE '45000';

    set vLagerId = fn_GetLagerId(inStadt); 
    set vLieferantId = fn_GetLieferantID(inLieferantName);

    if vLagerId = -1
        then SIGNAL noLagerFound SET MESSAGE_TEXT = 'Kein Lager in dieser Stadt!';

        elseif vLieferantId = -1
            then SIGNAL noLieferantFound SET MESSAGE_TEXT = 'Kein Lieferant mit diesem Namen!';

            else
                select Lager_LieferID into vOutLagerLieferId
                from lager_lieferant
                where LagerID = vLagerId and LieferantID = vLieferantId;
    end if;
    return ifnull(vOutLagerLieferId,-1);
END $$
DELIMITER ;

-- Testfälle
-- 1. Fall erwartet als Rückgabe den Wert 20
select fn_GetLagerLieferantID('Hamburg', 'Elite Industries');

-- 2. Fall erwartet Fehlermeldung, da es kein Lager in London gibt
select fn_GetLagerLieferantID('London', 'Elite Industries');

-- 3. Fall erwartet Fehlermeldung, da es im System keinen Lieferanten mit der Bezeichnung DHL gibt
select fn_GetLagerLieferantID('Erfurt', 'DHL');

-- 4. Fall erwartet -1, da Hermes das Lager in Hamburg nicht beliefert
select fn_GetLagerLieferantID('Hamburg', 'Hermes');

/********************************************************************************************************/

-- /F20.1.2.9./ Lieferanten im Lager registrieren - p_NewLagerLieferant 

-- diese Prozedur erwartet als Übergabe einen Lieferantennamen sowie einen Stadtnamen
-- Innerhalb der Funktion werden durch die Aufrufe der Funktionen fn_GetLagerId und fn_GetLieferantId die LagerId und LieferantenId ermittelt.
-- Die Prozedur fügt einen neuen Datensatz in die Tabelle LAGER_LIEFERANT ein, sofern der Lieferant für das jeweilige Lager noch nicht registriert ist. Dies wird mit der Funktion fn_GetLagerLieferantId überprüft.

DELIMITER $$
CREATE OR REPLACE procedure p_NewLagerLieferant(inLieferantName varchar(50), inStadt varchar(30))
BEGIN
    if (fn_GetLagerLieferantID(inStadt, inLieferantName)) = -1
        then INSERT into lager_lieferant (Lager_LieferID, LieferantID, LagerID)
        VALUES (testid, fn_GetLieferantID(inLieferantName), fn_GetLagerID(inStadt));
    else
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Der Lieferant ist schon in diesem Lager registriert!';
    end if;
END $$
DELIMITER ;

-- Testfälle
-- 1. Fall erwartet einen Neuen Eintrag in der Lager_Lieferant Tabelle(377, 76, 2)
call p_NewLagerLieferant('Hermes', 'Berlin');

-- 2. Fall erwartet eine Fehlermeldung, da der Lieferant Hermes in Erfurt schon registriert ist
call p_NewLagerLieferant('Hermes', 'Erfurt');

-- 3. Fall erwartet eine Fehlermeldung, da im System keinen Lieferanten DHL gibt
call p_NewLagerLieferant('DHL','Erfurt');

-- 4. Fall erwartet eine Fehlermeldung, da es in London kein Lager gibt
call p_NewLagerLieferant('Hermes','London');

/********************************************************************************************************/

-- /F20.1.2.10./ Letzte Lieferung aktualisieren - p_UpdateLieferantLetzteLieferung
-- Diese Funktion erwartet als Übergabe einen Lieferantennamen sowie ein Datum (Format: yyyy-mm-dd). Innerhalb der Prozedur wird über den Aufruf der Funktion fn_GetLieferantId die LieferantenId ermitteln. Die Prozedur aktualisiert das letzte Lieferungsdatum eines Lieferanten, welcher durch die LieferantenId referenziert wird. Dass der Lieferant registriert ist, wird über die Funktion fn_GetLieferantId überprüft.

DELIMITER $$
CREATE OR REPLACE procedure p_UpdateLieferantLetzteLieferung(inLieferantName varchar(50), inDatum date)
BEGIN
    if (inDatum < '2015-01-01')
        then SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Das Lieferdatum liegt vor der Firmengründung! Bitte die Eingabe überprüfen!';
    end if;

    if (fn_GetLieferantID(inLieferantName)) = -1
        then SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Es existiert kein Lieferant mit diesem Namen!';
    elseif inDatum < (select LetzteLieferung from Lieferant where LieferantName = inLieferantName)
        then SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Das neue LetzeLieferungsdatum darf nicht länger her sein als das LetzeLieferungsdatum! Bitte Eingabe prüfen!';
    else
        Update lieferant
        set LetzteLieferung = inDatum
        where LieferantName = inLieferantName;
    end if;
END $$
DELIMITER ;

-- Testfälle
-- 1. Fall aktualisiert das LetzteLieferung Datum des Lieferanten Amazon auf den 2023-07-03
call p_UpdateLieferantLetzteLieferung('Amazon', '2023-07-03');

-- 2. Fall erwartet eine Fehlermeldung, da der Lieferant Super Express nicht im System registriert ist
call p_UpdateLieferantLetzteLieferung('Super Express', '2023-07-03');

-- 3. Fall erwartet eine Fehlermeldung, da das neue LetzteLieferungsdatum nicht länger her sein darf als das LetzeLieferungsdatum
call p_UpdateLieferantLetzteLieferung('Elite Imports','2023-03-24');

-- 4. Fall erwartet eine Fehlermeldung, da das Lieferungsdatum nicht vor der Firmeneröffnung liegen darf
call p_UpdateLieferantLetzteLieferung('Elite Imports','2014-05-21');

/********************************************************************************************************/

-- /F20.1.2.11./ Lagerbestand aktualisieren - p_UpdateLagerbestand
-- Diese Prozedur erwartet als Übergabe einen Stadtnamen, eine Einzelteilzeichnung sowie die Anzahl der gelieferten Artikel
-- Innerhalb der Prozedur wird durch Aufruf der Funktion fn_GetLagerEinzelteileID die Lager_EteileID ermittelt
-- Über die Funktionen fn_GetBestand wird der aktuelle Bestand ermittelt
-- Die Prozedur berechnet den neuen Lagerbestand über den Aufruf der Funktion fn_BerechneNeuenBestand mit den benötigten Übergabewerten 
-- über die Funktion fn_KontrolliereBestand wird geprüft ob ausreichend kapazität im Lager vorhanden ist
-- die Prozedur aktualisiert den Bestand des Artikels, welcher über die Lager_EinzelteilId referenziert wird
-- Dass der Artikel in dem Lager registriert ist, wird über die Funktion fn_GetLagerEinzelteileID geprüft.

DELIMITER $$
CREATE OR REPLACE procedure p_UpdateLagerbestand(inStadt varchar(30), inEinzeilteilBezeichnung varchar(50), inAnzahl int)
BEGIN
    declare vLagerEteileID int;
    declare vNeuerBestand int;

    set vLagerEteileID = fn_GetLagerEinzelteileID(inStadt, inEinzeilteilBezeichnung);
    set vNeuerBestand = (fn_GetBestand(inStadt, inEinzeilteilBezeichnung) + inAnzahl);

    if inAnzahl <= 0
        then SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Anzahl darf nicht negativ oder null sein!';
    end if;

    if fn_KontrolliereBestand(inStadt, inEinzeilteilBezeichnung, vNeuerBestand) = 1
        then Update lager_einzelteile
             set Bestand = vNeuerBestand
             where Lager_ETeileID = vLagerEteileID;
    end if;
END $$
DELIMITER ;

-- Testfälle
-- 1. Fall aktualisiert den Lagerbestand Hydraulischen Bremshebel in Erfurt auf 600
call p_UpdateLagerbestand('Erfurt', 'Hydraulische Bremshebel', 66);

-- 2. Fall gibt Fehlermeldung zurück, Lagerkapazität nicht ausreichend
call p_UpdateLagerbestand('Erfurt', 'Aluminiumkurbelarme', 600);

-- 3. Fall gibt Fehlermeldung zurück, Anzahl darf nicht negativ oder null sein
call p_UpdateLagerbestand('Erfurt', 'Aluminiumkurbelarme', -10);

/********************************************************************************************************/

-- /F20.1.2.12./ Lieferdetails-Eintrag anlegen - p_NewLieferDetails 
-- Diese Prozedur erwartet als Übergabe eine Anzahl, einen Stückpreis, einen Stadtnamen, einen Lieferantennamen sowie eine Einzelteilbezeichnung
-- Innerhalb der Prozedur wird durch den Aufruf der Funktion fn_GetLagerLieferID die Lager_LieferID ermitteln
-- dass der Lieferant beziehungsweise das Einzelteil für das Lager registriert ist wird über die Funktionen fn_GetLagerLieferantID sowie fn_GetLagerEinzelteileID überprüft
-- die Prozedur fügt einen neuen Datensatz in der Tabelle LIEFERDETAILS ein.

DELIMITER $$
CREATE OR REPLACE procedure p_NewLieferDetails(inAnzahl int, inStueckpreis decimal(8,2), inStadt varchar(30), inLieferantName varchar(50), inEinzeilteilBezeichnung varchar(100))
BEGIN
    if fn_GetLagerLieferantID(inStadt, inLieferantName) = -1
        then SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Lieferant nicht für dieses Lager registriert!';
    elseif fn_GetEinzelteilID(inEinzeilteilBezeichnung) = -1
        then SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Kein Einzelteil mit dieser Bezeichnung registriert!';
    elseif fn_GetLagerEinzelteileID(inStadt, inEinzeilteilBezeichnung) = -1
        then SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Kein Einzelteil mit dieser Bezeichnung im Lager registriert!';
    else
        Insert into Lieferdetails (Anzahl, Stueckpreis, Lager_LieferID, EinzelteileId)
        VALUES (inAnzahl, inStueckpreis, fn_GetLagerLieferantID(inStadt, inLieferantName), fn_GetEinzelteilID(inEinzeilteilBezeichnung));
    end if;
END $$
DELIMITER ;

-- Testfälle
-- 1. Fall erwartet neuen Eintrag in der Lieferdetails Tabelle (402, 10, 50.00, 376, 52)
call p_NewLieferDetails(10,50.00, 'Erfurt', 'Hermes', 'OLED-Display');

-- 2. Fall erwartet Fehlermeldung, da das Einzelteil nicht im Lager registriert ist
call p_NewLieferDetails(20,50.00,'Berlin', 'Hermes', 'OLED-Display');

-- 3. Fall erwartet Fehlermeldung, da der Lieferant nicht im Lager registriert ist
call p_NewLieferDetails(10,50.00, 'Hamburg', 'Amazon', 'OLED-Display');

-- 4. Fall erwartet Fehlermeldung, da kein Einzelteil mit so einem Namen registriert ist
call p_NewLieferDetails(10,50.00, 'Erfurt', 'Hermes', 'Felgenschwamm');

/********************************************************************************************************/

-- /F20.1.2.13/ Gesamtpreis ermitteln - fn_GetGesamtPreisLieferung
-- diese FUnktion ermittelt das Produkt aus der Eingabe (Anzahl, Stückpreis) und liefert dieses zurück

DELIMITER $$
CREATE OR REPLACE function fn_GetGesamtPreisLieferung(inAnzahl int, inStueckpreis decimal(8,2))
returns decimal(8,2)
BEGIN 
    declare vOutGesamtPreis decimal(8,2);
    set vOutGesamtPreis = (inAnzahl * inStueckpreis);
    return vOutGesamtPreis;
END $$
DELIMITER ;

-- Testfälle
-- 1. Fall erwartet 100.00
select fn_GetGesamtPreisLieferung(20,5.00);

/********************************************************************************************************/

-- /F20.1.2.13./ Neue Lieferung anlegen - p_NewLieferung 
-- diese Prozedur erwartet als Übergabe ein Lieferdatum, eine Anzahl sowie einen Stückpreis
-- sie erstellt einen neuen Datensatz in der Tballe LIEFERUNG

DELIMITER $$
CREATE OR REPLACE procedure p_NewLieferung (inLieferDatum date, inAnzahl int, inStueckpreis decimal(8,2))
BEGIN
    declare vLetzteLieferdetailsID int;
    set vLetzteLieferdetailsID = (select MAX(LieferdetailsID) from Lieferdetails);

    Insert into lieferung (LieferDatum, GesamtPreis, LieferdetailsID)
    VALUES (inLieferDatum, fn_GetGesamtPreisLieferung(inAnzahl, inStueckpreis), vLetzteLieferdetailsID);
END $$
DELIMITER ;

-- Testfälle
-- 1. Fall erwartet neuen Eintrag in der Tabelle Lieferung (402, 2023-07-03, 500.00, 402)
call p_NewLieferung('2023-07-03', 10, 50.00);

/********************************************************************************************************/

-- /F20.1.2.14./ Mindestbestand ermitteln - fn_GetMindestbestand 
-- diese Funktion sucht mittels Eingabe (Stadtnamen, Einzelteilbezeichnung) den jeweiligen Mindestbestand und gibt diesen zurück
-- dass das Einzelteil im Lager registriert ist, wird über die Funktion fn_GetLagerEinzelteileID überprüft

DELIMITER $$
CREATE OR REPLACE function fn_GetMindestBestand(inStadt varchar(30), inEinzeilteilBezeichnung varchar(50))
returns int
BEGIN
    declare vOutMindestBestand int;

    select MinBestand into vOutMindestBestand
    from lager_einzelteile
    where Lager_ETeileID = fn_GetLagerEinzelteileID(inStadt, inEinzeilteilBezeichnung);

    return vOutMindestBestand;
END $$
DELIMITER ;

-- Testfälle
-- 1. Fall erwartet 220 als Rückgabe
select fn_GetMindestBestand('Erfurt', 'Lithium-Ionen');

/********************************************************************************************************/

-- /F20.1.2.15./ Aktuellen Bestand ermitteln - fn_GetBestand 
-- diese Funktion sucht mittels Eingabe (Stadtnamen, Einzelteilbezeichnung) den jeweiligen Mindestbestand und gibt diesen zurück
-- dass das Einzelteil im Lager registriert ist, wird über die Funktion fn_GetLagerEinzelteileID überprüft

DELIMITER $$
CREATE OR REPLACE function fn_GetBestand(inStadt varchar(30), inEinzeilteilBezeichnung varchar(50))
returns int
BEGIN
    declare vOutBestand int;

    select Bestand into vOutBestand
    from lager_einzelteile
    where Lager_ETeileID = fn_GetLagerEinzelteileID(inStadt, inEinzeilteilBezeichnung);

    return vOutBestand;
END $$
DELIMITER ;

-- Testfälle
-- 1. Fall erwartet 354 als Rückgabe
select fn_GetBestand('Erfurt', 'Lithium-Ionen');

/********************************************************************************************************/

-- /F20.1.2.16./ Maximalbestand ermitteln - fn_GetMaxBestand 
-- diese Funktion sucht mittels Eingabe (Stadtnamen, Einzelteilbezeichnung) den jeweiligen Mindestbestand und gibt diesen zurück
-- dass das Einzelteil im Lager registriert ist, wird über die Funktion fn_GetLagerEinzelteileID überprüft

DELIMITER $$
CREATE OR REPLACE function fn_GetMaxBestand(inStadt varchar(30), inEinzeilteilBezeichnung varchar(50))
returns int
BEGIN
    declare vOutMaximalBestand int;

    select MaxBestand into vOutMaximalBestand
    from lager_einzelteile
    where Lager_ETeileID = fn_GetLagerEinzelteileID(inStadt, inEinzeilteilBezeichnung);

    return vOutMaximalBestand;
END $$
DELIMITER ;

-- Testfälle
-- 1. Fall erwartet 520 als Rückgabe
select fn_GetMaxBestand('Erfurt', 'Lithium-Ionen');

/********************************************************************************************************/

-- /F20.1.2.17./ Neuen Restbestand ermitteln - fn_BerechneNeuenBestand
-- diese Funktion sucht berechnet mittels der Eingabe (Stadtname, Einzelteilbezeichnung, Anzahl) den neuen Lagerbestand
-- innerhalb der Funktion wird über die FUnktion fn_GetBestand der aktuelle BEstand ermittelt

DELIMITER $$
CREATE OR REPLACE function fn_BerechneNeuenBestand(inStadt varchar(30), inEinzeilteilBezeichnung varchar(50), inAnzahl int)
returns int
BEGIN
    return (fn_GetBestand(inStadt, inEinzeilteilBezeichnung) + inAnzahl);
END $$
DELIMITER ;

-- Testfälle
-- 1. Fall erwartet 500 als Rückgabe
select fn_BerechneNeuenBestand('Erfurt', 'Metallkettenschutz', 34)

/********************************************************************************************************/

-- /F20.1.2.18./ Standort eines Lagers ermitteln - fn_GetLagerStandortId
-- Diese Funktion erwartet als Übergabe einen Stadtnamen. Innerhalb der Funktion wird über den Aufruf der Funktion fn_GetLagerId die LagerId ermitteln. Die Funktion liefert die zugehörige StandortId für das jeweilige Lager zurück. Dass es in der Stadt ein Lager gibt, wird durch die Funktion fn_GetLagerId überprüft. 

/********************************************************************************************************/

-- /F20.1.2.19./ Prüfen ob Roller-Lieferung - fn_IstRollerLieferung
-- Diese Funktion erwartet als Übergabe eine Einzelteilbezeichnung und dient der Kategorisierung des Wareneinganges. Sie liefert den Wahrheitswert True, wenn es sich beim Wareneingang um einen Roller handelt, sonst False zurück.

DELIMITER $$
CREATE OR REPLACE function fn_IstRollerLieferung(inEinzeilteilBezeichnung varchar(50))
returns int
BEGIN
    declare vOut int;
    set vOut = 1;
    if inEinzeilteilBezeichnung = 'Roller'
        then set vOut = 0;
    end if;
    return vOut;
END $$
DELIMITER ;

/********************************************************************************************************/

-- /F20.1.2.20./ Roller-Eintrag anlegen - p_NewRoller
-- Diese Prozedur erwartet als Übergabe ein Datum, welches das letzte Wartungs-Datum repräsentiert (Format: yyyy-mm-dd), sowie einen Stadtnamen. Innerhalb der Prozedur wird durch den Aufruf der Funktion fn_BerechneNächsteWartung das nächste Wartungs-Datum ermittelt. Die Werte IstDefekt sowie Batterie werden als Standardwerte auf 0 beziehungsweise 100 gesetzt. Über den Aufruf der Funktion fn_GetLagerId wird mittels Übergabe des Stadtnamens die LagerId ermittelt. Die Funktion fn_GetLagerStandortId ermitteln die StandortId. Die Prozedur fügt daraufhin einen neuen Datensatz in der Tabelle EROLLER ein.

/********************************************************************************************************/

-- /F20.1.2.21./ Neues Wartungs-Datum ermitteln - fn_BerechneNächsteWartung
-- Diese Funktion erwartet als Eingabe ein Datum (Format: yyyy-mm-dd) und ermittelt nach einer Berechnungsvorschrift (durch Geschäftsbedingungen festgelegt) das nächste Wartungsdatum und liefert dieses zurück. 

/********************************************************************************************************/

-- /F20.1.2.22./ Neuen Restbestand überprüfen - fn_KontrolliereBestand
-- Diese Funktion erwartet als Eingabe einen Stadtnamen, eine Einzelteilbezeichnung sowie einen neuen Restbestand
-- Innerhalb der Funktion wird durch die Aufrufe der Funktionen fn_GetLagerId sowie fn_GetEinzelteilId, die LagerId und die EinzelzeilId ermitteln
-- Durch übergabe der Id´s an die Funktion fn_GetLagerEinzelteilId wird die Lager_EinzelteilId ermitteln
-- Innerhalb der Funktion wird die Funktion fn_GetMaxBestand aufgerufen und der zurückgelieferte Wert wird mit dem neuen Restbestand verglichen
-- Ist der neue Restbestand größer als der Maximalbestand, soll der neue Bestand auf den Maximalbestand gesetzt werden und es soll eine Fehlermeldung ausgegeben werden
-- in welcher die Anzahl der überschüssigen Artikel vermerkt wird.

DELIMITER $$
CREATE OR REPLACE function fn_KontrolliereBestand(inStadt varchar(30), inEinzeilteilBezeichnung varchar(50), inNeuerBestand int)
returns int
BEGIN
    declare vOut int;

    if ((fn_GetMaxBestand(inStadt, inEinzeilteilBezeichnung)) < inNeuerBestand) 
        then SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Nicht genügend Kapazität im Lager vorhanden!';         
    end if;

    set vOut = 1;
    return vOut;
END $$
DELIMITER ;

-- Testfälle
-- 1. Fall erwartet Rückgabe 1
select fn_KontrolliereBestand('Erfurt', 'Aluminiumlenker', 700);

-- 2. Fall erwartet Fehlermeldung, da neuer Bestand den Maximalbestand überschreitet
select fn_KontrolliereBestand('Erfurt', 'Aluminiumlenker', 900);

/********************************************************************************************************/

-- /F20.1.2./ Wareneingang neu anlegen - Prozedur p_CreateNewWareneingang
-- diese Funktion erwartet als Übergabe einen Stadtnamen, Lieferantennamen, eine Einzelteilbezeichnung, eine Anzahl, einen Stückpreis, einen Mindestbestand, Maximalbestand, ein Gewicht 
DELIMITER $$
CREATE OR REPLACE procedure p_CreateNewWareneingang(inStadt varchar(30), inEinzeilteilBezeichnung varchar(50), inAnzahl int, inStueckpreis decimal (8,2), inMindestBestand int, inMaximalBestand int, inGewicht decimal (5,2))
BEGIN

    if (fn_IstRollerLieferung(inEinzeilteilBezeichnung)) = 0
        then SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Roller Lieferungen können derzeit noch nicht automatisch eingetragen werden. Dieser Schritt muss noch implementiert werden!';
    end if;

    

END$$
DELIMITER ;