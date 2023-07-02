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
-- Diese Prozedur erwartet als Eingabe Artikeltyp, Artikelname sowie das Gewicht in Gramm des Einzelteils und fügt einen neuen Datensatz in die Tabelle EINZELTEIL ein, sofern das Einzelteil noch nicht existiert. Dies wird mit der Funktion fn_GetEinzelteilID überprüft.

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
-- Diese Prozedur erwartet als Eingabe den Mindestbestand, Maximalbestand, einen Stadtnamen sowie eine Einzelteilbezeichnung. Innerhalb der Prozedur wird durch die Aufrufe der Funktionen fn_GetLagerId und fn_GetEinzelteilId werden die Werte für die LagerId sowie EinzelteilId ermittelt. Da diese Prozedur nur aufgerufen werden kann, sofern ein Artikel neu im Lager ist, wird der aktuelle Bestand automatisch auf den Wert 0 gesetzt, welcher später durch die Prozedur p_UpdateBestand aktualisiert wird. Nachdem die Prozedur die benötigten Werte ermittelt hat, fügt sie einen neuen Datensatz in die Tabelle LAGER_EINZELTEILE ein, sofern das Einzelteil noch nicht im Lager registriert ist. Dies wird mit der Funktion fn_GetLagerEinzelteileID überprüft.

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
-- Diese Prozedur erwartet als Übergabe einen Lieferantennamen. Innerhalb der Prozedur wird das letzte Lieferungsdatum auf den Standardwert 2015-01-01 gesetzt und wird später durch die Prozedur p_UpdateLieferantLetzteLieferung automatisch aktualisiert. Die Prozedur fügt einen neuen Datensatz in die Tabelle LIEFERANT ein, sofern der Lieferant noch nicht im System registriert ist. Dies wird mit der Funktion fn_GetLieferantId überprüft.

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
-- Diese Prozedur erwarten als Übergabe einen Lieferantennamen und einen Stadtnamen. Innerhalb der Funktion werden durch die Aufrufe der Funktionen fn_GetLagerId und fn_GetLieferantId die LagerId und LieferantenId ermittelt. Die Prozedur fügt einen neuen Datensatz in die Tabelle LAGER_LIEFERANT ein, sofern der Lieferant für das jeweilige Lager noch nicht registriert ist. Dies wird mit der Funktion fn_GetLagerLieferantId überprüft.

/********************************************************************************************************/

-- /F20.1.2.10./ Letzte Lieferung aktualisieren - p_UpdateLieferantLetzteLieferung
-- Diese Funktion erwartet als Übergabe einen Lieferantennamen sowie ein Datum (Format: yyyy-mm-dd). Innerhalb der Prozedur wird über den Aufruf der Funktion fn_GetLieferantId die LieferantenId ermitteln. Die Prozedur aktualisiert das letzte Lieferungsdatum eines Lieferanten, welcher durch die LieferantenId referenziert wird. Dass der Lieferant registriert ist, wird über die Funktion fn_GetLieferantId überprüft.

/********************************************************************************************************/

-- /F20.1.2.11./ Lagerbestand aktualisieren - p_UpdateLagerbestand 
-- Diese Prozedur erwartet als Übergabe einen Stadtnamen, eine Einzelteilzeichnung sowie die Anzahl der gelieferten Artikel. Innerhalb der Prozedur wird durch Aufruf der Funktionen fn_GetLagerID sowie fn_GetEinzelteilID die Werte für die LagerId und EinzelteilId ermittelt. Nachdem diese Werte ermitteln wurden wird innerhalb noch die Funktion fn_GetLagerEinzelteileID aufgerufen, welche die Lager_EinzelteilId ermitteln. Über die Funktionen fn_GetBestand sowie fn_GetMaxBestand wird der aktuelle Bestand als auch der Maximalbestand ermittelt. Die Prozedur ruft die Funktion fn_BerechneNeuenBestand mit den benötigten Übergabewerten auf und aktualisiert den Bestand des Artikels, welcher über die Lager_EinzelteilId referenziert wird. Dass der Artikel in dem Lager registriert ist, wird über die Funktion fn_GetLagerEinzelteileID geprüft.

/********************************************************************************************************/

-- /F20.1.2.12./ Lieferdetails-Eintrag anlegen - p_NewLieferDetails 
-- Diese Prozedur erwartet als Übergabe eine Anzahl, einen Stückpreis, einen Stadtnamen, einen Lieferantennamen sowie eine Einzelteilbezeichnung. Innerhalb der Prozedur wird durch die Aufrufe der Funktionen fn_GetLagerId die LagerId und fn_GetLieferantId die LieferantId ermitteln. Durch den Aufruf der Funktion fn_GetLagerLieferantId wird mittels der Übergabe der zuvor Ermittelten Id ́s die Lager_LieferId bereitgestellt. Außerdem wird in der Prozedur noch geprüft, ob es sich um eine Roller Lieferung oder um eine Einzelteil Lieferung handelt. Bei einer Roller-Lieferung wird die automatisch erzeugte ID genutzt für den neuen Tabelleneintrag, bei Einzelzeilen wird durch den Aufruf der Funktion fn_GetEinzelteilId die EinzelteilId ermittelt. Die Prozedur fügt mit den ermittelten Daten einen neuen Datensatz in der Tabelle LIEFERDETAILS ein.

/********************************************************************************************************/

-- /F20.1.2.13/ Gesamtpreis ermitteln - fn_GetGeamtPreisLieferung
-- Diese Funktion erwartet als Übergabe eine Anzahl, sowie einen Stückpreis und liefert den berechneten Gesamtpreis (Anzahl * Stückpreis) zurück.

/********************************************************************************************************/

-- /F20.1.2.13./ Neue Lieferung anlegen - p_NewLieferung 
-- Diese Prozedur erwartet als Übergabe ein Lieferdatum, einen Gesamtpreis sowie eine LieferdetailsId und fügt einen neuen Datensatz in der Tabelle LIEFERUNG ein. 

/********************************************************************************************************/

-- /F20.1.2.14./ Mindestbestand ermitteln - fn_GetMindestbestand 
-- Diese Funktion erwartet als Eingabe einen Stadtnamen sowie eine Einzelteilbezeichnung. Innerhalb der Funktion wird durch die Aufrufe der Funktionen fn_GetLagerId sowie fn_GetEinzelteilId, die LagerId und die EinzelzeilId ermitteln. Durch übergabe der Id´s an die Funktion fn_GetLagerEinzelteilId wird die Lager_EinzelteilId ermitteln. Die Funktion gibt den jeweiligen Mindestbestand zurück.

/********************************************************************************************************/

-- /F20.1.2.15./ Aktuellen Bestand ermitteln - fn_GetBestand 
-- Diese Funktion erwartet als Eingabe einen Stadtnamen sowie eine Einzelteilbezeichnung. Innerhalb der Funktion wird durch die Aufrufe der Funktionen fn_GetLagerId sowie fn_GetEinzelteilId, die LagerId und die EinzelzeilId ermitteln. Durch übergabe der Id´s an die Funktion fn_GetLagerEinzelteilId wird die Lager_EinzelteilId ermitteln. Die Funktion gibt den jeweiligen aktuellen Bestand zurück.

/********************************************************************************************************/

-- /F20.1.2.16./ Maximalbestand ermitteln - fn_GetMaxBestand 
-- Diese Funktion erwartet als Eingabe einen Stadtnamen sowie eine Einzelteilbezeichnung. Innerhalb der Funktion wird durch die Aufrufe der Funktionen fn_GetLagerId sowie fn_GetEinzelteilId, die LagerId und die EinzelzeilId ermitteln. Durch übergabe der Id´s an die Funktion fn_GetLagerEinzelteilId wird die Lager_EinzelteilId ermitteln. Die Funktion gibt den jeweiligen Maximalbestand zurück.

/********************************************************************************************************/

-- /F20.1.2.17./ Neuen Restbestand ermitteln - fn_BerechneNeuenBestand 
-- Diese Funktion erwartet als Eingabe den aktuellen Bestand sowie die Anzahl der gelieferten Artikel und gibt die Summe dieser beiden Werte zurück. 

/********************************************************************************************************/

-- /F20.1.2.18./ Standort eines Lagers ermitteln - fn_GetLagerStandortId
-- Diese Funktion erwartet als Übergabe einen Stadtnamen. Innerhalb der Funktion wird über den Aufruf der Funktion fn_GetLagerId die LagerId ermitteln. Die Funktion liefert die zugehörige StandortId für das jeweilige Lager zurück. Dass es in der Stadt ein Lager gibt, wird durch die Funktion fn_GetLagerId überprüft. 

/********************************************************************************************************/

-- /F20.1.2.19./ Prüfen ob Roller-Lieferung - fn_IstRollerLieferung
-- Diese Funktion erwartet als Übergabe eine Einzelteilbezeichnung und dient der Kategorisierung des Wareneinganges. Sie liefert den Wahrheitswert True, wenn es sich beim Wareneingang um einen Roller handelt, sonst False zurück.

/********************************************************************************************************/

-- /F20.1.2.20./ Roller-Eintrag anlegen - p_NewRoller
-- Diese Prozedur erwartet als Übergabe ein Datum, welches das letzte Wartungs-Datum repräsentiert (Format: yyyy-mm-dd), sowie einen Stadtnamen. Innerhalb der Prozedur wird durch den Aufruf der Funktion fn_BerechneNächsteWartung das nächste Wartungs-Datum ermittelt. Die Werte IstDefekt sowie Batterie werden als Standardwerte auf 0 beziehungsweise 100 gesetzt. Über den Aufruf der Funktion fn_GetLagerId wird mittels Übergabe des Stadtnamens die LagerId ermittelt. Die Funktion fn_GetLagerStandortId ermitteln die StandortId. Die Prozedur fügt daraufhin einen neuen Datensatz in der Tabelle EROLLER ein.

/********************************************************************************************************/

-- /F20.1.2.21./ Neues Wartungs-Datum ermitteln - fn_BerechneNächsteWartung
-- Diese Funktion erwartet als Eingabe ein Datum (Format: yyyy-mm-dd) und ermittelt nach einer Berechnungsvorschrift (durch Geschäftsbedingungen festgelegt) das nächste Wartungsdatum und liefert dieses zurück. 

/********************************************************************************************************/

-- /F20.1.2.22./ Neuen Restbestand überprüfen - fn_KontrolliereBestand
-- Diese Funktion erwartet als Eingabe einen Stadtnamen, eine Einzelteilbezeichnung sowie einen neuen Restbestand. Innerhalb der Funktion wird durch die Aufrufe der Funktionen fn_GetLagerId sowie fn_GetEinzelteilId, die LagerId und die EinzelzeilId ermitteln. Durch übergabe der Id´s an die Funktion fn_GetLagerEinzelteilId wird die Lager_EinzelteilId ermitteln. Innerhalb der Funktion wird die Funktion fn_GetMaxBestand aufgerufen und der zurückgelieferte Wert wird mit dem neuen Restbestand verglichen. Ist der neue Restbestand größer als der Maximalbestand, soll der neue Bestand auf den Maximalbestand gesetzt werden und es soll eine Fehlermeldung ausgegeben werden, in welcher die Anzahl der überschüssigen Artikel vermerkt wird.