-- phpMyAdmin SQL Dump
-- version 5.2.1
-- https://www.phpmyadmin.net/
--
-- Host: 127.0.0.1
-- Erstellungszeit: 12. Jul 2023 um 15:34
-- Server-Version: 10.4.28-MariaDB
-- PHP-Version: 8.2.4

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Datenbank: `ew_db`
--

CREATE DATABASE IF NOT EXISTS `ew_db` DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci;
USE `ew_db`;

DELIMITER $$
--
-- Prozeduren
--
CREATE DEFINER=`root`@`localhost` PROCEDURE `p_BuchungsStatView` ()   begin

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

CREATE DEFINER=`root`@`localhost` PROCEDURE `p_CreateFahrtenbuch` (`inFirmenwagenID` INT, `inMitarbeiterEmail` VARCHAR(100))   begin
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

    -- select LAST_INSERT_ID(); 

end$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `p_CreateFirmenwagen` (`inFirmenwagenID` INT, `inAutoType` VARCHAR(50), `inNaechsteWartung` DATE, `inLagerID` INT)   begin

    insert into fuhrpark
    values (inFirmenwagenID, inAutoType, inNaechsteWartung, inLagerID);

end$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `p_CreateHaltepunkt` (`inFahrtenbuchID` INT, `inRollerID` INT)   begin
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
        SIGNAL RollerSchonInEinenWagen SET MESSAGE_TEXT = 'Roller ist schon in einem Wagen';
    end if;

    Insert Into Haltepunkt(Zeitpunkt, FahrtenbuchID, StandortID)
    values (CURRENT_TIMESTAMP(), inFahrtenbuchID, fn_GetRollerStandort(inRollerID));

    update eroller
    set HaltepunktID = (select Max(HaltepunktID) from Haltepunkt where FahrtenbuchID = inFahrtenbuchID and StandortID = fn_GetRollerStandort(inRollerID))
    where ERollerID = inRollerID;


end$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `p_CreateKundenStatistik` ()   BEGIN
    SELECT CONCAT(k.Vorname, ' ', k.Nachname) as Kunde, COUNT(*) AS 'Anzahl der Buchungen',   
           SUBSTRING(SEC_TO_TIME(AVG(TIME_TO_SEC(Nutzdauer))), 1, 8) AS 'Durchschnittliche Nutzungsdauer',
           ROUND(AVG(GesamtFahrstecke), 2) AS 'Durchschnittliche Fahrtstrecke',
           SEC_TO_TIME(SUM(TIME_TO_SEC(Nutzdauer))) AS 'Gesamte Nutzungsdauer',
           SUM(GesamtFahrstecke) AS 'Gesamte Fahrstrecke'
        FROM bestellung_eroller be
        join kunde k on be.KundeID = k.KundeID
        GROUP BY k.KundeID
        ORDER BY 2 DESC;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `p_CreateLieferungÜbersicht` (`inStadt` VARCHAR(30), `inStartDatum` DATE, `inEndDatum` DATE)   BEGIN

    if inStadt = ''
        then
            SELECT s.Stadt AS 'Lager (Stadt)', li.LieferantName AS Lieferant,e.EName as Einzelteil, ld.Anzahl as 'Anzahl der Einzelteile', l.GesamtPreis AS Gesamtpreis, l.LieferDatum AS Lieferdatum
            FROM lieferung l
            JOIN lieferdetails ld ON l.lieferdetailsID = ld.lieferdetailsID
            JOIN lager_lieferant lf ON ld.Lager_LieferID = lf.Lager_LieferID
            JOIN lieferant li ON lf.LieferantID = li.LieferantID
            JOIN lager la ON la.LagerID = lf. LagerID
            JOIN standort s on s.StandortID = la.StandortID
            JOIN einzelteile e on e.EinzelteileID = ld.EinzelteileID
            WHERE (l.Lieferdatum >= inStartDatum) and (l.Lieferdatum <= inEndDatum)
            ORDER BY la.LagerID, li.LieferantName, l.LieferDatum ASC;
    else
            SELECT s.Stadt AS 'Lager (Stadt)', li.LieferantName AS Lieferant,e.EName as Einzelteil, ld.Anzahl as 'Anzahl der Einzelteile', l.GesamtPreis AS Gesamtpreis, l.LieferDatum AS Lieferdatum
            FROM lieferung l
            JOIN lieferdetails ld ON l.lieferdetailsID = ld.lieferdetailsID
            JOIN lager_lieferant lf ON ld.Lager_LieferID = lf.Lager_LieferID
            JOIN lieferant li ON lf.LieferantID = li.LieferantID
            JOIN lager la ON la.LagerID = lf. LagerID
            JOIN standort s on s.StandortID = la.StandortID
            JOIN einzelteile e on e.EinzelteileID = ld.EinzelteileID
            WHERE (l.Lieferdatum >= inStartDatum) and (l.Lieferdatum <= inEndDatum) and (s.Stadt = UPPER(inStadt))
            ORDER BY la.LagerID, li.LieferantName, l.LieferDatum ASC;
	end if;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `p_CreateNewEinzelteilLieferung` (`inStadt` VARCHAR(30), `inLieferantName` VARCHAR(50), `inEinzeilteilBezeichnung` VARCHAR(100), `inLieferDatum` DATE, `inEinzelteiltyp` VARCHAR(50), `inAnzahl` INT, `inStueckpreis` DECIMAL(8,2), `inMindestBestand` INT, `inMaximalBestand` INT, `inGewicht` DECIMAL(8,2))   BEGIN
    declare vLagerID int;
    declare vLieferantId int;
    declare vEinzelteilID int;
    
    set vLagerID = fn_GetLagerID(inStadt);
    set vLieferantId = fn_GetLieferantID(inLieferantName);
    set vEinzelteilID = fn_GetEinzelteilID(inEinzeilteilBezeichnung);


    if fn_GetLagerID(inStadt) = -1
        then SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'In dieser Stadt gibt es kein Lager, bitte Eingabe überprüfen!';
    end if;

    if vLieferantId = -1
        then
            call p_NewLieferant(inLieferantName);
            call p_NewLagerLieferant(inLieferantName, inStadt);
    elseif (fn_GetLagerLieferantID(inStadt, inLieferantName)) = -1
        then
            call p_NewLagerLieferant(inLieferantName, inStadt);
    end if;

    if vEinzelteilID = -1
        then
            call p_NewEinzelteil(inEinzelteilTyp, inEinzeilteilBezeichnung, inGewicht);
            call p_NewLagerEinzelteil(inMindestBestand, inMaximalBestand, inStadt, inEinzeilteilBezeichnung);
    elseif (fn_GetLagerEinzelteileID(inStadt, inEinzeilteilBezeichnung)) = -1
        then
            call p_NewLagerEinzelteil(inMindestBestand, inMaximalBestand, inStadt, inEinzeilteilBezeichnung);
    end if;

    if fn_KontrolliereBestand(inStadt, inEinzeilteilBezeichnung, fn_BerechneNeuenBestand(inStadt, inEinzeilteilBezeichnung, inAnzahl)) = 1 and (fn_KontrolliereDatum(inLieferDatum) = 1)
        then
        call p_UpdateLieferantLetzteLieferung(inLieferantName, inLieferDatum);
        call p_UpdateLagerbestand(inStadt, inEinzeilteilBezeichnung, inAnzahl);
        call p_NewLieferDetails(inAnzahl, inStueckpreis, inStadt, inLieferantName, inEinzeilteilBezeichnung);
        call p_NewLieferung(inLieferDatum, inAnzahl, inStueckpreis);
    end if;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `p_CreateNewWareneingang` (`inStadt` VARCHAR(30), `inLieferantName` VARCHAR(50), `inEinzeilteilBezeichnung` VARCHAR(100), `inLieferDatum` DATE, `inEinzelteiltyp` VARCHAR(50), `inAnzahl` INT, `inStueckpreis` DECIMAL(8,2), `inMindestBestand` INT, `inMaximalBestand` INT, `inGewicht` DECIMAL(8,2))   BEGIN
    if (fn_IstRollerLieferung(inEinzeilteilBezeichnung)) = 1
        then SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Roller Lieferungen können derzeit noch nicht automatisch eingetragen werden. Dieser Schritt muss noch implementiert werden!';
    elseif fn_IstRollerLieferung(inEinzeilteilBezeichnung) = 0
        then call p_CreateNewEinzelteilLieferung(inStadt, inLieferantName, inEinzeilteilBezeichnung, inLieferDatum, inEinzelteilTyp, inAnzahl, inStueckpreis, inMindestBestand, inMaximalBestand, inGewicht);
    else
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Wareneingang konnte nicht kategorisiert werden, bitte Eingabe überprüfen!';
    end if;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `p_Fahrtenbuch` (`inFirmenwagenID` INT, `inMitarbeiterEmail` VARCHAR(100), `inFahrtenbuchID` INT)   begin
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

CREATE DEFINER=`root`@`localhost` PROCEDURE `p_FahrtenbuchView` ()   begin

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

CREATE DEFINER=`root`@`localhost` PROCEDURE `p_FinishFahrtenbuch` (`inFahrtenbuchID` INT)   begin

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

CREATE DEFINER=`root`@`localhost` PROCEDURE `p_NewEinzelteil` (`inEinzelteilTyp` VARCHAR(50), `inEinzeilteilBezeichnung` VARCHAR(100), `inGewicht` DECIMAL(8,2))   BEGIN
    if (fn_GetEinzelteilID(inEinzeilteilBezeichnung)) = -1
        then INSERT Into einzelteile (EType, EName, Gewicht)
        VALUES (inEinzelteilTyp, inEinzeilteilBezeichnung, inGewicht);
    else
         SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT ='Ein Einzelteil mit diesem Namen ist schon im System registriert!';
    end if;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `p_NewLagerEinzelteil` (`inMindestBestand` INT, `inMaximalBestand` INT, `inStadt` VARCHAR(30), `inEinzeilteilBezeichnung` VARCHAR(100))   BEGIN
    if (fn_GetLagerEinzelteileID(inStadt, inEinzeilteilBezeichnung)) = -1
        then INSERT into lager_einzelteile (MinBestand, MaxBestand, Bestand, LagerID, EinzelteileId)
        VALUES (inMindestBestand, inMaximalBestand, 0, fn_GetLagerID(inStadt), fn_GetEinzelteilID(inEinzeilteilBezeichnung));
    else
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Das Einzelteil ist schon in diesem Lager registriert!';
    end if;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `p_NewLagerLieferant` (`inLieferantName` VARCHAR(50), `inStadt` VARCHAR(30))   BEGIN
    if (fn_GetLagerLieferantID(inStadt, inLieferantName)) = -1
        then INSERT into lager_lieferant (LieferantID, LagerID)
        VALUES (fn_GetLieferantID(inLieferantName), fn_GetLagerID(inStadt));
    else
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Der Lieferant ist schon in diesem Lager registriert!';
    end if;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `p_NewLieferant` (`inLieferantName` VARCHAR(50))   BEGIN
    if (fn_GetLieferantID(inLieferantName)) = -1
        then INSERT Into Lieferant (LieferantName, LetzteLieferung)
        VALUES (inLieferantName, '2015-01-01');
    else
         SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT ='Lieferant existiert schon im System!';
    end if;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `p_NewLieferDetails` (`inAnzahl` INT, `inStueckpreis` DECIMAL(8,2), `inStadt` VARCHAR(30), `inLieferantName` VARCHAR(50), `inEinzeilteilBezeichnung` VARCHAR(100))   BEGIN
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
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `p_NewLieferung` (`inLieferDatum` DATE, `inAnzahl` INT, `inStueckpreis` DECIMAL(8,2))   BEGIN
    declare vLetzteLieferdetailsID int;
    set vLetzteLieferdetailsID = (select MAX(LieferdetailsID) from Lieferdetails);

    Insert into lieferung (LieferDatum, GesamtPreis, LieferdetailsID)
    VALUES (inLieferDatum, fn_GetGesamtPreisLieferung(inAnzahl, inStueckpreis), vLetzteLieferdetailsID);
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `p_RollerInLager` (`inFahrtenbuchID` INT)   begin
    declare vFirmenwagen int;

    select FirmenwagenID into vFirmenwagen from fahrtenbuch where fahrtenbuchID = inFahrtenbuchID;

    update ERoller
    set HaltepunktID = NULL, 
    StandortID = fn_GetFirmenwagenStandort(vFirmenwagen)
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

CREATE DEFINER=`root`@`localhost` PROCEDURE `p_SetAllGesamtPreisERollerBuchung` ()   BEGIN
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
	call p_SetGesamtPreisERollerBuchung(vID);	
	
		FETCH vZahlungCur into vID;
			IF vDone
				THEN LEAVE setGesamtPreisLoop;
			END IF;			
		END LOOP;
		CLOSE vZahlungCur;			
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `p_SetAllGesamtPreisLieferung` ()   BEGIN
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
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `p_SetAllLetzteZahlung` ()   BEGIN
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
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `p_SetGesamtPreisERollerBuchung` (IN `inZahlungID` INT)   BEGIN
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

CREATE DEFINER=`root`@`localhost` PROCEDURE `p_SetGesamtPreisLieferung` (IN `inLieferungID` INT)   BEGIN
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

CREATE DEFINER=`root`@`localhost` PROCEDURE `p_SetLetzteZahlung` (IN `inKundeID` INT)   BEGIN
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

CREATE DEFINER=`root`@`localhost` PROCEDURE `p_ShowWartung` (`inFirmenwagenID` INT)   begin

    select FirmenwagenID, NaechsteWartung
    from fuhrpark
    where FirmenwagenID = inFirmenwagenID;

end$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `p_UpdateLagerbestand` (`inStadt` VARCHAR(30), `inEinzeilteilBezeichnung` VARCHAR(50), `inAnzahl` INT)   BEGIN
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
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `p_UpdateLieferantLetzteLieferung` (`inLieferantName` VARCHAR(50), `inDatum` DATE)   BEGIN
    if (fn_KontrolliereDatum(inDatum)) = 1
        then
            if (fn_GetLieferantID(inLieferantName)) = -1
                then SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Es existiert kein Lieferant mit diesem Namen!';
            elseif inDatum < (select LetzteLieferung from Lieferant where LieferantName = inLieferantName)
                then SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Das neue LetzeLieferungsdatum darf nicht länger her sein als das LetzeLieferungsdatum! Bitte Eingabe prüfen!';
            else
                Update lieferant
                set LetzteLieferung = inDatum
                where LieferantName = inLieferantName;
            end if;
    end if;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `p_UpdateWartung` (`inFirmenwagenID` INT, `inNewWartung` DATE)   begin
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

--
-- Funktionen
--
CREATE DEFINER=`root`@`localhost` FUNCTION `fn_BerechneNeuenBestand` (`inStadt` VARCHAR(30), `inEinzeilteilBezeichnung` VARCHAR(50), `inAnzahl` INT) RETURNS INT(11)  BEGIN
    return (fn_GetBestand(inStadt, inEinzeilteilBezeichnung) + inAnzahl);
END$$

CREATE DEFINER=`root`@`localhost` FUNCTION `fn_CalculateFahrtdauer` (`inFahrtenbuchID` INT) RETURNS TIME  BEGIN
    declare outFahrtdauer time;

    select SUBTIME(from_unixtime(((UNIX_TIMESTAMP(Fahrtstart) - UNIX_TIMESTAMP(Fahrtende)) * (-1)), '%h:%i:%s'), '01:00:00')
    into outFahrtdauer 
    from fahrtenbuch 
    where FahrtenbuchID = inFahrtenbuchID;

    return outFahrtdauer;
end$$

CREATE DEFINER=`root`@`localhost` FUNCTION `fn_CheckIntegritaet` (`inFirmenwagenID` INT, `inMitarbeiterID` INT) RETURNS TINYINT(1)  begin
    declare vIntegritaet tinyint(1);

    DECLARE AbbruchJobName CONDITION FOR SQLSTATE '45000';
    DECLARE AbbruchMitarbeiterStandort CONDITION FOR SQLSTATE '45000';
    DECLARE NichtAbgeschlossenerEintrag CONDITION FOR SQLSTATE '45000';
    DECLARE AutoIstNochInBenutzung CONDITION FOR SQLSTATE '45000';

    if fn_GetFirmenwagenStandort(inFirmenwagenID) != fn_GetMitarbeiterStandort(inMitarbeiterID)
        then
        SIGNAL AbbruchMitarbeiterStandort SET MESSAGE_TEXT = 'Mitarbeiter und Lager/Fahrzeug sind nicht an Selben Standort/Region';
    end if;


    if STRCMP((select JobName from mitarbeiter where MitarbeiterID = inMitarbeiterID), 'KFZ-WH') != 0
        then
        SIGNAL AbbruchJobName SET MESSAGE_TEXT = 'Nicht passender JobName';
    end if;


-- es wird hier immer nur der Letzte Eintrag des Mitarbeiter/Fahrzeugs betrachte, 
--  weil der Rest wenn alles so wie geplannt funktioniert schon geprüft wurde

    if IFNUll((select Fahrtende from Fahrtenbuch where MitarbeiterID = inMitarbeiterID having max(Fahrtstart) < Fahrtende),-1) = -1
        then
        SIGNAL NichtAbgeschlossenerEintrag SET MESSAGE_TEXT ='Mitarbeiter hat noch einen nicht abgeschlossen Fahrtenbucheintrag';
    end if;


    if IFNUll((select Fahrtende from Fahrtenbuch where FirmenwagenID = inFirmenwagenID having max(Fahrtstart) < Fahrtende),-1) = -1
        then
        SIGNAL AutoIstNochInBenutzung SET MESSAGE_TEXT ='Das Ausgewealte Firmenfahrzeug ist noch in Benutztung';
    end if;
                        
    set vIntegritaet = 1;


    return IFNUll(vIntegritaet, -1);
end$$

CREATE DEFINER=`root`@`localhost` FUNCTION `fn_CheckRollerStatusH` (`inRollerID` INT) RETURNS INT(11)  BEGIN
    declare outHaltepunkt int;

    select HaltepunktID into outHaltepunkt from ERoller where ERollerID = inRollerID;

    return IFNUll(outHaltepunkt,-1);
end$$

CREATE DEFINER=`root`@`localhost` FUNCTION `fn_GetBestand` (`inStadt` VARCHAR(30), `inEinzeilteilBezeichnung` VARCHAR(50)) RETURNS INT(11)  BEGIN
    declare vOutBestand int;

    select Bestand into vOutBestand
    from lager_einzelteile
    where Lager_ETeileID = fn_GetLagerEinzelteileID(inStadt, inEinzeilteilBezeichnung);

    return vOutBestand;
END$$

CREATE DEFINER=`root`@`localhost` FUNCTION `fn_GetEinzelteilId` (`inEinzeilteilbezeichnung` VARCHAR(30)) RETURNS INT(11)  BEGIN
    declare vOutEinzelteilId int;

    select EinzelteileId into vOutEinzelteilId
    from einzelteile
    where EName = inEinzeilteilbezeichnung;

    return ifnull(vOutEinzelteilId,-1);
END$$

CREATE DEFINER=`root`@`localhost` FUNCTION `fn_GetFirmenwagenStandort` (`inFirmenwagenID` INT) RETURNS INT(11)  BEGIN
    declare outFStandort int;

    select standortID into outFStandort 
    from Lager 
    join fuhrpark on fuhrpark.LagerID = lager.LagerID 
    where FirmenwagenID = inFirmenwagenID;

    return outFStandort;
end$$

CREATE DEFINER=`root`@`localhost` FUNCTION `fn_GetGesamtPreisLieferung` (`inAnzahl` INT, `inStueckpreis` DECIMAL(8,2)) RETURNS DECIMAL(8,2)  BEGIN 
    declare vOutGesamtPreis decimal(8,2);
    set vOutGesamtPreis = (inAnzahl * inStueckpreis);
    return vOutGesamtPreis;
END$$

CREATE DEFINER=`root`@`localhost` FUNCTION `fn_GetLagerEinzelteileID` (`inStadt` VARCHAR(30), `inEinzeilteilbezeichnung` VARCHAR(30)) RETURNS INT(11)  BEGIN
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
END$$

CREATE DEFINER=`root`@`localhost` FUNCTION `fn_GetLagerId` (`inStadt` VARCHAR(30)) RETURNS INT(11)  BEGIN
    declare vOutLagerId int;

    select l.LagerID into vOutLagerId
    from standort s join lager l on s.StandortId = l.StandortId
    where s.Stadt = UPPER(inStadt);

    return ifnull(vOutLagerId, -1);
END$$

CREATE DEFINER=`root`@`localhost` FUNCTION `fn_GetLagerLieferantID` (`inStadt` VARCHAR(30), `inLieferantName` VARCHAR(30)) RETURNS INT(11)  BEGIN
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
END$$

CREATE DEFINER=`root`@`localhost` FUNCTION `fn_GetLieferantID` (`inLieferantName` VARCHAR(50)) RETURNS INT(11)  BEGIN
    declare vOutLieferantenId int;

    select LieferantID into vOutLieferantenId
    from lieferant
    where LieferantName = inLieferantName;

    return ifnull(vOutLieferantenId,-1);
END$$

CREATE DEFINER=`root`@`localhost` FUNCTION `fn_GetMaxBestand` (`inStadt` VARCHAR(30), `inEinzeilteilBezeichnung` VARCHAR(50)) RETURNS INT(11)  BEGIN
    declare vOutMaximalBestand int;

    select MaxBestand into vOutMaximalBestand
    from lager_einzelteile
    where Lager_ETeileID = fn_GetLagerEinzelteileID(inStadt, inEinzeilteilBezeichnung);

    return vOutMaximalBestand;
END$$

CREATE DEFINER=`root`@`localhost` FUNCTION `fn_GetMindestBestand` (`inStadt` VARCHAR(30), `inEinzeilteilBezeichnung` VARCHAR(50)) RETURNS INT(11)  BEGIN
    declare vOutMindestBestand int;

    select MinBestand into vOutMindestBestand
    from lager_einzelteile
    where Lager_ETeileID = fn_GetLagerEinzelteileID(inStadt, inEinzeilteilBezeichnung);

    return vOutMindestBestand;
END$$

CREATE DEFINER=`root`@`localhost` FUNCTION `fn_GetMitarbeiterID` (`inBusinessEmail` VARCHAR(100)) RETURNS INT(11)  BEGIN
    declare outMitarbeiterID int;
        
    select MitarbeiterID into outMitarbeiterID from Mitarbeiter where lower(BusinessEmail) = lower(inBusinessEmail);

    return IFNUll(outMitarbeiterID,-1);
end$$

CREATE DEFINER=`root`@`localhost` FUNCTION `fn_GetMitarbeiterStandort` (`inMitarbeiterID` INT) RETURNS INT(11)  BEGIN
    declare outMStandort int;

    select ArbeitsortID into outMStandort from Mitarbeiter where MitarbeiterID = inMitarbeiterID;

    return outMStandort;
end$$

CREATE DEFINER=`root`@`localhost` FUNCTION `fn_GetRollerStandort` (`inRollerID` INT) RETURNS INT(11)  BEGIN
    declare outStandortID int;

    set outStandortID = (select standortID from EROLLER where ERollerID = inRollerID);

    return outStandortID;
end$$

CREATE DEFINER=`root`@`localhost` FUNCTION `fn_IstRollerLieferung` (`inEinzeilteilBezeichnung` VARCHAR(50)) RETURNS INT(11)  BEGIN
    declare vOut int;
    set vOut = 0;
    if inEinzeilteilBezeichnung = 'Roller'
        then set vOut = 1;
    end if;
    return vOut;
END$$

CREATE DEFINER=`root`@`localhost` FUNCTION `fn_KontrolliereBestand` (`inStadt` VARCHAR(30), `inEinzeilteilBezeichnung` VARCHAR(50), `inNeuerBestand` INT) RETURNS INT(11)  BEGIN
    declare vOut int;

    if ((fn_GetMaxBestand(inStadt, inEinzeilteilBezeichnung)) < inNeuerBestand) 
        then SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Nicht genügend Kapazität im Lager vorhanden!';         
    end if;

    set vOut = 1;
    return vOut;
END$$

CREATE DEFINER=`root`@`localhost` FUNCTION `fn_KontrolliereDatum` (`inDatum` DATE) RETURNS INT(11)  BEGIN
     declare vOut int;
    	if (inDatum < '2015-01-01')
    	    then SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Das Lieferdatum liegt vor der Firmengründung! Bitte die Eingabe überprüfen!';
    	end if;
    	if (inDatum > CURRENT_DATE())
    	    then SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Das Lieferdatum liegt in der Zukunft! Bitte die Eingabe überprüfen!';
    	end if;
        

        set vOut = 1;
        return vOut;
END$$

DELIMITER ;

-- --------------------------------------------------------

--
-- Tabellenstruktur für Tabelle `abteilung`
--

CREATE TABLE `abteilung` (
  `AbteilungID` int(11) NOT NULL,
  `AbteilungName` varchar(30) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Daten für Tabelle `abteilung`
--

INSERT INTO `abteilung` (`AbteilungID`, `AbteilungName`) VALUES
(50, 'CUSTOMER SERVICE'),
(60, 'FIRMENORGANISATION'),
(30, 'HUMAN RESOURCE'),
(71, 'KFZ'),
(10, 'MANAGEMENT'),
(110, 'SOCIAL MEDIA'),
(70, 'WAREHOUSING'),
(72, 'WARTUNG AKKU');

-- --------------------------------------------------------

--
-- Tabellenstruktur für Tabelle `bestellung_eroller`
--

CREATE TABLE `bestellung_eroller` (
  `BestellERID` int(11) NOT NULL,
  `Nutzdauer` time NOT NULL,
  `StartPunktID` int(11) NOT NULL,
  `EndPunktID` int(11) NOT NULL,
  `GesamtFahrstecke` int(11) NOT NULL,
  `KundeID` int(11) NOT NULL,
  `ERollerID` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Daten für Tabelle `bestellung_eroller`
--

INSERT INTO `bestellung_eroller` (`BestellERID`, `Nutzdauer`, `StartPunktID`, `EndPunktID`, `GesamtFahrstecke`, `KundeID`, `ERollerID`) VALUES
(1, '00:26:00', 115, 748, 1375, 72, 24),
(2, '00:08:00', 6, 291, 671, 74, 688),
(3, '00:19:00', 196, 1026, 2265, 268, 396),
(4, '00:02:00', 71, 590, 2930, 234, 255),
(5, '00:20:00', 41, 401, 2740, 139, 733),
(6, '00:25:00', 229, 1207, 2673, 167, 586),
(7, '00:05:00', 37, 398, 2354, 59, 719),
(8, '00:09:00', 172, 975, 1404, 117, 341),
(9, '00:08:00', 32, 345, 805, 107, 695),
(10, '00:13:00', 196, 938, 2380, 262, 323),
(11, '00:23:00', 27, 280, 2633, 218, 747),
(12, '00:20:00', 243, 1054, 573, 275, 528),
(13, '00:00:00', 50, 335, 1978, 178, 748),
(14, '00:28:00', 64, 530, 989, 149, 293),
(15, '00:21:00', 34, 350, 2312, 274, 634),
(16, '00:17:00', 116, 809, 1897, 210, 87),
(17, '00:25:00', 6, 416, 498, 59, 716),
(18, '00:15:00', 86, 453, 1100, 5, 269),
(19, '00:11:00', 47, 287, 2447, 206, 620),
(20, '00:21:00', 170, 1010, 2197, 149, 308),
(21, '00:12:00', 140, 845, 709, 1, 16),
(22, '00:30:00', 157, 851, 1301, 179, 432),
(23, '00:17:00', 216, 1172, 2259, 46, 458),
(24, '00:24:00', 191, 898, 576, 82, 360),
(25, '00:04:00', 133, 795, 498, 231, 12),
(26, '00:25:00', 237, 1145, 184, 182, 473),
(27, '00:07:00', 84, 485, 1254, 64, 172),
(28, '00:27:00', 2, 377, 481, 25, 622),
(29, '00:13:00', 59, 543, 2164, 218, 280),
(30, '00:15:00', 209, 1094, 620, 150, 582),
(31, '00:14:00', 168, 877, 440, 270, 397),
(32, '00:09:00', 210, 1095, 523, 230, 459),
(33, '00:02:00', 241, 1210, 326, 40, 466),
(34, '00:13:00', 195, 981, 116, 211, 307),
(35, '00:09:00', 168, 968, 860, 152, 442),
(36, '00:14:00', 35, 432, 269, 150, 669),
(37, '00:29:00', 194, 934, 1206, 101, 437),
(38, '00:29:00', 86, 619, 520, 30, 245),
(39, '00:18:00', 107, 828, 1279, 153, 109),
(40, '00:24:00', 179, 1023, 1929, 34, 342),
(41, '00:00:00', 240, 1055, 1571, 136, 479),
(42, '00:16:00', 165, 960, 2440, 158, 416),
(43, '00:21:00', 154, 867, 1798, 252, 445),
(44, '00:19:00', 137, 808, 470, 102, 33),
(45, '00:02:00', 155, 954, 1949, 5, 364),
(46, '00:02:00', 199, 937, 2026, 235, 368),
(47, '00:10:00', 40, 384, 586, 281, 700),
(48, '00:15:00', 126, 728, 255, 180, 9),
(49, '00:04:00', 21, 316, 2447, 242, 669),
(50, '00:12:00', 20, 290, 519, 76, 618),
(51, '00:30:00', 218, 1123, 2374, 133, 599),
(52, '00:05:00', 35, 337, 1886, 54, 639),
(53, '00:22:00', 13, 400, 2247, 10, 706),
(54, '00:14:00', 222, 1207, 962, 8, 496),
(55, '00:29:00', 99, 592, 314, 60, 254),
(56, '00:02:00', 50, 348, 428, 96, 676),
(57, '00:24:00', 204, 1170, 2513, 36, 522),
(58, '00:20:00', 238, 1074, 2542, 131, 491),
(59, '00:27:00', 103, 670, 1948, 111, 136),
(60, '00:19:00', 62, 516, 1189, 243, 282),
(61, '00:29:00', 156, 891, 1910, 145, 369),
(62, '00:26:00', 155, 995, 2198, 252, 385),
(63, '00:02:00', 244, 1240, 1590, 209, 475),
(64, '00:24:00', 149, 754, 1572, 145, 103),
(65, '00:23:00', 192, 995, 2726, 36, 410),
(66, '00:03:00', 39, 261, 1258, 126, 709),
(67, '00:24:00', 194, 912, 731, 93, 384),
(68, '00:24:00', 176, 867, 1664, 295, 412),
(69, '00:01:00', 33, 383, 236, 131, 637),
(70, '00:04:00', 4, 367, 2349, 160, 689),
(71, '00:06:00', 40, 358, 1056, 30, 690),
(72, '00:04:00', 183, 1018, 153, 113, 413),
(73, '00:08:00', 129, 815, 1765, 53, 73),
(74, '00:23:00', 197, 893, 1971, 274, 434),
(75, '00:17:00', 2, 286, 1043, 30, 619),
(76, '00:24:00', 189, 899, 2660, 45, 390),
(77, '00:28:00', 92, 572, 1551, 297, 270),
(78, '00:29:00', 18, 320, 727, 83, 693),
(79, '00:17:00', 114, 763, 1352, 110, 143),
(80, '00:10:00', 104, 769, 1090, 217, 34),
(81, '00:13:00', 179, 991, 273, 267, 376),
(82, '00:02:00', 93, 558, 1876, 161, 269),
(83, '00:15:00', 129, 821, 907, 29, 112),
(84, '00:03:00', 202, 1060, 1467, 218, 470),
(85, '00:15:00', 146, 733, 441, 49, 80),
(86, '00:07:00', 100, 571, 1304, 16, 189),
(87, '00:30:00', 95, 637, 1540, 285, 175),
(88, '00:25:00', 62, 483, 609, 57, 238),
(89, '00:20:00', 144, 797, 2694, 58, 109),
(90, '00:15:00', 219, 1116, 392, 118, 505),
(91, '00:19:00', 180, 865, 805, 62, 387),
(92, '00:02:00', 97, 530, 196, 155, 220),
(93, '00:22:00', 92, 608, 663, 36, 152),
(94, '00:21:00', 155, 857, 2067, 287, 322),
(95, '00:00:00', 19, 282, 100, 146, 740),
(96, '00:26:00', 143, 818, 559, 259, 7),
(97, '00:22:00', 216, 1053, 1358, 149, 541),
(98, '00:25:00', 131, 766, 1931, 22, 113),
(99, '00:25:00', 166, 1010, 2810, 275, 317),
(100, '00:00:00', 157, 884, 2093, 148, 431),
(101, '00:07:00', 147, 749, 1834, 287, 12),
(102, '00:19:00', 215, 1248, 722, 226, 477),
(103, '00:14:00', 135, 714, 1986, 82, 121),
(104, '00:22:00', 110, 735, 2954, 46, 47),
(105, '00:10:00', 58, 598, 1509, 180, 269),
(106, '00:05:00', 29, 446, 2895, 168, 717),
(107, '00:27:00', 22, 379, 271, 192, 717),
(108, '00:17:00', 105, 706, 2499, 155, 100),
(109, '00:21:00', 188, 940, 1057, 265, 339),
(110, '00:18:00', 161, 877, 1582, 45, 309),
(111, '00:24:00', 18, 392, 1567, 32, 633),
(112, '00:26:00', 204, 1215, 867, 242, 553),
(113, '00:03:00', 198, 1034, 2918, 220, 306),
(114, '00:09:00', 162, 864, 2422, 145, 430),
(115, '00:06:00', 29, 409, 1127, 15, 636),
(116, '00:08:00', 182, 928, 1462, 130, 400),
(117, '00:28:00', 104, 833, 1982, 218, 76),
(118, '00:17:00', 238, 1096, 665, 263, 534),
(119, '00:06:00', 237, 1245, 1839, 12, 491),
(120, '00:09:00', 130, 810, 2206, 191, 112),
(121, '00:27:00', 233, 1129, 2599, 180, 584),
(122, '00:11:00', 53, 546, 816, 85, 228),
(123, '00:14:00', 128, 687, 2726, 144, 16),
(124, '00:09:00', 170, 974, 669, 110, 350),
(125, '00:16:00', 152, 959, 500, 18, 321),
(126, '00:27:00', 178, 997, 1077, 297, 408),
(127, '00:08:00', 18, 375, 2634, 179, 717),
(128, '00:26:00', 149, 840, 1742, 264, 116),
(129, '00:25:00', 165, 998, 1091, 265, 431),
(130, '00:21:00', 219, 1065, 539, 31, 525),
(131, '00:30:00', 54, 602, 1587, 40, 232),
(132, '00:29:00', 7, 302, 397, 289, 704),
(133, '00:19:00', 25, 349, 1965, 2, 652),
(134, '00:12:00', 121, 765, 1923, 253, 61),
(135, '00:26:00', 26, 330, 1523, 144, 742),
(136, '00:27:00', 124, 666, 1848, 180, 92),
(137, '00:28:00', 7, 411, 1430, 114, 688),
(138, '00:10:00', 13, 405, 2853, 18, 709),
(139, '00:27:00', 133, 750, 2781, 131, 102),
(140, '00:24:00', 4, 396, 1643, 28, 623),
(141, '00:29:00', 142, 663, 2495, 139, 145),
(142, '00:24:00', 227, 1121, 2986, 88, 528),
(143, '00:30:00', 46, 253, 1083, 68, 730),
(144, '00:12:00', 10, 305, 1996, 88, 709),
(145, '00:09:00', 84, 531, 2473, 292, 250),
(146, '00:13:00', 249, 1218, 2018, 74, 471),
(147, '00:28:00', 228, 1157, 2393, 202, 509),
(148, '00:22:00', 220, 1179, 605, 58, 520),
(149, '00:02:00', 117, 663, 2707, 89, 102),
(150, '00:01:00', 148, 825, 1186, 270, 61),
(151, '00:27:00', 71, 493, 1971, 112, 271),
(152, '00:05:00', 99, 612, 2990, 147, 271),
(153, '00:10:00', 93, 497, 122, 185, 232),
(154, '00:01:00', 141, 822, 1266, 283, 108),
(155, '00:15:00', 238, 1166, 2795, 263, 535),
(156, '00:06:00', 52, 585, 2848, 225, 293),
(157, '00:29:00', 119, 728, 2704, 125, 65),
(158, '00:17:00', 157, 995, 1617, 48, 375),
(159, '00:29:00', 243, 1132, 2063, 291, 558),
(160, '00:13:00', 220, 1223, 2367, 92, 502),
(161, '00:09:00', 44, 270, 1347, 50, 724),
(162, '00:11:00', 108, 693, 522, 31, 12),
(163, '00:03:00', 44, 315, 1274, 218, 712),
(164, '00:30:00', 37, 316, 315, 206, 720),
(165, '00:14:00', 232, 1194, 494, 108, 486),
(166, '00:23:00', 84, 625, 1784, 32, 225),
(167, '00:07:00', 139, 733, 2933, 259, 143),
(168, '00:10:00', 76, 537, 2991, 177, 226),
(169, '00:19:00', 100, 455, 277, 191, 264),
(170, '00:03:00', 90, 622, 660, 183, 273),
(171, '00:01:00', 22, 321, 254, 160, 669),
(172, '00:30:00', 178, 1028, 1148, 272, 409),
(173, '00:22:00', 165, 863, 975, 204, 436),
(174, '00:27:00', 159, 953, 620, 285, 337),
(175, '00:06:00', 144, 841, 2292, 206, 81),
(176, '00:05:00', 182, 910, 1106, 133, 351),
(177, '00:24:00', 188, 952, 1791, 72, 366),
(178, '00:03:00', 207, 1086, 1366, 40, 576),
(179, '00:17:00', 174, 1035, 1464, 22, 345),
(180, '00:18:00', 160, 956, 2640, 156, 325),
(181, '00:01:00', 32, 415, 1730, 116, 733),
(182, '00:09:00', 14, 345, 2991, 196, 604),
(183, '00:16:00', 72, 588, 970, 297, 254),
(184, '00:15:00', 219, 1080, 1351, 84, 468),
(185, '00:08:00', 215, 1241, 1052, 151, 539),
(186, '00:24:00', 153, 921, 2124, 181, 381),
(187, '00:22:00', 86, 559, 1387, 81, 244),
(188, '00:12:00', 223, 1107, 2712, 111, 529),
(189, '00:13:00', 77, 510, 2608, 54, 291),
(190, '00:29:00', 64, 462, 2479, 22, 266),
(191, '00:08:00', 9, 357, 881, 106, 740),
(192, '00:01:00', 78, 515, 1663, 15, 177),
(193, '00:04:00', 135, 711, 2228, 222, 8),
(194, '00:20:00', 244, 1132, 534, 111, 573),
(195, '00:28:00', 45, 305, 1018, 38, 667),
(196, '00:17:00', 42, 349, 342, 92, 748),
(197, '00:01:00', 219, 1138, 1946, 213, 489),
(198, '00:13:00', 119, 763, 621, 136, 122),
(199, '00:06:00', 217, 1076, 2569, 195, 532),
(200, '00:11:00', 198, 933, 1851, 29, 363),
(201, '00:10:00', 155, 915, 752, 6, 380),
(202, '00:08:00', 143, 761, 1559, 278, 102),
(203, '00:23:00', 120, 789, 1117, 112, 18),
(204, '00:06:00', 131, 817, 2803, 56, 71),
(205, '00:13:00', 15, 264, 2698, 227, 607),
(206, '00:27:00', 67, 551, 936, 189, 174),
(207, '00:18:00', 235, 1105, 1511, 129, 518),
(208, '00:09:00', 215, 1096, 169, 29, 574),
(209, '00:14:00', 189, 1006, 932, 69, 328),
(210, '00:12:00', 4, 312, 1468, 33, 648),
(211, '00:17:00', 61, 527, 189, 104, 259),
(212, '00:28:00', 7, 448, 515, 193, 656),
(213, '00:13:00', 225, 1200, 2960, 69, 568),
(214, '00:19:00', 134, 818, 2543, 202, 75),
(215, '00:18:00', 73, 625, 2008, 19, 180),
(216, '00:00:00', 126, 806, 1874, 27, 130),
(217, '00:17:00', 40, 328, 1652, 205, 648),
(218, '00:00:00', 239, 1066, 2193, 182, 516),
(219, '00:26:00', 219, 1107, 1330, 33, 471),
(220, '00:15:00', 224, 1097, 507, 187, 486),
(221, '00:14:00', 4, 365, 2594, 48, 711),
(222, '00:20:00', 42, 326, 2152, 92, 663),
(223, '00:12:00', 163, 961, 2342, 69, 448),
(224, '00:27:00', 75, 520, 1945, 260, 224),
(225, '00:05:00', 213, 1237, 302, 2, 469),
(226, '00:29:00', 238, 1228, 2920, 184, 576),
(227, '00:03:00', 57, 544, 453, 72, 230),
(228, '00:16:00', 145, 737, 742, 146, 129),
(229, '00:05:00', 80, 568, 724, 157, 162),
(230, '00:07:00', 168, 931, 2821, 230, 309),
(231, '00:22:00', 237, 1088, 2897, 88, 532),
(232, '00:27:00', 165, 918, 1709, 91, 335),
(233, '00:27:00', 66, 501, 1490, 32, 192),
(234, '00:28:00', 76, 644, 2144, 36, 187),
(235, '00:12:00', 210, 1075, 841, 247, 554),
(236, '00:09:00', 82, 479, 1063, 255, 243),
(237, '00:27:00', 67, 583, 2122, 89, 207),
(238, '00:20:00', 96, 469, 729, 70, 253),
(239, '00:20:00', 245, 1130, 306, 40, 600),
(240, '00:07:00', 44, 405, 2523, 262, 734),
(241, '00:01:00', 243, 1080, 1789, 259, 597),
(242, '00:23:00', 70, 619, 562, 45, 234),
(243, '00:19:00', 75, 531, 1429, 22, 195),
(244, '00:00:00', 143, 701, 1218, 48, 143),
(245, '00:17:00', 246, 1221, 2777, 298, 492),
(246, '00:25:00', 72, 535, 1367, 134, 244),
(247, '00:11:00', 230, 1165, 1923, 154, 469),
(248, '00:04:00', 70, 474, 2403, 65, 267),
(249, '00:24:00', 70, 466, 1808, 168, 167),
(250, '00:12:00', 49, 381, 615, 257, 644),
(251, '00:13:00', 123, 656, 2228, 174, 135),
(252, '00:25:00', 226, 1122, 1580, 119, 549),
(253, '00:25:00', 217, 1241, 912, 193, 475),
(254, '00:18:00', 76, 617, 621, 189, 224),
(255, '00:13:00', 123, 790, 2197, 176, 145),
(256, '00:12:00', 62, 582, 2023, 156, 282),
(257, '00:25:00', 2, 395, 498, 15, 633),
(258, '00:26:00', 109, 782, 1184, 26, 109),
(259, '00:19:00', 30, 297, 346, 284, 691),
(260, '00:08:00', 127, 750, 2730, 94, 61),
(261, '00:08:00', 60, 478, 2155, 291, 274),
(262, '00:01:00', 22, 402, 2002, 276, 652),
(263, '00:16:00', 200, 879, 1757, 237, 310),
(264, '00:05:00', 82, 473, 2608, 8, 234),
(265, '00:05:00', 120, 770, 2530, 125, 59),
(266, '00:01:00', 62, 613, 2147, 82, 277),
(267, '00:23:00', 217, 1086, 1944, 273, 581),
(268, '00:27:00', 219, 1169, 2785, 121, 532),
(269, '00:00:00', 83, 607, 714, 153, 178),
(270, '00:23:00', 240, 1164, 2890, 86, 465),
(271, '00:14:00', 47, 381, 812, 150, 644),
(272, '00:14:00', 46, 414, 2388, 244, 697),
(273, '00:09:00', 212, 1161, 1491, 273, 470),
(274, '00:16:00', 152, 943, 2395, 20, 413),
(275, '00:19:00', 56, 527, 1442, 131, 254),
(276, '00:27:00', 67, 647, 319, 289, 154),
(277, '00:25:00', 109, 651, 2107, 113, 11),
(278, '00:05:00', 240, 1163, 1024, 229, 591),
(279, '00:19:00', 71, 509, 2939, 89, 151),
(280, '00:27:00', 233, 1150, 2877, 209, 503),
(281, '00:08:00', 48, 311, 1820, 299, 636),
(282, '00:11:00', 94, 627, 1553, 105, 194),
(283, '00:20:00', 70, 638, 1615, 292, 174),
(284, '00:03:00', 143, 734, 1048, 34, 75),
(285, '00:11:00', 36, 261, 1290, 230, 748),
(286, '00:13:00', 2, 252, 1995, 252, 682),
(287, '00:00:00', 123, 768, 2704, 50, 122),
(288, '00:15:00', 235, 1185, 369, 178, 544),
(289, '00:06:00', 87, 571, 2997, 244, 294),
(290, '00:04:00', 100, 588, 1134, 51, 180),
(291, '00:20:00', 130, 783, 2990, 40, 120),
(292, '00:12:00', 102, 841, 1398, 273, 50),
(293, '00:27:00', 146, 760, 2820, 182, 123),
(294, '00:17:00', 192, 965, 2645, 39, 322),
(295, '00:29:00', 7, 279, 1940, 162, 719),
(296, '00:10:00', 219, 1221, 2602, 108, 471),
(297, '00:12:00', 142, 734, 1981, 34, 49),
(298, '00:09:00', 131, 675, 1824, 242, 124),
(299, '00:16:00', 150, 844, 2123, 181, 59),
(300, '00:03:00', 14, 276, 2031, 87, 687),
(301, '00:17:00', 216, 1205, 1224, 81, 464),
(302, '00:27:00', 195, 913, 631, 232, 346),
(303, '00:23:00', 229, 1248, 291, 286, 507),
(304, '00:26:00', 240, 1125, 1532, 147, 470),
(305, '00:22:00', 23, 388, 2690, 212, 691),
(306, '00:00:00', 189, 1024, 2959, 24, 381),
(307, '00:10:00', 22, 410, 1656, 115, 734),
(308, '00:13:00', 114, 685, 2754, 183, 94),
(309, '00:19:00', 179, 1038, 1179, 21, 437),
(310, '00:15:00', 232, 1235, 1630, 226, 541),
(311, '00:16:00', 150, 827, 1559, 150, 94),
(312, '00:17:00', 175, 1042, 1386, 218, 405),
(313, '00:03:00', 230, 1103, 1108, 16, 499),
(314, '00:10:00', 248, 1120, 752, 188, 469),
(315, '00:10:00', 79, 601, 1252, 295, 242),
(316, '00:26:00', 6, 413, 255, 109, 721),
(317, '00:09:00', 14, 373, 1547, 295, 601),
(318, '00:06:00', 18, 336, 1763, 265, 750),
(319, '00:21:00', 173, 1030, 433, 142, 378),
(320, '00:13:00', 161, 861, 451, 194, 317),
(321, '00:06:00', 41, 325, 1742, 10, 734),
(322, '00:25:00', 173, 1028, 2256, 160, 319),
(323, '00:27:00', 91, 617, 374, 254, 166),
(324, '00:10:00', 97, 535, 1643, 6, 219),
(325, '00:15:00', 90, 522, 2888, 197, 196),
(326, '00:26:00', 96, 635, 2871, 38, 282),
(327, '00:15:00', 44, 323, 1444, 194, 644),
(328, '00:07:00', 169, 931, 2033, 162, 394),
(329, '00:07:00', 170, 959, 1396, 225, 336),
(330, '00:13:00', 240, 1136, 2336, 284, 587),
(331, '00:24:00', 118, 735, 2734, 67, 19),
(332, '00:20:00', 182, 925, 2061, 231, 371),
(333, '00:02:00', 218, 1160, 1412, 12, 454),
(334, '00:18:00', 8, 437, 2540, 158, 640),
(335, '00:23:00', 8, 429, 2459, 190, 685),
(336, '00:12:00', 139, 655, 276, 33, 71),
(337, '00:27:00', 53, 538, 1424, 52, 157),
(338, '00:18:00', 22, 370, 377, 63, 729),
(339, '00:20:00', 62, 545, 2563, 30, 242),
(340, '00:15:00', 141, 803, 2936, 214, 131),
(341, '00:25:00', 193, 1044, 1421, 163, 423),
(342, '00:05:00', 7, 403, 2821, 183, 656),
(343, '00:04:00', 191, 878, 1402, 279, 447),
(344, '00:03:00', 249, 1085, 2435, 45, 590),
(345, '00:05:00', 33, 376, 2769, 42, 671),
(346, '00:12:00', 82, 595, 2375, 166, 185),
(347, '00:00:00', 208, 1198, 1472, 191, 576),
(348, '00:08:00', 246, 1192, 224, 257, 520),
(349, '00:08:00', 171, 934, 113, 42, 357),
(350, '00:08:00', 176, 932, 370, 87, 339),
(351, '00:19:00', 129, 762, 2835, 224, 133),
(352, '00:29:00', 202, 1197, 1028, 287, 517),
(353, '00:11:00', 109, 684, 2644, 169, 86),
(354, '00:07:00', 80, 548, 1909, 117, 266),
(355, '00:20:00', 154, 959, 1278, 33, 359),
(356, '00:01:00', 124, 792, 1071, 267, 140),
(357, '00:30:00', 195, 901, 1970, 46, 337),
(358, '00:17:00', 227, 1087, 2610, 249, 500),
(359, '00:05:00', 230, 1222, 1034, 275, 569),
(360, '00:30:00', 233, 1066, 2678, 257, 459),
(361, '00:01:00', 70, 612, 2344, 229, 161),
(362, '00:18:00', 125, 825, 2971, 212, 43),
(363, '00:26:00', 169, 940, 1570, 281, 355),
(364, '00:17:00', 249, 1230, 2229, 143, 463),
(365, '00:10:00', 135, 736, 1956, 159, 42),
(366, '00:25:00', 146, 849, 2612, 55, 101),
(367, '00:19:00', 221, 1096, 2527, 229, 462),
(368, '00:10:00', 81, 621, 221, 83, 204),
(369, '00:11:00', 77, 619, 248, 246, 235),
(370, '00:09:00', 124, 665, 1187, 143, 85),
(371, '00:25:00', 133, 742, 1905, 281, 30),
(372, '00:12:00', 80, 469, 2783, 236, 209),
(373, '00:07:00', 79, 535, 2157, 156, 183),
(374, '00:08:00', 4, 405, 279, 180, 721),
(375, '00:27:00', 87, 549, 2769, 128, 271),
(376, '00:24:00', 61, 624, 2877, 64, 181),
(377, '00:22:00', 123, 729, 1798, 232, 70),
(378, '00:10:00', 230, 1105, 1948, 246, 484),
(379, '00:14:00', 180, 905, 2708, 136, 417),
(380, '00:18:00', 47, 307, 2826, 176, 643),
(381, '00:05:00', 13, 386, 1306, 84, 629),
(382, '00:08:00', 170, 1040, 281, 48, 430),
(383, '00:17:00', 74, 571, 375, 88, 218),
(384, '00:18:00', 76, 618, 502, 298, 219),
(385, '00:16:00', 30, 399, 2157, 237, 685),
(386, '00:02:00', 207, 1214, 2318, 146, 582),
(387, '00:10:00', 112, 680, 1204, 157, 27),
(388, '00:30:00', 247, 1117, 2489, 53, 520),
(389, '00:16:00', 99, 480, 565, 266, 226),
(390, '00:09:00', 209, 1215, 2086, 154, 547),
(391, '00:28:00', 70, 577, 978, 18, 213),
(392, '00:17:00', 35, 296, 2399, 124, 707),
(393, '00:26:00', 191, 1000, 1789, 73, 388),
(394, '00:20:00', 157, 959, 2730, 248, 370),
(395, '00:07:00', 116, 754, 922, 292, 57),
(396, '00:29:00', 189, 893, 1197, 133, 430),
(397, '00:19:00', 192, 908, 1803, 1, 323),
(398, '00:12:00', 221, 1149, 2196, 45, 507),
(399, '00:25:00', 212, 1106, 1397, 270, 535),
(400, '00:00:00', 95, 568, 482, 160, 278),
(401, '00:26:00', 39, 266, 2005, 42, 662),
(402, '00:28:00', 150, 735, 1162, 82, 144),
(403, '00:26:00', 108, 715, 1141, 4, 15),
(404, '00:09:00', 29, 372, 2419, 6, 643),
(405, '00:02:00', 238, 1167, 129, 204, 469),
(406, '00:07:00', 34, 320, 457, 78, 630),
(407, '00:24:00', 37, 364, 2131, 7, 743),
(408, '00:21:00', 87, 505, 1574, 150, 252),
(409, '00:10:00', 44, 391, 2894, 131, 617),
(410, '00:07:00', 214, 1112, 2502, 259, 484),
(411, '00:02:00', 162, 1050, 2433, 57, 350),
(412, '00:25:00', 239, 1133, 1554, 120, 512),
(413, '00:28:00', 25, 355, 746, 40, 629),
(414, '00:07:00', 234, 1223, 2074, 51, 506),
(415, '00:23:00', 63, 493, 646, 88, 223),
(416, '00:19:00', 206, 1220, 536, 105, 473),
(417, '00:25:00', 124, 758, 2480, 81, 49),
(418, '00:09:00', 161, 860, 2030, 114, 315),
(419, '00:06:00', 9, 387, 213, 253, 678),
(420, '00:30:00', 119, 734, 2427, 143, 38),
(421, '00:18:00', 163, 948, 816, 83, 361),
(422, '00:18:00', 29, 423, 2487, 248, 645),
(423, '00:00:00', 239, 1185, 1666, 111, 484),
(424, '00:10:00', 50, 283, 2006, 157, 651),
(425, '00:10:00', 104, 672, 449, 18, 118),
(426, '00:18:00', 69, 505, 554, 165, 192),
(427, '00:17:00', 90, 507, 1102, 114, 212),
(428, '00:00:00', 90, 485, 1851, 101, 228),
(429, '00:26:00', 69, 613, 324, 254, 285),
(430, '00:16:00', 113, 696, 2545, 121, 122),
(431, '00:06:00', 242, 1219, 1085, 215, 483),
(432, '00:26:00', 52, 639, 1621, 138, 257),
(433, '00:00:00', 215, 1203, 2441, 230, 564),
(434, '00:20:00', 231, 1138, 2864, 242, 514),
(435, '00:01:00', 14, 428, 2190, 100, 742),
(436, '00:14:00', 212, 1184, 685, 293, 539),
(437, '00:02:00', 158, 965, 1223, 217, 338),
(438, '00:01:00', 203, 1080, 2239, 234, 560),
(439, '00:27:00', 138, 812, 797, 140, 28),
(440, '00:20:00', 8, 404, 2582, 47, 643),
(441, '00:25:00', 146, 717, 1516, 52, 7),
(442, '00:11:00', 74, 618, 2600, 50, 241),
(443, '00:00:00', 67, 533, 1912, 55, 286),
(444, '00:29:00', 20, 297, 1516, 113, 678),
(445, '00:10:00', 87, 592, 2950, 15, 277),
(446, '00:06:00', 87, 631, 362, 35, 269),
(447, '00:21:00', 109, 824, 799, 56, 123),
(448, '00:00:00', 225, 1218, 1183, 275, 555),
(449, '00:30:00', 170, 874, 138, 72, 367),
(450, '00:29:00', 160, 918, 1415, 49, 403),
(451, '00:10:00', 70, 469, 1324, 110, 220),
(452, '00:26:00', 112, 750, 1299, 187, 116),
(453, '00:24:00', 25, 353, 1335, 285, 715),
(454, '00:13:00', 209, 1216, 1492, 63, 453),
(455, '00:21:00', 179, 972, 663, 121, 330),
(456, '00:14:00', 165, 909, 529, 271, 366),
(457, '00:22:00', 35, 262, 1806, 290, 729),
(458, '00:30:00', 74, 595, 2282, 4, 166),
(459, '00:03:00', 162, 885, 2866, 49, 387),
(460, '00:16:00', 190, 954, 2145, 245, 362),
(461, '00:30:00', 108, 836, 2105, 41, 62),
(462, '00:23:00', 60, 539, 154, 189, 160),
(463, '00:28:00', 10, 258, 2950, 173, 663),
(464, '00:14:00', 27, 374, 891, 191, 628),
(465, '00:02:00', 121, 722, 2579, 186, 131),
(466, '00:25:00', 109, 733, 221, 201, 60),
(467, '00:20:00', 236, 1168, 1283, 47, 597),
(468, '00:09:00', 187, 1010, 1812, 286, 348),
(469, '00:20:00', 124, 758, 2694, 279, 47),
(470, '00:09:00', 198, 912, 1970, 290, 392),
(471, '00:25:00', 183, 922, 847, 282, 361),
(472, '00:23:00', 66, 539, 2505, 274, 287),
(473, '00:30:00', 5, 401, 455, 155, 679),
(474, '00:20:00', 96, 578, 2148, 280, 195),
(475, '00:23:00', 161, 966, 1246, 70, 412),
(476, '00:16:00', 177, 1028, 1353, 147, 438),
(477, '00:06:00', 244, 1124, 902, 125, 568),
(478, '00:24:00', 24, 349, 2388, 80, 719),
(479, '00:29:00', 202, 1070, 2834, 240, 494),
(480, '00:23:00', 118, 746, 510, 141, 108),
(481, '00:26:00', 177, 987, 139, 5, 430),
(482, '00:05:00', 228, 1137, 845, 137, 497),
(483, '00:15:00', 22, 442, 398, 164, 666),
(484, '00:27:00', 27, 397, 1029, 76, 730),
(485, '00:01:00', 78, 486, 412, 52, 170),
(486, '00:20:00', 136, 793, 2628, 243, 4),
(487, '00:05:00', 8, 287, 1846, 15, 689),
(488, '00:07:00', 85, 553, 346, 21, 282),
(489, '00:25:00', 144, 738, 2263, 266, 98),
(490, '00:21:00', 5, 378, 1118, 186, 704),
(491, '00:22:00', 4, 341, 803, 275, 732),
(492, '00:21:00', 76, 457, 1778, 152, 272),
(493, '00:18:00', 186, 851, 2170, 77, 345),
(494, '00:00:00', 21, 308, 2899, 29, 705),
(495, '00:07:00', 24, 317, 2447, 269, 638),
(496, '00:08:00', 230, 1108, 533, 90, 468),
(497, '00:09:00', 236, 1094, 1278, 243, 559),
(498, '00:23:00', 68, 498, 1861, 7, 276),
(499, '00:03:00', 163, 997, 1127, 48, 308),
(500, '00:02:00', 52, 598, 1663, 281, 254);

-- --------------------------------------------------------

--
-- Tabellenstruktur für Tabelle `defekt`
--

CREATE TABLE `defekt` (
  `DefektID` int(11) NOT NULL,
  `Defekts` varchar(250) NOT NULL,
  `ERollerID` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Daten für Tabelle `defekt`
--

INSERT INTO `defekt` (`DefektID`, `Defekts`, `ERollerID`) VALUES
(1, 'Verschleiss', 75),
(2, 'Falsch montiert', 67),
(3, 'ueberhitzt', 125),
(4, 'Schlechte Qualitaet', 77),
(5, 'Lose Verbindung', 95),
(6, 'Verschleiss', 13),
(7, 'Abgenutzt', 68),
(8, 'Falsch montiert', 106),
(9, 'Rost', 93),
(10, 'Schlechte Qualitaet', 121),
(11, 'Falsch montiert', 145),
(12, 'Verschleiss', 99),
(13, 'Verstopft', 32),
(14, 'Knackgeraeusche', 11),
(15, 'Unregelmaessige Funktion', 117),
(16, 'Falsch montiert', 27),
(17, 'Beschaedigt', 53),
(18, 'Keine Leistung', 129),
(19, 'Eingeklemmt', 130),
(20, 'Eingeklemmt', 20),
(21, 'Falsch montiert', 233),
(22, 'Kurzschluss', 256),
(23, 'Eingeklemmt', 169),
(24, 'Schlechte Ausrichtung', 237),
(25, 'Unregelmaessige Funktion', 230),
(26, 'ueberhitzt', 233),
(27, 'Verdreht', 190),
(28, 'Feuchtigkeitsschaden', 299),
(29, 'Geringe Lebensdauer', 213),
(30, 'Verstopft', 297),
(31, 'ueberhitzt', 229),
(32, 'Eingeklemmt', 233),
(33, 'Verdreht', 195),
(34, 'Geringe Lebensdauer', 178),
(35, 'Schlechte Ausrichtung', 221),
(36, 'Abgenutzt', 266),
(37, 'Lose Verbindung', 200),
(38, 'Lose Verbindung', 295),
(39, 'Lose Verbindung', 229),
(40, 'Verdreht', 244),
(41, 'Verdreht', 340),
(42, 'Beschaedigt', 340),
(43, 'Fehlfunktion', 430),
(44, 'Gebrochen', 404),
(45, 'Verschleiss', 371),
(46, 'Feuchtigkeitsschaden', 378),
(47, 'Rost', 379),
(48, 'Abgenutzt', 438),
(49, 'Fehlfunktion', 309),
(50, 'Falsch montiert', 418),
(51, 'Fehlfunktion', 425),
(52, 'Keine Leistung', 336),
(53, 'Kurzschluss', 350),
(54, 'Geringe Lebensdauer', 367),
(55, 'Falsch montiert', 356),
(56, 'Eingeklemmt', 447),
(57, 'Schlechte Qualitaet', 372),
(58, 'Rost', 409),
(59, 'Keine Leistung', 430),
(60, 'Keine Leistung', 327),
(61, 'Verschleiss', 462),
(62, 'Rost', 583),
(63, 'Beschaedigt', 451),
(64, 'Knackgeraeusche', 480),
(65, 'Knackgeraeusche', 559),
(66, 'Eingeklemmt', 567),
(67, 'Schlechte Ausrichtung', 517),
(68, 'Beschaedigt', 490),
(69, 'Schlechte Ausrichtung', 593),
(70, 'Geringe Lebensdauer', 455),
(71, 'Knackgeraeusche', 515),
(72, 'Knackgeraeusche', 516),
(73, 'Gebrochen', 510),
(74, 'Lose Verbindung', 549),
(75, 'Schlechte Ausrichtung', 460),
(76, 'Eingeklemmt', 509),
(77, 'Abgenutzt', 521),
(78, 'Feuchtigkeitsschaden', 500),
(79, 'Geringe Lebensdauer', 453),
(80, 'Verstopft', 496),
(81, 'Knackgeraeusche', 607),
(82, 'Abgenutzt', 699),
(83, 'Beschaedigt', 657),
(84, 'Verstopft', 714),
(85, 'Abgenutzt', 702),
(86, 'Beschaedigt', 750),
(87, 'Schlechte Qualitaet', 717),
(88, 'Feuchtigkeitsschaden', 723),
(89, 'Unregelmaessige Funktion', 729),
(90, 'Geringe Lebensdauer', 606),
(91, 'Rost', 613),
(92, 'Verschleiss', 702),
(93, 'Beschaedigt', 748),
(94, 'Verdreht', 679),
(95, 'Knackgeraeusche', 738),
(96, 'Falsch montiert', 703),
(97, 'Lose Verbindung', 707),
(98, 'Unregelmaessige Funktion', 682),
(99, 'Eingeklemmt', 732),
(100, 'ueberhitzt', 622);

-- --------------------------------------------------------

--
-- Tabellenstruktur für Tabelle `einzelteile`
--

CREATE TABLE `einzelteile` (
  `EinzelteileID` int(11) NOT NULL,
  `EType` varchar(50) NOT NULL,
  `EName` varchar(100) NOT NULL,
  `Gewicht` decimal(8,2) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Daten für Tabelle `einzelteile`
--

INSERT INTO `einzelteile` (`EinzelteileID`, `EType`, `EName`, `Gewicht`) VALUES
(1, 'Batterie', 'Lithium-Ionen', 5000.00),
(2, 'Motor', 'Elektromotor', 10000.00),
(3, 'Reifen', 'Luftreifen', 2000.00),
(4, 'Bremsen', 'Scheibenbremsen', 1500.00),
(5, 'Lenker', 'Aluminiumlenker', 1000.00),
(6, 'Sitz', 'Komfortsitz', 2000.00),
(7, 'Beleuchtung', 'LED-Scheinwerfer', 500.00),
(8, 'Federung', 'Vordergabel-Federung', 1200.00),
(9, 'Schutzblech', 'Kunststoffschutzblech', 800.00),
(10, 'Kettenschutz', 'Metallkettenschutz', 600.00),
(11, 'Rahmen', 'Stahlrahmen', 8000.00),
(12, 'Griffe', 'Gummi-Griffe', 200.00),
(13, 'Stehflaeche', 'Aluminiumstehflaeche', 3000.00),
(14, 'Gepaecktraeger', 'Lenker-Gepaecktraeger', 1000.00),
(15, 'Staender', 'Seitenstaender', 500.00),
(16, 'Kabelbaum', 'Elektrischer Kabelbaum', 700.00),
(17, 'Controller', 'Elektronischer Controller', 800.00),
(18, 'Display', 'LCD-Display', 300.00),
(19, 'Gabelschaft', 'Stahlgabelschaft', 600.00),
(20, 'Bremshebel', 'Hydraulische Bremshebel', 200.00),
(21, 'Bremsbelaege', 'Scheibenbremsbelaege', 100.00),
(22, 'Kurbelarme', 'Aluminiumkurbelarme', 700.00),
(23, 'Kettenblatt', 'Stahlkettenblatt', 300.00),
(24, 'Kette', 'Motorkette', 2000.00),
(25, 'Schaltwerk', 'Rollerschaltwerk', 400.00),
(26, 'Federbein', 'Hinteres Federbein', 1500.00),
(27, 'Ladeanschluss', 'Stecker fuer Ladeanschluss', 200.00),
(28, 'Gepaeckbox', 'Gepaeckbox fuer Roller', 1000.00),
(29, 'Bremsscheibe', 'Bremsscheibe fuer Vorderrad', 300.00),
(30, 'Gummimatte', 'Gummimatte fuer Trittbrett', 500.00),
(31, 'Spiegel', 'Rueckspiegel', 200.00),
(32, 'Ruecklicht', 'LED-Ruecklicht', 150.00),
(33, 'Schluesselschalter', 'Schluesselschalter fuer Zuendung', 100.00),
(34, 'Hupe', 'Elektrische Hupe', 200.00),
(35, 'Federbeinhalter', 'Halterung fuer Federbein', 400.00),
(36, 'Schraubensatz', 'Schraubensatz fuer Roller', 500.00),
(37, 'Ladekabel', 'Ladekabel fuer Akku', 300.00),
(38, 'Rueckspiegelhalter', 'Halterung fuer Rueckspiegel', 100.00),
(39, 'Lenkergriffe', 'Gummi-Lenkergriffe', 100.00),
(40, 'Seitenverkleidung', 'Verkleidung fuer Seitenbereich', 600.00),
(41, 'Sicherung', 'Sicherung fuer Elektronik', 50.00),
(42, 'Kettenspanner', 'Kettenspanner fuer Antrieb', 200.00),
(43, 'Stehtritt', 'Komfort-Stehtritt', 1500.00),
(44, 'Bremshebelgriff', 'Griff fuer Bremshebel', 100.00),
(45, 'Gasgriff', 'Gasgriff fuer Beschleunigung', 150.00),
(46, 'Blinker', 'LED-Blinker', 100.00),
(47, 'Bremslichtschalter', 'Schalter fuer Bremslicht', 50.00),
(48, 'Kettenschutzhalter', 'Halterung fuer Kettenschutz', 100.00),
(49, 'Felge', 'Aluminiumfelge', 1000.00),
(50, 'Felgenbremse', 'Mechanische Felgenbremse', 300.00),
(51, 'Batterie', 'Akku', 2000.00),
(52, 'Display', 'OLED-Display', 400.00),
(53, 'Reflektor', 'Hinterrad Reflektoren', 10.00),
(54, 'Tritt', 'XL-Trittflaeche', 5000.00);

-- --------------------------------------------------------

--
-- Tabellenstruktur für Tabelle `eroller`
--

CREATE TABLE `eroller` (
  `ERollerID` int(11) NOT NULL,
  `LetzteWartung` date NOT NULL,
  `NaechsteWartung` date NOT NULL,
  `IstDefekt` tinyint(1) NOT NULL,
  `Batterie` int(11) NOT NULL,
  `StandortID` int(11) NOT NULL,
  `LagerID` int(11) NOT NULL,
  `HaltepunktID` int(11) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Daten für Tabelle `eroller`
--

INSERT INTO `eroller` (`ERollerID`, `LetzteWartung`, `NaechsteWartung`, `IstDefekt`, `Batterie`, `StandortID`, `LagerID`, `HaltepunktID`) VALUES
(1, '2023-06-26', '2023-07-03', 0, 93, 148, 1, NULL),
(2, '2023-06-24', '2023-07-01', 0, 47, 131, 1, NULL),
(3, '2023-06-20', '2023-06-27', 0, 52, 129, 1, NULL),
(4, '2023-06-22', '2023-06-29', 0, 49, 143, 1, NULL),
(5, '2023-06-23', '2023-06-30', 0, 90, 138, 1, NULL),
(6, '2023-06-24', '2023-07-01', 0, 91, 135, 1, NULL),
(7, '2023-06-22', '2023-06-29', 0, 57, 117, 1, NULL),
(8, '2023-06-26', '2023-07-03', 0, 99, 111, 1, NULL),
(9, '2023-06-26', '2023-07-03', 0, 100, 128, 1, NULL),
(10, '2023-06-26', '2023-07-03', 0, 88, 147, 1, NULL),
(11, '2023-06-22', '2023-06-29', 0, 15, 103, 1, NULL),
(12, '2023-06-27', '2023-07-04', 0, 35, 146, 1, NULL),
(13, '2023-06-27', '2023-07-04', 0, 94, 102, 1, NULL),
(14, '2023-06-25', '2023-07-02', 0, 78, 142, 1, NULL),
(15, '2023-06-20', '2023-06-27', 0, 30, 102, 1, NULL),
(16, '2023-06-26', '2023-07-03', 0, 94, 115, 1, NULL),
(17, '2023-06-22', '2023-06-29', 0, 42, 133, 1, NULL),
(18, '2023-06-22', '2023-06-29', 0, 66, 142, 1, NULL),
(19, '2023-06-26', '2023-07-03', 0, 8, 124, 1, NULL),
(20, '2023-06-25', '2023-07-02', 0, 72, 120, 1, NULL),
(21, '2023-06-26', '2023-07-03', 0, 20, 139, 1, NULL),
(22, '2023-06-27', '2023-07-04', 0, 12, 144, 1, NULL),
(23, '2023-06-21', '2023-06-28', 0, 15, 101, 1, NULL),
(24, '2023-06-25', '2023-07-02', 0, 19, 125, 1, NULL),
(25, '2023-06-23', '2023-06-30', 0, 9, 125, 1, NULL),
(26, '2023-06-27', '2023-07-04', 0, 77, 123, 1, NULL),
(27, '2023-06-23', '2023-06-30', 0, 29, 131, 1, NULL),
(28, '2023-06-26', '2023-07-03', 0, 9, 136, 1, NULL),
(29, '2023-06-23', '2023-06-30', 0, 63, 131, 1, NULL),
(30, '2023-06-22', '2023-06-29', 0, 74, 111, 1, NULL),
(31, '2023-06-20', '2023-06-27', 0, 43, 137, 1, NULL),
(32, '2023-06-23', '2023-06-30', 0, 90, 133, 1, NULL),
(33, '2023-06-21', '2023-06-28', 0, 77, 127, 1, NULL),
(34, '2023-06-25', '2023-07-02', 0, 67, 115, 1, NULL),
(35, '2023-06-25', '2023-07-02', 0, 26, 147, 1, NULL),
(36, '2023-06-21', '2023-06-28', 0, 55, 107, 1, NULL),
(37, '2023-06-25', '2023-07-02', 0, 63, 109, 1, NULL),
(38, '2023-06-24', '2023-07-01', 0, 74, 108, 1, NULL),
(39, '2023-06-24', '2023-07-01', 0, 95, 138, 1, NULL),
(40, '2023-06-24', '2023-07-01', 0, 57, 136, 1, NULL),
(41, '2023-06-27', '2023-07-04', 0, 26, 117, 1, NULL),
(42, '2023-06-24', '2023-07-01', 0, 68, 109, 1, NULL),
(43, '2023-06-20', '2023-06-27', 0, 86, 139, 1, NULL),
(44, '2023-06-23', '2023-06-30', 0, 43, 148, 1, NULL),
(45, '2023-06-26', '2023-07-03', 0, 18, 135, 1, NULL),
(46, '2023-06-23', '2023-06-30', 0, 52, 123, 1, NULL),
(47, '2023-06-25', '2023-07-02', 0, 35, 120, 1, NULL),
(48, '2023-06-24', '2023-07-01', 0, 3, 117, 1, NULL),
(49, '2023-06-22', '2023-06-29', 0, 53, 124, 1, NULL),
(50, '2023-06-23', '2023-06-30', 0, 24, 144, 1, NULL),
(51, '2023-06-26', '2023-07-03', 0, 29, 137, 1, NULL),
(52, '2023-06-21', '2023-06-28', 0, 24, 101, 1, NULL),
(53, '2023-06-21', '2023-06-28', 0, 3, 113, 1, NULL),
(54, '2023-06-22', '2023-06-29', 0, 63, 139, 1, NULL),
(55, '2023-06-24', '2023-07-01', 0, 24, 107, 1, NULL),
(56, '2023-06-23', '2023-06-30', 0, 20, 125, 1, NULL),
(57, '2023-06-27', '2023-07-04', 0, 17, 108, 1, NULL),
(58, '2023-06-27', '2023-07-04', 0, 36, 132, 1, NULL),
(59, '2023-06-20', '2023-06-27', 0, 88, 141, 1, NULL),
(60, '2023-06-20', '2023-06-27', 0, 5, 102, 1, NULL),
(61, '2023-06-25', '2023-07-02', 0, 46, 149, 1, NULL),
(62, '2023-06-25', '2023-07-02', 0, 97, 102, 1, NULL),
(63, '2023-06-23', '2023-06-30', 0, 8, 129, 1, NULL),
(64, '2023-06-24', '2023-07-01', 0, 65, 116, 1, NULL),
(65, '2023-06-22', '2023-06-29', 0, 75, 101, 1, NULL),
(66, '2023-06-21', '2023-06-28', 0, 7, 109, 1, NULL),
(67, '2023-06-21', '2023-06-28', 0, 94, 101, 1, NULL),
(68, '2023-06-22', '2023-06-29', 0, 99, 122, 1, NULL),
(69, '2023-06-27', '2023-07-04', 0, 42, 106, 1, NULL),
(70, '2023-06-25', '2023-07-02', 0, 18, 150, 1, NULL),
(71, '2023-06-27', '2023-07-04', 0, 75, 143, 1, NULL),
(72, '2023-06-21', '2023-06-28', 0, 79, 126, 1, NULL),
(73, '2023-06-27', '2023-07-04', 0, 18, 142, 1, NULL),
(74, '2023-06-25', '2023-07-02', 0, 55, 139, 1, NULL),
(75, '2023-06-23', '2023-06-30', 0, 78, 127, 1, NULL),
(76, '2023-06-22', '2023-06-29', 0, 67, 141, 1, NULL),
(77, '2023-06-25', '2023-07-02', 0, 75, 141, 1, NULL),
(78, '2023-06-25', '2023-07-02', 0, 8, 106, 1, NULL),
(79, '2023-06-20', '2023-06-27', 0, 64, 149, 1, NULL),
(80, '2023-06-20', '2023-06-27', 0, 97, 120, 1, NULL),
(81, '2023-06-24', '2023-07-01', 0, 77, 103, 1, NULL),
(82, '2023-06-25', '2023-07-02', 0, 15, 116, 1, NULL),
(83, '2023-06-23', '2023-06-30', 0, 80, 130, 1, NULL),
(84, '2023-06-22', '2023-06-29', 0, 21, 112, 1, NULL),
(85, '2023-06-20', '2023-06-27', 0, 75, 131, 1, NULL),
(86, '2023-06-24', '2023-07-01', 0, 17, 105, 1, NULL),
(87, '2023-06-25', '2023-07-02', 0, 45, 118, 1, NULL),
(88, '2023-06-25', '2023-07-02', 0, 66, 130, 1, NULL),
(89, '2023-06-23', '2023-06-30', 0, 85, 149, 1, NULL),
(90, '2023-06-21', '2023-06-28', 0, 33, 101, 1, NULL),
(91, '2023-06-22', '2023-06-29', 0, 56, 104, 1, NULL),
(92, '2023-06-20', '2023-06-27', 0, 69, 139, 1, NULL),
(93, '2023-06-26', '2023-07-03', 0, 17, 148, 1, NULL),
(94, '2023-06-22', '2023-06-29', 0, 58, 113, 1, NULL),
(95, '2023-06-27', '2023-07-04', 0, 69, 119, 1, NULL),
(96, '2023-06-24', '2023-07-01', 0, 49, 104, 1, NULL),
(97, '2023-06-25', '2023-07-02', 0, 69, 141, 1, NULL),
(98, '2023-06-26', '2023-07-03', 0, 30, 138, 1, NULL),
(99, '2023-06-23', '2023-06-30', 0, 49, 107, 1, NULL),
(100, '2023-06-20', '2023-06-27', 0, 72, 110, 1, NULL),
(101, '2023-06-24', '2023-07-01', 0, 83, 113, 1, NULL),
(102, '2023-06-26', '2023-07-03', 0, 97, 120, 1, NULL),
(103, '2023-06-24', '2023-07-01', 0, 56, 141, 1, NULL),
(104, '2023-06-27', '2023-07-04', 0, 41, 144, 1, NULL),
(105, '2023-06-22', '2023-06-29', 0, 35, 133, 1, NULL),
(106, '2023-06-27', '2023-07-04', 0, 30, 131, 1, NULL),
(107, '2023-06-27', '2023-07-04', 0, 41, 101, 1, NULL),
(108, '2023-06-26', '2023-07-03', 0, 100, 118, 1, NULL),
(109, '2023-06-21', '2023-06-28', 0, 41, 131, 1, NULL),
(110, '2023-06-20', '2023-06-27', 0, 79, 137, 1, NULL),
(111, '2023-06-22', '2023-06-29', 0, 3, 117, 1, NULL),
(112, '2023-06-23', '2023-06-30', 0, 8, 107, 1, NULL),
(113, '2023-06-20', '2023-06-27', 0, 73, 108, 1, NULL),
(114, '2023-06-20', '2023-06-27', 0, 74, 134, 1, NULL),
(115, '2023-06-24', '2023-07-01', 0, 51, 118, 1, NULL),
(116, '2023-06-26', '2023-07-03', 0, 68, 117, 1, NULL),
(117, '2023-06-21', '2023-06-28', 0, 19, 130, 1, NULL),
(118, '2023-06-25', '2023-07-02', 0, 57, 134, 1, NULL),
(119, '2023-06-24', '2023-07-01', 0, 62, 130, 1, NULL),
(120, '2023-06-21', '2023-06-28', 0, 46, 112, 1, NULL),
(121, '2023-06-24', '2023-07-01', 0, 99, 123, 1, NULL),
(122, '2023-06-27', '2023-07-04', 0, 33, 102, 1, NULL),
(123, '2023-06-26', '2023-07-03', 0, 11, 145, 1, NULL),
(124, '2023-06-27', '2023-07-04', 0, 7, 127, 1, NULL),
(125, '2023-06-27', '2023-07-04', 0, 85, 103, 1, NULL),
(126, '2023-06-26', '2023-07-03', 0, 20, 107, 1, NULL),
(127, '2023-06-25', '2023-07-02', 0, 27, 104, 1, NULL),
(128, '2023-06-26', '2023-07-03', 0, 89, 131, 1, NULL),
(129, '2023-06-27', '2023-07-04', 0, 57, 104, 1, NULL),
(130, '2023-06-21', '2023-06-28', 0, 84, 114, 1, NULL),
(131, '2023-06-26', '2023-07-03', 0, 56, 126, 1, NULL),
(132, '2023-06-26', '2023-07-03', 0, 91, 107, 1, NULL),
(133, '2023-06-27', '2023-07-04', 0, 89, 102, 1, NULL),
(134, '2023-06-23', '2023-06-30', 0, 4, 148, 1, NULL),
(135, '2023-06-27', '2023-07-04', 0, 71, 147, 1, NULL),
(136, '2023-06-26', '2023-07-03', 0, 74, 135, 1, NULL),
(137, '2023-06-23', '2023-06-30', 0, 36, 134, 1, NULL),
(138, '2023-06-22', '2023-06-29', 0, 79, 125, 1, NULL),
(139, '2023-06-22', '2023-06-29', 0, 9, 130, 1, NULL),
(140, '2023-06-24', '2023-07-01', 0, 69, 118, 1, NULL),
(141, '2023-06-26', '2023-07-03', 0, 6, 146, 1, NULL),
(142, '2023-06-27', '2023-07-04', 0, 69, 144, 1, NULL),
(143, '2023-06-23', '2023-06-30', 0, 18, 129, 1, NULL),
(144, '2023-06-25', '2023-07-02', 0, 72, 103, 1, NULL),
(145, '2023-06-24', '2023-07-01', 0, 93, 121, 1, NULL),
(146, '2023-06-25', '2023-07-02', 0, 81, 147, 1, NULL),
(147, '2023-06-21', '2023-06-28', 0, 74, 135, 1, NULL),
(148, '2023-06-26', '2023-07-03', 0, 99, 141, 1, NULL),
(149, '2023-06-26', '2023-07-03', 0, 79, 114, 1, NULL),
(150, '2023-06-24', '2023-07-01', 0, 66, 131, 1, NULL),
(151, '2023-06-25', '2023-07-02', 0, 59, 56, 2, NULL),
(152, '2023-06-23', '2023-06-30', 0, 83, 90, 2, NULL),
(153, '2023-06-24', '2023-07-01', 0, 57, 52, 2, NULL),
(154, '2023-06-27', '2023-07-04', 0, 3, 96, 2, NULL),
(155, '2023-06-25', '2023-07-02', 0, 53, 57, 2, NULL),
(156, '2023-06-21', '2023-06-28', 0, 42, 62, 2, NULL),
(157, '2023-06-24', '2023-07-01', 0, 54, 79, 2, NULL),
(158, '2023-06-20', '2023-06-27', 0, 2, 77, 2, NULL),
(159, '2023-06-26', '2023-07-03', 0, 13, 79, 2, NULL),
(160, '2023-06-22', '2023-06-29', 0, 92, 57, 2, NULL),
(161, '2023-06-23', '2023-06-30', 0, 76, 69, 2, NULL),
(162, '2023-06-22', '2023-06-29', 0, 69, 63, 2, NULL),
(163, '2023-06-20', '2023-06-27', 0, 88, 90, 2, NULL),
(164, '2023-06-25', '2023-07-02', 0, 32, 73, 2, NULL),
(165, '2023-06-20', '2023-06-27', 0, 33, 72, 2, NULL),
(166, '2023-06-23', '2023-06-30', 0, 9, 61, 2, NULL),
(167, '2023-06-22', '2023-06-29', 0, 47, 80, 2, NULL),
(168, '2023-06-20', '2023-06-27', 0, 14, 63, 2, NULL),
(169, '2023-06-22', '2023-06-29', 0, 9, 81, 2, NULL),
(170, '2023-06-20', '2023-06-27', 0, 37, 53, 2, NULL),
(171, '2023-06-21', '2023-06-28', 0, 90, 90, 2, NULL),
(172, '2023-06-20', '2023-06-27', 0, 42, 63, 2, NULL),
(173, '2023-06-22', '2023-06-29', 0, 69, 90, 2, NULL),
(174, '2023-06-26', '2023-07-03', 0, 34, 93, 2, NULL),
(175, '2023-06-20', '2023-06-27', 0, 37, 67, 2, NULL),
(176, '2023-06-26', '2023-07-03', 0, 64, 91, 2, NULL),
(177, '2023-06-23', '2023-06-30', 0, 48, 80, 2, NULL),
(178, '2023-06-21', '2023-06-28', 0, 88, 69, 2, NULL),
(179, '2023-06-27', '2023-07-04', 0, 19, 51, 2, NULL),
(180, '2023-06-22', '2023-06-29', 0, 40, 53, 2, NULL),
(181, '2023-06-23', '2023-06-30', 0, 54, 60, 2, NULL),
(182, '2023-06-27', '2023-07-04', 0, 87, 90, 2, NULL),
(183, '2023-06-26', '2023-07-03', 0, 96, 100, 2, NULL),
(184, '2023-06-24', '2023-07-01', 0, 57, 75, 2, NULL),
(185, '2023-06-22', '2023-06-29', 0, 16, 77, 2, NULL),
(186, '2023-06-23', '2023-06-30', 0, 39, 61, 2, NULL),
(187, '2023-06-26', '2023-07-03', 0, 29, 70, 2, NULL),
(188, '2023-06-25', '2023-07-02', 0, 24, 58, 2, NULL),
(189, '2023-06-24', '2023-07-01', 0, 58, 86, 2, NULL),
(190, '2023-06-26', '2023-07-03', 0, 26, 98, 2, NULL),
(191, '2023-06-24', '2023-07-01', 0, 40, 71, 2, NULL),
(192, '2023-06-27', '2023-07-04', 0, 54, 89, 2, NULL),
(193, '2023-06-24', '2023-07-01', 0, 100, 92, 2, NULL),
(194, '2023-06-23', '2023-06-30', 0, 81, 71, 2, NULL),
(195, '2023-06-21', '2023-06-28', 0, 7, 72, 2, NULL),
(196, '2023-06-22', '2023-06-29', 0, 71, 96, 2, NULL),
(197, '2023-06-25', '2023-07-02', 0, 87, 62, 2, NULL),
(198, '2023-06-23', '2023-06-30', 0, 87, 55, 2, NULL),
(199, '2023-06-26', '2023-07-03', 0, 14, 75, 2, NULL),
(200, '2023-06-25', '2023-07-02', 0, 97, 74, 2, NULL),
(201, '2023-06-21', '2023-06-28', 0, 14, 69, 2, NULL),
(202, '2023-06-20', '2023-06-27', 0, 94, 90, 2, NULL),
(203, '2023-06-22', '2023-06-29', 0, 39, 64, 2, NULL),
(204, '2023-06-22', '2023-06-29', 0, 25, 84, 2, NULL),
(205, '2023-06-22', '2023-06-29', 0, 39, 69, 2, NULL),
(206, '2023-06-26', '2023-07-03', 0, 2, 100, 2, NULL),
(207, '2023-06-20', '2023-06-27', 0, 46, 95, 2, NULL),
(208, '2023-06-23', '2023-06-30', 0, 1, 54, 2, NULL),
(209, '2023-06-24', '2023-07-01', 0, 38, 55, 2, NULL),
(210, '2023-06-24', '2023-07-01', 0, 9, 98, 2, NULL),
(211, '2023-06-26', '2023-07-03', 0, 33, 76, 2, NULL),
(212, '2023-06-24', '2023-07-01', 0, 41, 97, 2, NULL),
(213, '2023-06-27', '2023-07-04', 0, 4, 77, 2, NULL),
(214, '2023-06-21', '2023-06-28', 0, 66, 51, 2, NULL),
(215, '2023-06-26', '2023-07-03', 0, 87, 72, 2, NULL),
(216, '2023-06-24', '2023-07-01', 0, 1, 77, 2, NULL),
(217, '2023-06-24', '2023-07-01', 0, 2, 88, 2, NULL),
(218, '2023-06-24', '2023-07-01', 0, 29, 75, 2, NULL),
(219, '2023-06-26', '2023-07-03', 0, 51, 66, 2, NULL),
(220, '2023-06-24', '2023-07-01', 0, 93, 89, 2, NULL),
(221, '2023-06-26', '2023-07-03', 0, 96, 56, 2, NULL),
(222, '2023-06-22', '2023-06-29', 0, 34, 84, 2, NULL),
(223, '2023-06-22', '2023-06-29', 0, 91, 51, 2, NULL),
(224, '2023-06-24', '2023-07-01', 0, 75, 67, 2, NULL),
(225, '2023-06-21', '2023-06-28', 0, 33, 78, 2, NULL),
(226, '2023-06-22', '2023-06-29', 0, 19, 54, 2, NULL),
(227, '2023-06-27', '2023-07-04', 0, 89, 97, 2, NULL),
(228, '2023-06-24', '2023-07-01', 0, 7, 84, 2, NULL),
(229, '2023-06-20', '2023-06-27', 0, 56, 61, 2, NULL),
(230, '2023-06-25', '2023-07-02', 0, 10, 64, 2, NULL),
(231, '2023-06-25', '2023-07-02', 0, 86, 66, 2, NULL),
(232, '2023-06-26', '2023-07-03', 0, 29, 96, 2, NULL),
(233, '2023-06-21', '2023-06-28', 0, 33, 90, 2, NULL),
(234, '2023-06-21', '2023-06-28', 0, 41, 91, 2, NULL),
(235, '2023-06-25', '2023-07-02', 0, 47, 67, 2, NULL),
(236, '2023-06-20', '2023-06-27', 0, 96, 61, 2, NULL),
(237, '2023-06-23', '2023-06-30', 0, 79, 86, 2, NULL),
(238, '2023-06-26', '2023-07-03', 0, 74, 52, 2, NULL),
(239, '2023-06-24', '2023-07-01', 0, 25, 58, 2, NULL),
(240, '2023-06-25', '2023-07-02', 0, 70, 84, 2, NULL),
(241, '2023-06-23', '2023-06-30', 0, 58, 77, 2, NULL),
(242, '2023-06-27', '2023-07-04', 0, 83, 53, 2, NULL),
(243, '2023-06-23', '2023-06-30', 0, 51, 60, 2, NULL),
(244, '2023-06-26', '2023-07-03', 0, 8, 61, 2, NULL),
(245, '2023-06-21', '2023-06-28', 0, 38, 53, 2, NULL),
(246, '2023-06-25', '2023-07-02', 0, 55, 76, 2, NULL),
(247, '2023-06-26', '2023-07-03', 0, 17, 64, 2, NULL),
(248, '2023-06-26', '2023-07-03', 0, 87, 69, 2, NULL),
(249, '2023-06-21', '2023-06-28', 0, 46, 62, 2, NULL),
(250, '2023-06-25', '2023-07-02', 0, 38, 75, 2, NULL),
(251, '2023-06-27', '2023-07-04', 0, 9, 96, 2, NULL),
(252, '2023-06-23', '2023-06-30', 0, 44, 85, 2, NULL),
(253, '2023-06-27', '2023-07-04', 0, 7, 92, 2, NULL),
(254, '2023-06-25', '2023-07-02', 0, 6, 88, 2, NULL),
(255, '2023-06-26', '2023-07-03', 0, 64, 67, 2, NULL),
(256, '2023-06-23', '2023-06-30', 0, 33, 95, 2, NULL),
(257, '2023-06-26', '2023-07-03', 0, 71, 60, 2, NULL),
(258, '2023-06-22', '2023-06-29', 0, 79, 90, 2, NULL),
(259, '2023-06-21', '2023-06-28', 0, 84, 74, 2, NULL),
(260, '2023-06-24', '2023-07-01', 0, 6, 61, 2, NULL),
(261, '2023-06-23', '2023-06-30', 0, 26, 72, 2, NULL),
(262, '2023-06-21', '2023-06-28', 0, 71, 99, 2, NULL),
(263, '2023-06-27', '2023-07-04', 0, 64, 58, 2, NULL),
(264, '2023-06-21', '2023-06-28', 0, 89, 64, 2, NULL),
(265, '2023-06-21', '2023-06-28', 0, 89, 79, 2, NULL),
(266, '2023-06-25', '2023-07-02', 0, 23, 66, 2, NULL),
(267, '2023-06-23', '2023-06-30', 0, 70, 66, 2, NULL),
(268, '2023-06-22', '2023-06-29', 0, 84, 79, 2, NULL),
(269, '2023-06-26', '2023-07-03', 0, 50, 51, 2, NULL),
(270, '2023-06-22', '2023-06-29', 0, 78, 99, 2, NULL),
(271, '2023-06-27', '2023-07-04', 0, 35, 54, 2, NULL),
(272, '2023-06-25', '2023-07-02', 0, 77, 77, 2, NULL),
(273, '2023-06-27', '2023-07-04', 0, 4, 97, 2, NULL),
(274, '2023-06-26', '2023-07-03', 0, 75, 72, 2, NULL),
(275, '2023-06-23', '2023-06-30', 0, 15, 84, 2, NULL),
(276, '2023-06-25', '2023-07-02', 0, 8, 64, 2, NULL),
(277, '2023-06-20', '2023-06-27', 0, 69, 60, 2, NULL),
(278, '2023-06-21', '2023-06-28', 0, 92, 61, 2, NULL),
(279, '2023-06-22', '2023-06-29', 0, 27, 98, 2, NULL),
(280, '2023-06-25', '2023-07-02', 0, 89, 66, 2, NULL),
(281, '2023-06-25', '2023-07-02', 0, 89, 71, 2, NULL),
(282, '2023-06-23', '2023-06-30', 0, 88, 66, 2, NULL),
(283, '2023-06-20', '2023-06-27', 0, 28, 88, 2, NULL),
(284, '2023-06-27', '2023-07-04', 0, 38, 69, 2, NULL),
(285, '2023-06-21', '2023-06-28', 0, 65, 60, 2, NULL),
(286, '2023-06-23', '2023-06-30', 0, 70, 74, 2, NULL),
(287, '2023-06-20', '2023-06-27', 0, 58, 61, 2, NULL),
(288, '2023-06-25', '2023-07-02', 0, 10, 73, 2, NULL),
(289, '2023-06-22', '2023-06-29', 0, 8, 74, 2, NULL),
(290, '2023-06-22', '2023-06-29', 0, 98, 98, 2, NULL),
(291, '2023-06-24', '2023-07-01', 0, 13, 94, 2, NULL),
(292, '2023-06-24', '2023-07-01', 0, 14, 82, 2, NULL),
(293, '2023-06-20', '2023-06-27', 0, 7, 100, 2, NULL),
(294, '2023-06-25', '2023-07-02', 0, 53, 76, 2, NULL),
(295, '2023-06-24', '2023-07-01', 0, 78, 59, 2, NULL),
(296, '2023-06-21', '2023-06-28', 0, 92, 93, 2, NULL),
(297, '2023-06-22', '2023-06-29', 0, 35, 60, 2, NULL),
(298, '2023-06-20', '2023-06-27', 0, 25, 78, 2, NULL),
(299, '2023-06-22', '2023-06-29', 0, 67, 98, 2, NULL),
(300, '2023-06-24', '2023-07-01', 0, 8, 52, 2, NULL),
(301, '2023-06-26', '2023-07-03', 0, 16, 159, 3, NULL),
(302, '2023-06-25', '2023-07-02', 0, 64, 191, 3, NULL),
(303, '2023-06-27', '2023-07-04', 0, 53, 195, 3, NULL),
(304, '2023-06-26', '2023-07-03', 0, 18, 190, 3, NULL),
(305, '2023-06-21', '2023-06-28', 0, 90, 168, 3, NULL),
(306, '2023-06-23', '2023-06-30', 0, 93, 194, 3, NULL),
(307, '2023-06-25', '2023-07-02', 0, 36, 179, 3, NULL),
(308, '2023-06-20', '2023-06-27', 0, 73, 166, 3, NULL),
(309, '2023-06-22', '2023-06-29', 0, 60, 175, 3, NULL),
(310, '2023-06-26', '2023-07-03', 0, 38, 151, 3, NULL),
(311, '2023-06-23', '2023-06-30', 0, 60, 195, 3, NULL),
(312, '2023-06-27', '2023-07-04', 0, 14, 195, 3, NULL),
(313, '2023-06-23', '2023-06-30', 0, 42, 179, 3, NULL),
(314, '2023-06-22', '2023-06-29', 0, 29, 198, 3, NULL),
(315, '2023-06-24', '2023-07-01', 0, 49, 172, 3, NULL),
(316, '2023-06-25', '2023-07-02', 0, 81, 159, 3, NULL),
(317, '2023-06-21', '2023-06-28', 0, 56, 179, 3, NULL),
(318, '2023-06-26', '2023-07-03', 0, 69, 199, 3, NULL),
(319, '2023-06-21', '2023-06-28', 0, 66, 172, 3, NULL),
(320, '2023-06-20', '2023-06-27', 0, 8, 151, 3, NULL),
(321, '2023-06-20', '2023-06-27', 0, 26, 180, 3, NULL),
(322, '2023-06-24', '2023-07-01', 0, 62, 161, 3, NULL),
(323, '2023-06-27', '2023-07-04', 0, 87, 193, 3, NULL),
(324, '2023-06-23', '2023-06-30', 0, 24, 168, 3, NULL),
(325, '2023-06-21', '2023-06-28', 0, 35, 178, 3, NULL),
(326, '2023-06-24', '2023-07-01', 0, 6, 159, 3, NULL),
(327, '2023-06-21', '2023-06-28', 0, 53, 178, 3, NULL),
(328, '2023-06-24', '2023-07-01', 0, 95, 179, 3, NULL),
(329, '2023-06-24', '2023-07-01', 0, 90, 151, 3, NULL),
(330, '2023-06-20', '2023-06-27', 0, 4, 181, 3, NULL),
(331, '2023-06-22', '2023-06-29', 0, 60, 180, 3, NULL),
(332, '2023-06-25', '2023-07-02', 0, 37, 167, 3, NULL),
(333, '2023-06-23', '2023-06-30', 0, 29, 191, 3, NULL),
(334, '2023-06-21', '2023-06-28', 0, 71, 198, 3, NULL),
(335, '2023-06-21', '2023-06-28', 0, 99, 161, 3, NULL),
(336, '2023-06-20', '2023-06-27', 0, 31, 161, 3, NULL),
(337, '2023-06-24', '2023-07-01', 0, 5, 191, 3, NULL),
(338, '2023-06-20', '2023-06-27', 0, 76, 176, 3, NULL),
(339, '2023-06-21', '2023-06-28', 0, 95, 169, 3, NULL),
(340, '2023-06-26', '2023-07-03', 0, 97, 169, 3, NULL),
(341, '2023-06-25', '2023-07-02', 0, 62, 173, 3, NULL),
(342, '2023-06-26', '2023-07-03', 0, 16, 170, 3, NULL),
(343, '2023-06-25', '2023-07-02', 0, 86, 168, 3, NULL),
(344, '2023-06-27', '2023-07-04', 0, 7, 196, 3, NULL),
(345, '2023-06-22', '2023-06-29', 0, 95, 178, 3, NULL),
(346, '2023-06-20', '2023-06-27', 0, 54, 198, 3, NULL),
(347, '2023-06-27', '2023-07-04', 0, 21, 177, 3, NULL),
(348, '2023-06-21', '2023-06-28', 0, 61, 182, 3, NULL),
(349, '2023-06-22', '2023-06-29', 0, 15, 152, 3, NULL),
(350, '2023-06-21', '2023-06-28', 0, 9, 191, 3, NULL),
(351, '2023-06-22', '2023-06-29', 0, 11, 177, 3, NULL),
(352, '2023-06-20', '2023-06-27', 0, 66, 173, 3, NULL),
(353, '2023-06-23', '2023-06-30', 0, 62, 159, 3, NULL),
(354, '2023-06-22', '2023-06-29', 0, 13, 162, 3, NULL),
(355, '2023-06-20', '2023-06-27', 0, 88, 166, 3, NULL),
(356, '2023-06-23', '2023-06-30', 0, 74, 153, 3, NULL),
(357, '2023-06-21', '2023-06-28', 0, 60, 175, 3, NULL),
(358, '2023-06-26', '2023-07-03', 0, 21, 190, 3, NULL),
(359, '2023-06-23', '2023-06-30', 0, 24, 193, 3, NULL),
(360, '2023-06-22', '2023-06-29', 0, 17, 171, 3, NULL),
(361, '2023-06-21', '2023-06-28', 0, 79, 156, 3, NULL),
(362, '2023-06-21', '2023-06-28', 0, 33, 176, 3, NULL),
(363, '2023-06-21', '2023-06-28', 0, 18, 179, 3, NULL),
(364, '2023-06-23', '2023-06-30', 0, 28, 155, 3, NULL),
(365, '2023-06-20', '2023-06-27', 0, 75, 198, 3, NULL),
(366, '2023-06-26', '2023-07-03', 0, 83, 193, 3, NULL),
(367, '2023-06-23', '2023-06-30', 0, 71, 175, 3, NULL),
(368, '2023-06-21', '2023-06-28', 0, 8, 177, 3, NULL),
(369, '2023-06-20', '2023-06-27', 0, 100, 159, 3, NULL),
(370, '2023-06-25', '2023-07-02', 0, 100, 168, 3, NULL),
(371, '2023-06-23', '2023-06-30', 0, 47, 186, 3, NULL),
(372, '2023-06-23', '2023-06-30', 0, 52, 198, 3, NULL),
(373, '2023-06-23', '2023-06-30', 0, 95, 182, 3, NULL),
(374, '2023-06-25', '2023-07-02', 0, 52, 161, 3, NULL),
(375, '2023-06-26', '2023-07-03', 0, 64, 195, 3, NULL),
(376, '2023-06-21', '2023-06-28', 0, 36, 167, 3, NULL),
(377, '2023-06-23', '2023-06-30', 0, 29, 153, 3, NULL),
(378, '2023-06-23', '2023-06-30', 0, 84, 189, 3, NULL),
(379, '2023-06-21', '2023-06-28', 0, 83, 172, 3, NULL),
(380, '2023-06-24', '2023-07-01', 0, 89, 190, 3, NULL),
(381, '2023-06-22', '2023-06-29', 0, 59, 154, 3, NULL),
(382, '2023-06-24', '2023-07-01', 0, 100, 176, 3, NULL),
(383, '2023-06-22', '2023-06-29', 0, 96, 176, 3, NULL),
(384, '2023-06-27', '2023-07-04', 0, 50, 170, 3, NULL),
(385, '2023-06-20', '2023-06-27', 0, 61, 190, 3, NULL),
(386, '2023-06-27', '2023-07-04', 0, 24, 197, 3, NULL),
(387, '2023-06-27', '2023-07-04', 0, 62, 174, 3, NULL),
(388, '2023-06-21', '2023-06-28', 0, 81, 166, 3, NULL),
(389, '2023-06-25', '2023-07-02', 0, 59, 173, 3, NULL),
(390, '2023-06-23', '2023-06-30', 0, 4, 163, 3, NULL),
(391, '2023-06-23', '2023-06-30', 0, 7, 196, 3, NULL),
(392, '2023-06-25', '2023-07-02', 0, 47, 196, 3, NULL),
(393, '2023-06-21', '2023-06-28', 0, 59, 162, 3, NULL),
(394, '2023-06-23', '2023-06-30', 0, 41, 184, 3, NULL),
(395, '2023-06-26', '2023-07-03', 0, 93, 196, 3, NULL),
(396, '2023-06-21', '2023-06-28', 0, 93, 180, 3, NULL),
(397, '2023-06-21', '2023-06-28', 0, 16, 183, 3, NULL),
(398, '2023-06-24', '2023-07-01', 0, 81, 180, 3, NULL),
(399, '2023-06-21', '2023-06-28', 0, 68, 184, 3, NULL),
(400, '2023-06-20', '2023-06-27', 0, 31, 183, 3, NULL),
(401, '2023-06-21', '2023-06-28', 0, 74, 169, 3, NULL),
(402, '2023-06-22', '2023-06-29', 0, 26, 192, 3, NULL),
(403, '2023-06-23', '2023-06-30', 0, 72, 178, 3, NULL),
(404, '2023-06-26', '2023-07-03', 0, 71, 164, 3, NULL),
(405, '2023-06-22', '2023-06-29', 0, 89, 196, 3, NULL),
(406, '2023-06-23', '2023-06-30', 0, 42, 191, 3, NULL),
(407, '2023-06-23', '2023-06-30', 0, 1, 151, 3, NULL),
(408, '2023-06-23', '2023-06-30', 0, 12, 156, 3, NULL),
(409, '2023-06-21', '2023-06-28', 0, 20, 160, 3, NULL),
(410, '2023-06-24', '2023-07-01', 0, 97, 155, 3, NULL),
(411, '2023-06-25', '2023-07-02', 0, 99, 177, 3, NULL),
(412, '2023-06-20', '2023-06-27', 0, 11, 173, 3, NULL),
(413, '2023-06-22', '2023-06-29', 0, 75, 180, 3, NULL),
(414, '2023-06-26', '2023-07-03', 0, 66, 155, 3, NULL),
(415, '2023-06-26', '2023-07-03', 0, 5, 155, 3, NULL),
(416, '2023-06-22', '2023-06-29', 0, 51, 184, 3, NULL),
(417, '2023-06-27', '2023-07-04', 0, 76, 169, 3, NULL),
(418, '2023-06-23', '2023-06-30', 0, 32, 187, 3, NULL),
(419, '2023-06-20', '2023-06-27', 0, 22, 164, 3, NULL),
(420, '2023-06-22', '2023-06-29', 0, 91, 181, 3, NULL),
(421, '2023-06-24', '2023-07-01', 0, 17, 161, 3, NULL),
(422, '2023-06-26', '2023-07-03', 0, 98, 172, 3, NULL),
(423, '2023-06-24', '2023-07-01', 0, 74, 178, 3, NULL),
(424, '2023-06-20', '2023-06-27', 0, 100, 164, 3, NULL),
(425, '2023-06-24', '2023-07-01', 0, 12, 157, 3, NULL),
(426, '2023-06-26', '2023-07-03', 0, 88, 171, 3, NULL),
(427, '2023-06-24', '2023-07-01', 0, 58, 185, 3, NULL),
(428, '2023-06-25', '2023-07-02', 0, 45, 173, 3, NULL),
(429, '2023-06-25', '2023-07-02', 0, 58, 182, 3, NULL),
(430, '2023-06-25', '2023-07-02', 0, 8, 191, 3, NULL),
(431, '2023-06-23', '2023-06-30', 0, 4, 192, 3, NULL),
(432, '2023-06-21', '2023-06-28', 0, 6, 166, 3, NULL),
(433, '2023-06-25', '2023-07-02', 0, 79, 197, 3, NULL),
(434, '2023-06-22', '2023-06-29', 0, 7, 186, 3, NULL),
(435, '2023-06-25', '2023-07-02', 0, 38, 191, 3, NULL),
(436, '2023-06-26', '2023-07-03', 0, 28, 195, 3, NULL),
(437, '2023-06-26', '2023-07-03', 0, 18, 198, 3, NULL),
(438, '2023-06-27', '2023-07-04', 0, 29, 196, 3, NULL),
(439, '2023-06-24', '2023-07-01', 0, 67, 181, 3, NULL),
(440, '2023-06-27', '2023-07-04', 0, 48, 162, 3, NULL),
(441, '2023-06-23', '2023-06-30', 0, 94, 152, 3, NULL),
(442, '2023-06-21', '2023-06-28', 0, 11, 171, 3, NULL),
(443, '2023-06-23', '2023-06-30', 0, 15, 180, 3, NULL),
(444, '2023-06-22', '2023-06-29', 0, 18, 200, 3, NULL),
(445, '2023-06-21', '2023-06-28', 0, 28, 192, 3, NULL),
(446, '2023-06-23', '2023-06-30', 0, 23, 164, 3, NULL),
(447, '2023-06-21', '2023-06-28', 0, 29, 197, 3, NULL),
(448, '2023-06-25', '2023-07-02', 0, 64, 191, 3, NULL),
(449, '2023-06-20', '2023-06-27', 0, 84, 162, 3, NULL),
(450, '2023-06-26', '2023-07-03', 0, 72, 151, 3, NULL),
(451, '2023-06-21', '2023-06-28', 0, 88, 242, 4, NULL),
(452, '2023-06-25', '2023-07-02', 0, 49, 201, 4, NULL),
(453, '2023-06-26', '2023-07-03', 0, 74, 221, 4, NULL),
(454, '2023-06-21', '2023-06-28', 0, 16, 250, 4, NULL),
(455, '2023-06-20', '2023-06-27', 0, 42, 250, 4, NULL),
(456, '2023-06-23', '2023-06-30', 0, 11, 221, 4, NULL),
(457, '2023-06-22', '2023-06-29', 0, 21, 222, 4, NULL),
(458, '2023-06-26', '2023-07-03', 0, 46, 204, 4, NULL),
(459, '2023-06-23', '2023-06-30', 0, 13, 215, 4, NULL),
(460, '2023-06-20', '2023-06-27', 0, 32, 236, 4, NULL),
(461, '2023-06-26', '2023-07-03', 0, 25, 228, 4, NULL),
(462, '2023-06-26', '2023-07-03', 0, 71, 207, 4, NULL),
(463, '2023-06-22', '2023-06-29', 0, 64, 239, 4, NULL),
(464, '2023-06-23', '2023-06-30', 0, 87, 212, 4, NULL),
(465, '2023-06-27', '2023-07-04', 0, 78, 202, 4, NULL),
(466, '2023-06-23', '2023-06-30', 0, 19, 241, 4, NULL),
(467, '2023-06-26', '2023-07-03', 0, 37, 229, 4, NULL),
(468, '2023-06-25', '2023-07-02', 0, 18, 233, 4, NULL),
(469, '2023-06-23', '2023-06-30', 0, 95, 248, 4, NULL),
(470, '2023-06-24', '2023-07-01', 0, 99, 218, 4, NULL),
(471, '2023-06-20', '2023-06-27', 0, 36, 213, 4, NULL),
(472, '2023-06-21', '2023-06-28', 0, 8, 205, 4, NULL),
(473, '2023-06-20', '2023-06-27', 0, 53, 233, 4, NULL),
(474, '2023-06-27', '2023-07-04', 0, 67, 209, 4, NULL),
(475, '2023-06-22', '2023-06-29', 0, 20, 232, 4, NULL),
(476, '2023-06-24', '2023-07-01', 0, 100, 250, 4, NULL),
(477, '2023-06-22', '2023-06-29', 0, 91, 208, 4, NULL),
(478, '2023-06-25', '2023-07-02', 0, 1, 231, 4, NULL),
(479, '2023-06-21', '2023-06-28', 0, 67, 240, 4, NULL),
(480, '2023-06-25', '2023-07-02', 0, 85, 216, 4, NULL),
(481, '2023-06-20', '2023-06-27', 0, 15, 224, 4, NULL),
(482, '2023-06-27', '2023-07-04', 0, 89, 230, 4, NULL),
(483, '2023-06-27', '2023-07-04', 0, 65, 250, 4, NULL),
(484, '2023-06-21', '2023-06-28', 0, 78, 238, 4, NULL),
(485, '2023-06-23', '2023-06-30', 0, 81, 224, 4, NULL),
(486, '2023-06-20', '2023-06-27', 0, 13, 237, 4, NULL),
(487, '2023-06-27', '2023-07-04', 0, 67, 233, 4, NULL),
(488, '2023-06-27', '2023-07-04', 0, 57, 227, 4, NULL),
(489, '2023-06-25', '2023-07-02', 0, 52, 247, 4, NULL),
(490, '2023-06-27', '2023-07-04', 0, 24, 233, 4, NULL),
(491, '2023-06-21', '2023-06-28', 0, 69, 238, 4, NULL),
(492, '2023-06-20', '2023-06-27', 0, 60, 206, 4, NULL),
(493, '2023-06-24', '2023-07-01', 0, 50, 236, 4, NULL),
(494, '2023-06-26', '2023-07-03', 0, 55, 230, 4, NULL),
(495, '2023-06-24', '2023-07-01', 0, 59, 206, 4, NULL),
(496, '2023-06-21', '2023-06-28', 0, 51, 233, 4, NULL),
(497, '2023-06-20', '2023-06-27', 0, 44, 245, 4, NULL),
(498, '2023-06-23', '2023-06-30', 0, 43, 224, 4, NULL),
(499, '2023-06-23', '2023-06-30', 0, 25, 245, 4, NULL),
(500, '2023-06-26', '2023-07-03', 0, 22, 247, 4, NULL),
(501, '2023-06-22', '2023-06-29', 0, 66, 204, 4, NULL),
(502, '2023-06-24', '2023-07-01', 0, 47, 208, 4, NULL),
(503, '2023-06-24', '2023-07-01', 0, 19, 232, 4, NULL),
(504, '2023-06-22', '2023-06-29', 0, 88, 240, 4, NULL),
(505, '2023-06-25', '2023-07-02', 0, 4, 223, 4, NULL),
(506, '2023-06-21', '2023-06-28', 0, 7, 212, 4, NULL),
(507, '2023-06-24', '2023-07-01', 0, 65, 214, 4, NULL),
(508, '2023-06-25', '2023-07-02', 0, 27, 237, 4, NULL),
(509, '2023-06-20', '2023-06-27', 0, 11, 245, 4, NULL),
(510, '2023-06-26', '2023-07-03', 0, 48, 204, 4, NULL),
(511, '2023-06-24', '2023-07-01', 0, 9, 211, 4, NULL),
(512, '2023-06-25', '2023-07-02', 0, 1, 229, 4, NULL),
(513, '2023-06-26', '2023-07-03', 0, 40, 235, 4, NULL),
(514, '2023-06-23', '2023-06-30', 0, 27, 203, 4, NULL),
(515, '2023-06-20', '2023-06-27', 0, 86, 221, 4, NULL),
(516, '2023-06-26', '2023-07-03', 0, 31, 242, 4, NULL),
(517, '2023-06-24', '2023-07-01', 0, 42, 201, 4, NULL),
(518, '2023-06-22', '2023-06-29', 0, 13, 225, 4, NULL),
(519, '2023-06-22', '2023-06-29', 0, 16, 201, 4, NULL),
(520, '2023-06-25', '2023-07-02', 0, 66, 229, 4, NULL),
(521, '2023-06-25', '2023-07-02', 0, 52, 213, 4, NULL),
(522, '2023-06-24', '2023-07-01', 0, 88, 224, 4, NULL),
(523, '2023-06-20', '2023-06-27', 0, 97, 238, 4, NULL),
(524, '2023-06-23', '2023-06-30', 0, 95, 233, 4, NULL),
(525, '2023-06-25', '2023-07-02', 0, 22, 202, 4, NULL),
(526, '2023-06-27', '2023-07-04', 0, 83, 206, 4, NULL),
(527, '2023-06-23', '2023-06-30', 0, 58, 223, 4, NULL),
(528, '2023-06-20', '2023-06-27', 0, 33, 248, 4, NULL),
(529, '2023-06-21', '2023-06-28', 0, 25, 221, 4, NULL),
(530, '2023-06-27', '2023-07-04', 0, 48, 238, 4, NULL),
(531, '2023-06-27', '2023-07-04', 0, 19, 221, 4, NULL),
(532, '2023-06-20', '2023-06-27', 0, 68, 243, 4, NULL),
(533, '2023-06-23', '2023-06-30', 0, 32, 203, 4, NULL),
(534, '2023-06-20', '2023-06-27', 0, 98, 218, 4, NULL),
(535, '2023-06-24', '2023-07-01', 0, 53, 207, 4, NULL),
(536, '2023-06-24', '2023-07-01', 0, 58, 245, 4, NULL),
(537, '2023-06-22', '2023-06-29', 0, 37, 213, 4, NULL),
(538, '2023-06-23', '2023-06-30', 0, 31, 208, 4, NULL),
(539, '2023-06-25', '2023-07-02', 0, 51, 214, 4, NULL),
(540, '2023-06-20', '2023-06-27', 0, 22, 226, 4, NULL),
(541, '2023-06-23', '2023-06-30', 0, 52, 247, 4, NULL),
(542, '2023-06-23', '2023-06-30', 0, 92, 218, 4, NULL),
(543, '2023-06-27', '2023-07-04', 0, 65, 216, 4, NULL),
(544, '2023-06-27', '2023-07-04', 0, 44, 217, 4, NULL),
(545, '2023-06-27', '2023-07-04', 0, 74, 232, 4, NULL),
(546, '2023-06-26', '2023-07-03', 0, 90, 203, 4, NULL),
(547, '2023-06-22', '2023-06-29', 0, 17, 240, 4, NULL),
(548, '2023-06-24', '2023-07-01', 0, 27, 244, 4, NULL),
(549, '2023-06-21', '2023-06-28', 0, 15, 242, 4, NULL),
(550, '2023-06-27', '2023-07-04', 0, 48, 211, 4, NULL),
(551, '2023-06-23', '2023-06-30', 0, 43, 237, 4, NULL),
(552, '2023-06-27', '2023-07-04', 0, 47, 232, 4, NULL),
(553, '2023-06-25', '2023-07-02', 0, 30, 202, 4, NULL),
(554, '2023-06-24', '2023-07-01', 0, 51, 243, 4, NULL),
(555, '2023-06-22', '2023-06-29', 0, 76, 232, 4, NULL),
(556, '2023-06-27', '2023-07-04', 0, 31, 201, 4, NULL),
(557, '2023-06-25', '2023-07-02', 0, 42, 232, 4, NULL),
(558, '2023-06-20', '2023-06-27', 0, 34, 219, 4, NULL),
(559, '2023-06-21', '2023-06-28', 0, 28, 201, 4, NULL),
(560, '2023-06-23', '2023-06-30', 0, 15, 210, 4, NULL),
(561, '2023-06-21', '2023-06-28', 0, 50, 231, 4, NULL),
(562, '2023-06-22', '2023-06-29', 0, 3, 229, 4, NULL),
(563, '2023-06-23', '2023-06-30', 0, 46, 229, 4, NULL),
(564, '2023-06-20', '2023-06-27', 0, 46, 239, 4, NULL),
(565, '2023-06-23', '2023-06-30', 0, 24, 241, 4, NULL),
(566, '2023-06-20', '2023-06-27', 0, 2, 226, 4, NULL),
(567, '2023-06-22', '2023-06-29', 0, 23, 215, 4, NULL),
(568, '2023-06-26', '2023-07-03', 0, 95, 213, 4, NULL),
(569, '2023-06-20', '2023-06-27', 0, 99, 248, 4, NULL),
(570, '2023-06-25', '2023-07-02', 0, 100, 214, 4, NULL),
(571, '2023-06-26', '2023-07-03', 0, 34, 227, 4, NULL),
(572, '2023-06-23', '2023-06-30', 0, 8, 209, 4, NULL),
(573, '2023-06-24', '2023-07-01', 0, 41, 236, 4, NULL),
(574, '2023-06-25', '2023-07-02', 0, 93, 204, 4, NULL),
(575, '2023-06-26', '2023-07-03', 0, 22, 202, 4, NULL),
(576, '2023-06-24', '2023-07-01', 0, 76, 246, 4, NULL),
(577, '2023-06-21', '2023-06-28', 0, 97, 213, 4, NULL),
(578, '2023-06-20', '2023-06-27', 0, 94, 220, 4, NULL),
(579, '2023-06-20', '2023-06-27', 0, 98, 201, 4, NULL),
(580, '2023-06-23', '2023-06-30', 0, 56, 205, 4, NULL),
(581, '2023-06-22', '2023-06-29', 0, 70, 229, 4, NULL),
(582, '2023-06-24', '2023-07-01', 0, 38, 213, 4, NULL),
(583, '2023-06-24', '2023-07-01', 0, 100, 231, 4, NULL),
(584, '2023-06-22', '2023-06-29', 0, 9, 217, 4, NULL),
(585, '2023-06-27', '2023-07-04', 0, 79, 240, 4, NULL),
(586, '2023-06-25', '2023-07-02', 0, 22, 230, 4, NULL),
(587, '2023-06-23', '2023-06-30', 0, 51, 234, 4, NULL),
(588, '2023-06-27', '2023-07-04', 0, 70, 203, 4, NULL),
(589, '2023-06-27', '2023-07-04', 0, 58, 224, 4, NULL),
(590, '2023-06-26', '2023-07-03', 0, 81, 210, 4, NULL),
(591, '2023-06-21', '2023-06-28', 0, 4, 226, 4, NULL),
(592, '2023-06-24', '2023-07-01', 0, 82, 245, 4, NULL),
(593, '2023-06-21', '2023-06-28', 0, 27, 230, 4, NULL),
(594, '2023-06-25', '2023-07-02', 0, 22, 207, 4, NULL),
(595, '2023-06-24', '2023-07-01', 0, 58, 212, 4, NULL),
(596, '2023-06-23', '2023-06-30', 0, 60, 234, 4, NULL),
(597, '2023-06-27', '2023-07-04', 0, 15, 249, 4, NULL),
(598, '2023-06-21', '2023-06-28', 0, 37, 243, 4, NULL),
(599, '2023-06-23', '2023-06-30', 0, 96, 223, 4, NULL),
(600, '2023-06-22', '2023-06-29', 0, 67, 231, 4, NULL),
(601, '2023-06-22', '2023-06-29', 0, 24, 39, 5, NULL),
(602, '2023-06-23', '2023-06-30', 0, 19, 27, 5, NULL),
(603, '2023-06-27', '2023-07-04', 0, 74, 20, 5, NULL),
(604, '2023-06-23', '2023-06-30', 0, 17, 38, 5, NULL),
(605, '2023-06-25', '2023-07-02', 0, 71, 34, 5, NULL),
(606, '2023-06-24', '2023-07-01', 0, 18, 30, 5, NULL),
(607, '2023-06-26', '2023-07-03', 0, 80, 1, 5, NULL),
(608, '2023-06-25', '2023-07-02', 0, 82, 36, 5, NULL),
(609, '2023-06-21', '2023-06-28', 0, 6, 42, 5, NULL),
(610, '2023-06-22', '2023-06-29', 0, 23, 3, 5, NULL),
(611, '2023-06-21', '2023-06-28', 0, 54, 32, 5, NULL),
(612, '2023-06-22', '2023-06-29', 0, 50, 8, 5, NULL),
(613, '2023-06-23', '2023-06-30', 0, 66, 9, 5, NULL),
(614, '2023-06-27', '2023-07-04', 0, 62, 37, 5, NULL),
(615, '2023-06-22', '2023-06-29', 0, 57, 7, 5, NULL),
(616, '2023-06-22', '2023-06-29', 0, 1, 42, 5, NULL),
(617, '2023-06-24', '2023-07-01', 0, 4, 32, 5, NULL),
(618, '2023-06-23', '2023-06-30', 0, 42, 24, 5, NULL),
(619, '2023-06-21', '2023-06-28', 0, 22, 5, 5, NULL),
(620, '2023-06-25', '2023-07-02', 0, 92, 16, 5, NULL),
(621, '2023-06-25', '2023-07-02', 0, 80, 25, 5, NULL),
(622, '2023-06-21', '2023-06-28', 0, 97, 2, 5, NULL),
(623, '2023-06-25', '2023-07-02', 0, 42, 11, 5, NULL),
(624, '2023-06-26', '2023-07-03', 0, 67, 22, 5, NULL),
(625, '2023-06-21', '2023-06-28', 0, 14, 19, 5, NULL),
(626, '2023-06-21', '2023-06-28', 0, 91, 26, 5, NULL),
(627, '2023-06-27', '2023-07-04', 0, 53, 49, 5, NULL),
(628, '2023-06-26', '2023-07-03', 0, 45, 1, 5, NULL),
(629, '2023-06-23', '2023-06-30', 0, 21, 19, 5, NULL),
(630, '2023-06-26', '2023-07-03', 0, 6, 16, 5, NULL),
(631, '2023-06-23', '2023-06-30', 0, 90, 33, 5, NULL),
(632, '2023-06-21', '2023-06-28', 0, 19, 38, 5, NULL),
(633, '2023-06-25', '2023-07-02', 0, 12, 26, 5, NULL),
(634, '2023-06-20', '2023-06-27', 0, 23, 47, 5, NULL),
(635, '2023-06-23', '2023-06-30', 0, 78, 24, 5, NULL),
(636, '2023-06-24', '2023-07-01', 0, 12, 38, 5, NULL),
(637, '2023-06-27', '2023-07-04', 0, 88, 24, 5, NULL),
(638, '2023-06-27', '2023-07-04', 0, 27, 41, 5, NULL),
(639, '2023-06-26', '2023-07-03', 0, 66, 13, 5, NULL),
(640, '2023-06-22', '2023-06-29', 0, 40, 12, 5, NULL),
(641, '2023-06-22', '2023-06-29', 0, 2, 43, 5, NULL),
(642, '2023-06-21', '2023-06-28', 0, 99, 37, 5, NULL),
(643, '2023-06-27', '2023-07-04', 0, 30, 3, 5, NULL),
(644, '2023-06-20', '2023-06-27', 0, 11, 18, 5, NULL),
(645, '2023-06-22', '2023-06-29', 0, 36, 5, 5, NULL),
(646, '2023-06-23', '2023-06-30', 0, 9, 28, 5, NULL),
(647, '2023-06-24', '2023-07-01', 0, 34, 15, 5, NULL),
(648, '2023-06-22', '2023-06-29', 0, 39, 25, 5, NULL),
(649, '2023-06-27', '2023-07-04', 0, 72, 50, 5, NULL),
(650, '2023-06-23', '2023-06-30', 0, 37, 21, 5, NULL),
(651, '2023-06-25', '2023-07-02', 0, 91, 13, 5, NULL),
(652, '2023-06-20', '2023-06-27', 0, 92, 7, 5, NULL),
(653, '2023-06-27', '2023-07-04', 0, 38, 46, 5, NULL),
(654, '2023-06-22', '2023-06-29', 0, 83, 40, 5, NULL),
(655, '2023-06-24', '2023-07-01', 0, 97, 43, 5, NULL),
(656, '2023-06-21', '2023-06-28', 0, 42, 47, 5, NULL),
(657, '2023-06-20', '2023-06-27', 0, 71, 4, 5, NULL),
(658, '2023-06-24', '2023-07-01', 0, 7, 6, 5, NULL),
(659, '2023-06-23', '2023-06-30', 0, 37, 48, 5, NULL),
(660, '2023-06-25', '2023-07-02', 0, 6, 32, 5, NULL),
(661, '2023-06-26', '2023-07-03', 0, 59, 35, 5, NULL),
(662, '2023-06-25', '2023-07-02', 0, 19, 16, 5, NULL),
(663, '2023-06-22', '2023-06-29', 0, 75, 22, 5, NULL),
(664, '2023-06-26', '2023-07-03', 0, 52, 23, 5, NULL),
(665, '2023-06-22', '2023-06-29', 0, 35, 6, 5, NULL),
(666, '2023-06-25', '2023-07-02', 0, 53, 48, 5, NULL),
(667, '2023-06-22', '2023-06-29', 0, 61, 22, 5, NULL),
(668, '2023-06-23', '2023-06-30', 0, 45, 40, 5, NULL),
(669, '2023-06-21', '2023-06-28', 0, 44, 1, 5, NULL),
(670, '2023-06-26', '2023-07-03', 0, 10, 42, 5, NULL),
(671, '2023-06-23', '2023-06-30', 0, 69, 48, 5, NULL),
(672, '2023-06-21', '2023-06-28', 0, 15, 42, 5, NULL),
(673, '2023-06-20', '2023-06-27', 0, 54, 21, 5, NULL),
(674, '2023-06-20', '2023-06-27', 0, 35, 11, 5, NULL),
(675, '2023-06-22', '2023-06-29', 0, 26, 5, 5, NULL),
(676, '2023-06-27', '2023-07-04', 0, 12, 12, 5, NULL),
(677, '2023-06-22', '2023-06-29', 0, 13, 38, 5, NULL),
(678, '2023-06-26', '2023-07-03', 0, 96, 36, 5, NULL),
(679, '2023-06-24', '2023-07-01', 0, 84, 35, 5, NULL),
(680, '2023-06-23', '2023-06-30', 0, 26, 21, 5, NULL),
(681, '2023-06-20', '2023-06-27', 0, 92, 30, 5, NULL),
(682, '2023-06-22', '2023-06-29', 0, 73, 1, 5, NULL),
(683, '2023-06-20', '2023-06-27', 0, 25, 30, 5, NULL),
(684, '2023-06-24', '2023-07-01', 0, 28, 15, 5, NULL),
(685, '2023-06-23', '2023-06-30', 0, 22, 5, 5, NULL),
(686, '2023-06-24', '2023-07-01', 0, 22, 20, 5, NULL),
(687, '2023-06-22', '2023-06-29', 0, 98, 42, 5, NULL),
(688, '2023-06-22', '2023-06-29', 0, 25, 26, 5, NULL),
(689, '2023-06-22', '2023-06-29', 0, 43, 35, 5, NULL),
(690, '2023-06-26', '2023-07-03', 0, 13, 14, 5, NULL),
(691, '2023-06-25', '2023-07-02', 0, 28, 8, 5, NULL),
(692, '2023-06-22', '2023-06-29', 0, 39, 49, 5, NULL),
(693, '2023-06-21', '2023-06-28', 0, 13, 44, 5, NULL),
(694, '2023-06-23', '2023-06-30', 0, 56, 17, 5, NULL),
(695, '2023-06-20', '2023-06-27', 0, 18, 40, 5, NULL),
(696, '2023-06-25', '2023-07-02', 0, 27, 16, 5, NULL),
(697, '2023-06-26', '2023-07-03', 0, 8, 18, 5, NULL),
(698, '2023-06-25', '2023-07-02', 0, 87, 37, 5, NULL),
(699, '2023-06-26', '2023-07-03', 0, 69, 42, 5, NULL),
(700, '2023-06-22', '2023-06-29', 0, 7, 26, 5, NULL),
(701, '2023-06-22', '2023-06-29', 0, 44, 43, 5, NULL),
(702, '2023-06-27', '2023-07-04', 0, 73, 3, 5, NULL),
(703, '2023-06-22', '2023-06-29', 0, 9, 34, 5, NULL),
(704, '2023-06-22', '2023-06-29', 0, 99, 10, 5, NULL),
(705, '2023-06-23', '2023-06-30', 0, 23, 9, 5, NULL),
(706, '2023-06-26', '2023-07-03', 0, 77, 39, 5, NULL),
(707, '2023-06-20', '2023-06-27', 0, 3, 19, 5, NULL),
(708, '2023-06-21', '2023-06-28', 0, 98, 8, 5, NULL),
(709, '2023-06-20', '2023-06-27', 0, 86, 37, 5, NULL),
(710, '2023-06-20', '2023-06-27', 0, 70, 28, 5, NULL),
(711, '2023-06-26', '2023-07-03', 0, 83, 16, 5, NULL),
(712, '2023-06-22', '2023-06-29', 0, 96, 21, 5, NULL),
(713, '2023-06-21', '2023-06-28', 0, 22, 8, 5, NULL),
(714, '2023-06-21', '2023-06-28', 0, 67, 15, 5, NULL),
(715, '2023-06-27', '2023-07-04', 0, 38, 4, 5, NULL),
(716, '2023-06-27', '2023-07-04', 0, 53, 17, 5, NULL),
(717, '2023-06-23', '2023-06-30', 0, 5, 3, 5, NULL),
(718, '2023-06-25', '2023-07-02', 0, 53, 45, 5, NULL),
(719, '2023-06-26', '2023-07-03', 0, 18, 8, 5, NULL),
(720, '2023-06-20', '2023-06-27', 0, 35, 26, 5, NULL),
(721, '2023-06-22', '2023-06-29', 0, 58, 20, 5, NULL),
(722, '2023-06-25', '2023-07-02', 0, 61, 42, 5, NULL),
(723, '2023-06-22', '2023-06-29', 0, 98, 33, 5, NULL),
(724, '2023-06-27', '2023-07-04', 0, 80, 47, 5, NULL),
(725, '2023-06-21', '2023-06-28', 0, 44, 8, 5, NULL),
(726, '2023-06-27', '2023-07-04', 0, 44, 21, 5, NULL),
(727, '2023-06-21', '2023-06-28', 0, 25, 38, 5, NULL),
(728, '2023-06-20', '2023-06-27', 0, 16, 17, 5, NULL),
(729, '2023-06-20', '2023-06-27', 0, 62, 3, 5, NULL),
(730, '2023-06-25', '2023-07-02', 0, 7, 47, 5, NULL),
(731, '2023-06-24', '2023-07-01', 0, 30, 46, 5, NULL),
(732, '2023-06-25', '2023-07-02', 0, 90, 28, 5, NULL),
(733, '2023-06-26', '2023-07-03', 0, 90, 1, 5, NULL),
(734, '2023-06-27', '2023-07-04', 0, 17, 8, 5, NULL),
(735, '2023-06-27', '2023-07-04', 0, 16, 16, 5, NULL),
(736, '2023-06-25', '2023-07-02', 0, 31, 9, 5, NULL),
(737, '2023-06-20', '2023-06-27', 0, 16, 41, 5, NULL),
(738, '2023-06-25', '2023-07-02', 0, 100, 25, 5, NULL),
(739, '2023-06-22', '2023-06-29', 0, 19, 5, 5, NULL),
(740, '2023-06-27', '2023-07-04', 0, 64, 48, 5, NULL),
(741, '2023-06-25', '2023-07-02', 0, 58, 49, 5, NULL),
(742, '2023-06-22', '2023-06-29', 0, 45, 14, 5, NULL),
(743, '2023-06-20', '2023-06-27', 0, 63, 42, 5, NULL),
(744, '2023-06-24', '2023-07-01', 0, 38, 4, 5, NULL),
(745, '2023-06-25', '2023-07-02', 0, 4, 18, 5, NULL),
(746, '2023-06-25', '2023-07-02', 0, 43, 47, 5, NULL),
(747, '2023-06-27', '2023-07-04', 0, 96, 37, 5, NULL),
(748, '2023-06-25', '2023-07-02', 0, 66, 30, 5, NULL),
(749, '2023-06-27', '2023-07-04', 0, 82, 40, 5, NULL),
(750, '2023-06-23', '2023-06-30', 0, 90, 11, 5, NULL);

-- --------------------------------------------------------

--
-- Tabellenstruktur für Tabelle `fahrtenbuch`
--

CREATE TABLE `fahrtenbuch` (
  `FahrtenbuchID` int(11) NOT NULL,
  `Fahrtstart` timestamp NULL DEFAULT NULL,
  `Fahrtende` timestamp NULL DEFAULT NULL,
  `Fahrtdauer` time DEFAULT NULL,
  `FirmenwagenID` int(11) NOT NULL,
  `MitarbeiterID` int(11) NOT NULL,
  `RollerEingesamelt` int(11) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Daten für Tabelle `fahrtenbuch`
--

INSERT INTO `fahrtenbuch` (`FahrtenbuchID`, `Fahrtstart`, `Fahrtende`, `Fahrtdauer`, `FirmenwagenID`, `MitarbeiterID`, `RollerEingesamelt`) VALUES
(1, '2022-10-05 08:19:09', '2022-10-05 13:03:48', '05:44:39', 19, 25, 5),
(2, '2022-10-07 06:44:30', '2022-10-07 13:02:49', '07:18:19', 8, 16, 6),
(3, '2022-10-09 07:51:05', '2022-10-09 13:27:44', '06:36:39', 14, 23, 7),
(4, '2022-10-14 08:11:48', '2022-10-14 13:29:30', '06:17:42', 3, 12, 6),
(5, '2022-10-17 06:11:45', '2022-10-17 12:56:36', '07:44:51', 6, 13, 9),
(6, '2022-10-19 08:08:58', '2022-10-19 14:14:39', '07:05:41', 7, 16, 4),
(7, '2022-10-22 08:40:15', '2022-10-22 13:57:16', '06:17:01', 18, 43, 8),
(8, '2022-10-23 09:14:37', '2022-10-23 14:04:03', '05:49:26', 15, 22, 4),
(9, '2022-10-25 08:26:38', '2022-10-25 14:28:29', '07:01:51', 10, 20, 9),
(10, '2022-10-28 09:10:02', '2022-10-28 13:15:06', '05:05:04', 9, 19, 8),
(11, '2022-10-29 06:51:13', '2022-10-29 12:32:29', '06:41:16', 2, 9, 10),
(12, '2022-10-30 07:30:20', '2022-10-30 14:50:57', '08:20:37', 10, 18, 5),
(13, '2022-10-31 07:53:09', '2022-10-31 15:31:34', '08:38:25', 11, 17, 7),
(14, '2022-11-01 10:17:40', '2022-11-01 15:09:35', '05:51:55', 8, 13, 7),
(15, '2022-11-02 07:07:28', '2022-11-02 15:40:20', '09:32:52', 20, 25, 6),
(16, '2022-11-03 07:45:21', '2022-11-03 14:26:47', '07:41:26', 13, 24, 4),
(17, '2022-11-04 07:23:03', '2022-11-04 14:33:34', '08:10:31', 12, 20, 8),
(18, '2022-11-06 07:58:17', '2022-11-06 14:35:51', '07:37:34', 4, 11, 8),
(19, '2022-11-10 07:05:23', '2022-11-10 15:40:03', '09:34:40', 9, 18, 5),
(20, '2022-11-12 08:47:26', '2022-11-12 15:27:51', '07:40:25', 13, 21, 10),
(21, '2022-11-13 09:31:28', '2022-11-13 14:43:24', '06:11:56', 1, 10, 7),
(22, '2022-11-15 09:00:56', '2022-11-15 14:40:07', '06:39:11', 20, 25, 7),
(23, '2022-11-18 08:59:06', '2022-11-18 13:57:50', '05:58:44', 10, 20, 5),
(24, '2022-11-20 08:45:22', '2022-11-20 15:06:07', '07:20:45', 19, 45, 6),
(25, '2022-11-21 10:23:49', '2022-11-21 14:25:40', '05:01:51', 15, 21, 6),
(26, '2022-11-24 09:05:41', '2022-11-24 15:18:14', '07:12:33', 11, 19, 7),
(27, '2022-11-27 08:17:36', '2022-11-27 14:13:56', '06:56:20', 14, 21, 9),
(28, '2022-11-30 07:56:47', '2022-11-30 14:38:41', '07:41:54', 9, 17, 8),
(29, '2022-12-02 07:14:59', '2022-12-02 14:54:19', '08:39:20', 12, 20, 9),
(30, '2022-12-05 08:08:21', '2022-12-05 13:34:26', '06:26:05', 11, 18, 10),
(31, '2022-12-06 10:22:50', '2022-12-06 14:38:47', '05:15:57', 16, 24, 5),
(32, '2022-12-07 09:50:47', '2022-12-07 14:56:12', '06:05:25', 17, 25, 6),
(33, '2022-12-11 10:07:39', '2022-12-11 15:47:54', '06:40:15', 6, 14, 9),
(34, '2022-12-16 09:15:15', '2022-12-16 17:00:35', '08:45:20', 8, 15, 5),
(35, '2022-12-17 08:32:54', '2022-12-17 15:18:19', '07:45:25', 6, 16, 5),
(36, '2022-12-18 10:04:07', '2022-12-18 15:34:47', '06:30:40', 12, 19, 6),
(37, '2022-12-21 10:38:53', '2022-12-21 17:14:43', '07:35:50', 5, 13, 10),
(38, '2022-12-24 07:59:22', '2022-12-24 15:42:17', '08:42:55', 8, 15, 8),
(39, '2022-12-27 09:22:05', '2022-12-27 15:22:35', '07:00:30', 19, 45, 5),
(40, '2022-12-29 07:32:17', '2022-12-29 15:23:02', '08:50:45', 10, 17, 7),
(41, '2022-12-30 09:47:14', '2022-12-30 17:32:39', '08:45:25', 12, 20, 7),
(42, '2023-01-04 09:51:09', '2023-01-04 16:46:54', '07:55:45', 3, 12, 4),
(43, '2023-01-09 07:37:19', '2023-01-09 13:02:59', '06:25:40', 1, 11, 4),
(44, '2023-01-12 08:36:37', '2023-01-12 15:00:32', '07:23:55', 10, 17, 9),
(45, '2023-01-15 09:42:09', '2023-01-15 16:02:34', '07:20:25', 18, 25, 8),
(46, '2023-01-20 08:24:59', '2023-01-20 15:43:44', '08:18:45', 5, 13, 6),
(47, '2023-01-21 08:26:41', '2023-01-21 15:42:36', '08:15:55', 11, 20, 9),
(48, '2023-01-27 08:06:42', '2023-01-27 15:34:02', '08:27:20', 7, 15, 9),
(49, '2023-01-30 09:02:41', '2023-01-30 14:13:31', '06:10:50', 18, 43, 7),
(50, '2023-01-31 07:07:19', '2023-01-31 12:22:44', '06:15:25', 5, 14, 7),
(51, '2023-02-05 07:19:31', '2023-02-05 15:05:46', '08:46:15', 5, 13, 7),
(52, '2023-02-08 08:43:49', '2023-02-08 13:54:59', '06:11:10', 5, 15, 10),
(53, '2023-02-09 10:05:48', '2023-02-09 16:26:38', '07:20:50', 2, 10, 8),
(54, '2023-02-10 07:28:18', '2023-02-10 13:59:13', '07:30:55', 4, 12, 6),
(55, '2023-02-19 07:26:43', '2023-02-19 13:47:08', '07:20:25', 9, 17, 5),
(56, '2023-02-20 09:59:33', '2023-02-20 17:54:58', '08:55:25', 7, 13, 9),
(57, '2023-02-25 07:37:18', '2023-02-25 13:37:43', '07:00:25', 1, 9, 9),
(58, '2023-02-27 09:00:47', '2023-02-27 15:56:17', '07:55:30', 15, 24, 5),
(59, '2023-03-02 07:14:12', '2023-03-02 16:48:02', '10:33:50', 16, 22, 7),
(60, '2023-03-05 09:22:07', '2023-03-05 12:35:07', '04:13:00', 2, 12, 5),
(61, '2023-03-10 09:04:34', '2023-03-10 16:03:02', '07:58:28', 13, 21, 4),
(62, '2023-03-14 09:47:58', '2023-03-14 12:24:22', '03:36:24', 2, 11, 7),
(63, '2023-03-17 10:35:20', '2023-03-17 15:26:44', '05:51:24', 9, 20, 8),
(64, '2023-03-19 08:27:43', '2023-03-19 16:43:13', '09:15:30', 7, 16, 8),
(65, '2023-03-21 07:17:49', '2023-03-21 17:41:05', '11:23:16', 14, 21, 9),
(66, '2023-03-24 09:49:22', '2023-03-24 14:13:03', '05:23:41', 19, 44, 10),
(67, '2023-03-28 09:11:58', '2023-03-28 12:48:44', '04:36:46', 13, 22, 4),
(68, '2023-04-01 08:13:06', '2023-04-01 13:59:37', '06:46:31', 4, 9, 7),
(69, '2023-04-02 07:15:17', '2023-04-02 16:47:38', '10:32:21', 3, 10, 5),
(70, '2023-04-04 06:36:47', '2023-04-04 14:33:51', '08:57:04', 13, 23, 5),
(71, '2023-04-10 07:53:04', '2023-04-10 14:30:27', '07:37:23', 17, 44, 7),
(72, '2023-04-11 07:39:47', '2023-04-11 13:27:07', '06:47:20', 18, 45, 10),
(73, '2023-04-13 09:03:14', '2023-04-13 14:13:34', '06:10:20', 17, 42, 8),
(74, '2023-04-14 06:21:56', '2023-04-14 14:28:42', '09:06:46', 9, 19, 5),
(75, '2023-04-16 08:34:36', '2023-04-16 17:59:09', '10:24:33', 11, 17, 4),
(76, '2023-04-18 06:29:07', '2023-04-18 11:37:41', '06:08:34', 9, 18, 8),
(77, '2023-04-19 07:48:42', '2023-04-19 14:05:21', '07:16:39', 12, 20, 9),
(78, '2023-04-25 07:21:04', '2023-04-25 11:49:57', '05:28:53', 15, 22, 9),
(79, '2023-05-02 06:39:35', '2023-05-02 14:49:12', '09:09:37', 17, 45, 10),
(80, '2023-05-06 07:32:28', '2023-05-06 12:51:49', '06:19:21', 3, 9, 10),
(81, '2023-05-12 07:39:29', '2023-05-12 14:25:25', '07:45:56', 14, 22, 10),
(82, '2023-05-14 08:15:57', '2023-05-14 14:23:18', '07:07:21', 20, 44, 5),
(83, '2023-05-17 08:30:57', '2023-05-17 13:24:39', '05:53:42', 7, 13, 8),
(84, '2023-05-21 07:09:21', '2023-05-21 13:56:52', '07:47:31', 9, 19, 8),
(85, '2023-05-25 08:17:33', '2023-05-25 15:06:52', '07:49:19', 9, 20, 7),
(86, '2023-05-26 09:26:11', '2023-05-26 12:40:16', '04:14:05', 2, 11, 5),
(87, '2023-05-31 07:08:35', '2023-05-31 13:33:13', '07:24:38', 7, 14, 6),
(88, '2023-06-03 09:35:59', '2023-06-03 16:31:26', '07:55:27', 12, 17, 8),
(89, '2023-06-04 07:07:55', '2023-06-04 13:04:15', '06:56:20', 10, 20, 5),
(90, '2023-06-06 09:28:32', '2023-06-06 17:16:09', '08:47:37', 10, 19, 7),
(91, '2023-06-07 08:56:40', '2023-06-07 14:13:05', '06:16:25', 9, 19, 10),
(92, '2023-06-08 08:33:53', '2023-06-08 16:39:17', '09:05:24', 2, 10, 7),
(93, '2023-06-10 09:18:03', '2023-06-10 15:22:05', '07:04:02', 17, 25, 4),
(94, '2023-06-17 08:54:54', '2023-06-17 15:24:48', '07:29:54', 11, 17, 10),
(95, '2023-06-22 07:58:34', '2023-06-22 15:23:13', '08:24:39', 15, 23, 6),
(96, '2023-06-23 08:20:34', '2023-06-23 14:35:09', '07:14:35', 11, 18, 8),
(97, '2023-06-26 06:43:11', '2023-06-26 14:28:44', '08:45:33', 4, 12, 7),
(98, '2023-06-27 06:12:55', '2023-06-27 15:11:14', '09:58:19', 13, 21, 7),
(99, '2023-06-29 09:29:28', '2023-06-29 11:59:54', '03:30:26', 2, 9, 9),
(100, '2023-06-30 08:58:02', '2023-06-30 11:49:03', '03:51:01', 16, 24, 8);

-- --------------------------------------------------------

--
-- Tabellenstruktur für Tabelle `fuhrpark`
--

CREATE TABLE `fuhrpark` (
  `FirmenwagenID` int(11) NOT NULL,
  `AutoType` varchar(50) NOT NULL,
  `NaechsteWartung` date NOT NULL,
  `LagerID` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Daten für Tabelle `fuhrpark`
--

INSERT INTO `fuhrpark` (`FirmenwagenID`, `AutoType`, `NaechsteWartung`, `LagerID`) VALUES
(1, 'VW Crafter', '2023-11-14', 1),
(2, 'VW Crafter', '2024-02-22', 1),
(3, 'VW Crafter', '2023-10-01', 1),
(4, 'VW Crafter', '2023-11-05', 1),
(5, 'VW Crafter', '2024-02-18', 2),
(6, 'VW Crafter', '2023-07-30', 2),
(7, 'VW Crafter', '2023-10-19', 2),
(8, 'VW Crafter', '2024-05-12', 2),
(9, 'VW Crafter', '2024-01-25', 3),
(10, 'VW Crafter', '2023-08-09', 3),
(11, 'VW Crafter', '2023-08-03', 3),
(12, 'VW Crafter', '2024-09-22', 3),
(13, 'VW Crafter', '2023-11-07', 4),
(14, 'VW Crafter', '2024-08-27', 4),
(15, 'VW Crafter', '2023-10-15', 4),
(16, 'VW Crafter', '2023-02-11', 4),
(17, 'VW Crafter', '2024-09-14', 5),
(18, 'VW Crafter', '2023-12-23', 5),
(19, 'VW Crafter', '2023-09-04', 5),
(20, 'VW Crafter', '2023-12-02', 5);

-- --------------------------------------------------------

--
-- Tabellenstruktur für Tabelle `haltepunkt`
--

CREATE TABLE `haltepunkt` (
  `HaltepunktID` int(11) NOT NULL,
  `Zeitpunkt` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  `FahrtenbuchID` int(11) NOT NULL,
  `StandortID` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Daten für Tabelle `haltepunkt`
--

INSERT INTO `haltepunkt` (`HaltepunktID`, `Zeitpunkt`, `FahrtenbuchID`, `StandortID`) VALUES
(1, '2022-10-05 09:23:09', 1, 233),
(2, '2022-10-05 10:23:38', 1, 255),
(3, '2022-10-05 12:53:21', 1, 432),
(4, '2022-10-07 07:47:33', 2, 99),
(5, '2022-10-07 08:50:36', 2, 88),
(6, '2022-10-07 09:53:39', 2, 77),
(7, '2022-10-07 10:56:42', 2, 66),
(8, '2022-10-07 11:59:45', 2, 55),
(9, '2022-10-09 09:43:18', 3, 1200),
(10, '2022-10-09 11:35:31', 3, 222),
(11, '2022-10-14 09:57:42', 4, 666),
(12, '2022-10-14 11:43:36', 4, 845),
(13, '2022-10-17 07:52:57', 5, 452),
(14, '2022-10-17 09:34:10', 5, 59),
(15, '2022-10-17 11:15:23', 5, 600),
(16, '2022-10-19 09:40:23', 6, 500),
(17, '2022-10-19 11:11:48', 6, 52),
(18, '2022-10-19 12:43:13', 6, 87),
(19, '2022-10-22 10:25:55', 7, 35),
(20, '2022-10-22 12:11:35', 7, 354),
(21, '2022-10-23 10:12:30', 8, 236),
(22, '2022-10-23 11:10:23', 8, 203),
(23, '2022-10-23 12:08:16', 8, 1111),
(24, '2022-10-23 13:06:09', 8, 1089),
(25, '2022-10-25 09:57:05', 9, 169),
(26, '2022-10-25 11:27:33', 9, 199),
(27, '2022-10-25 12:58:01', 9, 868),
(28, '2022-10-28 09:59:02', 10, 869),
(29, '2022-10-28 10:48:03', 10, 996),
(30, '2022-10-28 11:37:04', 10, 168),
(31, '2022-10-28 12:26:05', 10, 189),
(32, '2022-10-29 08:16:32', 11, 133),
(33, '2022-10-29 09:41:51', 11, 833),
(34, '2022-10-29 11:07:10', 11, 799),
(35, '2022-10-30 08:43:46', 12, 168),
(36, '2022-10-30 09:57:12', 12, 773),
(37, '2022-10-30 11:10:38', 12, 700),
(38, '2022-10-30 12:24:04', 12, 833),
(39, '2022-10-30 13:37:30', 12, 152),
(40, '2022-10-31 09:09:33', 13, 179),
(41, '2022-10-31 10:25:57', 13, 909),
(42, '2022-10-31 11:42:21', 13, 1003),
(43, '2022-10-31 12:58:45', 13, 1030),
(44, '2022-10-31 14:15:09', 13, 900),
(45, '2022-11-01 11:54:58', 14, 76),
(46, '2022-11-01 13:32:16', 14, 580),
(47, '2022-11-02 08:32:56', 15, 400),
(48, '2022-11-02 09:58:25', 15, 399),
(49, '2022-11-02 11:23:54', 15, 33),
(50, '2022-11-02 12:49:22', 15, 45),
(51, '2022-11-02 14:14:51', 15, 267),
(52, '2022-11-03 09:25:42', 16, 245),
(53, '2022-11-03 11:06:04', 16, 235),
(54, '2022-11-03 12:46:25', 16, 244),
(55, '2022-11-04 08:49:09', 17, 163),
(56, '2022-11-04 10:15:15', 17, 852),
(57, '2022-11-04 11:41:21', 17, 894),
(58, '2022-11-04 13:07:27', 17, 1049),
(59, '2022-11-06 08:55:04', 18, 102),
(60, '2022-11-06 09:51:52', 18, 103),
(61, '2022-11-06 10:48:40', 18, 104),
(62, '2022-11-06 11:45:27', 18, 105),
(63, '2022-11-06 12:42:15', 18, 107),
(64, '2022-11-06 13:39:03', 18, 108),
(65, '2022-11-10 08:48:19', 19, 190),
(66, '2022-11-10 10:31:15', 19, 159),
(67, '2022-11-10 12:14:11', 19, 161),
(68, '2022-11-10 13:57:07', 19, 1040),
(69, '2022-11-12 10:27:32', 20, 230),
(70, '2022-11-12 12:07:38', 20, 220),
(71, '2022-11-12 13:47:44', 20, 1090),
(72, '2022-11-13 10:23:27', 21, 666),
(73, '2022-11-13 11:15:26', 21, 690),
(74, '2022-11-13 12:07:25', 21, 800),
(75, '2022-11-13 12:59:25', 21, 102),
(76, '2022-11-13 13:51:24', 21, 129),
(77, '2022-11-15 10:25:43', 22, 33),
(78, '2022-11-15 11:50:31', 22, 20),
(79, '2022-11-15 13:15:19', 22, 29),
(80, '2022-11-18 09:41:46', 23, 1000),
(81, '2022-11-18 10:24:27', 23, 999),
(82, '2022-11-18 11:07:07', 23, 888),
(83, '2022-11-18 11:49:48', 23, 169),
(84, '2022-11-18 12:32:28', 23, 168),
(85, '2022-11-18 13:15:09', 23, 153),
(86, '2022-11-20 09:48:49', 24, 2),
(87, '2022-11-20 10:52:17', 24, 3),
(88, '2022-11-20 11:55:44', 24, 4),
(89, '2022-11-20 12:59:12', 24, 5),
(90, '2022-11-20 14:02:39', 24, 6),
(91, '2022-11-21 11:12:11', 25, 202),
(92, '2022-11-21 12:00:33', 25, 1052),
(93, '2022-11-21 12:48:55', 25, 1060),
(94, '2022-11-21 13:37:17', 25, 1111),
(95, '2022-11-24 10:20:11', 26, 899),
(96, '2022-11-24 11:34:42', 26, 900),
(97, '2022-11-24 12:49:12', 26, 969),
(98, '2022-11-24 14:03:43', 26, 967),
(99, '2022-11-27 09:16:59', 27, 209),
(100, '2022-11-27 10:16:22', 27, 249),
(101, '2022-11-27 11:15:45', 27, 1200),
(102, '2022-11-27 12:15:09', 27, 1100),
(103, '2022-11-27 13:14:32', 27, 1059),
(104, '2022-11-30 10:10:45', 28, 859),
(105, '2022-11-30 12:24:43', 28, 879),
(106, '2022-12-02 08:31:32', 29, 987),
(107, '2022-12-02 09:48:05', 29, 164),
(108, '2022-12-02 11:04:38', 29, 990),
(109, '2022-12-02 12:21:12', 29, 980),
(110, '2022-12-02 13:37:45', 29, 1018),
(111, '2022-12-05 09:57:02', 30, 1042),
(112, '2022-12-05 11:45:44', 30, 870),
(113, '2022-12-06 11:26:49', 31, 222),
(114, '2022-12-06 12:30:48', 31, 231),
(115, '2022-12-06 13:34:47', 31, 1200),
(116, '2022-12-07 10:34:24', 32, 2),
(117, '2022-12-07 11:18:02', 32, 15),
(118, '2022-12-07 12:01:40', 32, 400),
(119, '2022-12-07 12:45:18', 32, 401),
(120, '2022-12-07 13:28:56', 32, 46),
(121, '2022-12-07 14:12:34', 32, 23),
(122, '2022-12-11 12:01:04', 33, 54),
(123, '2022-12-11 13:54:29', 33, 86),
(124, '2022-12-16 10:32:48', 34, 78),
(125, '2022-12-16 11:50:21', 34, 98),
(126, '2022-12-16 13:07:54', 34, 65),
(127, '2022-12-16 14:25:28', 34, 75),
(128, '2022-12-16 15:43:01', 34, 97),
(129, '2022-12-17 09:53:59', 35, 84),
(130, '2022-12-17 11:15:04', 35, 80),
(131, '2022-12-17 12:36:09', 35, 66),
(132, '2022-12-17 13:57:14', 35, 69),
(133, '2022-12-18 11:26:47', 36, 909),
(134, '2022-12-18 12:49:27', 36, 885),
(135, '2022-12-18 14:12:07', 36, 954),
(136, '2022-12-21 11:44:51', 37, 78),
(137, '2022-12-21 12:50:49', 37, 600),
(138, '2022-12-21 13:56:47', 37, 589),
(139, '2022-12-21 15:02:46', 37, 559),
(140, '2022-12-21 16:08:44', 37, 640),
(141, '2022-12-24 09:16:31', 38, 99),
(142, '2022-12-24 10:33:40', 38, 90),
(143, '2022-12-24 11:50:49', 38, 500),
(144, '2022-12-24 13:07:58', 38, 555),
(145, '2022-12-24 14:25:07', 38, 633),
(146, '2022-12-27 11:22:15', 39, 266),
(147, '2022-12-27 13:22:25', 39, 278),
(148, '2022-12-29 08:50:44', 40, 1033),
(149, '2022-12-29 10:09:12', 40, 1044),
(150, '2022-12-29 11:27:39', 40, 1003),
(151, '2022-12-29 12:46:07', 40, 886),
(152, '2022-12-29 14:04:34', 40, 881),
(153, '2022-12-30 10:53:43', 41, 161),
(154, '2022-12-30 12:00:12', 41, 171),
(155, '2022-12-30 13:06:41', 41, 181),
(156, '2022-12-30 14:13:11', 41, 191),
(157, '2022-12-30 15:19:40', 41, 871),
(158, '2022-12-30 16:26:09', 41, 1041),
(159, '2023-01-04 11:35:05', 42, 111),
(160, '2023-01-04 13:19:01', 42, 121),
(161, '2023-01-04 15:02:57', 42, 131),
(162, '2023-01-09 08:23:50', 43, 141),
(163, '2023-01-09 09:10:21', 43, 771),
(164, '2023-01-09 09:56:53', 43, 781),
(165, '2023-01-09 10:43:24', 43, 791),
(166, '2023-01-09 11:29:56', 43, 801),
(167, '2023-01-09 12:16:27', 43, 811),
(168, '2023-01-12 09:31:27', 44, 191),
(169, '2023-01-12 10:26:18', 44, 192),
(170, '2023-01-12 11:21:09', 44, 909),
(171, '2023-01-12 12:15:59', 44, 951),
(172, '2023-01-12 13:10:50', 44, 971),
(173, '2023-01-12 14:05:41', 44, 1044),
(174, '2023-01-15 11:17:15', 45, 7),
(175, '2023-01-15 12:52:21', 45, 6),
(176, '2023-01-15 14:27:27', 45, 5),
(177, '2023-01-20 10:14:40', 46, 97),
(178, '2023-01-20 12:04:21', 46, 488),
(179, '2023-01-20 13:54:02', 46, 633),
(180, '2023-01-21 09:28:57', 47, 175),
(181, '2023-01-21 10:31:13', 47, 183),
(182, '2023-01-21 11:33:30', 47, 198),
(183, '2023-01-21 12:35:46', 47, 885),
(184, '2023-01-21 13:38:03', 47, 960),
(185, '2023-01-21 14:40:19', 47, 974),
(186, '2023-01-27 10:35:48', 48, 70),
(187, '2023-01-27 13:04:55', 48, 80),
(188, '2023-01-30 10:04:51', 49, 633),
(189, '2023-01-30 11:07:01', 49, 609),
(190, '2023-01-30 12:09:11', 49, 559),
(191, '2023-01-30 13:11:21', 49, 581),
(192, '2023-01-31 07:52:22', 50, 63),
(193, '2023-01-31 08:37:26', 50, 563),
(194, '2023-01-31 09:22:29', 50, 593),
(195, '2023-01-31 10:07:33', 50, 539),
(196, '2023-01-31 10:52:36', 50, 536),
(197, '2023-01-31 11:37:40', 50, 635),
(198, '2023-02-05 09:54:56', 51, 99),
(199, '2023-02-05 12:30:21', 51, 89),
(200, '2023-02-08 10:27:32', 52, 500),
(201, '2023-02-08 12:11:15', 52, 532),
(202, '2023-02-09 11:09:16', 53, 122),
(203, '2023-02-09 12:12:44', 53, 139),
(204, '2023-02-09 13:16:12', 53, 666),
(205, '2023-02-09 14:19:41', 53, 823),
(206, '2023-02-09 15:23:09', 53, 767),
(207, '2023-02-10 08:46:29', 54, 700),
(208, '2023-02-10 10:04:40', 54, 707),
(209, '2023-02-10 11:22:51', 54, 112),
(210, '2023-02-10 12:41:02', 54, 131),
(211, '2023-02-19 08:30:07', 55, 161),
(212, '2023-02-19 09:33:31', 55, 909),
(213, '2023-02-19 10:36:55', 55, 967),
(214, '2023-02-19 11:40:19', 55, 939),
(215, '2023-02-19 12:43:43', 55, 1032),
(216, '2023-02-20 12:38:01', 56, 66),
(217, '2023-02-20 15:16:29', 56, 69),
(218, '2023-02-25 09:07:24', 57, 102),
(219, '2023-02-25 10:37:30', 57, 129),
(220, '2023-02-25 12:07:36', 57, 666),
(221, '2023-02-27 10:10:02', 58, 222),
(222, '2023-02-27 11:19:17', 58, 223),
(223, '2023-02-27 12:28:32', 58, 273),
(224, '2023-02-27 13:37:47', 58, 1120),
(225, '2023-02-27 14:47:02', 58, 1222),
(226, '2023-03-02 08:49:50', 59, 1088),
(227, '2023-03-02 10:25:28', 59, 1069),
(228, '2023-03-02 12:01:06', 59, 1070),
(229, '2023-03-02 13:36:45', 59, 1071),
(230, '2023-03-02 15:12:23', 59, 1232),
(231, '2023-03-05 09:49:41', 60, 109),
(232, '2023-03-05 10:17:15', 60, 143),
(233, '2023-03-05 10:44:49', 60, 172),
(234, '2023-03-05 11:12:24', 60, 750),
(235, '2023-03-05 11:39:58', 60, 754),
(236, '2023-03-05 12:07:32', 60, 781),
(237, '2023-03-10 11:24:03', 61, 222),
(238, '2023-03-10 13:43:32', 61, 1111),
(239, '2023-03-14 10:19:14', 62, 699),
(240, '2023-03-14 10:50:31', 62, 702),
(241, '2023-03-14 11:21:48', 62, 809),
(242, '2023-03-14 11:53:05', 62, 832),
(243, '2023-03-17 12:12:28', 63, 887),
(244, '2023-03-17 13:49:36', 63, 175),
(245, '2023-03-19 09:50:18', 64, 89),
(246, '2023-03-19 11:12:53', 64, 79),
(247, '2023-03-19 12:35:28', 64, 92),
(248, '2023-03-19 13:58:03', 64, 469),
(249, '2023-03-19 15:20:38', 64, 489),
(250, '2023-03-21 09:01:41', 65, 1123),
(251, '2023-03-21 10:45:34', 65, 1140),
(252, '2023-03-21 12:29:27', 65, 227),
(253, '2023-03-21 14:13:19', 65, 1078),
(254, '2023-03-21 15:57:12', 65, 1129),
(255, '2023-03-24 10:55:17', 66, 40),
(256, '2023-03-24 12:01:12', 66, 404),
(257, '2023-03-24 13:07:07', 66, 4),
(258, '2023-03-28 10:24:13', 67, 1230),
(259, '2023-03-28 11:36:28', 67, 1090),
(260, '2023-04-01 09:10:51', 68, 122),
(261, '2023-04-01 10:08:36', 68, 137),
(262, '2023-04-01 11:06:21', 68, 683),
(263, '2023-04-01 12:04:06', 68, 787),
(264, '2023-04-01 13:01:51', 68, 753),
(265, '2023-04-02 09:09:45', 69, 767),
(266, '2023-04-02 11:04:13', 69, 127),
(267, '2023-04-02 12:58:41', 69, 847),
(268, '2023-04-02 14:53:09', 69, 800),
(269, '2023-04-04 08:12:11', 70, 222),
(270, '2023-04-04 09:47:36', 70, 287),
(271, '2023-04-04 11:23:01', 70, 265),
(272, '2023-04-04 12:58:26', 70, 1055),
(273, '2023-04-10 09:12:32', 71, 404),
(274, '2023-04-10 10:32:01', 71, 44),
(275, '2023-04-10 11:51:29', 71, 4),
(276, '2023-04-10 13:10:58', 71, 333),
(277, '2023-04-11 08:49:15', 72, 444),
(278, '2023-04-11 09:58:43', 72, 43),
(279, '2023-04-11 11:08:11', 72, 34),
(280, '2023-04-11 12:17:39', 72, 3),
(281, '2023-04-13 09:47:34', 73, 4),
(282, '2023-04-13 10:31:54', 73, 434),
(283, '2023-04-13 11:16:14', 73, 343),
(284, '2023-04-13 12:00:34', 73, 344),
(285, '2023-04-13 12:44:54', 73, 433),
(286, '2023-04-13 13:29:14', 73, 443),
(287, '2023-04-14 09:04:11', 74, 171),
(288, '2023-04-14 11:46:26', 74, 161),
(289, '2023-04-16 10:08:41', 75, 1017),
(290, '2023-04-16 11:42:47', 75, 917),
(291, '2023-04-16 13:16:52', 75, 979),
(292, '2023-04-16 14:50:58', 75, 853),
(293, '2023-04-16 16:25:03', 75, 153),
(294, '2023-04-18 07:13:11', 76, 1011),
(295, '2023-04-18 07:57:16', 76, 1032),
(296, '2023-04-18 08:41:21', 76, 957),
(297, '2023-04-18 09:25:26', 76, 975),
(298, '2023-04-18 10:09:31', 76, 995),
(299, '2023-04-18 10:53:36', 76, 997),
(300, '2023-04-19 09:54:15', 77, 172),
(301, '2023-04-19 11:59:48', 77, 173),
(302, '2023-04-25 08:14:50', 78, 238),
(303, '2023-04-25 09:08:37', 78, 888),
(304, '2023-04-25 10:02:23', 78, 878),
(305, '2023-04-25 10:56:10', 78, 837),
(306, '2023-05-02 07:49:31', 79, 404),
(307, '2023-05-02 08:59:28', 79, 303),
(308, '2023-05-02 10:09:25', 79, 278),
(309, '2023-05-02 11:19:21', 79, 298),
(310, '2023-05-02 12:29:18', 79, 36),
(311, '2023-05-02 13:39:15', 79, 29),
(312, '2023-05-06 08:25:41', 80, 123),
(313, '2023-05-06 09:18:55', 80, 132),
(314, '2023-05-06 10:12:08', 80, 133),
(315, '2023-05-06 11:05:22', 80, 122),
(316, '2023-05-06 11:58:35', 80, 131),
(317, '2023-05-12 09:54:47', 81, 232),
(318, '2023-05-12 12:10:06', 81, 1066),
(319, '2023-05-14 09:29:25', 82, 375),
(320, '2023-05-14 10:42:53', 82, 373),
(321, '2023-05-14 11:56:21', 82, 298),
(322, '2023-05-14 13:09:49', 82, 404),
(323, '2023-05-17 09:19:54', 83, 99),
(324, '2023-05-17 10:08:51', 83, 79),
(325, '2023-05-17 10:57:48', 83, 69),
(326, '2023-05-17 11:46:45', 83, 454),
(327, '2023-05-17 12:35:42', 83, 578),
(328, '2023-05-21 08:17:16', 84, 159),
(329, '2023-05-21 09:25:11', 84, 177),
(330, '2023-05-21 10:33:06', 84, 176),
(331, '2023-05-21 11:41:01', 84, 175),
(332, '2023-05-21 12:48:56', 84, 198),
(333, '2023-05-25 09:39:24', 85, 163),
(334, '2023-05-25 11:01:16', 85, 883),
(335, '2023-05-25 12:23:08', 85, 987),
(336, '2023-05-25 13:45:00', 85, 952),
(337, '2023-05-26 10:30:52', 86, 143),
(338, '2023-05-26 11:35:34', 86, 743),
(339, '2023-05-31 08:44:44', 87, 95),
(340, '2023-05-31 10:20:54', 87, 579),
(341, '2023-05-31 11:57:03', 87, 597),
(342, '2023-06-03 11:19:50', 88, 153),
(343, '2023-06-03 13:03:42', 88, 179),
(344, '2023-06-03 14:47:34', 88, 196),
(345, '2023-06-04 07:58:49', 89, 975),
(346, '2023-06-04 08:49:43', 89, 937),
(347, '2023-06-04 09:40:37', 89, 965),
(348, '2023-06-04 10:31:32', 89, 1003),
(349, '2023-06-04 11:22:26', 89, 179),
(350, '2023-06-04 12:13:20', 89, 1032),
(351, '2023-06-06 11:02:03', 90, 922),
(352, '2023-06-06 12:35:34', 90, 933),
(353, '2023-06-06 14:09:06', 90, 955),
(354, '2023-06-06 15:42:37', 90, 944),
(355, '2023-06-07 09:41:52', 91, 1023),
(356, '2023-06-07 10:27:04', 91, 167),
(357, '2023-06-07 11:12:16', 91, 159),
(358, '2023-06-07 11:57:28', 91, 864),
(359, '2023-06-07 12:42:40', 91, 895),
(360, '2023-06-07 13:27:52', 91, 954),
(361, '2023-06-08 10:35:14', 92, 111),
(362, '2023-06-08 12:36:35', 92, 117),
(363, '2023-06-08 14:37:56', 92, 113),
(364, '2023-06-10 10:49:03', 93, 404),
(365, '2023-06-10 12:20:04', 93, 323),
(366, '2023-06-10 13:51:04', 93, 303),
(367, '2023-06-17 10:12:52', 94, 178),
(368, '2023-06-17 11:30:51', 94, 198),
(369, '2023-06-17 12:48:50', 94, 855),
(370, '2023-06-17 14:06:49', 94, 896),
(371, '2023-06-22 09:27:29', 95, 222),
(372, '2023-06-22 10:56:25', 95, 1222),
(373, '2023-06-22 12:25:21', 95, 1234),
(374, '2023-06-22 13:54:17', 95, 1232),
(375, '2023-06-23 09:54:12', 96, 169),
(376, '2023-06-23 11:27:51', 96, 198),
(377, '2023-06-23 13:01:30', 96, 900),
(378, '2023-06-26 08:00:46', 97, 700),
(379, '2023-06-26 09:18:22', 97, 735),
(380, '2023-06-26 10:35:57', 97, 795),
(381, '2023-06-26 11:53:33', 97, 736),
(382, '2023-06-26 13:11:08', 97, 933),
(383, '2023-06-27 07:42:38', 98, 243),
(384, '2023-06-27 09:12:21', 98, 1070),
(385, '2023-06-27 10:42:04', 98, 1067),
(386, '2023-06-27 12:11:47', 98, 1233),
(387, '2023-06-27 13:41:30', 98, 1200),
(388, '2023-06-29 09:50:57', 99, 137),
(389, '2023-06-29 10:12:26', 99, 139),
(390, '2023-06-29 10:33:56', 99, 700),
(391, '2023-06-29 10:55:25', 99, 707),
(392, '2023-06-29 11:16:55', 99, 709),
(393, '2023-06-29 11:38:24', 99, 797),
(394, '2023-06-30 09:40:47', 100, 243),
(395, '2023-06-30 10:23:32', 100, 1077),
(396, '2023-06-30 11:06:17', 100, 1111);

-- --------------------------------------------------------

--
-- Tabellenstruktur für Tabelle `kunde`
--

CREATE TABLE `kunde` (
  `KundeID` int(11) NOT NULL,
  `Nachname` varchar(30) NOT NULL,
  `Vorname` varchar(30) NOT NULL,
  `EmailAdress` varchar(100) NOT NULL,
  `Mobilnummer` varchar(30) NOT NULL,
  `Geschlecht` enum('M','W','D') DEFAULT NULL,
  `LetzteNutzung` date NOT NULL,
  `Inaktiv` tinyint(1) NOT NULL,
  `KKontoID` int(11) NOT NULL,
  `WohnortID` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Daten für Tabelle `kunde`
--

INSERT INTO `kunde` (`KundeID`, `Nachname`, `Vorname`, `EmailAdress`, `Mobilnummer`, `Geschlecht`, `LetzteNutzung`, `Inaktiv`, `KKontoID`, `WohnortID`) VALUES
(1, 'Patterson', 'Eric', 'eric.patterson@gmail.com', '0123456789580', 'M', '2022-07-07', 0, 1, 237),
(2, 'Clayton', 'Jeremy', 'jeremy.clayton@gmail.com', '0123456789861', 'M', '2020-07-22', 0, 2, 605),
(3, 'Perkins', 'Christina', 'christina.perkins@gmail.com', '0123456789320', 'W', '2018-03-31', 1, 3, 774),
(4, 'Benton', 'Sharon', 'sharon.benton@gmail.com', '0123456789317', 'W', '2023-06-10', 0, 4, 744),
(5, 'Steele', 'Crystal', 'crystal.steele@gmail.com', '0123456789659', 'W', '2022-12-31', 0, 5, 200),
(6, 'Smith', 'Tina', 'tina.smith@gmail.com', '0123456789681', 'W', '2022-07-31', 0, 6, 237),
(7, 'Richard', 'Harold', 'harold.richard@gmail.com', '0123456789298', 'M', '2022-11-22', 0, 7, 866),
(8, 'Reyes', 'Nicholas', 'nicholas.reyes@gmail.com', '0123456789875', 'M', '2021-07-09', 0, 8, 1043),
(9, 'Young', 'Nicole', 'nicole.young@gmail.com', '0123456789551', 'W', '2023-03-22', 0, 9, 494),
(10, 'Ward', 'Dylan', 'dylan.ward@gmail.com', '0123456789831', 'M', '2019-07-08', 1, 10, 642),
(11, 'Hunt', 'Christina', 'christina.hunt@gmail.com', '0123456789418', 'W', '2022-06-29', 0, 11, 368),
(12, 'Dean', 'Joshua', 'joshua.dean@gmail.com', '0123456789257', 'M', '2021-10-24', 0, 12, 592),
(13, 'Sherman', 'Eric', 'eric.sherman@gmail.com', '0123456789114', 'M', '2020-10-28', 0, 13, 322),
(14, 'Diaz', 'Cory', 'cory.diaz@gmail.com', '0123456789236', 'M', '2020-02-28', 1, 14, 645),
(15, 'Davis', 'Douglas', 'douglas.davis@gmail.com', '0123456789250', 'M', '2023-01-26', 0, 15, 1070),
(16, 'Bell', 'April', 'april.bell@gmail.com', '0123456789530', 'W', '2019-09-15', 1, 16, 1008),
(17, 'Schmidt', 'Jason', 'jason.schmidt@gmail.com', '0123456789910', 'M', '2023-05-26', 0, 17, 149),
(18, 'Cox', 'Corey', 'corey.cox@gmail.com', '0123456789680', 'M', '2019-03-22', 1, 18, 760),
(19, 'Nicholson', 'Christopher', 'christopher.nicholson@gmail.com', '0123456789552', 'M', '2021-03-22', 0, 19, 373),
(20, 'Jordan', 'Javier', 'javier.jordan@gmail.com', '0123456789884', 'M', '2019-11-01', 1, 20, 1000),
(21, 'Williams', 'Stacey', 'stacey.williams@gmail.com', '0123456789379', 'W', '2023-05-01', 0, 21, 556),
(22, 'Mosley', 'Mary', 'mary.mosley@gmail.com', '0123456789485', 'W', '2021-04-13', 0, 22, 817),
(23, 'Bennett', 'James', 'james.bennett@gmail.com', '0123456789448', 'M', '2018-01-28', 1, 23, 620),
(24, 'Dickson', 'Robert', 'robert.dickson@gmail.com', '0123456789883', 'M', '2021-11-20', 0, 24, 486),
(25, 'Lindsey', 'Morgan', 'morgan.lindsey@gmail.com', '0123456789291', 'W', '2022-01-27', 0, 25, 772),
(26, 'Sullivan', 'Jeffrey', 'jeffrey.sullivan@gmail.com', '0123456789712', 'M', '2021-02-07', 0, 26, 669),
(27, 'Stephens', 'Kimberly', 'kimberly.stephens@gmail.com', '0123456789818', 'W', '2023-01-03', 0, 27, 732),
(28, 'Brown', 'Amy', 'amy.brown@gmail.com', '0123456789431', 'W', '2019-05-10', 1, 28, 907),
(29, 'Sanders', 'Jeffrey', 'jeffrey.sanders@gmail.com', '0123456789405', 'M', '2019-11-30', 1, 29, 1189),
(30, 'Johnston', 'Michael', 'michael.johnston@gmail.com', '0123456789728', 'M', '2020-07-31', 0, 30, 1155),
(31, 'Freeman', 'Jessica', 'jessica.freeman@gmail.com', '0123456789984', 'W', '2020-07-05', 0, 31, 810),
(32, 'Perez', 'Christine', 'christine.perez@gmail.com', '0123456789158', 'W', '2019-04-17', 1, 32, 1139),
(33, 'Little', 'Amber', 'amber.little@gmail.com', '0123456789227', 'W', '2018-04-15', 1, 33, 1152),
(34, 'Hamilton', 'Brittany', 'brittany.hamilton@gmail.com', '0123456789882', 'W', '2019-03-24', 1, 34, 198),
(35, 'Evans', 'Mark', 'mark.evans@gmail.com', '0123456789390', 'M', '2018-06-13', 1, 35, 717),
(36, 'Davis', 'Kathleen', 'kathleen.davis@gmail.com', '0123456789629', 'W', '2021-02-25', 0, 36, 222),
(37, 'Harper', 'Shawn', 'shawn.harper@gmail.com', '0123456789603', 'M', '2020-01-25', 1, 37, 306),
(38, 'Walker', 'Kimberly', 'kimberly.walker@gmail.com', '0123456789259', 'W', '2023-06-26', 0, 38, 236),
(39, 'Todd', 'Janet', 'janet.todd@gmail.com', '0123456789955', 'W', '2020-12-30', 0, 39, 1095),
(40, 'Hicks', 'Michael', 'michael.hicks@gmail.com', '0123456789958', 'M', '2018-07-22', 1, 40, 706),
(41, 'Blanchard', 'Kyle', 'kyle.blanchard@gmail.com', '0123456789289', 'M', '2020-04-01', 1, 41, 745),
(42, 'Jackson', 'Edwin', 'edwin.jackson@gmail.com', '0123456789344', 'M', '2020-07-24', 0, 42, 517),
(43, 'Ward', 'Jose', 'jose.ward@gmail.com', '0123456789396', 'M', '2019-11-27', 1, 43, 679),
(44, 'Gonzalez', 'Suzanne', 'suzanne.gonzalez@gmail.com', '0123456789531', 'W', '2022-01-23', 0, 44, 21),
(45, 'Wilson', 'Kristen', 'kristen.wilson@gmail.com', '0123456789612', 'W', '2019-05-30', 1, 45, 800),
(46, 'Miranda', 'Susan', 'susan.miranda@gmail.com', '0123456789352', 'W', '2019-08-01', 1, 46, 868),
(47, 'Kidd', 'Matthew', 'matthew.kidd@gmail.com', '0123456789385', 'M', '2021-02-16', 0, 47, 343),
(48, 'Hamilton', 'Melissa', 'melissa.hamilton@gmail.com', '0123456789615', 'W', '2021-05-25', 0, 48, 931),
(49, 'Gibson', 'Jerry', 'jerry.gibson@gmail.com', '0123456789184', 'M', '2019-04-14', 1, 49, 889),
(50, 'Graham', 'Betty', 'betty.graham@gmail.com', '0123456789717', 'W', '2018-03-30', 1, 50, 682),
(51, 'Jones', 'Audrey', 'audrey.jones@gmail.com', '0123456789138', 'W', '2018-09-21', 1, 51, 756),
(52, 'Garza', 'Michael', 'michael.garza@gmail.com', '0123456789568', 'M', '2022-04-08', 0, 52, 903),
(53, 'Butler', 'Jeremy', 'jeremy.butler@gmail.com', '0123456789205', 'M', '2018-01-27', 1, 53, 140),
(54, 'Reyes', 'John', 'john.reyes@gmail.com', '0123456789338', 'M', '2019-01-13', 1, 54, 222),
(55, 'Warren', 'Jeffery', 'jeffery.warren@gmail.com', '0123456789929', 'M', '2018-05-14', 1, 55, 583),
(56, 'Whitney', 'Bradley', 'bradley.whitney@gmail.com', '0123456789102', 'M', '2018-01-21', 1, 56, 606),
(57, 'Simmons', 'Paul', 'paul.simmons@gmail.com', '0123456789149', 'M', '2021-11-13', 0, 57, 852),
(58, 'Gates', 'Stephanie', 'stephanie.gates@gmail.com', '0123456789692', 'W', '2020-11-27', 0, 58, 563),
(59, 'Hahn', 'Anna', 'anna.hahn@gmail.com', '0123456789733', 'W', '2022-03-31', 0, 59, 898),
(60, 'Hill', 'Margaret', 'margaret.hill@gmail.com', '0123456789979', 'W', '2018-06-22', 1, 60, 550),
(61, 'Marshall', 'Lisa', 'lisa.marshall@gmail.com', '0123456789466', 'W', '2022-02-21', 0, 61, 904),
(62, 'Gonzales', 'Brandon', 'brandon.gonzales@gmail.com', '0123456789275', 'M', '2019-04-18', 1, 62, 301),
(63, 'Brown', 'Richard', 'richard.brown@gmail.com', '0123456789528', 'M', '2020-03-06', 1, 63, 713),
(64, 'Parker', 'Robert', 'robert.parker@gmail.com', '0123456789545', 'M', '2020-11-13', 0, 64, 984),
(65, 'Wall', 'Daniel', 'daniel.wall@gmail.com', '0123456789869', 'M', '2019-06-12', 1, 65, 484),
(66, 'Velez', 'Jacob', 'jacob.velez@gmail.com', '0123456789626', 'M', '2019-07-07', 1, 66, 849),
(67, 'Parker', 'Christopher', 'christopher.parker@gmail.com', '0123456789315', 'M', '2022-02-20', 0, 67, 64),
(68, 'Ramos', 'Eric', 'eric.ramos@gmail.com', '0123456789790', 'M', '2022-07-16', 0, 68, 818),
(69, 'Kelly', 'Michele', 'michele.kelly@gmail.com', '0123456789312', 'W', '2020-11-04', 0, 69, 744),
(70, 'Harrison', 'Nicole', 'nicole.harrison@gmail.com', '0123456789917', 'W', '2021-08-09', 0, 70, 912),
(71, 'Graham', 'Shawna', 'shawna.graham@gmail.com', '0123456789447', 'W', '2023-04-30', 0, 71, 864),
(72, 'Rodgers', 'Lisa', 'lisa.rodgers@gmail.com', '0123456789653', 'W', '2023-04-08', 0, 72, 772),
(73, 'Duran', 'Brenda', 'brenda.duran@gmail.com', '0123456789697', 'W', '2018-11-20', 1, 73, 992),
(74, 'Silva', 'Mary', 'mary.silva@gmail.com', '0123456789478', 'W', '2021-11-08', 0, 74, 416),
(75, 'Trevino', 'Mary', 'mary.trevino@gmail.com', '0123456789300', 'W', '2020-07-14', 0, 75, 509),
(76, 'Bell', 'Joseph', 'joseph.bell@gmail.com', '0123456789822', 'M', '2018-08-08', 1, 76, 469),
(77, 'Kidd', 'Jason', 'jason.kidd@gmail.com', '0123456789347', 'M', '2019-09-21', 1, 77, 1047),
(78, 'Baldwin', 'Lori', 'lori.baldwin@gmail.com', '0123456789750', 'W', '2022-01-12', 0, 78, 964),
(79, 'Everett', 'John', 'john.everett@gmail.com', '0123456789525', 'M', '2019-02-02', 1, 79, 729),
(80, 'Allen', 'Kevin', 'kevin.allen@gmail.com', '0123456789649', 'M', '2019-09-07', 1, 80, 719),
(81, 'Dudley', 'Gina', 'gina.dudley@gmail.com', '0123456789880', 'W', '2019-06-02', 1, 81, 574),
(82, 'Tate', 'Christopher', 'christopher.tate@gmail.com', '0123456789691', 'M', '2019-07-31', 1, 82, 1013),
(83, 'Black', 'Joseph', 'joseph.black@gmail.com', '0123456789780', 'M', '2018-12-24', 1, 83, 441),
(84, 'Hubbard', 'Sarah', 'sarah.hubbard@gmail.com', '0123456789173', 'W', '2020-02-01', 1, 84, 856),
(85, 'Ward', 'Steve', 'steve.ward@gmail.com', '0123456789331', 'M', '2019-08-31', 1, 85, 140),
(86, 'Oneill', 'Andrew', 'andrew.oneill@gmail.com', '0123456789444', 'M', '2018-07-23', 1, 86, 754),
(87, 'Miles', 'Jason', 'jason.miles@gmail.com', '0123456789345', 'M', '2019-02-20', 1, 87, 286),
(88, 'Mcdonald', 'Matthew', 'matthew.mcdonald@gmail.com', '0123456789356', 'M', '2019-10-15', 1, 88, 150),
(89, 'Shelton', 'Travis', 'travis.shelton@gmail.com', '0123456789821', 'M', '2019-12-09', 1, 89, 855),
(90, 'Doyle', 'Jacob', 'jacob.doyle@gmail.com', '0123456789144', 'M', '2022-01-17', 0, 90, 548),
(91, 'Arnold', 'Yolanda', 'yolanda.arnold@gmail.com', '0123456789826', 'W', '2018-10-02', 1, 91, 1217),
(92, 'Phillips', 'Anna', 'anna.phillips@gmail.com', '0123456789350', 'W', '2020-04-21', 1, 92, 955),
(93, 'Carrillo', 'Cathy', 'cathy.carrillo@gmail.com', '0123456789147', 'W', '2020-04-28', 1, 93, 655),
(94, 'Jacobson', 'Christian', 'christian.jacobson@gmail.com', '0123456789916', 'M', '2018-12-30', 1, 94, 70),
(95, 'Caldwell', 'Jane', 'jane.caldwell@gmail.com', '0123456789318', 'W', '2019-07-04', 1, 95, 1051),
(96, 'Petty', 'Curtis', 'curtis.petty@gmail.com', '0123456789602', 'M', '2019-08-26', 1, 96, 771),
(97, 'Rodriguez', 'Jonathan', 'jonathan.rodriguez@gmail.com', '0123456789623', 'M', '2020-09-10', 0, 97, 785),
(98, 'Leon', 'Jesus', 'jesus.leon@gmail.com', '0123456789566', 'M', '2018-02-09', 1, 98, 603),
(99, 'Mcclure', 'Randall', 'randall.mcclure@gmail.com', '0123456789878', 'M', '2023-04-29', 0, 99, 1204),
(100, 'Wilson', 'Vicki', 'vicki.wilson@gmail.com', '0123456789282', 'W', '2021-04-14', 0, 100, 950),
(101, 'Anderson', 'Craig', 'craig.anderson@gmail.com', '0123456789437', 'M', '2022-10-27', 0, 101, 214),
(102, 'Patterson', 'Linda', 'linda.patterson@gmail.com', '0123456789641', 'W', '2020-01-26', 1, 102, 13),
(103, 'Doyle', 'Ashley', 'ashley.doyle@gmail.com', '0123456789239', 'W', '2022-03-13', 0, 103, 1035),
(104, 'Gonzalez', 'Shannon', 'shannon.gonzalez@gmail.com', '0123456789506', 'M', '2019-02-27', 1, 104, 935),
(105, 'Davis', 'Jaclyn', 'jaclyn.davis@gmail.com', '0123456789906', 'W', '2018-04-06', 1, 105, 708),
(106, 'Matthews', 'Jessica', 'jessica.matthews@gmail.com', '0123456789581', 'W', '2022-09-07', 0, 106, 1056),
(107, 'Mathews', 'Patrick', 'patrick.mathews@gmail.com', '0123456789489', 'M', '2021-05-26', 0, 107, 1235),
(108, 'Mason', 'Patrick', 'patrick.mason@gmail.com', '0123456789170', 'M', '2022-09-09', 0, 108, 1029),
(109, 'Curtis', 'Michael', 'michael.curtis@gmail.com', '0123456789886', 'M', '2021-02-11', 0, 109, 885),
(110, 'Pierce', 'Mark', 'mark.pierce@gmail.com', '0123456789246', 'M', '2019-02-05', 1, 110, 399),
(111, 'Villegas', 'Julie', 'julie.villegas@gmail.com', '0123456789177', 'W', '2019-01-27', 1, 111, 182),
(112, 'Reid', 'Thomas', 'thomas.reid@gmail.com', '0123456789107', 'M', '2020-12-21', 0, 112, 480),
(113, 'George', 'Alexandria', 'alexandria.george@gmail.com', '0123456789986', 'W', '2022-02-09', 0, 113, 608),
(114, 'Hill', 'Eileen', 'eileen.hill@gmail.com', '0123456789559', 'W', '2020-10-02', 0, 114, 717),
(115, 'Cantrell', 'Julie', 'julie.cantrell@gmail.com', '0123456789838', 'W', '2020-12-18', 0, 115, 876),
(116, 'Ritter', 'Aaron', 'aaron.ritter@gmail.com', '0123456789139', 'M', '2020-08-14', 0, 116, 1102),
(117, 'Knight', 'Joseph', 'joseph.knight@gmail.com', '0123456789970', 'M', '2022-01-19', 0, 117, 762),
(118, 'Smith', 'Brittany', 'brittany.smith@gmail.com', '0123456789493', 'W', '2022-06-28', 0, 118, 999),
(119, 'Robinson', 'Christina', 'christina.robinson@gmail.com', '0123456789723', 'W', '2019-04-04', 1, 119, 1214),
(120, 'Lawson', 'Victoria', 'victoria.lawson@gmail.com', '0123456789819', 'W', '2023-06-27', 0, 120, 794),
(121, 'Cisneros', 'Gregory', 'gregory.cisneros@gmail.com', '0123456789849', 'M', '2019-01-15', 1, 121, 363),
(122, 'Ray', 'Barbara', 'barbara.ray@gmail.com', '0123456789143', 'W', '2018-06-06', 1, 122, 1191),
(123, 'Nguyen', 'Tammy', 'tammy.nguyen@gmail.com', '0123456789561', 'W', '2021-11-27', 0, 123, 821),
(124, 'English', 'Mariah', 'mariah.english@gmail.com', '0123456789171', 'W', '2020-12-23', 0, 124, 436),
(125, 'Pham', 'Justin', 'justin.pham@gmail.com', '0123456789265', 'M', '2021-06-18', 0, 125, 221),
(126, 'Brown', 'Kurt', 'kurt.brown@gmail.com', '0123456789852', 'M', '2022-05-06', 0, 126, 698),
(127, 'Goodman', 'Jason', 'jason.goodman@gmail.com', '0123456789355', 'M', '2019-06-12', 1, 127, 880),
(128, 'Brock', 'Samantha', 'samantha.brock@gmail.com', '0123456789669', 'W', '2022-08-23', 0, 128, 695),
(129, 'Parker', 'Andrew', 'andrew.parker@gmail.com', '0123456789460', 'M', '2019-01-07', 1, 129, 405),
(130, 'Benjamin', 'Jeremy', 'jeremy.benjamin@gmail.com', '0123456789665', 'M', '2021-12-14', 0, 130, 1155),
(131, 'Oconnor', 'Jose', 'jose.oconnor@gmail.com', '0123456789633', 'M', '2021-12-26', 0, 131, 432),
(132, 'Martinez', 'Mason', 'mason.martinez@gmail.com', '0123456789455', 'M', '2021-02-19', 0, 132, 1177),
(133, 'Lane', 'Brenda', 'brenda.lane@gmail.com', '0123456789527', 'W', '2020-08-05', 0, 133, 992),
(134, 'Simpson', 'Mark', 'mark.simpson@gmail.com', '0123456789809', 'M', '2019-08-06', 1, 134, 537),
(135, 'Miller', 'Laura', 'laura.miller@gmail.com', '0123456789749', 'W', '2019-10-10', 1, 135, 659),
(136, 'Alvarado', 'Kenneth', 'kenneth.alvarado@gmail.com', '0123456789798', 'M', '2018-09-10', 1, 136, 592),
(137, 'Hill', 'Jacob', 'jacob.hill@gmail.com', '0123456789499', 'M', '2022-07-21', 0, 137, 823),
(138, 'Lin', 'Alexander', 'alexander.lin@gmail.com', '0123456789911', 'M', '2018-05-13', 1, 138, 1022),
(139, 'Morris', 'Courtney', 'courtney.morris@gmail.com', '0123456789229', 'W', '2019-02-01', 1, 139, 392),
(140, 'Sanchez', 'Cory', 'cory.sanchez@gmail.com', '0123456789134', 'M', '2023-02-17', 0, 140, 112),
(141, 'Greene', 'Dustin', 'dustin.greene@gmail.com', '0123456789242', 'M', '2019-06-23', 1, 141, 531),
(142, 'Taylor', 'James', 'james.taylor@gmail.com', '0123456789590', 'M', '2021-05-22', 0, 142, 192),
(143, 'Harrell', 'Thomas', 'thomas.harrell@gmail.com', '0123456789688', 'M', '2020-09-06', 0, 143, 487),
(144, 'Rowe', 'Alexandra', 'alexandra.rowe@gmail.com', '0123456789745', 'W', '2018-04-18', 1, 144, 1175),
(145, 'Henderson', 'Patricia', 'patricia.henderson@gmail.com', '0123456789468', 'W', '2018-07-25', 1, 145, 946),
(146, 'Bailey', 'Lisa', 'lisa.bailey@gmail.com', '0123456789786', 'W', '2021-03-30', 0, 146, 1196),
(147, 'Roberts', 'Adam', 'adam.roberts@gmail.com', '0123456789828', 'M', '2022-01-21', 0, 147, 1223),
(148, 'Ortiz', 'Alexander', 'alexander.ortiz@gmail.com', '0123456789270', 'M', '2018-06-17', 1, 148, 1043),
(149, 'Everett', 'Robert', 'robert.everett@gmail.com', '0123456789230', 'M', '2019-03-14', 1, 149, 464),
(150, 'Mejia', 'Laura', 'laura.mejia@gmail.com', '0123456789293', 'W', '2019-03-18', 1, 150, 657),
(151, 'Davis', 'Michael', 'michael.davis@gmail.com', '0123456789567', 'M', '2018-04-30', 1, 151, 897),
(152, 'Butler', 'Elizabeth', 'elizabeth.butler@gmail.com', '0123456789895', 'W', '2019-08-04', 1, 152, 859),
(153, 'Stone', 'Michelle', 'michelle.stone@gmail.com', '0123456789442', 'W', '2018-10-14', 1, 153, 902),
(154, 'Waters', 'Nathan', 'nathan.waters@gmail.com', '0123456789877', 'M', '2018-09-26', 1, 154, 587),
(155, 'Jackson', 'David', 'david.jackson@gmail.com', '0123456789744', 'M', '2018-09-01', 1, 155, 960),
(156, 'Hunter', 'Jenny', 'jenny.hunter@gmail.com', '0123456789684', 'W', '2019-09-23', 1, 156, 910),
(157, 'Keller', 'Melissa', 'melissa.keller@gmail.com', '0123456789424', 'W', '2021-12-29', 0, 157, 769),
(158, 'Dillon', 'Willie', 'willie.dillon@gmail.com', '0123456789256', 'M', '2018-09-13', 1, 158, 785),
(159, 'Curry', 'Tiffany', 'tiffany.curry@gmail.com', '0123456789732', 'W', '2018-02-04', 1, 159, 944),
(160, 'Young', 'Christina', 'christina.young@gmail.com', '0123456789824', 'W', '2023-06-19', 0, 160, 859),
(161, 'Arroyo', 'Deborah', 'deborah.arroyo@gmail.com', '0123456789608', 'W', '2019-09-10', 1, 161, 1009),
(162, 'Lewis', 'Kenneth', 'kenneth.lewis@gmail.com', '0123456789994', 'M', '2019-07-17', 1, 162, 946),
(163, 'Drake', 'Angelica', 'angelica.drake@gmail.com', '0123456789562', 'W', '2021-07-22', 0, 163, 837),
(164, 'Craig', 'Wesley', 'wesley.craig@gmail.com', '0123456789865', 'M', '2022-08-24', 0, 164, 1004),
(165, 'Sanchez', 'Melissa', 'melissa.sanchez@gmail.com', '0123456789971', 'W', '2020-06-23', 1, 165, 868),
(166, 'Gonzalez', 'Richard', 'richard.gonzalez@gmail.com', '0123456789647', 'M', '2021-08-13', 0, 166, 441),
(167, 'Parker', 'Bryan', 'bryan.parker@gmail.com', '0123456789508', 'M', '2020-11-30', 0, 167, 245),
(168, 'Morgan', 'Rachel', 'rachel.morgan@gmail.com', '0123456789384', 'W', '2021-09-11', 0, 168, 478),
(169, 'Patterson', 'Crystal', 'crystal.patterson@gmail.com', '0123456789267', 'W', '2018-04-02', 1, 169, 417),
(170, 'Pierce', 'Angela', 'angela.pierce@gmail.com', '0123456789991', 'W', '2021-08-01', 0, 170, 1049),
(171, 'Morrison', 'Daniel', 'daniel.morrison@gmail.com', '0123456789872', 'M', '2023-06-08', 0, 171, 654),
(172, 'Meyer', 'William', 'william.meyer@gmail.com', '0123456789656', 'M', '2019-05-17', 1, 172, 458),
(173, 'Williams', 'Brianna', 'brianna.williams@gmail.com', '0123456789445', 'W', '2022-02-13', 0, 173, 806),
(174, 'Wright', 'Laurie', 'laurie.wright@gmail.com', '0123456789375', 'W', '2020-07-24', 0, 174, 811),
(175, 'Daniels', 'Steven', 'steven.daniels@gmail.com', '0123456789123', 'M', '2020-07-12', 0, 175, 521),
(176, 'Baxter', 'Colton', 'colton.baxter@gmail.com', '0123456789679', 'M', '2020-09-10', 0, 176, 309),
(177, 'Parker', 'Charles', 'charles.parker@gmail.com', '0123456789879', 'M', '2021-06-28', 0, 177, 487),
(178, 'Simmons', 'Autumn', 'autumn.simmons@gmail.com', '0123456789938', 'W', '2019-10-08', 1, 178, 146),
(179, 'Solis', 'Randall', 'randall.solis@gmail.com', '0123456789885', 'M', '2018-07-26', 1, 179, 984),
(180, 'Watkins', 'Carlos', 'carlos.watkins@gmail.com', '0123456789237', 'M', '2018-10-12', 1, 180, 845),
(181, 'Taylor', 'Alex', 'alex.taylor@gmail.com', '0123456789791', 'M', '2021-09-03', 0, 181, 1085),
(182, 'Brown', 'Christopher', 'christopher.brown@gmail.com', '0123456789430', 'M', '2021-05-05', 0, 182, 1026),
(183, 'Harris', 'Mark', 'mark.harris@gmail.com', '0123456789367', 'M', '2021-07-15', 0, 183, 1218),
(184, 'Murray', 'Nancy', 'nancy.murray@gmail.com', '0123456789595', 'W', '2023-04-12', 0, 184, 468),
(185, 'Grimes', 'Carlos', 'carlos.grimes@gmail.com', '0123456789475', 'M', '2019-01-31', 1, 185, 86),
(186, 'Lee', 'Maxwell', 'maxwell.lee@gmail.com', '0123456789735', 'M', '2021-09-09', 0, 186, 541),
(187, 'Potter', 'April', 'april.potter@gmail.com', '0123456789959', 'W', '2021-09-20', 0, 187, 983),
(188, 'Pham', 'David', 'david.pham@gmail.com', '0123456789782', 'M', '2019-11-17', 1, 188, 538),
(189, 'Johnson', 'Eric', 'eric.johnson@gmail.com', '0123456789646', 'M', '2022-09-02', 0, 189, 1062),
(190, 'Hernandez', 'Francisco', 'francisco.hernandez@gmail.com', '0123456789391', 'M', '2021-02-11', 0, 190, 198),
(191, 'Gilbert', 'Kevin', 'kevin.gilbert@gmail.com', '0123456789446', 'M', '2018-02-17', 1, 191, 982),
(192, 'Burke', 'Ashley', 'ashley.burke@gmail.com', '0123456789689', 'W', '2022-07-11', 0, 192, 126),
(193, 'Todd', 'Lori', 'lori.todd@gmail.com', '0123456789360', 'W', '2023-05-31', 0, 193, 368),
(194, 'Travis', 'Anita', 'anita.travis@gmail.com', '0123456789816', 'W', '2020-07-12', 0, 194, 1198),
(195, 'Garcia', 'Robert', 'robert.garcia@gmail.com', '0123456789401', 'M', '2022-02-14', 0, 195, 674),
(196, 'Cervantes', 'Mark', 'mark.cervantes@gmail.com', '0123456789351', 'M', '2018-10-04', 1, 196, 215),
(197, 'Thompson', 'Hannah', 'hannah.thompson@gmail.com', '0123456789414', 'W', '2019-08-04', 1, 197, 548),
(198, 'Wood', 'Vanessa', 'vanessa.wood@gmail.com', '0123456789743', 'W', '2021-06-01', 0, 198, 1121),
(199, 'Gray', 'Heidi', 'heidi.gray@gmail.com', '0123456789135', 'W', '2023-01-20', 0, 199, 470),
(200, 'Gomez', 'Gerald', 'gerald.gomez@gmail.com', '0123456789873', 'M', '2023-01-03', 0, 200, 1043),
(201, 'Diaz', 'Lisa', 'lisa.diaz@gmail.com', '0123456789550', 'W', '2020-05-01', 1, 201, 986),
(202, 'Mcdonald', 'Brandon', 'brandon.mcdonald@gmail.com', '0123456789443', 'M', '2020-01-12', 1, 202, 26),
(203, 'Jacobson', 'Dorothy', 'dorothy.jacobson@gmail.com', '0123456789117', 'W', '2022-09-20', 0, 203, 1149),
(204, 'Kidd', 'Wendy', 'wendy.kidd@gmail.com', '0123456789261', 'W', '2022-01-14', 0, 204, 112),
(205, 'Owens', 'John', 'john.owens@gmail.com', '0123456789774', 'M', '2021-08-29', 0, 205, 1173),
(206, 'Chen', 'Joshua', 'joshua.chen@gmail.com', '0123456789859', 'M', '2019-04-15', 1, 206, 322),
(207, 'Andrews', 'Robert', 'robert.andrews@gmail.com', '0123456789904', 'M', '2023-03-03', 0, 207, 343),
(208, 'Hoffman', 'Savannah', 'savannah.hoffman@gmail.com', '0123456789253', 'W', '2018-05-14', 1, 208, 92),
(209, 'Howard', 'Robert', 'robert.howard@gmail.com', '0123456789201', 'M', '2022-04-23', 0, 209, 1157),
(210, 'Marshall', 'Robin', 'robin.marshall@gmail.com', '0123456789604', 'M', '2022-09-18', 0, 210, 284),
(211, 'Morgan', 'Terri', 'terri.morgan@gmail.com', '0123456789235', 'W', '2019-07-02', 1, 211, 144),
(212, 'Martin', 'Paula', 'paula.martin@gmail.com', '0123456789365', 'W', '2019-06-15', 1, 212, 1078),
(213, 'Mitchell', 'Stefanie', 'stefanie.mitchell@gmail.com', '0123456789783', 'W', '2019-04-03', 1, 213, 219),
(214, 'Cox', 'Michael', 'michael.cox@gmail.com', '0123456789898', 'M', '2021-12-05', 0, 214, 50),
(215, 'Miranda', 'Morgan', 'morgan.miranda@gmail.com', '0123456789456', 'W', '2021-12-30', 0, 215, 943),
(216, 'Lynch', 'Jessica', 'jessica.lynch@gmail.com', '0123456789670', 'W', '2019-02-05', 1, 216, 603),
(217, 'Lam', 'Nicole', 'nicole.lam@gmail.com', '0123456789913', 'W', '2018-02-16', 1, 217, 1011),
(218, 'Grimes', 'Crystal', 'crystal.grimes@gmail.com', '0123456789276', 'W', '2018-12-28', 1, 218, 478),
(219, 'Holt', 'Mike', 'mike.holt@gmail.com', '0123456789742', 'M', '2018-09-08', 1, 219, 1195),
(220, 'Sanders', 'Chelsea', 'chelsea.sanders@gmail.com', '0123456789319', 'W', '2020-07-05', 0, 220, 188),
(221, 'Johnston', 'Johnathan', 'johnathan.johnston@gmail.com', '0123456789570', 'M', '2018-06-19', 1, 221, 638),
(222, 'Griffith', 'Becky', 'becky.griffith@gmail.com', '0123456789993', 'W', '2020-04-11', 1, 222, 723),
(223, 'Mora', 'Douglas', 'douglas.mora@gmail.com', '0123456789501', 'M', '2023-06-21', 0, 223, 98),
(224, 'Walker', 'George', 'george.walker@gmail.com', '0123456789121', 'M', '2021-02-28', 0, 224, 1085),
(225, 'Salazar', 'Jennifer', 'jennifer.salazar@gmail.com', '0123456789847', 'W', '2019-12-21', 1, 225, 731),
(226, 'Baker', 'Tara', 'tara.baker@gmail.com', '0123456789739', 'W', '2018-03-05', 1, 226, 114),
(227, 'Wright', 'Anthony', 'anthony.wright@gmail.com', '0123456789332', 'M', '2022-11-16', 0, 227, 668),
(228, 'Reed', 'Victoria', 'victoria.reed@gmail.com', '0123456789225', 'W', '2019-07-27', 1, 228, 678),
(229, 'Levine', 'John', 'john.levine@gmail.com', '0123456789966', 'M', '2018-06-08', 1, 229, 687),
(230, 'Morse', 'Andrew', 'andrew.morse@gmail.com', '0123456789359', 'M', '2019-04-30', 1, 230, 96),
(231, 'Garner', 'Carol', 'carol.garner@gmail.com', '0123456789232', 'W', '2020-11-07', 0, 231, 1171),
(232, 'White', 'Brian', 'brian.white@gmail.com', '0123456789307', 'M', '2019-02-23', 1, 232, 969),
(233, 'Green', 'Adam', 'adam.green@gmail.com', '0123456789369', 'M', '2020-07-04', 0, 233, 836),
(234, 'Powell', 'Sabrina', 'sabrina.powell@gmail.com', '0123456789214', 'W', '2019-08-30', 1, 234, 133),
(235, 'Griffin', 'Thomas', 'thomas.griffin@gmail.com', '0123456789676', 'M', '2022-09-28', 0, 235, 812),
(236, 'Berry', 'Patricia', 'patricia.berry@gmail.com', '0123456789583', 'W', '2022-01-20', 0, 236, 811),
(237, 'Smith', 'Laura', 'laura.smith@gmail.com', '0123456789492', 'W', '2018-08-30', 1, 237, 1185),
(238, 'Blackwell', 'Anthony', 'anthony.blackwell@gmail.com', '0123456789209', 'M', '2021-12-11', 0, 238, 1148),
(239, 'Boyd', 'Samantha', 'samantha.boyd@gmail.com', '0123456789941', 'W', '2021-01-10', 0, 239, 622),
(240, 'Mcdonald', 'Eric', 'eric.mcdonald@gmail.com', '0123456789486', 'M', '2018-07-22', 1, 240, 971),
(241, 'Cooley', 'Richard', 'richard.cooley@gmail.com', '0123456789297', 'M', '2021-05-23', 0, 241, 801),
(242, 'Bailey', 'Deborah', 'deborah.bailey@gmail.com', '0123456789975', 'W', '2020-04-14', 1, 242, 903),
(243, 'Stanley', 'Shane', 'shane.stanley@gmail.com', '0123456789477', 'M', '2022-03-28', 0, 243, 1027),
(244, 'Rodriguez', 'Leah', 'leah.rodriguez@gmail.com', '0123456789522', 'W', '2022-11-14', 0, 244, 351),
(245, 'Edwards', 'Jacob', 'jacob.edwards@gmail.com', '0123456789850', 'M', '2019-10-05', 1, 245, 1234),
(246, 'Meza', 'Daniel', 'daniel.meza@gmail.com', '0123456789856', 'M', '2018-10-26', 1, 246, 322),
(247, 'Harris', 'Michael', 'michael.harris@gmail.com', '0123456789326', 'M', '2023-05-20', 0, 247, 930),
(248, 'Willis', 'Michael', 'michael.willis@gmail.com', '0123456789106', 'M', '2023-04-11', 0, 248, 356),
(249, 'Walker', 'Kathleen', 'kathleen.walker@gmail.com', '0123456789399', 'W', '2023-03-19', 0, 249, 319),
(250, 'Munoz', 'Tiffany', 'tiffany.munoz@gmail.com', '0123456789963', 'W', '2019-11-03', 1, 250, 244),
(251, 'Allen', 'Aaron', 'aaron.allen@gmail.com', '0123456789599', 'M', '2023-02-08', 0, 251, 71),
(252, 'Campbell', 'Ernest', 'ernest.campbell@gmail.com', '0123456789272', 'M', '2022-11-05', 0, 252, 626),
(253, 'Arnold', 'Michael', 'michael.arnold@gmail.com', '0123456789614', 'M', '2023-02-22', 0, 253, 882),
(254, 'Wallace', 'Nicole', 'nicole.wallace@gmail.com', '0123456789240', 'W', '2020-10-26', 0, 254, 282),
(255, 'Brady', 'Christopher', 'christopher.brady@gmail.com', '0123456789103', 'M', '2021-09-08', 0, 255, 313),
(256, 'Newton', 'Kayla', 'kayla.newton@gmail.com', '0123456789893', 'W', '2019-07-05', 1, 256, 749),
(257, 'Anderson', 'Lisa', 'lisa.anderson@gmail.com', '0123456789388', 'W', '2021-09-24', 0, 257, 713),
(258, 'Williams', 'Daniel', 'daniel.williams@gmail.com', '0123456789719', 'M', '2021-02-09', 0, 258, 1122),
(259, 'Haris', 'Michael', 'michael.haris@gmail.com', '0123456789373', 'M', '2022-08-25', 0, 259, 1204),
(260, 'Perez', 'Brandon', 'brandon.perez@gmail.com', '0123456789403', 'M', '2018-09-23', 1, 260, 1217),
(261, 'Rivas', 'Tara', 'tara.rivas@gmail.com', '0123456789512', 'W', '2020-11-08', 0, 261, 223),
(262, 'Hernandez', 'Ashley', 'ashley.hernandez@gmail.com', '0123456789419', 'W', '2021-09-21', 0, 262, 280),
(263, 'Collins', 'David', 'david.collins@gmail.com', '0123456789950', 'M', '2021-03-22', 0, 263, 150),
(264, 'Russell', 'William', 'william.russell@gmail.com', '0123456789372', 'M', '2022-04-08', 0, 264, 641),
(265, 'Vega', 'Jessica', 'jessica.vega@gmail.com', '0123456789480', 'W', '2019-06-17', 1, 265, 789),
(266, 'Mason', 'Teresa', 'teresa.mason@gmail.com', '0123456789393', 'W', '2023-06-06', 0, 266, 218),
(267, 'Mcgee', 'Matthew', 'matthew.mcgee@gmail.com', '0123456789560', 'M', '2021-11-26', 0, 267, 655),
(268, 'Cook', 'Cheryl', 'cheryl.cook@gmail.com', '0123456789494', 'W', '2020-08-07', 0, 268, 1081),
(269, 'Weeks', 'Matthew', 'matthew.weeks@gmail.com', '0123456789722', 'M', '2019-06-15', 1, 269, 839),
(270, 'Ellison', 'Samantha', 'samantha.ellison@gmail.com', '0123456789458', 'W', '2019-08-14', 1, 270, 1025),
(271, 'Randall', 'Anna', 'anna.randall@gmail.com', '0123456789685', 'W', '2018-10-03', 1, 271, 92),
(272, 'Ramirez', 'Kyle', 'kyle.ramirez@gmail.com', '0123456789383', 'M', '2023-03-23', 0, 272, 905),
(273, 'Serrano', 'Albert', 'albert.serrano@gmail.com', '0123456789736', 'M', '2022-04-11', 0, 273, 478),
(274, 'Chavez', 'Tracey', 'tracey.chavez@gmail.com', '0123456789703', 'W', '2022-10-25', 0, 274, 573),
(275, 'Wilson', 'Trevor', 'trevor.wilson@gmail.com', '0123456789469', 'M', '2019-10-31', 1, 275, 644),
(276, 'Woods', 'Kenneth', 'kenneth.woods@gmail.com', '0123456789533', 'M', '2020-01-18', 1, 276, 976),
(277, 'Gonzalez', 'Samantha', 'samantha.gonzalez@gmail.com', '0123456789195', 'W', '2020-07-12', 0, 277, 774),
(278, 'Martinez', 'Jacob', 'jacob.martinez@gmail.com', '0123456789907', 'M', '2018-10-15', 1, 278, 97),
(279, 'Price', 'Jade', 'jade.price@gmail.com', '0123456789325', 'W', '2022-09-26', 0, 279, 636),
(280, 'Perez', 'Victoria', 'victoria.perez@gmail.com', '0123456789337', 'W', '2022-05-05', 0, 280, 226),
(281, 'Hernandez', 'Kimberly', 'kimberly.hernandez@gmail.com', '0123456789924', 'W', '2020-04-18', 1, 281, 366),
(282, 'Brooks', 'Melissa', 'melissa.brooks@gmail.com', '0123456789578', 'W', '2020-06-12', 1, 282, 647),
(283, 'Garrett', 'Eric', 'eric.garrett@gmail.com', '0123456789843', 'M', '2018-08-04', 1, 283, 446),
(284, 'Reilly', 'Joe', 'joe.reilly@gmail.com', '0123456789792', 'M', '2021-12-17', 0, 284, 1069),
(285, 'Branch', 'Nicole', 'nicole.branch@gmail.com', '0123456789524', 'W', '2021-06-30', 0, 285, 1137),
(286, 'Wong', 'Richard', 'richard.wong@gmail.com', '0123456789199', 'M', '2022-09-02', 0, 286, 792),
(287, 'Bauer', 'Janet', 'janet.bauer@gmail.com', '0123456789707', 'W', '2022-01-13', 0, 287, 899),
(288, 'Rodgers', 'Tammy', 'tammy.rodgers@gmail.com', '0123456789988', 'W', '2020-12-05', 0, 288, 607),
(289, 'Sullivan', 'Stephanie', 'stephanie.sullivan@gmail.com', '0123456789421', 'W', '2022-06-02', 0, 289, 77),
(290, 'Patterson', 'Heather', 'heather.patterson@gmail.com', '0123456789500', 'W', '2019-11-02', 1, 290, 286),
(291, 'Sanders', 'Nicole', 'nicole.sanders@gmail.com', '0123456789800', 'W', '2021-08-26', 0, 291, 173),
(292, 'Miranda', 'Brianna', 'brianna.miranda@gmail.com', '0123456789939', 'W', '2023-01-11', 0, 292, 371),
(293, 'Shaw', 'Angelica', 'angelica.shaw@gmail.com', '0123456789905', 'W', '2020-02-02', 1, 293, 596),
(294, 'Holt', 'Richard', 'richard.holt@gmail.com', '0123456789890', 'M', '2022-11-10', 0, 294, 1197),
(295, 'Atkinson', 'Arthur', 'arthur.atkinson@gmail.com', '0123456789116', 'M', '2020-08-01', 0, 295, 1136),
(296, 'Hernandez', 'Joseph', 'joseph.hernandez@gmail.com', '0123456789484', 'M', '2023-02-28', 0, 296, 581),
(297, 'Johnson', 'Henry', 'henry.johnson@gmail.com', '0123456789252', 'M', '2019-07-02', 1, 297, 381),
(298, 'Flores', 'Bailey', 'bailey.flores@gmail.com', '0123456789796', 'W', '2018-02-07', 1, 298, 1063),
(299, 'Howell', 'Stephanie', 'stephanie.howell@gmail.com', '0123456789285', 'W', '2018-08-02', 1, 299, 113),
(300, 'Mills', 'Sara', 'sara.mills@gmail.com', '0123456789273', 'W', '2019-02-20', 1, 300, 542);

-- --------------------------------------------------------

--
-- Tabellenstruktur für Tabelle `kundenkonto`
--

CREATE TABLE `kundenkonto` (
  `KKontoID` int(11) NOT NULL,
  `Guthaben` decimal(5,2) NOT NULL,
  `LetzteZahlung` date DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Daten für Tabelle `kundenkonto`
--

INSERT INTO `kundenkonto` (`KKontoID`, `Guthaben`, `LetzteZahlung`) VALUES
(1, 22.58, '2022-07-07'),
(2, 188.98, '2020-07-22'),
(3, 610.86, '2018-03-31'),
(4, 436.80, '2023-06-10'),
(5, 300.78, '2022-12-31'),
(6, 950.29, '2022-07-31'),
(7, 616.04, '2022-11-22'),
(8, 611.53, '2021-07-09'),
(9, 296.08, '2023-03-22'),
(10, 613.52, '2019-07-08'),
(11, 123.32, '2022-06-29'),
(12, 79.36, '2021-10-24'),
(13, 758.64, '2020-10-28'),
(14, 476.87, '2020-02-28'),
(15, 244.58, '2023-01-26'),
(16, 298.39, '2019-09-15'),
(17, 543.55, '2023-05-26'),
(18, 211.85, '2019-03-22'),
(19, 923.78, '2021-03-22'),
(20, 608.94, '2019-11-01'),
(21, 327.35, '2023-05-01'),
(22, 878.37, '2021-04-13'),
(23, 198.56, '2018-01-28'),
(24, 104.50, '2021-11-20'),
(25, 430.23, '2022-01-27'),
(26, 295.87, '2021-02-07'),
(27, 749.74, '2023-01-03'),
(28, 48.03, '2019-05-10'),
(29, 45.77, '2019-11-30'),
(30, 842.26, '2020-07-31'),
(31, 467.43, '2020-07-05'),
(32, 407.53, '2019-04-17'),
(33, 102.36, '2018-04-15'),
(34, 754.96, '2019-03-24'),
(35, 355.37, '2018-06-13'),
(36, 446.26, '2021-02-25'),
(37, 923.54, '2020-01-25'),
(38, 302.18, '2023-06-26'),
(39, 152.83, '2020-12-30'),
(40, 767.51, '2018-07-22'),
(41, 115.68, '2020-04-01'),
(42, 570.47, '2020-07-24'),
(43, 364.34, '2019-11-27'),
(44, 729.66, '2022-01-23'),
(45, 72.50, '2019-05-30'),
(46, 350.42, '2019-08-01'),
(47, 640.65, '2021-02-16'),
(48, 217.04, '2021-05-25'),
(49, 972.27, '2019-04-14'),
(50, 120.08, '2018-03-30'),
(51, 240.62, '2018-09-21'),
(52, 492.96, '2022-04-08'),
(53, 868.91, '2018-01-27'),
(54, 801.68, '2019-01-13'),
(55, 362.74, '2018-05-14'),
(56, 384.33, '2018-01-21'),
(57, 465.75, '2021-11-13'),
(58, 242.14, '2020-11-27'),
(59, 288.92, '2022-03-31'),
(60, 440.59, '2018-06-22'),
(61, 837.71, '2022-02-21'),
(62, 978.43, '2019-04-18'),
(63, 450.44, '2020-03-06'),
(64, 452.84, '2020-11-13'),
(65, 115.78, '2019-06-12'),
(66, 863.04, '2019-07-07'),
(67, 865.52, '2022-02-20'),
(68, 824.78, '2022-07-16'),
(69, 270.75, '2020-11-04'),
(70, 70.83, '2021-08-09'),
(71, 114.22, '2023-04-30'),
(72, 978.19, '2023-04-08'),
(73, 427.85, '2018-11-20'),
(74, 913.40, '2021-11-08'),
(75, 204.92, '2020-07-14'),
(76, 570.02, '2018-08-08'),
(77, 28.50, '2019-09-21'),
(78, 118.76, '2022-01-12'),
(79, 175.46, '2019-02-02'),
(80, 196.97, '2019-09-07'),
(81, 852.54, '2019-06-02'),
(82, 922.47, '2019-07-31'),
(83, 562.77, '2018-12-24'),
(84, 995.24, '2020-02-01'),
(85, 632.15, '2019-08-31'),
(86, 279.61, '2018-07-23'),
(87, 642.46, '2019-02-20'),
(88, 427.62, '2019-10-15'),
(89, 333.43, '2019-12-09'),
(90, 190.11, '2022-01-17'),
(91, 41.04, '2018-10-02'),
(92, 902.30, '2020-04-21'),
(93, 597.27, '2020-04-28'),
(94, 625.15, '2018-12-30'),
(95, 580.17, '2019-07-04'),
(96, 68.38, '2019-08-26'),
(97, 210.83, '2020-09-10'),
(98, 285.35, '2018-02-09'),
(99, 104.63, '2023-04-29'),
(100, 143.21, '2021-04-14'),
(101, 802.20, '2022-10-27'),
(102, 141.03, '2020-01-26'),
(103, 359.78, '2022-03-13'),
(104, 442.41, '2019-02-27'),
(105, 353.48, '2018-04-06'),
(106, 286.71, '2022-09-07'),
(107, 0.68, '2021-05-26'),
(108, 87.37, '2022-09-09'),
(109, 159.47, '2021-02-11'),
(110, 967.64, '2019-02-05'),
(111, 583.20, '2019-01-27'),
(112, 698.13, '2020-12-21'),
(113, 149.57, '2022-02-09'),
(114, 764.55, '2020-10-02'),
(115, 868.55, '2020-12-18'),
(116, 865.61, '2020-08-14'),
(117, 311.01, '2022-01-19'),
(118, 491.08, '2022-06-28'),
(119, 707.27, '2019-04-04'),
(120, 872.30, '2023-06-27'),
(121, 994.45, '2019-01-15'),
(122, 146.09, '2018-06-06'),
(123, 591.66, '2021-11-27'),
(124, 420.00, '2020-12-23'),
(125, 255.29, '2021-06-18'),
(126, 281.87, '2022-05-06'),
(127, 22.72, '2019-06-12'),
(128, 451.32, '2022-08-23'),
(129, 415.79, '2019-01-07'),
(130, 549.73, '2021-12-14'),
(131, 639.47, '2021-12-26'),
(132, 486.43, '2021-02-19'),
(133, 689.89, '2020-08-05'),
(134, 731.79, '2019-08-06'),
(135, 125.66, '2019-10-10'),
(136, 743.10, '2018-09-10'),
(137, 413.20, '2022-07-21'),
(138, 271.70, '2018-05-13'),
(139, 198.06, '2019-02-01'),
(140, 38.79, '2023-02-17'),
(141, 187.50, '2019-06-23'),
(142, 336.94, '2021-05-22'),
(143, 668.34, '2020-09-06'),
(144, 646.78, '2018-04-18'),
(145, 191.70, '2018-07-25'),
(146, 305.84, '2021-03-30'),
(147, 903.91, '2022-01-21'),
(148, 466.23, '2018-06-17'),
(149, 590.15, '2019-03-14'),
(150, 340.81, '2019-03-18'),
(151, 968.34, '2018-04-30'),
(152, 151.42, '2019-08-04'),
(153, 444.97, '2018-10-14'),
(154, 824.45, '2018-09-26'),
(155, 358.11, '2018-09-01'),
(156, 423.58, '2019-09-23'),
(157, 190.06, '2021-12-29'),
(158, 910.54, '2018-09-13'),
(159, 604.46, '2018-02-04'),
(160, 281.36, '2023-06-19'),
(161, 544.21, '2019-09-10'),
(162, 969.95, '2019-07-17'),
(163, 655.88, '2021-07-22'),
(164, 233.63, '2022-08-24'),
(165, 954.19, '2020-06-23'),
(166, 546.18, '2021-08-13'),
(167, 385.06, '2020-11-30'),
(168, 949.40, '2021-09-11'),
(169, 367.95, '2018-04-02'),
(170, 829.81, '2021-08-01'),
(171, 834.81, '2023-06-08'),
(172, 375.19, '2019-05-17'),
(173, 819.67, '2022-02-13'),
(174, 627.04, '2020-07-24'),
(175, 961.48, '2020-07-12'),
(176, 74.24, '2020-09-10'),
(177, 816.11, '2021-06-28'),
(178, 539.35, '2019-10-08'),
(179, 204.59, '2018-07-26'),
(180, 657.31, '2018-10-12'),
(181, 39.44, '2021-09-03'),
(182, 653.89, '2021-05-05'),
(183, 186.54, '2021-07-15'),
(184, 674.20, '2023-04-12'),
(185, 583.03, '2019-01-31'),
(186, 119.95, '2021-09-09'),
(187, 548.33, '2021-09-20'),
(188, 45.87, '2019-11-17'),
(189, 893.06, '2022-09-02'),
(190, 454.43, '2021-02-11'),
(191, 539.62, '2018-02-17'),
(192, 822.50, '2022-07-11'),
(193, 356.55, '2023-05-31'),
(194, 735.83, '2020-07-12'),
(195, 415.60, '2022-02-14'),
(196, 394.69, '2018-10-04'),
(197, 632.03, '2019-08-04'),
(198, 630.00, '2021-06-01'),
(199, 812.78, '2023-01-20'),
(200, 446.22, '2023-01-03'),
(201, 921.71, '2020-05-01'),
(202, 966.24, '2020-01-12'),
(203, 196.30, '2022-09-20'),
(204, 996.18, '2022-01-14'),
(205, 387.49, '2021-08-29'),
(206, 247.35, '2019-04-15'),
(207, 314.74, '2023-03-03'),
(208, 178.73, '2018-05-14'),
(209, 59.77, '2022-04-23'),
(210, 912.90, '2022-09-18'),
(211, 580.48, '2019-07-02'),
(212, 145.94, '2019-06-15'),
(213, 920.27, '2019-04-03'),
(214, 792.90, '2021-12-05'),
(215, 833.26, '2021-12-30'),
(216, 185.29, '2019-02-05'),
(217, 20.46, '2018-02-16'),
(218, 773.42, '2018-12-28'),
(219, 757.30, '2018-09-08'),
(220, 249.20, '2020-07-05'),
(221, 970.30, '2018-06-19'),
(222, 132.74, '2020-04-11'),
(223, 99.30, '2023-06-21'),
(224, 331.02, '2021-02-28'),
(225, 375.62, '2019-12-21'),
(226, 127.08, '2018-03-05'),
(227, 784.58, '2022-11-16'),
(228, 250.73, '2019-07-27'),
(229, 818.72, '2018-06-08'),
(230, 845.76, '2019-04-30'),
(231, 31.24, '2020-11-07'),
(232, 491.94, '2019-02-23'),
(233, 637.21, '2020-07-04'),
(234, 929.69, '2019-08-30'),
(235, 874.60, '2022-09-28'),
(236, 66.13, '2022-01-20'),
(237, 531.41, '2018-08-30'),
(238, 309.17, '2021-12-11'),
(239, 210.98, '2021-01-10'),
(240, 155.46, '2018-07-22'),
(241, 388.92, '2021-05-23'),
(242, 392.91, '2020-04-14'),
(243, 253.76, '2022-03-28'),
(244, 968.04, '2022-11-14'),
(245, 136.48, '2019-10-05'),
(246, 940.79, '2018-10-26'),
(247, 924.89, '2023-05-20'),
(248, 38.73, '2023-04-11'),
(249, 787.61, '2023-03-19'),
(250, 954.91, '2019-11-03'),
(251, 825.48, '2023-02-08'),
(252, 78.35, '2022-11-05'),
(253, 606.75, '2023-02-22'),
(254, 972.64, '2020-10-26'),
(255, 28.65, '2021-09-08'),
(256, 268.75, '2019-07-05'),
(257, 652.92, '2021-09-24'),
(258, 244.50, '2021-02-09'),
(259, 290.29, '2022-08-25'),
(260, 277.93, '2018-09-23'),
(261, 85.88, '2020-11-08'),
(262, 989.98, '2021-09-21'),
(263, 424.40, '2021-03-22'),
(264, 66.29, '2022-04-08'),
(265, 696.41, '2019-06-17'),
(266, 605.30, '2023-06-06'),
(267, 657.31, '2021-11-26'),
(268, 985.03, '2020-08-07'),
(269, 612.66, '2019-06-15'),
(270, 843.92, '2019-08-14'),
(271, 863.76, '2018-10-03'),
(272, 736.64, '2023-03-23'),
(273, 327.19, '2022-04-11'),
(274, 601.01, '2022-10-25'),
(275, 445.45, '2019-10-31'),
(276, 612.15, '2020-01-18'),
(277, 204.12, '2020-07-12'),
(278, 653.23, '2018-10-15'),
(279, 888.11, '2022-09-26'),
(280, 621.15, '2022-05-05'),
(281, 731.71, '2020-04-18'),
(282, 79.50, '2020-06-12'),
(283, 398.02, '2018-08-04'),
(284, 765.77, '2021-12-17'),
(285, 159.47, '2021-06-30'),
(286, 16.13, '2022-09-02'),
(287, 753.08, '2022-01-13'),
(288, 20.67, '2020-12-05'),
(289, 981.41, '2022-06-02'),
(290, 292.51, '2019-11-02'),
(291, 198.07, '2021-08-26'),
(292, 885.81, '2023-01-11'),
(293, 267.34, '2020-02-02'),
(294, 424.87, '2022-11-10'),
(295, 542.29, '2020-08-01'),
(296, 55.23, '2023-02-28'),
(297, 219.54, '2019-07-02'),
(298, 884.93, '2018-02-07'),
(299, 659.74, '2018-08-02'),
(300, 878.33, '2019-02-20');

-- --------------------------------------------------------

--
-- Tabellenstruktur für Tabelle `lager`
--

CREATE TABLE `lager` (
  `LagerID` int(11) NOT NULL,
  `StandortID` int(11) NOT NULL,
  `RegionID` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Daten für Tabelle `lager`
--

INSERT INTO `lager` (`LagerID`, `StandortID`, `RegionID`) VALUES
(1, 101, 5),
(2, 51, 4),
(3, 151, 3),
(4, 201, 2),
(5, 1, 1);

-- --------------------------------------------------------

--
-- Tabellenstruktur für Tabelle `lager_einzelteile`
--

CREATE TABLE `lager_einzelteile` (
  `Lager_EteileID` int(11) NOT NULL,
  `MinBestand` int(11) NOT NULL,
  `MaxBestand` int(11) NOT NULL,
  `Bestand` int(11) NOT NULL,
  `LagerID` int(11) NOT NULL,
  `EinzelteileID` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Daten für Tabelle `lager_einzelteile`
--

INSERT INTO `lager_einzelteile` (`Lager_EteileID`, `MinBestand`, `MaxBestand`, `Bestand`, `LagerID`, `EinzelteileID`) VALUES
(1, 220, 520, 354, 1, 1),
(2, 390, 420, 398, 1, 2),
(3, 260, 830, 568, 1, 3),
(4, 300, 910, 882, 1, 4),
(5, 230, 800, 634, 1, 5),
(6, 370, 430, 384, 1, 6),
(7, 400, 660, 610, 1, 7),
(8, 390, 430, 412, 1, 8),
(9, 290, 510, 340, 1, 9),
(10, 340, 780, 466, 1, 10),
(11, 200, 830, 782, 1, 11),
(12, 210, 850, 330, 1, 12),
(13, 370, 840, 614, 1, 13),
(14, 290, 670, 651, 1, 14),
(15, 350, 620, 455, 1, 15),
(16, 400, 910, 625, 1, 16),
(17, 270, 930, 874, 1, 17),
(18, 370, 620, 597, 1, 18),
(19, 230, 500, 274, 1, 19),
(20, 270, 700, 600, 1, 20),
(21, 210, 500, 491, 1, 21),
(22, 280, 680, 336, 1, 22),
(23, 330, 720, 485, 1, 23),
(24, 310, 850, 719, 1, 24),
(25, 380, 650, 642, 1, 25),
(26, 210, 430, 403, 1, 26),
(27, 390, 420, 419, 1, 27),
(28, 400, 550, 448, 1, 28),
(29, 390, 490, 476, 1, 29),
(30, 340, 900, 465, 1, 30),
(31, 340, 480, 404, 1, 31),
(32, 320, 560, 376, 1, 32),
(33, 400, 1000, 913, 1, 33),
(34, 300, 720, 479, 1, 34),
(35, 320, 770, 472, 1, 35),
(36, 400, 710, 587, 1, 36),
(37, 400, 930, 712, 1, 37),
(38, 400, 1000, 896, 1, 38),
(39, 230, 830, 260, 1, 39),
(40, 330, 820, 587, 1, 40),
(41, 380, 510, 459, 1, 41),
(42, 370, 410, 395, 1, 42),
(43, 230, 540, 267, 1, 43),
(44, 240, 940, 473, 1, 44),
(45, 310, 700, 401, 1, 45),
(46, 400, 550, 432, 1, 46),
(47, 330, 790, 548, 1, 47),
(48, 210, 630, 250, 1, 48),
(49, 300, 420, 406, 1, 49),
(50, 320, 510, 374, 1, 50),
(51, 230, 670, 487, 1, 51),
(52, 320, 830, 324, 2, 1),
(53, 350, 950, 900, 2, 2),
(54, 280, 970, 717, 2, 3),
(55, 290, 780, 608, 2, 4),
(56, 390, 830, 507, 2, 5),
(57, 270, 700, 451, 2, 6),
(58, 360, 870, 788, 2, 7),
(59, 220, 740, 321, 2, 8),
(60, 250, 400, 344, 2, 9),
(61, 300, 460, 449, 2, 10),
(62, 280, 750, 315, 2, 11),
(63, 230, 780, 231, 2, 12),
(64, 260, 1000, 602, 2, 13),
(65, 250, 930, 302, 2, 14),
(66, 210, 420, 312, 2, 15),
(67, 350, 670, 515, 2, 16),
(68, 350, 830, 425, 2, 17),
(69, 330, 760, 488, 2, 18),
(70, 290, 780, 471, 2, 19),
(71, 320, 700, 636, 2, 20),
(72, 270, 480, 383, 2, 21),
(73, 350, 650, 648, 2, 22),
(74, 360, 840, 439, 2, 23),
(75, 220, 790, 309, 2, 24),
(76, 260, 700, 285, 2, 25),
(77, 230, 400, 315, 2, 26),
(78, 350, 620, 480, 2, 27),
(79, 270, 620, 583, 2, 28),
(80, 300, 760, 670, 2, 29),
(81, 270, 760, 503, 2, 30),
(82, 230, 830, 754, 2, 31),
(83, 340, 790, 779, 2, 32),
(84, 270, 1000, 339, 2, 33),
(85, 320, 820, 745, 2, 34),
(86, 360, 780, 453, 2, 35),
(87, 340, 440, 390, 2, 36),
(88, 240, 560, 531, 2, 37),
(89, 350, 450, 407, 2, 38),
(90, 380, 570, 501, 2, 39),
(91, 280, 500, 387, 2, 40),
(92, 320, 500, 409, 2, 41),
(93, 380, 580, 470, 2, 42),
(94, 360, 860, 665, 2, 43),
(95, 320, 540, 468, 2, 44),
(96, 350, 530, 447, 2, 45),
(97, 230, 780, 382, 2, 46),
(98, 280, 540, 336, 2, 47),
(99, 360, 900, 780, 2, 48),
(100, 360, 480, 381, 2, 49),
(101, 220, 500, 237, 2, 50),
(102, 400, 830, 407, 2, 51),
(103, 390, 950, 856, 3, 1),
(104, 330, 680, 528, 3, 2),
(105, 230, 940, 292, 3, 3),
(106, 280, 910, 751, 3, 4),
(107, 300, 750, 408, 3, 5),
(108, 260, 990, 483, 3, 6),
(109, 330, 500, 496, 3, 7),
(110, 320, 700, 417, 3, 8),
(111, 250, 650, 468, 3, 9),
(112, 380, 1000, 843, 3, 10),
(113, 230, 970, 348, 3, 11),
(114, 370, 710, 631, 3, 12),
(115, 310, 430, 417, 3, 13),
(116, 280, 440, 356, 3, 14),
(117, 380, 930, 485, 3, 15),
(118, 210, 720, 277, 3, 16),
(119, 250, 840, 749, 3, 17),
(120, 370, 960, 756, 3, 18),
(121, 360, 960, 477, 3, 19),
(122, 310, 880, 463, 3, 20),
(123, 270, 750, 312, 3, 21),
(124, 390, 910, 720, 3, 22),
(125, 390, 710, 489, 3, 23),
(126, 320, 570, 504, 3, 24),
(127, 330, 410, 379, 3, 25),
(128, 350, 900, 583, 3, 26),
(129, 370, 600, 376, 3, 27),
(130, 370, 560, 495, 3, 28),
(131, 340, 630, 422, 3, 29),
(132, 270, 760, 353, 3, 30),
(133, 400, 540, 407, 3, 31),
(134, 400, 740, 503, 3, 32),
(135, 350, 780, 778, 3, 33),
(136, 330, 730, 464, 3, 34),
(137, 320, 590, 368, 3, 35),
(138, 390, 810, 622, 3, 36),
(139, 350, 570, 436, 3, 37),
(140, 200, 940, 814, 3, 38),
(141, 320, 670, 567, 3, 39),
(142, 330, 780, 446, 3, 40),
(143, 220, 950, 264, 3, 41),
(144, 220, 670, 431, 3, 42),
(145, 300, 720, 674, 3, 43),
(146, 380, 890, 654, 3, 44),
(147, 230, 750, 471, 3, 45),
(148, 250, 510, 428, 3, 46),
(149, 220, 420, 318, 3, 47),
(150, 230, 820, 465, 3, 48),
(151, 330, 630, 499, 3, 49),
(152, 240, 980, 632, 3, 50),
(153, 220, 700, 620, 3, 51),
(154, 270, 920, 548, 4, 1),
(155, 300, 760, 737, 4, 2),
(156, 400, 880, 532, 4, 3),
(157, 230, 560, 512, 4, 4),
(158, 320, 950, 451, 4, 5),
(159, 220, 810, 510, 4, 6),
(160, 320, 770, 621, 4, 7),
(161, 200, 460, 418, 4, 8),
(162, 310, 600, 510, 4, 9),
(163, 280, 920, 541, 4, 10),
(164, 380, 970, 748, 4, 11),
(165, 380, 810, 748, 4, 12),
(166, 220, 560, 539, 4, 13),
(167, 260, 660, 315, 4, 14),
(168, 350, 740, 442, 4, 15),
(169, 280, 600, 507, 4, 16),
(170, 280, 610, 317, 4, 17),
(171, 350, 590, 587, 4, 18),
(172, 360, 500, 409, 4, 19),
(173, 360, 510, 452, 4, 20),
(174, 230, 920, 479, 4, 21),
(175, 300, 860, 757, 4, 22),
(176, 260, 500, 455, 4, 23),
(177, 380, 1000, 468, 4, 24),
(178, 310, 790, 466, 4, 25),
(179, 380, 890, 385, 4, 26),
(180, 320, 880, 728, 4, 27),
(181, 260, 690, 487, 4, 28),
(182, 240, 430, 406, 4, 29),
(183, 380, 810, 540, 4, 30),
(184, 310, 660, 341, 4, 31),
(185, 210, 500, 464, 4, 32),
(186, 390, 870, 787, 4, 33),
(187, 310, 1000, 727, 4, 34),
(188, 300, 410, 312, 4, 35),
(189, 280, 770, 335, 4, 36),
(190, 390, 530, 416, 4, 37),
(191, 290, 670, 335, 4, 38),
(192, 260, 710, 276, 4, 39),
(193, 210, 610, 520, 4, 40),
(194, 360, 740, 516, 4, 41),
(195, 380, 880, 412, 4, 42),
(196, 340, 810, 769, 4, 43),
(197, 200, 710, 293, 4, 44),
(198, 340, 690, 563, 4, 45),
(199, 220, 710, 362, 4, 46),
(200, 320, 450, 431, 4, 47),
(201, 380, 850, 626, 4, 48),
(202, 280, 470, 469, 4, 49),
(203, 260, 540, 307, 4, 50),
(204, 390, 610, 517, 4, 51),
(205, 200, 880, 772, 5, 1),
(206, 280, 870, 467, 5, 2),
(207, 200, 850, 200, 5, 3),
(208, 280, 460, 371, 5, 4),
(209, 350, 580, 393, 5, 5),
(210, 350, 480, 438, 5, 6),
(211, 380, 940, 628, 5, 7),
(212, 360, 780, 433, 5, 8),
(213, 400, 780, 637, 5, 9),
(214, 360, 440, 368, 5, 10),
(215, 350, 680, 438, 5, 11),
(216, 370, 400, 371, 5, 12),
(217, 230, 860, 428, 5, 13),
(218, 310, 890, 728, 5, 14),
(219, 300, 950, 728, 5, 15),
(220, 380, 940, 650, 5, 16),
(221, 200, 730, 640, 5, 17),
(222, 270, 860, 347, 5, 18),
(223, 350, 710, 670, 5, 19),
(224, 380, 560, 487, 5, 20),
(225, 360, 650, 378, 5, 21),
(226, 350, 410, 408, 5, 22),
(227, 320, 480, 466, 5, 23),
(228, 210, 870, 243, 5, 24),
(229, 350, 400, 394, 5, 25),
(230, 370, 450, 449, 5, 26),
(231, 200, 560, 477, 5, 27),
(232, 390, 580, 424, 5, 28),
(233, 240, 990, 578, 5, 29),
(234, 260, 890, 618, 5, 30),
(235, 400, 420, 410, 5, 31),
(236, 370, 440, 406, 5, 32),
(237, 400, 690, 444, 5, 33),
(238, 380, 910, 632, 5, 34),
(239, 230, 950, 633, 5, 35),
(240, 240, 900, 597, 5, 36),
(241, 390, 640, 538, 5, 37),
(242, 280, 510, 452, 5, 38),
(243, 200, 640, 531, 5, 39),
(244, 340, 570, 388, 5, 40),
(245, 320, 470, 402, 5, 41),
(246, 380, 430, 403, 5, 42),
(247, 260, 750, 339, 5, 43),
(248, 310, 580, 566, 5, 44),
(249, 220, 580, 307, 5, 45),
(250, 270, 570, 289, 5, 46),
(251, 330, 550, 480, 5, 47),
(252, 310, 730, 664, 5, 48),
(253, 370, 920, 542, 5, 49),
(254, 320, 770, 347, 5, 50),
(255, 250, 930, 453, 5, 51),
(256, 200, 400, 300, 1, 52),
(257, 200, 400, 0, 5, 52),
(258, 100, 300, 200, 1, 54),
(259, 200, 500, 400, 5, 54);

-- --------------------------------------------------------

--
-- Tabellenstruktur für Tabelle `lager_lieferant`
--

CREATE TABLE `lager_lieferant` (
  `Lager_LieferID` int(11) NOT NULL,
  `LieferantID` int(11) NOT NULL,
  `LagerID` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Daten für Tabelle `lager_lieferant`
--

INSERT INTO `lager_lieferant` (`Lager_LieferID`, `LieferantID`, `LagerID`) VALUES
(1, 1, 1),
(2, 1, 2),
(3, 1, 3),
(4, 1, 4),
(5, 1, 5),
(6, 2, 1),
(7, 2, 2),
(8, 2, 3),
(9, 2, 4),
(10, 2, 5),
(11, 3, 1),
(12, 3, 2),
(13, 3, 3),
(14, 3, 4),
(15, 3, 5),
(16, 4, 1),
(17, 4, 2),
(18, 4, 3),
(19, 4, 4),
(20, 4, 5),
(21, 5, 1),
(22, 5, 2),
(23, 5, 3),
(24, 5, 4),
(25, 5, 5),
(26, 6, 1),
(27, 6, 2),
(28, 6, 3),
(29, 6, 4),
(30, 6, 5),
(31, 7, 1),
(32, 7, 2),
(33, 7, 3),
(34, 7, 4),
(35, 7, 5),
(36, 8, 1),
(37, 8, 2),
(38, 8, 3),
(39, 8, 4),
(40, 8, 5),
(41, 9, 1),
(42, 9, 2),
(43, 9, 3),
(44, 9, 4),
(45, 9, 5),
(46, 10, 1),
(47, 10, 2),
(48, 10, 3),
(49, 10, 4),
(50, 10, 5),
(51, 11, 1),
(52, 11, 2),
(53, 11, 3),
(54, 11, 4),
(55, 11, 5),
(56, 12, 1),
(57, 12, 2),
(58, 12, 3),
(59, 12, 4),
(60, 12, 5),
(61, 13, 1),
(62, 13, 2),
(63, 13, 3),
(64, 13, 4),
(65, 13, 5),
(66, 14, 1),
(67, 14, 2),
(68, 14, 3),
(69, 14, 4),
(70, 14, 5),
(71, 15, 1),
(72, 15, 2),
(73, 15, 3),
(74, 15, 4),
(75, 15, 5),
(76, 16, 1),
(77, 16, 2),
(78, 16, 3),
(79, 16, 4),
(80, 16, 5),
(81, 17, 1),
(82, 17, 2),
(83, 17, 3),
(84, 17, 4),
(85, 17, 5),
(86, 18, 1),
(87, 18, 2),
(88, 18, 3),
(89, 18, 4),
(90, 18, 5),
(91, 19, 1),
(92, 19, 2),
(93, 19, 3),
(94, 19, 4),
(95, 19, 5),
(96, 20, 1),
(97, 20, 2),
(98, 20, 3),
(99, 20, 4),
(100, 20, 5),
(101, 21, 1),
(102, 21, 2),
(103, 21, 3),
(104, 21, 4),
(105, 21, 5),
(106, 22, 1),
(107, 22, 2),
(108, 22, 3),
(109, 22, 4),
(110, 22, 5),
(111, 23, 1),
(112, 23, 2),
(113, 23, 3),
(114, 23, 4),
(115, 23, 5),
(116, 24, 1),
(117, 24, 2),
(118, 24, 3),
(119, 24, 4),
(120, 24, 5),
(121, 25, 1),
(122, 25, 2),
(123, 25, 3),
(124, 25, 4),
(125, 25, 5),
(126, 26, 1),
(127, 26, 2),
(128, 26, 3),
(129, 26, 4),
(130, 26, 5),
(131, 27, 1),
(132, 27, 2),
(133, 27, 3),
(134, 27, 4),
(135, 27, 5),
(136, 28, 1),
(137, 28, 2),
(138, 28, 3),
(139, 28, 4),
(140, 28, 5),
(141, 29, 1),
(142, 29, 2),
(143, 29, 3),
(144, 29, 4),
(145, 29, 5),
(146, 30, 1),
(147, 30, 2),
(148, 30, 3),
(149, 30, 4),
(150, 30, 5),
(151, 31, 1),
(152, 31, 2),
(153, 31, 3),
(154, 31, 4),
(155, 31, 5),
(156, 32, 1),
(157, 32, 2),
(158, 32, 3),
(159, 32, 4),
(160, 32, 5),
(161, 33, 1),
(162, 33, 2),
(163, 33, 3),
(164, 33, 4),
(165, 33, 5),
(166, 34, 1),
(167, 34, 2),
(168, 34, 3),
(169, 34, 4),
(170, 34, 5),
(171, 35, 1),
(172, 35, 2),
(173, 35, 3),
(174, 35, 4),
(175, 35, 5),
(176, 36, 1),
(177, 36, 2),
(178, 36, 3),
(179, 36, 4),
(180, 36, 5),
(181, 37, 1),
(182, 37, 2),
(183, 37, 3),
(184, 37, 4),
(185, 37, 5),
(186, 38, 1),
(187, 38, 2),
(188, 38, 3),
(189, 38, 4),
(190, 38, 5),
(191, 39, 1),
(192, 39, 2),
(193, 39, 3),
(194, 39, 4),
(195, 39, 5),
(196, 40, 1),
(197, 40, 2),
(198, 40, 3),
(199, 40, 4),
(200, 40, 5),
(201, 41, 1),
(202, 41, 2),
(203, 41, 3),
(204, 41, 4),
(205, 41, 5),
(206, 42, 1),
(207, 42, 2),
(208, 42, 3),
(209, 42, 4),
(210, 42, 5),
(211, 43, 1),
(212, 43, 2),
(213, 43, 3),
(214, 43, 4),
(215, 43, 5),
(216, 44, 1),
(217, 44, 2),
(218, 44, 3),
(219, 44, 4),
(220, 44, 5),
(221, 45, 1),
(222, 45, 2),
(223, 45, 3),
(224, 45, 4),
(225, 45, 5),
(226, 46, 1),
(227, 46, 2),
(228, 46, 3),
(229, 46, 4),
(230, 46, 5),
(231, 47, 1),
(232, 47, 2),
(233, 47, 3),
(234, 47, 4),
(235, 47, 5),
(236, 48, 1),
(237, 48, 2),
(238, 48, 3),
(239, 48, 4),
(240, 48, 5),
(241, 49, 1),
(242, 49, 2),
(243, 49, 3),
(244, 49, 4),
(245, 49, 5),
(246, 50, 1),
(247, 50, 2),
(248, 50, 3),
(249, 50, 4),
(250, 50, 5),
(251, 51, 1),
(252, 51, 2),
(253, 51, 3),
(254, 51, 4),
(255, 51, 5),
(256, 52, 1),
(257, 52, 2),
(258, 52, 3),
(259, 52, 4),
(260, 52, 5),
(261, 53, 1),
(262, 53, 2),
(263, 53, 3),
(264, 53, 4),
(265, 53, 5),
(266, 54, 1),
(267, 54, 2),
(268, 54, 3),
(269, 54, 4),
(270, 54, 5),
(271, 55, 1),
(272, 55, 2),
(273, 55, 3),
(274, 55, 4),
(275, 55, 5),
(276, 56, 1),
(277, 56, 2),
(278, 56, 3),
(279, 56, 4),
(280, 56, 5),
(281, 57, 1),
(282, 57, 2),
(283, 57, 3),
(284, 57, 4),
(285, 57, 5),
(286, 58, 1),
(287, 58, 2),
(288, 58, 3),
(289, 58, 4),
(290, 58, 5),
(291, 59, 1),
(292, 59, 2),
(293, 59, 3),
(294, 59, 4),
(295, 59, 5),
(296, 60, 1),
(297, 60, 2),
(298, 60, 3),
(299, 60, 4),
(300, 60, 5),
(301, 61, 1),
(302, 61, 2),
(303, 61, 3),
(304, 61, 4),
(305, 61, 5),
(306, 62, 1),
(307, 62, 2),
(308, 62, 3),
(309, 62, 4),
(310, 62, 5),
(311, 63, 1),
(312, 63, 2),
(313, 63, 3),
(314, 63, 4),
(315, 63, 5),
(316, 64, 1),
(317, 64, 2),
(318, 64, 3),
(319, 64, 4),
(320, 64, 5),
(321, 65, 1),
(322, 65, 2),
(323, 65, 3),
(324, 65, 4),
(325, 65, 5),
(326, 66, 1),
(327, 66, 2),
(328, 66, 3),
(329, 66, 4),
(330, 66, 5),
(331, 67, 1),
(332, 67, 2),
(333, 67, 3),
(334, 67, 4),
(335, 67, 5),
(336, 68, 1),
(337, 68, 2),
(338, 68, 3),
(339, 68, 4),
(340, 68, 5),
(341, 69, 1),
(342, 69, 2),
(343, 69, 3),
(344, 69, 4),
(345, 69, 5),
(346, 70, 1),
(347, 70, 2),
(348, 70, 3),
(349, 70, 4),
(350, 70, 5),
(351, 71, 1),
(352, 71, 2),
(353, 71, 3),
(354, 71, 4),
(355, 71, 5),
(356, 72, 1),
(357, 72, 2),
(358, 72, 3),
(359, 72, 4),
(360, 72, 5),
(361, 73, 1),
(362, 73, 2),
(363, 73, 3),
(364, 73, 4),
(365, 73, 5),
(366, 74, 1),
(367, 74, 2),
(368, 74, 3),
(369, 74, 4),
(370, 74, 5),
(371, 75, 1),
(372, 75, 2),
(373, 75, 3),
(374, 75, 4),
(375, 75, 5),
(376, 76, 1),
(377, 76, 2),
(378, 78, 1);

-- --------------------------------------------------------

--
-- Tabellenstruktur für Tabelle `lieferant`
--

CREATE TABLE `lieferant` (
  `LieferantID` int(11) NOT NULL,
  `LieferantName` varchar(50) NOT NULL,
  `LetzteLieferung` date NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Daten für Tabelle `lieferant`
--

INSERT INTO `lieferant` (`LieferantID`, `LieferantName`, `LetzteLieferung`) VALUES
(1, 'Elite Distribution', '2023-07-05'),
(2, 'Elite Exports', '2023-05-16'),
(3, 'Elite Imports', '2023-04-24'),
(4, 'Elite Industries', '2023-06-02'),
(5, 'Elite Logistics', '2022-05-07'),
(6, 'Elite Supply', '2022-12-29'),
(7, 'Elite Trading', '2022-03-29'),
(8, 'Express Distribution', '2022-07-03'),
(9, 'Express Exports', '2021-11-22'),
(10, 'Express Group', '2023-05-01'),
(11, 'Express Imports', '2022-03-04'),
(12, 'Express Industries', '2023-04-02'),
(13, 'Express Logistics', '2022-02-10'),
(14, 'Express Services', '2021-12-15'),
(15, 'Express Solutions', '2022-01-21'),
(16, 'Express Supply', '2023-06-11'),
(17, 'Express Trading', '2021-11-17'),
(18, 'Global Distribution', '2022-04-04'),
(19, 'Global Exports', '2022-06-23'),
(20, 'Global Group', '2021-12-31'),
(21, 'Global Imports', '2021-09-05'),
(22, 'Global Industries', '2022-03-25'),
(23, 'Global Logistics', '2023-02-25'),
(24, 'Global Services', '2022-11-20'),
(25, 'Global Solutions', '2023-02-04'),
(26, 'Global Trading', '2023-06-13'),
(27, 'International Distribution', '2022-12-26'),
(28, 'International Group', '2022-07-14'),
(29, 'International Industries', '2021-12-15'),
(30, 'International Logistics', '2021-09-24'),
(31, 'International Services', '2021-11-13'),
(32, 'International Solutions', '2022-07-16'),
(33, 'International Supply', '2023-01-21'),
(34, 'International Trading', '2021-11-15'),
(35, 'Local Distribution', '2022-03-16'),
(36, 'Local Exports', '2022-12-21'),
(37, 'Local Imports', '2023-07-04'),
(38, 'Local Industries', '2022-11-24'),
(39, 'Local Logistics', '2021-09-19'),
(40, 'Local Services', '2022-07-17'),
(41, 'Local Solutions', '2023-04-04'),
(42, 'Local Supply', '2023-02-16'),
(43, 'Local Trading', '2023-03-17'),
(44, 'National Group', '2021-09-28'),
(45, 'National Imports', '2022-10-15'),
(46, 'National Logistics', '2021-11-25'),
(47, 'National Solutions', '2021-11-27'),
(48, 'National Supply', '2021-08-18'),
(49, 'National Trading', '2022-03-10'),
(50, 'Premium Distribution', '2022-12-09'),
(51, 'Premium Group', '2022-06-26'),
(52, 'Premium Imports', '2021-12-11'),
(53, 'Premium Industries', '2022-06-28'),
(54, 'Premium Services', '2023-02-05'),
(55, 'Premium Supply', '2021-10-16'),
(56, 'Prime Distribution', '2022-05-29'),
(57, 'Prime Group', '2021-10-03'),
(58, 'Prime Imports', '2022-03-13'),
(59, 'Prime Logistics', '2022-03-24'),
(60, 'Prime Services', '2021-12-13'),
(61, 'Prime Supply', '2023-04-23'),
(62, 'Prime Trading', '2022-08-23'),
(63, 'Pro Group', '2021-12-04'),
(64, 'Pro Imports', '2022-10-23'),
(65, 'Pro Industries', '2023-02-13'),
(66, 'Pro Services', '2021-07-30'),
(67, 'Pro Solutions', '2023-04-01'),
(68, 'Regional Exports', '2022-07-28'),
(69, 'Regional Imports', '2021-07-02'),
(70, 'Regional Industries', '2022-04-27'),
(71, 'Regional Logistics', '2023-06-14'),
(72, 'Regional Services', '2022-09-24'),
(73, 'Regional Solutions', '2021-10-12'),
(74, 'Regional Supply', '2022-08-18'),
(75, 'Regional Trading', '2023-05-18'),
(76, 'Hermes', '2023-07-03'),
(77, 'Amazon', '2023-07-03'),
(78, 'Super Transports', '2023-07-04');

-- --------------------------------------------------------

--
-- Tabellenstruktur für Tabelle `lieferdetails`
--

CREATE TABLE `lieferdetails` (
  `LieferdetailsID` int(11) NOT NULL,
  `Anzahl` int(11) NOT NULL,
  `Stueckpreis` decimal(8,2) NOT NULL,
  `Lager_LieferID` int(11) NOT NULL,
  `EinzelteileID` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Daten für Tabelle `lieferdetails`
--

INSERT INTO `lieferdetails` (`LieferdetailsID`, `Anzahl`, `Stueckpreis`, `Lager_LieferID`, `EinzelteileID`) VALUES
(1, 87, 4.77, 4, 31),
(2, 129, 1.09, 8, 45),
(3, 67, 4.77, 11, 2),
(4, 100, 1.05, 17, 44),
(5, 59, 1.88, 22, 24),
(6, 25, 2.92, 27, 21),
(7, 75, 0.74, 31, 46),
(8, 12, 1.33, 38, 11),
(9, 28, 4.69, 43, 37),
(10, 65, 2.02, 46, 12),
(11, 61, 2.22, 55, 27),
(12, 69, 4.00, 56, 18),
(13, 113, 1.21, 63, 6),
(14, 115, 2.61, 67, 21),
(15, 139, 3.24, 71, 26),
(16, 113, 3.19, 76, 29),
(17, 150, 1.19, 81, 1),
(18, 64, 1.23, 90, 32),
(19, 81, 1.29, 92, 45),
(20, 109, 0.51, 96, 5),
(21, 127, 3.75, 102, 9),
(22, 75, 3.62, 110, 42),
(23, 84, 2.35, 114, 31),
(24, 118, 3.82, 117, 22),
(25, 105, 0.72, 122, 48),
(26, 128, 1.62, 126, 29),
(27, 119, 2.09, 133, 23),
(28, 24, 3.60, 138, 46),
(29, 77, 0.65, 144, 9),
(30, 181, 0.51, 148, 47),
(31, 152, 3.54, 152, 49),
(32, 93, 2.28, 159, 40),
(33, 33, 1.15, 165, 18),
(34, 145, 4.49, 170, 44),
(35, 181, 2.68, 171, 34),
(36, 63, 3.00, 180, 4),
(37, 33, 3.28, 183, 2),
(38, 87, 3.39, 188, 8),
(39, 48, 0.79, 191, 22),
(40, 150, 4.21, 196, 16),
(41, 154, 3.80, 202, 10),
(42, 31, 1.02, 207, 44),
(43, 174, 1.18, 211, 44),
(44, 141, 4.96, 220, 11),
(45, 107, 4.71, 223, 50),
(46, 37, 1.82, 230, 13),
(47, 188, 4.84, 234, 29),
(48, 26, 1.51, 236, 17),
(49, 146, 2.43, 245, 38),
(50, 96, 1.37, 246, 23),
(51, 163, 2.37, 252, 8),
(52, 77, 1.89, 260, 23),
(53, 186, 1.42, 262, 15),
(54, 180, 1.61, 268, 49),
(55, 127, 4.01, 272, 32),
(56, 83, 3.79, 279, 45),
(57, 131, 0.63, 281, 8),
(58, 113, 2.65, 288, 16),
(59, 112, 1.55, 291, 18),
(60, 151, 2.87, 300, 33),
(61, 159, 4.91, 303, 47),
(62, 186, 2.59, 307, 25),
(63, 26, 4.00, 312, 33),
(64, 127, 1.63, 318, 14),
(65, 50, 4.06, 322, 46),
(66, 105, 3.07, 327, 39),
(67, 13, 4.38, 334, 15),
(68, 58, 3.28, 337, 5),
(69, 197, 3.89, 342, 5),
(70, 45, 2.36, 347, 31),
(71, 110, 0.55, 355, 6),
(72, 162, 0.85, 357, 47),
(73, 191, 4.86, 364, 28),
(74, 39, 3.76, 368, 18),
(75, 121, 4.54, 373, 28),
(76, 142, 7.36, 258, 35),
(77, 184, 4.60, 256, 18),
(78, 42, 7.96, 4, 4),
(79, 97, 3.70, 253, 2),
(80, 72, 1.20, 169, 20),
(81, 145, 8.89, 110, 43),
(82, 44, 2.94, 312, 46),
(83, 194, 8.44, 320, 16),
(84, 41, 9.81, 29, 9),
(85, 175, 4.63, 219, 31),
(86, 159, 1.28, 147, 49),
(87, 57, 2.75, 235, 25),
(88, 62, 5.55, 173, 44),
(89, 45, 9.44, 28, 8),
(90, 30, 7.51, 283, 29),
(91, 195, 8.65, 33, 2),
(92, 154, 6.73, 250, 38),
(93, 98, 6.23, 329, 16),
(94, 98, 4.03, 296, 49),
(95, 27, 6.57, 312, 10),
(96, 162, 1.43, 19, 35),
(97, 141, 1.77, 318, 3),
(98, 85, 4.08, 182, 13),
(99, 75, 7.25, 194, 3),
(100, 138, 7.19, 288, 51),
(101, 165, 8.87, 93, 44),
(102, 95, 9.54, 15, 45),
(103, 50, 5.41, 258, 22),
(104, 152, 5.91, 56, 21),
(105, 145, 1.28, 235, 7),
(106, 28, 2.80, 212, 14),
(107, 89, 9.68, 187, 35),
(108, 24, 3.82, 94, 48),
(109, 52, 8.78, 76, 9),
(110, 191, 8.58, 281, 13),
(111, 45, 6.03, 102, 38),
(112, 128, 9.23, 133, 3),
(113, 190, 4.21, 217, 37),
(114, 135, 4.92, 283, 44),
(115, 97, 5.61, 272, 4),
(116, 188, 2.50, 222, 11),
(117, 92, 3.61, 279, 38),
(118, 23, 1.92, 216, 33),
(119, 123, 4.27, 159, 10),
(120, 145, 5.27, 229, 12),
(121, 126, 4.04, 273, 21),
(122, 46, 9.79, 282, 48),
(123, 24, 2.82, 274, 49),
(124, 186, 7.32, 99, 20),
(125, 33, 3.74, 247, 38),
(126, 174, 2.42, 145, 26),
(127, 86, 1.12, 66, 36),
(128, 96, 4.95, 29, 29),
(129, 136, 8.41, 206, 34),
(130, 145, 4.02, 109, 19),
(131, 105, 8.40, 21, 29),
(132, 62, 8.89, 294, 8),
(133, 106, 7.03, 113, 11),
(134, 58, 1.21, 81, 30),
(135, 19, 9.81, 99, 27),
(136, 27, 6.96, 241, 3),
(137, 186, 7.21, 240, 22),
(138, 113, 3.45, 48, 3),
(139, 81, 0.99, 71, 46),
(140, 60, 4.87, 329, 26),
(141, 179, 8.12, 265, 16),
(142, 146, 3.75, 104, 32),
(143, 34, 8.51, 83, 27),
(144, 140, 2.26, 187, 30),
(145, 171, 9.74, 84, 7),
(146, 98, 9.81, 280, 6),
(147, 132, 6.59, 61, 28),
(148, 68, 2.51, 86, 15),
(149, 111, 5.04, 59, 38),
(150, 13, 5.57, 112, 23),
(151, 56, 1.32, 140, 26),
(152, 199, 3.55, 339, 31),
(153, 14, 0.58, 350, 21),
(154, 180, 9.12, 235, 8),
(155, 190, 1.84, 338, 21),
(156, 63, 7.46, 112, 11),
(157, 87, 9.74, 12, 40),
(158, 94, 1.98, 250, 33),
(159, 136, 3.78, 43, 43),
(160, 149, 7.10, 304, 30),
(161, 11, 3.46, 149, 1),
(162, 65, 0.89, 357, 23),
(163, 71, 3.51, 260, 4),
(164, 20, 6.95, 242, 51),
(165, 28, 8.02, 350, 15),
(166, 133, 9.54, 72, 22),
(167, 83, 3.30, 342, 1),
(168, 84, 3.23, 104, 12),
(169, 116, 1.07, 285, 35),
(170, 137, 3.02, 183, 18),
(171, 18, 3.88, 154, 17),
(172, 117, 7.64, 277, 32),
(173, 94, 4.71, 114, 11),
(174, 193, 8.50, 27, 37),
(175, 122, 6.77, 29, 15),
(176, 39, 6.18, 4, 42),
(177, 117, 8.17, 269, 6),
(178, 29, 6.07, 69, 27),
(179, 77, 2.27, 239, 20),
(180, 148, 8.12, 63, 7),
(181, 93, 8.91, 224, 42),
(182, 30, 5.78, 98, 17),
(183, 129, 3.60, 197, 10),
(184, 59, 3.28, 104, 46),
(185, 134, 0.83, 119, 2),
(186, 175, 3.91, 49, 34),
(187, 92, 2.12, 237, 49),
(188, 27, 5.60, 168, 36),
(189, 59, 5.24, 375, 39),
(190, 153, 5.65, 24, 30),
(191, 64, 8.50, 40, 30),
(192, 36, 6.74, 259, 7),
(193, 68, 0.68, 172, 3),
(194, 135, 5.06, 136, 30),
(195, 94, 1.51, 263, 28),
(196, 80, 4.10, 359, 42),
(197, 47, 3.52, 212, 37),
(198, 39, 1.13, 341, 47),
(199, 135, 8.64, 244, 44),
(200, 31, 1.00, 190, 9),
(201, 137, 5.36, 273, 40),
(202, 100, 7.49, 106, 44),
(203, 186, 1.52, 344, 19),
(204, 99, 4.35, 255, 11),
(205, 186, 2.43, 174, 1),
(206, 74, 9.54, 100, 30),
(207, 91, 7.59, 17, 51),
(208, 156, 3.60, 190, 42),
(209, 27, 1.69, 212, 24),
(210, 192, 7.41, 100, 51),
(211, 182, 7.60, 375, 49),
(212, 87, 9.56, 51, 21),
(213, 165, 7.67, 169, 34),
(214, 151, 9.33, 217, 18),
(215, 124, 9.41, 304, 19),
(216, 98, 4.52, 49, 14),
(217, 175, 1.76, 313, 35),
(218, 10, 8.78, 7, 11),
(219, 177, 2.62, 113, 47),
(220, 90, 1.20, 366, 40),
(221, 181, 3.95, 182, 20),
(222, 191, 0.66, 209, 8),
(223, 197, 6.92, 339, 17),
(224, 16, 2.36, 49, 45),
(225, 58, 1.80, 210, 23),
(226, 84, 1.88, 162, 21),
(227, 58, 7.81, 229, 14),
(228, 28, 1.89, 231, 24),
(229, 190, 8.77, 175, 31),
(230, 111, 2.44, 30, 4),
(231, 85, 9.66, 231, 7),
(232, 40, 6.84, 272, 3),
(233, 110, 3.89, 140, 1),
(234, 18, 3.23, 54, 47),
(235, 171, 5.12, 6, 34),
(236, 119, 5.91, 150, 18),
(237, 114, 6.65, 283, 9),
(238, 115, 5.09, 98, 42),
(239, 76, 4.47, 246, 15),
(240, 151, 5.93, 327, 43),
(241, 198, 1.34, 254, 44),
(242, 136, 6.51, 364, 29),
(243, 146, 2.07, 305, 34),
(244, 36, 3.08, 89, 35),
(245, 30, 2.40, 360, 6),
(246, 108, 7.93, 314, 13),
(247, 17, 5.49, 258, 11),
(248, 13, 9.77, 44, 16),
(249, 80, 4.99, 157, 20),
(250, 17, 5.06, 241, 31),
(251, 50, 5.61, 22, 51),
(252, 22, 6.07, 131, 9),
(253, 163, 0.55, 2, 43),
(254, 126, 5.96, 46, 39),
(255, 16, 6.31, 102, 6),
(256, 129, 9.72, 280, 15),
(257, 199, 6.55, 45, 33),
(258, 56, 2.50, 314, 34),
(259, 194, 6.32, 244, 19),
(260, 34, 4.58, 375, 1),
(261, 114, 4.89, 316, 10),
(262, 135, 4.15, 124, 7),
(263, 157, 3.83, 95, 8),
(264, 87, 9.01, 35, 40),
(265, 189, 7.03, 279, 2),
(266, 82, 8.96, 338, 46),
(267, 132, 2.10, 236, 22),
(268, 63, 8.14, 321, 33),
(269, 74, 2.90, 14, 34),
(270, 47, 8.53, 209, 38),
(271, 154, 1.04, 349, 28),
(272, 40, 6.90, 126, 13),
(273, 104, 1.27, 198, 38),
(274, 130, 7.16, 284, 3),
(275, 126, 1.02, 9, 43),
(276, 99, 3.38, 364, 40),
(277, 127, 3.56, 143, 17),
(278, 198, 5.97, 148, 33),
(279, 187, 1.69, 223, 16),
(280, 153, 3.96, 232, 39),
(281, 105, 7.25, 41, 42),
(282, 77, 1.93, 120, 2),
(283, 138, 7.47, 1, 29),
(284, 57, 7.17, 171, 16),
(285, 120, 1.84, 67, 33),
(286, 146, 0.87, 245, 7),
(287, 160, 2.40, 172, 36),
(288, 123, 3.21, 281, 33),
(289, 172, 1.61, 328, 6),
(290, 95, 9.03, 175, 21),
(291, 187, 4.04, 192, 33),
(292, 66, 1.75, 290, 20),
(293, 11, 4.43, 293, 5),
(294, 40, 4.92, 127, 10),
(295, 176, 4.05, 62, 37),
(296, 71, 1.16, 161, 15),
(297, 190, 1.89, 358, 23),
(298, 16, 9.65, 26, 27),
(299, 78, 2.04, 231, 19),
(300, 150, 5.96, 187, 22),
(301, 186, 2.85, 17, 27),
(302, 168, 1.72, 201, 38),
(303, 45, 4.64, 274, 29),
(304, 88, 6.70, 130, 25),
(305, 91, 0.69, 277, 33),
(306, 146, 5.76, 30, 33),
(307, 56, 8.32, 248, 9),
(308, 142, 5.06, 228, 30),
(309, 51, 1.28, 160, 5),
(310, 141, 6.37, 243, 6),
(311, 195, 6.18, 361, 33),
(312, 24, 5.72, 147, 7),
(313, 60, 2.12, 117, 27),
(314, 78, 3.13, 232, 47),
(315, 167, 6.42, 279, 38),
(316, 34, 5.50, 164, 41),
(317, 172, 9.01, 303, 28),
(318, 53, 7.23, 212, 28),
(319, 189, 3.58, 72, 29),
(320, 140, 7.48, 255, 5),
(321, 148, 7.46, 161, 35),
(322, 182, 9.20, 62, 13),
(323, 26, 1.51, 362, 24),
(324, 92, 5.13, 149, 24),
(325, 19, 0.99, 280, 45),
(326, 186, 9.11, 219, 1),
(327, 177, 3.29, 176, 7),
(328, 102, 5.39, 55, 43),
(329, 11, 5.59, 63, 24),
(330, 43, 8.48, 236, 25),
(331, 48, 9.51, 266, 19),
(332, 146, 6.51, 133, 23),
(333, 86, 5.25, 220, 15),
(334, 75, 9.53, 216, 19),
(335, 33, 9.03, 192, 6),
(336, 23, 6.67, 318, 43),
(337, 16, 4.50, 176, 43),
(338, 117, 0.54, 308, 5),
(339, 51, 3.27, 164, 39),
(340, 163, 2.40, 129, 39),
(341, 177, 3.35, 85, 34),
(342, 150, 4.53, 134, 6),
(343, 42, 5.00, 261, 49),
(344, 106, 8.83, 148, 45),
(345, 139, 1.93, 147, 27),
(346, 80, 9.63, 63, 29),
(347, 132, 0.51, 184, 45),
(348, 158, 4.79, 239, 2),
(349, 110, 5.40, 241, 35),
(350, 162, 2.84, 128, 23),
(351, 14, 2.26, 243, 10),
(352, 106, 5.65, 311, 12),
(353, 35, 1.23, 55, 13),
(354, 100, 5.70, 83, 21),
(355, 170, 1.17, 85, 5),
(356, 199, 9.57, 62, 33),
(357, 143, 5.01, 103, 19),
(358, 12, 8.60, 261, 15),
(359, 27, 1.65, 247, 15),
(360, 96, 4.77, 319, 40),
(361, 173, 8.19, 313, 8),
(362, 167, 7.34, 263, 41),
(363, 135, 5.50, 64, 39),
(364, 142, 2.76, 130, 7),
(365, 140, 6.76, 289, 44),
(366, 161, 5.22, 85, 20),
(367, 198, 0.97, 206, 48),
(368, 71, 4.42, 75, 19),
(369, 153, 6.04, 43, 36),
(370, 182, 3.27, 213, 23),
(371, 153, 1.47, 197, 22),
(372, 118, 1.40, 125, 17),
(373, 131, 7.90, 289, 39),
(374, 87, 8.65, 229, 24),
(375, 196, 5.93, 353, 30),
(376, 22, 7.02, 331, 28),
(377, 88, 1.09, 369, 40),
(378, 181, 1.16, 344, 36),
(379, 160, 8.16, 109, 50),
(380, 65, 9.92, 348, 11),
(381, 56, 7.88, 55, 19),
(382, 10, 2.36, 305, 36),
(383, 144, 7.57, 209, 46),
(384, 114, 7.46, 186, 45),
(385, 196, 3.05, 233, 40),
(386, 110, 2.49, 82, 23),
(387, 113, 4.15, 6, 17),
(388, 176, 4.53, 68, 23),
(389, 157, 4.87, 128, 42),
(390, 57, 7.49, 50, 13),
(391, 77, 5.16, 37, 30),
(392, 195, 9.31, 322, 24),
(393, 166, 2.81, 272, 30),
(394, 90, 1.29, 151, 2),
(395, 45, 6.68, 18, 13),
(396, 91, 4.01, 174, 30),
(397, 94, 3.80, 164, 42),
(398, 74, 9.52, 187, 40),
(399, 23, 8.33, 334, 29),
(400, 58, 9.28, 187, 49),
(401, 20, 100.00, 376, 52),
(402, 10, 50.00, 376, 52),
(403, 200, 10.00, 378, 54),
(404, 400, 8.00, 5, 54),
(405, 87, 20.00, 182, 2);

-- --------------------------------------------------------

--
-- Tabellenstruktur für Tabelle `lieferung`
--

CREATE TABLE `lieferung` (
  `LieferungID` int(11) NOT NULL,
  `LieferDatum` date NOT NULL,
  `GesamtPreis` decimal(8,2) NOT NULL,
  `LieferdetailsID` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Daten für Tabelle `lieferung`
--

INSERT INTO `lieferung` (`LieferungID`, `LieferDatum`, `GesamtPreis`, `LieferdetailsID`) VALUES
(1, '2023-05-26', 414.99, 1),
(2, '2023-05-22', 140.61, 2),
(3, '2023-06-03', 319.59, 3),
(4, '2023-06-05', 105.00, 4),
(5, '2023-06-01', 110.92, 5),
(6, '2023-05-06', 73.00, 6),
(7, '2023-05-28', 55.50, 7),
(8, '2023-05-17', 15.96, 8),
(9, '2023-06-07', 131.32, 9),
(10, '2023-06-18', 131.30, 10),
(11, '2023-06-23', 135.42, 11),
(12, '2023-05-05', 276.00, 12),
(13, '2023-06-23', 136.73, 13),
(14, '2023-05-08', 300.15, 14),
(15, '2023-06-09', 450.36, 15),
(16, '2023-05-20', 360.47, 16),
(17, '2023-06-10', 178.50, 17),
(18, '2023-05-30', 78.72, 18),
(19, '2023-06-08', 104.49, 19),
(20, '2023-05-17', 55.59, 20),
(21, '2023-05-04', 476.25, 21),
(22, '2023-06-14', 271.50, 22),
(23, '2023-06-21', 197.40, 23),
(24, '2023-06-21', 450.76, 24),
(25, '2023-05-31', 75.60, 25),
(26, '2023-05-07', 207.36, 26),
(27, '2023-06-13', 248.71, 27),
(28, '2023-06-02', 86.40, 28),
(29, '2023-04-30', 50.05, 29),
(30, '2023-05-18', 92.31, 30),
(31, '2023-05-11', 538.08, 31),
(32, '2023-06-01', 212.04, 32),
(33, '2023-06-02', 37.95, 33),
(34, '2023-05-20', 651.05, 34),
(35, '2023-05-29', 485.08, 35),
(36, '2023-05-16', 189.00, 36),
(37, '2023-05-25', 108.24, 37),
(38, '2023-05-20', 294.93, 38),
(39, '2023-05-22', 37.92, 39),
(40, '2023-06-09', 631.50, 40),
(41, '2023-06-05', 585.20, 41),
(42, '2023-05-30', 31.62, 42),
(43, '2023-06-22', 205.32, 43),
(44, '2023-05-13', 699.36, 44),
(45, '2023-06-09', 503.97, 45),
(46, '2023-05-03', 67.34, 46),
(47, '2023-05-28', 909.92, 47),
(48, '2023-06-21', 39.26, 48),
(49, '2023-05-06', 354.78, 49),
(50, '2023-06-03', 131.52, 50),
(51, '2023-05-31', 386.31, 51),
(52, '2023-06-09', 145.53, 52),
(53, '2023-06-09', 264.12, 53),
(54, '2023-06-16', 289.80, 54),
(55, '2023-05-11', 509.27, 55),
(56, '2023-05-24', 314.57, 56),
(57, '2023-05-25', 82.53, 57),
(58, '2023-05-27', 299.45, 58),
(59, '2023-05-30', 173.60, 59),
(60, '2023-06-02', 433.37, 60),
(61, '2023-06-09', 780.69, 61),
(62, '2023-05-20', 481.74, 62),
(63, '2023-04-30', 104.00, 63),
(64, '2023-05-23', 207.01, 64),
(65, '2023-06-07', 203.00, 65),
(66, '2023-06-03', 322.35, 66),
(67, '2023-06-23', 56.94, 67),
(68, '2023-06-25', 190.24, 68),
(69, '2023-05-17', 766.33, 69),
(70, '2023-05-18', 106.20, 70),
(71, '2023-05-27', 60.50, 71),
(72, '2023-04-30', 137.70, 72),
(73, '2023-05-17', 928.26, 73),
(74, '2023-04-30', 146.64, 74),
(75, '2023-06-20', 549.34, 75),
(76, '2021-08-19', 1045.12, 76),
(77, '2022-10-28', 846.40, 77),
(78, '2022-11-18', 334.32, 78),
(79, '2022-12-30', 358.90, 79),
(80, '2022-10-08', 86.40, 80),
(81, '2021-10-04', 1289.05, 81),
(82, '2022-06-09', 129.36, 82),
(83, '2022-05-07', 1637.36, 83),
(84, '2023-02-02', 402.21, 84),
(85, '2021-11-28', 810.25, 85),
(86, '2022-10-06', 203.52, 86),
(87, '2023-04-15', 156.75, 87),
(88, '2021-07-14', 344.10, 88),
(89, '2022-07-22', 424.80, 89),
(90, '2022-02-11', 225.30, 90),
(91, '2022-01-03', 1686.75, 91),
(92, '2022-10-21', 1036.42, 92),
(93, '2023-01-08', 610.54, 93),
(94, '2023-04-13', 394.94, 94),
(95, '2023-04-03', 177.39, 95),
(96, '2022-02-05', 231.66, 96),
(97, '2023-02-06', 249.57, 97),
(98, '2021-11-05', 346.80, 98),
(99, '2022-09-03', 543.75, 99),
(100, '2021-07-21', 992.22, 100),
(101, '2022-10-24', 1463.55, 101),
(102, '2023-03-03', 906.30, 102),
(103, '2023-03-27', 270.50, 103),
(104, '2023-02-08', 898.32, 104),
(105, '2021-09-25', 185.60, 105),
(106, '2023-03-01', 78.40, 106),
(107, '2021-12-28', 861.52, 107),
(108, '2022-02-07', 91.68, 108),
(109, '2022-09-15', 456.56, 109),
(110, '2021-08-24', 1638.78, 110),
(111, '2023-04-10', 271.35, 111),
(112, '2022-07-22', 1181.44, 112),
(113, '2021-08-23', 799.90, 113),
(114, '2022-08-26', 664.20, 114),
(115, '2022-08-13', 544.17, 115),
(116, '2021-08-07', 470.00, 116),
(117, '2022-12-15', 332.12, 117),
(118, '2021-11-05', 44.16, 118),
(119, '2022-05-09', 525.21, 119),
(120, '2021-11-12', 764.15, 120),
(121, '2022-10-07', 509.04, 121),
(122, '2021-10-04', 450.34, 122),
(123, '2022-09-18', 67.68, 123),
(124, '2023-02-24', 1361.52, 124),
(125, '2023-04-19', 123.42, 125),
(126, '2021-09-06', 421.08, 126),
(127, '2022-08-21', 96.32, 127),
(128, '2022-03-19', 475.20, 128),
(129, '2023-04-24', 1143.76, 129),
(130, '2022-11-16', 582.90, 130),
(131, '2022-08-29', 882.00, 131),
(132, '2022-10-31', 551.18, 132),
(133, '2022-01-06', 745.18, 133),
(134, '2022-07-20', 70.18, 134),
(135, '2022-07-13', 186.39, 135),
(136, '2022-02-05', 187.92, 136),
(137, '2022-07-04', 1341.06, 137),
(138, '2022-06-21', 389.85, 138),
(139, '2022-02-11', 80.19, 139),
(140, '2022-09-12', 292.20, 140),
(141, '2023-03-02', 1453.48, 141),
(142, '2022-03-27', 547.50, 142),
(143, '2023-02-26', 289.34, 143),
(144, '2022-04-12', 316.40, 144),
(145, '2021-11-04', 1665.54, 145),
(146, '2022-02-07', 961.38, 146),
(147, '2023-01-25', 869.88, 147),
(148, '2021-09-15', 170.68, 148),
(149, '2022-09-19', 559.44, 149),
(150, '2023-03-30', 72.41, 150),
(151, '2023-02-11', 73.92, 151),
(152, '2022-01-22', 706.45, 152),
(153, '2021-07-27', 8.12, 153),
(154, '2023-01-31', 1641.60, 154),
(155, '2021-07-12', 349.60, 155),
(156, '2022-10-16', 469.98, 156),
(157, '2022-03-13', 847.38, 157),
(158, '2022-07-01', 186.12, 158),
(159, '2022-12-20', 514.08, 159),
(160, '2022-02-11', 1057.90, 160),
(161, '2022-02-20', 38.06, 161),
(162, '2023-02-22', 57.85, 162),
(163, '2023-04-02', 249.21, 163),
(164, '2021-07-16', 139.00, 164),
(165, '2022-06-05', 224.56, 165),
(166, '2022-09-21', 1268.82, 166),
(167, '2022-11-01', 273.90, 167),
(168, '2022-06-23', 271.32, 168),
(169, '2021-07-19', 124.12, 169),
(170, '2021-11-07', 413.74, 170),
(171, '2022-01-02', 69.84, 171),
(172, '2021-11-19', 893.88, 172),
(173, '2022-05-08', 442.74, 173),
(174, '2022-05-08', 1640.50, 174),
(175, '2022-03-21', 825.94, 175),
(176, '2023-02-27', 241.02, 176),
(177, '2021-09-13', 955.89, 177),
(178, '2021-08-06', 176.03, 178),
(179, '2021-08-29', 174.79, 179),
(180, '2022-12-19', 1201.76, 180),
(181, '2022-01-31', 828.63, 181),
(182, '2022-01-28', 173.40, 182),
(183, '2022-11-02', 464.40, 183),
(184, '2022-04-05', 193.52, 184),
(185, '2022-11-20', 111.22, 185),
(186, '2022-03-30', 684.25, 186),
(187, '2022-11-07', 195.04, 187),
(188, '2021-11-14', 151.20, 188),
(189, '2021-11-22', 309.16, 189),
(190, '2021-12-03', 864.45, 190),
(191, '2022-09-20', 544.00, 191),
(192, '2022-08-03', 242.64, 192),
(193, '2021-07-15', 46.24, 193),
(194, '2022-02-02', 683.10, 194),
(195, '2023-03-01', 141.94, 195),
(196, '2022-03-28', 328.00, 196),
(197, '2022-03-02', 165.44, 197),
(198, '2021-12-15', 44.07, 198),
(199, '2022-11-21', 1166.40, 199),
(200, '2021-09-03', 31.00, 200),
(201, '2021-08-27', 734.32, 201),
(202, '2022-02-18', 749.00, 202),
(203, '2023-01-26', 282.72, 203),
(204, '2021-08-29', 430.65, 204),
(205, '2021-08-23', 451.98, 205),
(206, '2021-09-15', 705.96, 206),
(207, '2022-01-04', 690.69, 207),
(208, '2022-11-17', 561.60, 208),
(209, '2022-01-09', 45.63, 209),
(210, '2021-12-19', 1422.72, 210),
(211, '2022-05-24', 1383.20, 211),
(212, '2023-03-28', 831.72, 212),
(213, '2022-02-07', 1265.55, 213),
(214, '2022-07-11', 1408.83, 214),
(215, '2023-03-08', 1166.84, 215),
(216, '2023-04-18', 442.96, 216),
(217, '2022-08-12', 308.00, 217),
(218, '2022-11-05', 87.80, 218),
(219, '2023-02-28', 463.74, 219),
(220, '2023-02-12', 108.00, 220),
(221, '2023-01-05', 714.95, 221),
(222, '2022-11-01', 126.06, 222),
(223, '2022-04-22', 1363.24, 223),
(224, '2022-09-16', 37.76, 224),
(225, '2022-01-08', 104.40, 225),
(226, '2022-11-10', 157.92, 226),
(227, '2023-01-03', 452.98, 227),
(228, '2022-10-24', 52.92, 228),
(229, '2022-05-31', 1666.30, 229),
(230, '2021-08-03', 270.84, 230),
(231, '2023-03-01', 821.10, 231),
(232, '2023-01-15', 273.60, 232),
(233, '2022-08-28', 427.90, 233),
(234, '2022-02-11', 58.14, 234),
(235, '2023-03-17', 875.52, 235),
(236, '2022-10-17', 703.29, 236),
(237, '2022-10-16', 758.10, 237),
(238, '2021-09-23', 585.35, 238),
(239, '2022-09-15', 339.72, 239),
(240, '2021-12-07', 895.43, 240),
(241, '2022-09-02', 265.32, 241),
(242, '2022-05-05', 885.36, 242),
(243, '2023-02-09', 302.22, 243),
(244, '2023-01-13', 110.88, 244),
(245, '2022-08-15', 72.00, 245),
(246, '2022-06-20', 856.44, 246),
(247, '2021-08-22', 93.33, 247),
(248, '2023-03-26', 127.01, 248),
(249, '2022-08-04', 399.20, 249),
(250, '2022-03-09', 86.02, 250),
(251, '2022-03-29', 280.50, 251),
(252, '2023-01-15', 133.54, 252),
(253, '2023-04-02', 89.65, 253),
(254, '2023-04-07', 750.96, 254),
(255, '2023-01-28', 100.96, 255),
(256, '2022-08-08', 1253.88, 256),
(257, '2023-01-24', 1303.45, 257),
(258, '2022-07-11', 140.00, 258),
(259, '2023-01-05', 1226.08, 259),
(260, '2021-09-22', 155.72, 260),
(261, '2021-12-18', 557.46, 261),
(262, '2022-09-18', 560.25, 262),
(263, '2023-03-18', 601.31, 263),
(264, '2022-06-06', 783.87, 264),
(265, '2022-06-22', 1328.67, 265),
(266, '2021-07-25', 734.72, 266),
(267, '2022-02-16', 277.20, 267),
(268, '2021-08-24', 512.82, 268),
(269, '2022-02-10', 214.60, 269),
(270, '2021-08-01', 400.91, 270),
(271, '2022-03-09', 160.16, 271),
(272, '2021-11-24', 276.00, 272),
(273, '2021-08-12', 132.08, 273),
(274, '2023-04-08', 930.80, 274),
(275, '2022-12-20', 128.52, 275),
(276, '2022-09-11', 334.62, 276),
(277, '2021-09-15', 452.12, 277),
(278, '2023-01-03', 1182.06, 278),
(279, '2023-01-03', 316.03, 279),
(280, '2022-01-31', 605.88, 280),
(281, '2022-05-26', 761.25, 281),
(282, '2022-11-15', 148.61, 282),
(283, '2021-09-10', 1030.86, 283),
(284, '2021-08-09', 408.69, 284),
(285, '2022-04-22', 220.80, 285),
(286, '2022-02-27', 127.02, 286),
(287, '2021-10-09', 384.00, 287),
(288, '2021-10-01', 394.83, 288),
(289, '2021-10-16', 276.92, 289),
(290, '2022-06-03', 857.85, 290),
(291, '2021-07-10', 755.48, 291),
(292, '2022-12-30', 115.50, 292),
(293, '2021-11-14', 48.73, 293),
(294, '2022-08-15', 196.80, 294),
(295, '2023-02-20', 712.80, 295),
(296, '2022-06-02', 82.36, 296),
(297, '2023-03-07', 359.10, 297),
(298, '2022-10-19', 154.40, 298),
(299, '2021-07-03', 159.12, 299),
(300, '2023-04-08', 894.00, 300),
(301, '2022-03-08', 530.10, 301),
(302, '2021-10-23', 288.96, 302),
(303, '2022-09-11', 208.80, 303),
(304, '2022-04-11', 589.60, 304),
(305, '2022-02-15', 62.79, 305),
(306, '2022-11-10', 840.96, 306),
(307, '2023-01-29', 465.92, 307),
(308, '2023-02-03', 718.52, 308),
(309, '2022-03-16', 65.28, 309),
(310, '2022-09-15', 898.17, 310),
(311, '2022-06-12', 1205.10, 311),
(312, '2021-09-07', 137.28, 312),
(313, '2022-10-11', 127.20, 313),
(314, '2022-04-13', 244.14, 314),
(315, '2022-02-26', 1072.14, 315),
(316, '2022-01-05', 187.00, 316),
(317, '2021-10-26', 1549.72, 317),
(318, '2021-12-23', 383.19, 318),
(319, '2022-05-15', 676.62, 319),
(320, '2021-11-02', 1047.20, 320),
(321, '2022-07-14', 1104.08, 321),
(322, '2022-09-20', 1674.40, 322),
(323, '2023-01-24', 39.26, 323),
(324, '2021-11-13', 471.96, 324),
(325, '2022-02-17', 18.81, 325),
(326, '2022-07-05', 1694.46, 326),
(327, '2021-07-24', 582.33, 327),
(328, '2021-11-21', 549.78, 328),
(329, '2022-06-28', 61.49, 329),
(330, '2022-06-02', 364.64, 330),
(331, '2022-04-05', 456.48, 331),
(332, '2022-02-25', 950.46, 332),
(333, '2022-03-23', 451.50, 333),
(334, '2022-01-15', 714.75, 334),
(335, '2022-09-17', 297.99, 335),
(336, '2021-09-20', 153.41, 336),
(337, '2022-07-28', 72.00, 337),
(338, '2021-08-23', 63.18, 338),
(339, '2022-07-08', 166.77, 339),
(340, '2022-10-15', 391.20, 340),
(341, '2022-06-29', 592.95, 341),
(342, '2022-12-09', 679.50, 342),
(343, '2022-08-25', 210.00, 343),
(344, '2021-10-28', 935.98, 344),
(345, '2022-01-29', 268.27, 345),
(346, '2023-04-27', 770.40, 346),
(347, '2022-08-24', 67.32, 347),
(348, '2022-02-11', 756.82, 348),
(349, '2022-07-29', 594.00, 349),
(350, '2022-10-30', 460.08, 350),
(351, '2021-10-29', 31.64, 351),
(352, '2021-06-28', 598.90, 352),
(353, '2022-12-18', 43.05, 353),
(354, '2023-01-19', 570.00, 354),
(355, '2021-11-06', 198.90, 355),
(356, '2022-02-23', 1904.43, 356),
(357, '2022-01-27', 716.43, 357),
(358, '2023-04-05', 103.20, 358),
(359, '2022-05-17', 44.55, 359),
(360, '2023-04-03', 457.92, 360),
(361, '2021-11-09', 1416.87, 361),
(362, '2021-10-17', 1225.78, 362),
(363, '2022-02-12', 742.50, 363),
(364, '2022-10-14', 391.92, 364),
(365, '2022-04-11', 946.40, 365),
(366, '2022-10-02', 840.42, 366),
(367, '2021-12-19', 192.06, 367),
(368, '2021-10-06', 313.82, 368),
(369, '2021-10-10', 924.12, 369),
(370, '2022-09-09', 595.14, 370),
(371, '2023-02-27', 224.91, 371),
(372, '2021-12-08', 165.20, 372),
(373, '2022-08-18', 1034.90, 373),
(374, '2021-09-12', 752.55, 374),
(375, '2022-04-13', 1162.28, 375),
(376, '2022-05-20', 154.44, 376),
(377, '2022-01-12', 95.92, 377),
(378, '2022-08-26', 209.96, 378),
(379, '2021-11-18', 1305.60, 379),
(380, '2022-03-14', 644.80, 380),
(381, '2023-04-04', 441.28, 381),
(382, '2023-01-29', 23.60, 382),
(383, '2022-08-14', 1090.08, 383),
(384, '2021-09-19', 850.44, 384),
(385, '2022-12-08', 597.80, 385),
(386, '2021-10-24', 273.90, 386),
(387, '2021-09-21', 468.95, 387),
(388, '2022-12-17', 797.28, 388),
(389, '2021-10-27', 764.59, 389),
(390, '2022-01-05', 426.93, 390),
(391, '2022-03-23', 397.32, 391),
(392, '2022-11-24', 1815.45, 392),
(393, '2022-04-24', 466.46, 393),
(394, '2022-12-20', 116.10, 394),
(395, '2022-10-25', 300.60, 395),
(396, '2021-10-14', 364.91, 396),
(397, '2022-09-01', 357.20, 397),
(398, '2022-12-23', 704.48, 398),
(399, '2022-10-09', 191.59, 399),
(400, '2021-12-12', 538.24, 400),
(401, '2023-07-03', 2000.00, 401),
(402, '2023-07-03', 500.00, 402),
(403, '2023-07-04', 2000.00, 403),
(404, '2023-07-05', 3200.00, 404),
(405, '2023-07-04', 1740.00, 405);

-- --------------------------------------------------------

--
-- Tabellenstruktur für Tabelle `mitarbeiter`
--

CREATE TABLE `mitarbeiter` (
  `MitarbeiterID` int(11) NOT NULL,
  `BusinessPhone` varchar(30) DEFAULT NULL,
  `BusinessEmail` varchar(100) NOT NULL,
  `JobName` varchar(30) NOT NULL,
  `Einstelldatum` date NOT NULL,
  `ManagerID` int(11) DEFAULT NULL,
  `PrivatinfoID` int(11) NOT NULL,
  `ArbeitsortID` int(11) NOT NULL,
  `AbteilungID` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Daten für Tabelle `mitarbeiter`
--

INSERT INTO `mitarbeiter` (`MitarbeiterID`, `BusinessPhone`, `BusinessEmail`, `JobName`, `Einstelldatum`, `ManagerID`, `PrivatinfoID`, `ArbeitsortID`, `AbteilungID`) VALUES
(1, NULL, 'a.schmidt@EcoWheels.com', 'President', '2015-01-01', NULL, 1, 101, 10),
(2, NULL, 'b.mayer@EcoWheels.com', 'VP-Investement', '2015-01-01', 1, 2, 101, 10),
(3, NULL, 'c.bauer@EcoWheels.com', 'VP-Warehousing', '2015-01-01', 1, 3, 101, 70),
(4, NULL, 'd.keller@EcoWheels.com', 'Abteilungsleiter WH', '2015-01-01', 3, 4, 101, 70),
(5, NULL, 'e.vogel@EcoWheels.com', 'Abteilungsleiter WH', '2017-04-01', 3, 5, 51, 70),
(6, NULL, 'f.becker@EcoWheels.com', 'Abteilungsleiter WH', '2016-04-01', 3, 6, 151, 70),
(7, NULL, 'g.mueller@EcoWheels.com', 'Abteilungsleiter WH', '2019-04-01', 3, 7, 201, 70),
(8, NULL, 'h.schmitt@EcoWheels.com', 'Abteilungsleiter WH', '2016-04-01', 3, 8, 1, 70),
(9, NULL, 'i.wagner@EcoWheels.com', 'KFZ-WH', '2015-01-01', 4, 9, 101, 71),
(10, NULL, 'j.hofmann@EcoWheels.com', 'KFZ-WH', '2015-01-01', 4, 10, 101, 71),
(11, NULL, 'k.krause@EcoWheels.com', 'KFZ-WH', '2015-01-01', 4, 11, 101, 71),
(12, NULL, 'l.schulz@EcoWheels.com', 'KFZ-WH', '2015-01-01', 4, 12, 101, 71),
(13, NULL, 'm.franz@EcoWheels.com', 'KFZ-WH', '2017-04-01', 5, 13, 51, 71),
(14, NULL, 'n.baumann@EcoWheels.com', 'KFZ-WH', '2017-04-01', 5, 14, 51, 71),
(15, NULL, 'o.maier@EcoWheels.com', 'KFZ-WH', '2017-07-01', 5, 15, 51, 71),
(16, NULL, 'p.ott@EcoWheels.com', 'KFZ-WH', '2017-10-01', 5, 16, 51, 71),
(17, NULL, 'q.berger@EcoWheels.com', 'KFZ-WH', '2016-04-01', 6, 17, 151, 71),
(18, NULL, 'r.kuehn@EcoWheels.com', 'KFZ-WH', '2016-04-01', 6, 18, 151, 71),
(19, NULL, 's.schneider@EcoWheels.com', 'KFZ-WH', '2016-07-01', 6, 19, 151, 71),
(20, NULL, 't.gross@EcoWheels.com', 'KFZ-WH', '2016-10-01', 6, 20, 151, 71),
(21, NULL, 'u.frank@EcoWheels.com', 'KFZ-WH', '2019-04-01', 7, 21, 201, 71),
(22, NULL, 'v.wolf@EcoWheels.com', 'KFZ-WH', '2019-04-01', 7, 22, 201, 71),
(23, NULL, 'w.schwarz@EcoWheels.com', 'KFZ-WH', '2019-07-01', 7, 23, 201, 71),
(24, NULL, 'x.bauer@EcoWheels.com', 'KFZ-WH', '2019-10-01', 7, 24, 201, 71),
(25, NULL, 'y.koch@EcoWheels.com', 'KFZ-WH', '2016-04-01', 8, 25, 1, 71),
(26, NULL, 'a.schulz@EcoWheels.com', 'Firmenorganisation', '2015-01-01', 1, 26, 101, 10),
(27, NULL, 'b.koch@EcoWheels.com', 'Human Ressource', '2015-04-01', 26, 27, 101, 30),
(28, NULL, 'c.weiss@EcoWheels.com', 'Human Ressource', '2015-07-01', 26, 28, 101, 30),
(29, NULL, 'd.lang@EcoWheels.com', 'Customer Service', '2017-04-01', 26, 29, 51, 50),
(30, NULL, 'e.roth@EcoWheels.com', 'Customer Service', '2016-04-01', 26, 30, 151, 50),
(31, NULL, 'f.kaufmann@EcoWheels.com', 'Customer Service', '2019-04-01', 26, 31, 201, 50),
(32, NULL, 'g.mayer@EcoWheels.com', 'Customer Service', '2016-04-01', 26, 32, 1, 50),
(33, NULL, 'h.schaefer@EcoWheels.com', 'Logistik', '2015-01-01', 4, 33, 101, 70),
(34, NULL, 'i.bauer@EcoWheels.com', 'Logistik', '2015-10-01', 4, 34, 101, 70),
(35, NULL, 'j.krueger@EcoWheels.com', 'Logistik', '2017-04-01', 5, 35, 51, 70),
(36, NULL, 'k.frank@EcoWheels.com', 'Logistik', '2017-10-01', 5, 36, 51, 70),
(37, NULL, 'l.rauch@EcoWheels.com', 'Logistik', '2016-04-01', 6, 37, 151, 70),
(38, NULL, 'm.meier@EcoWheels.com', 'Logistik', '2016-07-01', 6, 38, 151, 70),
(39, NULL, 'n.schmidt@EcoWheels.com', 'Logistik', '2019-04-01', 7, 39, 201, 70),
(40, NULL, 'o.weise@EcoWheels.com', 'Logistik', '2019-10-01', 7, 40, 201, 70),
(41, NULL, 'p.schreiber@EcoWheels.com', 'Logistik', '2016-04-01', 8, 41, 1, 70),
(42, NULL, 'q.hoffmann@EcoWheels.com', 'Logistik', '2016-10-01', 8, 42, 1, 70),
(43, NULL, 'r.kaiser@EcoWheels.com', 'KFZ-WH', '2016-04-01', 8, 43, 1, 71),
(44, NULL, 's.rose@EcoWheels.com', 'KFZ-WH', '2016-07-01', 8, 44, 1, 71),
(45, NULL, 't.vogel@EcoWheels.com', 'KFZ-WH', '2016-10-01', 8, 45, 1, 71),
(46, NULL, 'e.beyer@EcoWheels.com', 'Social-Media', '2018-04-01', 1, 46, 101, 110),
(47, NULL, 'a.maier@EcoWheels.com', 'Akku-WH', '2015-04-01', 4, 47, 101, 72),
(48, NULL, 'b.huber@EcoWheels.com', 'Akku-WH', '2017-04-01', 5, 48, 51, 72),
(49, NULL, 'c.weber@EcoWheels.com', 'Akku-WH', '2016-04-01', 6, 49, 151, 72),
(50, NULL, 'd.schneider@EcoWheels.com', 'Akku-WH', '2019-04-01', 7, 50, 201, 72),
(51, NULL, 'e.schulte@EcoWheels.com', 'Akku-WH', '2016-04-01', 8, 51, 1, 72);

-- --------------------------------------------------------

--
-- Tabellenstruktur für Tabelle `privatinfo`
--

CREATE TABLE `privatinfo` (
  `PrivatInfoID` int(11) NOT NULL,
  `Nachname` varchar(30) NOT NULL,
  `Vorname` varchar(30) NOT NULL,
  `Mobilnummer` varchar(30) NOT NULL,
  `EmailPrivate` varchar(100) NOT NULL,
  `WohnortID` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Daten für Tabelle `privatinfo`
--

INSERT INTO `privatinfo` (`PrivatInfoID`, `Nachname`, `Vorname`, `Mobilnummer`, `EmailPrivate`, `WohnortID`) VALUES
(1, 'SCHMIDT', 'ALEXANDER', '017612345678', 'a.schmidt@gmail.com', 123),
(2, 'MAYER', 'BENJAMIN', '017623456789', 'b.mayer@gmail.com', 135),
(3, 'BAUER', 'CHRISTOPHER', '017634567890', 'c.bauer@googlemail.com', 124),
(4, 'KELLER', 'DANIEL', '017645678901', 'd.keller@googlemail.com', 144),
(5, 'VOGEL', 'ERIC', '017656789012', 'e.vogel@googlemail.com', 89),
(6, 'BECKER', 'FLORIAN', '017667890123', 'f.becker@googlemail.com', 190),
(7, 'MÜLLER', 'GABRIEL', '017678901234', 'g.mueller@googlemail.com', 230),
(8, 'SCHMITT', 'HENRY', '017689012345', 'h.schmitt@gmail.com', 42),
(9, 'WAGNER', 'IVAN', '017600123456', 'i.wagner@gmail.com', 140),
(10, 'HOFMANN', 'JONAS', '017611234567', 'j.hofmann@googlemail.com', 150),
(11, 'KRAUSE', 'KAI', '017622345678', 'k.krause@googlemail.com', 132),
(12, 'SCHULZ', 'LUKAS', '017633456789', 'l.schulz@googlemail.com', 117),
(13, 'FRANZ', 'MAXIMILIAN', '017644567890', 'm.franz@googlemail.com', 88),
(14, 'BAUMANN', 'NICO', '017655678901', 'n.baumann@googlemail.com', 84),
(15, 'MAIER', 'OLIVER', '017666789012', 'o.maier@googlemail.com', 92),
(16, 'OTT', 'PATRICK', '017677890123', 'p.ott@gmail.com', 99),
(17, 'BERGER', 'QUENTIN', '017688901234', 'q.berger@gmail.com', 171),
(18, 'KÜHN', 'RICHARD', '017699012345', 'r.kuehn@gmail.com', 177),
(19, 'SCHNEIDER', 'SEBASTIAN', '017610123456', 's.schneider@gmail.com', 180),
(20, 'GROß', 'TIMO', '017621234567', 't.gross@googlemail.com', 182),
(21, 'FRANK', 'UWE', '017632345678', 'u.frank@googlemail.com', 250),
(22, 'WOLF', 'VIKTOR', '017643456789', 'v.wolf@gmail.com', 240),
(23, 'SCHWARZ', 'WILHELM', '017654567890', 'w.schwarz@gmail.com', 241),
(24, 'BAUER', 'XAVER', '017665678901', 'x.bauer@gmail.com', 226),
(25, 'KOCH', 'YANNICK', '017676789012', 'y.koch@gmail.com', 44),
(26, 'SCHULZ', 'ANNA', '017687654321', 'a.schulz@gmail.com', 136),
(27, 'KOCH', 'BIANCA', '017676543210', 'b.koch@gmail.com', 141),
(28, 'WEISS', 'CAROLINA', '017665432109', 'c.weiss@gmail.com', 149),
(29, 'LANG', 'DENISE', '017654321098', 'd.lang@gmail.com', 100),
(30, 'ROTH', 'EMILY', '017643210987', 'e.roth@googlemail.com', 190),
(31, 'KAUFMANN', 'FRANZISKA', '017632109876', 'f.kaufmann@googlemail.com', 210),
(32, 'MAYER', 'GISELA', '017621098765', 'g.mayer@googlemail.com', 48),
(33, 'SCHÄFER', 'HANNAH', '017610987654', 'h.schaefer@googlemail.com', 147),
(34, 'BAUER', 'ISABEL', '017699876543', 'i.bauer@googlemail.com', 115),
(35, 'KRÜGER', 'JULIA', '017688765432', 'j.krueger@gmail.com', 68),
(36, 'FRANK', 'KATHARINA', '017677654321', 'k.frank@gmail.com', 63),
(37, 'RAUCH', 'LENA', '017666543210', 'l.rauch@gmail.com', 196),
(38, 'MEIER', 'MARIE', '017655432109', 'm.meier@gmail.com', 198),
(39, 'SCHMIDT', 'NADINE', '017644321098', 'n.schmidt@gmail.com', 248),
(40, 'WEISE', 'OLIVIA', '017633210987', 'o.weise@gmail.com', 239),
(41, 'SCHREIBER', 'PAULA', '017622109876', 'p.schreiber@gmail.com', 33),
(42, 'HOFFMANN', 'QUEENIE', '017611098765', 'q.hoffmann@EcoWheels.com', 36),
(43, 'KAISER', 'REBEKKA', '017600987654', 'r.kaiser@gmail.com', 40),
(44, 'ROSE', 'SOPHIA', '017589876543', 's.rose@gmail.com', 47),
(45, 'VOGEL', 'TINA', '017578765432', 't.vogel@gmail.com', 29),
(46, 'BEYER', 'EMILIAN', '017652622457', 'e.beyer@gmail.com', 122),
(47, 'MAIER', 'ALEXANDER', '017567654321', 'a.maier@gmail.com', 120),
(48, 'HUBER', 'BENJAMIN', '017556543210', 'b.huber@googlemail.com', 72),
(49, 'WEBER', 'CHRISTIAN', '017545432109', 'c.weber@googlemail.com', 200),
(50, 'SCHNEIDER', 'DAVID', '017534321098', 'd.schneider@googlemail.com', 228),
(51, 'SCHULTE', 'ERIK', '017523210987', 'e.schulte@googlemail.com', 35);

-- --------------------------------------------------------

--
-- Tabellenstruktur für Tabelle `region`
--

CREATE TABLE `region` (
  `RegionID` int(11) NOT NULL,
  `Region_Name` varchar(30) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Daten für Tabelle `region`
--

INSERT INTO `region` (`RegionID`, `Region_Name`) VALUES
(1, 'NORTH'),
(2, 'SOUTH'),
(3, 'WEST'),
(4, 'EAST'),
(5, 'MIDDLE');

-- --------------------------------------------------------

--
-- Tabellenstruktur für Tabelle `reparatur`
--

CREATE TABLE `reparatur` (
  `ReparaturID` int(11) NOT NULL,
  `ReparaturDatum` date NOT NULL,
  `ReparaturDauer` int(11) DEFAULT NULL,
  `Abgeschlossen` tinyint(1) DEFAULT NULL,
  `DefektID` int(11) NOT NULL,
  `BearbeiterID` int(11) NOT NULL,
  `LagerID` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Daten für Tabelle `reparatur`
--

INSERT INTO `reparatur` (`ReparaturID`, `ReparaturDatum`, `ReparaturDauer`, `Abgeschlossen`, `DefektID`, `BearbeiterID`, `LagerID`) VALUES
(1, '2023-06-21', NULL, NULL, 1, 9, 1),
(2, '2023-06-21', NULL, NULL, 2, 12, 1),
(3, '2023-06-19', NULL, NULL, 3, 11, 1),
(4, '2023-06-21', NULL, NULL, 4, 10, 1),
(5, '2023-06-20', NULL, NULL, 5, 12, 1),
(6, '2023-06-16', NULL, NULL, 6, 11, 1),
(7, '2023-06-22', NULL, NULL, 7, 12, 1),
(8, '2023-06-22', NULL, NULL, 8, 12, 1),
(9, '2023-06-16', NULL, NULL, 9, 11, 1),
(10, '2023-06-19', NULL, NULL, 10, 9, 1),
(11, '2023-06-17', NULL, NULL, 11, 12, 1),
(12, '2023-06-19', NULL, NULL, 12, 10, 1),
(13, '2023-06-21', NULL, NULL, 13, 10, 1),
(14, '2023-06-18', NULL, NULL, 14, 9, 1),
(15, '2023-06-22', NULL, NULL, 15, 11, 1),
(16, '2023-06-20', NULL, NULL, 16, 11, 1),
(17, '2023-06-17', NULL, NULL, 17, 9, 1),
(18, '2023-06-16', NULL, NULL, 18, 9, 1),
(19, '2023-06-19', NULL, NULL, 19, 10, 1),
(20, '2023-06-18', NULL, NULL, 20, 9, 1),
(21, '2023-06-16', NULL, NULL, 21, 13, 2),
(22, '2023-06-22', NULL, NULL, 22, 15, 2),
(23, '2023-06-19', NULL, NULL, 23, 14, 2),
(24, '2023-06-20', NULL, NULL, 24, 15, 2),
(25, '2023-06-16', NULL, NULL, 25, 14, 2),
(26, '2023-06-22', NULL, NULL, 26, 15, 2),
(27, '2023-06-17', NULL, NULL, 27, 16, 2),
(28, '2023-06-21', NULL, NULL, 28, 16, 2),
(29, '2023-06-22', NULL, NULL, 29, 14, 2),
(30, '2023-06-22', NULL, NULL, 30, 15, 2),
(31, '2023-06-19', NULL, NULL, 31, 14, 2),
(32, '2023-06-20', NULL, NULL, 32, 13, 2),
(33, '2023-06-22', NULL, NULL, 33, 13, 2),
(34, '2023-06-20', NULL, NULL, 34, 16, 2),
(35, '2023-06-20', NULL, NULL, 35, 16, 2),
(36, '2023-06-17', NULL, NULL, 36, 13, 2),
(37, '2023-06-16', NULL, NULL, 37, 15, 2),
(38, '2023-06-20', NULL, NULL, 38, 16, 2),
(39, '2023-06-17', NULL, NULL, 39, 14, 2),
(40, '2023-06-20', NULL, NULL, 40, 13, 2),
(41, '2023-06-16', NULL, NULL, 41, 17, 3),
(42, '2023-06-20', NULL, NULL, 42, 18, 3),
(43, '2023-06-17', NULL, NULL, 43, 18, 3),
(44, '2023-06-22', NULL, NULL, 44, 18, 3),
(45, '2023-06-18', NULL, NULL, 45, 20, 3),
(46, '2023-06-18', NULL, NULL, 46, 20, 3),
(47, '2023-06-22', NULL, NULL, 47, 18, 3),
(48, '2023-06-18', NULL, NULL, 48, 20, 3),
(49, '2023-06-19', NULL, NULL, 49, 19, 3),
(50, '2023-06-21', NULL, NULL, 50, 17, 3),
(51, '2023-06-17', NULL, NULL, 51, 20, 3),
(52, '2023-06-17', NULL, NULL, 52, 18, 3),
(53, '2023-06-21', NULL, NULL, 53, 20, 3),
(54, '2023-06-17', NULL, NULL, 54, 20, 3),
(55, '2023-06-21', NULL, NULL, 55, 17, 3),
(56, '2023-06-19', NULL, NULL, 56, 17, 3),
(57, '2023-06-20', NULL, NULL, 57, 20, 3),
(58, '2023-06-21', NULL, NULL, 58, 17, 3),
(59, '2023-06-19', NULL, NULL, 59, 17, 3),
(60, '2023-06-20', NULL, NULL, 60, 18, 3),
(61, '2023-06-17', NULL, NULL, 61, 23, 4),
(62, '2023-06-17', NULL, NULL, 62, 22, 4),
(63, '2023-06-20', NULL, NULL, 63, 23, 4),
(64, '2023-06-19', NULL, NULL, 64, 24, 4),
(65, '2023-06-16', NULL, NULL, 65, 24, 4),
(66, '2023-06-18', NULL, NULL, 66, 23, 4),
(67, '2023-06-16', NULL, NULL, 67, 24, 4),
(68, '2023-06-17', NULL, NULL, 68, 22, 4),
(69, '2023-06-19', NULL, NULL, 69, 24, 4),
(70, '2023-06-20', NULL, NULL, 70, 22, 4),
(71, '2023-06-18', NULL, NULL, 71, 22, 4),
(72, '2023-06-21', NULL, NULL, 72, 21, 4),
(73, '2023-06-20', NULL, NULL, 73, 22, 4),
(74, '2023-06-19', NULL, NULL, 74, 22, 4),
(75, '2023-06-19', NULL, NULL, 75, 22, 4),
(76, '2023-06-22', NULL, NULL, 76, 22, 4),
(77, '2023-06-16', NULL, NULL, 77, 24, 4),
(78, '2023-06-18', NULL, NULL, 78, 22, 4),
(79, '2023-06-21', NULL, NULL, 79, 22, 4),
(80, '2023-06-22', NULL, NULL, 80, 21, 4),
(81, '2023-06-22', NULL, NULL, 81, 25, 5),
(82, '2023-06-18', NULL, NULL, 82, 25, 5),
(83, '2023-06-21', NULL, NULL, 83, 25, 5),
(84, '2023-06-18', NULL, NULL, 84, 25, 5),
(85, '2023-06-18', NULL, NULL, 85, 25, 5),
(86, '2023-06-18', NULL, NULL, 86, 25, 5),
(87, '2023-06-21', NULL, NULL, 87, 25, 5),
(88, '2023-06-16', NULL, NULL, 88, 25, 5),
(89, '2023-06-16', NULL, NULL, 89, 25, 5),
(90, '2023-06-16', NULL, NULL, 90, 25, 5),
(91, '2023-06-19', NULL, NULL, 91, 25, 5),
(92, '2023-06-19', NULL, NULL, 92, 25, 5),
(93, '2023-06-16', NULL, NULL, 93, 25, 5),
(94, '2023-06-22', NULL, NULL, 94, 25, 5),
(95, '2023-06-20', NULL, NULL, 95, 25, 5),
(96, '2023-06-22', NULL, NULL, 96, 25, 5),
(97, '2023-06-18', NULL, NULL, 97, 25, 5),
(98, '2023-06-20', NULL, NULL, 98, 25, 5),
(99, '2023-06-22', NULL, NULL, 99, 25, 5),
(100, '2023-06-18', NULL, NULL, 100, 25, 5);

-- --------------------------------------------------------

--
-- Tabellenstruktur für Tabelle `standort`
--

CREATE TABLE `standort` (
  `StandortID` int(11) NOT NULL,
  `PLZ` char(5) NOT NULL,
  `Stadt` varchar(30) NOT NULL,
  `Strasse` varchar(30) NOT NULL,
  `Sammelpunkt` tinyint(1) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Daten für Tabelle `standort`
--

INSERT INTO `standort` (`StandortID`, `PLZ`, `Stadt`, `Strasse`, `Sammelpunkt`) VALUES
(1, '49140', 'HAMBURG', 'Tschentscherstrasse', 0),
(2, '04872', 'HAMBURG', 'Evelyn-Boerner-Gasse', 1),
(3, '42532', 'HAMBURG', 'Hinrich-Juncken-Weg', 1),
(4, '91227', 'HAMBURG', 'Friedemann-Schenk-Strasse', 1),
(5, '15911', 'HAMBURG', 'Heini-Wernecke-Strasse', 1),
(6, '78804', 'HAMBURG', 'Katalin-Schueler-Ring', 1),
(7, '16767', 'HAMBURG', 'Siegward-Nerger-Platz', 1),
(8, '34995', 'HAMBURG', 'Marieluise-Scholz-Ring', 1),
(9, '88797', 'HAMBURG', 'Boris-Suessebier-Platz', 1),
(10, '45271', 'HAMBURG', 'Schomberplatz', 1),
(11, '70811', 'HAMBURG', 'Kaethe-Walter-Gasse', 1),
(12, '93311', 'HAMBURG', 'Theodora-Zaenker-Platz', 0),
(13, '88056', 'HAMBURG', 'Galina-Plath-Weg', 0),
(14, '66961', 'HAMBURG', 'Waehnerallee', 0),
(15, '97005', 'HAMBURG', 'Raedelstrasse', 0),
(16, '50134', 'HAMBURG', 'Roehrichtweg', 0),
(17, '84935', 'HAMBURG', 'Fred-Adler-Platz', 0),
(18, '46672', 'HAMBURG', 'Bluemelstr.', 0),
(19, '14692', 'HAMBURG', 'Marian-Bohnbach-Gasse', 0),
(20, '90743', 'HAMBURG', 'Giessstr.', 0),
(21, '19165', 'HAMBURG', 'Losekannstr.', 0),
(22, '06162', 'HAMBURG', 'Hornichstr.', 0),
(23, '79453', 'HAMBURG', 'Siegmar-Juettner-Platz', 0),
(24, '07039', 'HAMBURG', 'Fritschgasse', 0),
(25, '11517', 'HAMBURG', 'Kobeltring', 0),
(26, '64968', 'HAMBURG', 'Urszula-Seifert-Strasse', 0),
(27, '71926', 'HAMBURG', 'Klotzstrasse', 0),
(28, '24290', 'HAMBURG', 'Hartungweg', 0),
(29, '31689', 'HAMBURG', 'Anneli-Weinhage-Allee', 0),
(30, '67417', 'HAMBURG', 'Hans-Hinrich-Weitzel-Allee', 0),
(31, '57432', 'HAMBURG', 'Trubinstr.', 0),
(32, '55016', 'HAMBURG', 'Hessering', 0),
(33, '58528', 'HAMBURG', 'Hillerplatz', 0),
(34, '97579', 'HAMBURG', 'Emanuel-Kramer-Weg', 0),
(35, '17597', 'HAMBURG', 'Hartmut-Fischer-Allee', 0),
(36, '47001', 'HAMBURG', 'Dunja-Meyer-Gasse', 0),
(37, '92451', 'HAMBURG', 'Jesselring', 0),
(38, '40478', 'HAMBURG', 'Nadeshda-Bolander-Ring', 0),
(39, '48432', 'HAMBURG', 'Bernd-Dieter-Rudolph-Platz', 0),
(40, '79897', 'HAMBURG', 'Miesring', 0),
(41, '50624', 'HAMBURG', 'Kristine-Wulf-Platz', 0),
(42, '34805', 'HAMBURG', 'Jonas-Kramer-Gasse', 0),
(43, '46805', 'HAMBURG', 'Pechelweg', 0),
(44, '09315', 'HAMBURG', 'Gabriella-Geisel-Allee', 0),
(45, '70732', 'HAMBURG', 'Mielcarekstrasse', 0),
(46, '50474', 'HAMBURG', 'Roland-Mude-Gasse', 0),
(47, '22354', 'HAMBURG', 'Kreinallee', 0),
(48, '98942', 'HAMBURG', 'Erich-Holzapfel-Weg', 0),
(49, '21427', 'HAMBURG', 'Sauergasse', 0),
(50, '12215', 'HAMBURG', 'Seipstrasse', 0),
(51, '38172', 'BERLIN', 'Groettnerring', 0),
(52, '41800', 'BERLIN', 'Gabor-Waehner-Platz', 1),
(53, '21393', 'BERLIN', 'Hoevelallee', 1),
(54, '74012', 'BERLIN', 'Kreingasse', 1),
(55, '99572', 'BERLIN', 'Frederik-Anders-Allee', 1),
(56, '19873', 'BERLIN', 'Bohlanderweg', 1),
(57, '05535', 'BERLIN', 'Wagenknechtstrasse', 1),
(58, '56444', 'BERLIN', 'Ortmannstr.', 1),
(59, '83843', 'BERLIN', 'Isabell-Juncken-Ring', 1),
(60, '99769', 'BERLIN', 'Mendegasse', 1),
(61, '79975', 'BERLIN', 'Dowergring', 1),
(62, '43704', 'BERLIN', 'Lene-Baum-Weg', 0),
(63, '97597', 'BERLIN', 'Hans-Detlef-Walter-Weg', 0),
(64, '63736', 'BERLIN', 'Kristin-Koch-Ring', 0),
(65, '69164', 'BERLIN', 'Romy-Barth-Allee', 0),
(66, '59510', 'BERLIN', 'Jacobi Jaeckelallee', 0),
(67, '24241', 'BERLIN', 'Faustgasse', 0),
(68, '98809', 'BERLIN', 'Tilo-Kroker-Strasse', 0),
(69, '33645', 'BERLIN', 'Oxana-Kabus-Weg', 0),
(70, '44213', 'BERLIN', 'Blanka-Mohaupt-Ring', 0),
(71, '11618', 'BERLIN', 'Stahrring', 0),
(72, '83841', 'BERLIN', 'Jesselweg', 0),
(73, '28868', 'BERLIN', 'Dunja-Trommler-Ring', 0),
(74, '49559', 'BERLIN', 'Roemerplatz', 0),
(75, '45404', 'BERLIN', 'Hartungallee', 0),
(76, '45752', 'BERLIN', 'Herta-Klapp-Gasse', 0),
(77, '06542', 'BERLIN', 'Dippelallee', 0),
(78, '69143', 'BERLIN', 'Pohlstr.', 0),
(79, '97408', 'BERLIN', 'Dippelplatz', 0),
(80, '82406', 'BERLIN', 'Beckerweg', 0),
(81, '89526', 'BERLIN', 'Elisa-Flantz-Platz', 0),
(82, '57180', 'BERLIN', 'Damaris-Wilms-Allee', 0),
(83, '30161', 'BERLIN', 'Helmuth-Poelitz-Gasse', 0),
(84, '15195', 'BERLIN', 'Ziegertgasse', 0),
(85, '85515', 'BERLIN', 'Elzbieta-Wende-Strasse', 0),
(86, '44042', 'BERLIN', 'Frankeplatz', 0),
(87, '02978', 'BERLIN', 'Else-Eigenwillig-Allee', 0),
(88, '18308', 'BERLIN', 'Austermuehleplatz', 0),
(89, '81315', 'BERLIN', 'Antonius-Neuschaefer-Allee', 0),
(90, '16311', 'BERLIN', 'Hesergasse', 0),
(91, '75255', 'BERLIN', 'Sagerstr.', 0),
(92, '50230', 'BERLIN', 'Oswald-Gerlach-Allee', 0),
(93, '88326', 'BERLIN', 'Reisingstr.', 0),
(94, '76070', 'BERLIN', 'Soelzerallee', 0),
(95, '60568', 'BERLIN', 'Manja-Zobel-Ring', 0),
(96, '24959', 'BERLIN', 'Suessebierweg', 0),
(97, '00639', 'BERLIN', 'Mark-Rosemann-Gasse', 0),
(98, '92293', 'BERLIN', 'Wolfhard-Hecker-Allee', 0),
(99, '40646', 'BERLIN', 'Roggeweg', 0),
(100, '49860', 'BERLIN', 'Nikolaus-Loeffler-Ring', 0),
(101, '96084', 'ERFURT', 'Lukas-Klemm-Allee', 0),
(102, '19660', 'ERFURT', 'Wesackallee', 1),
(103, '18518', 'ERFURT', 'Loefflerweg', 1),
(104, '78359', 'ERFURT', 'Janusz-Drewes-Allee', 1),
(105, '65245', 'ERFURT', 'Manja-Schleich-Ring', 1),
(106, '30062', 'ERFURT', 'Loewerstrasse', 1),
(107, '12488', 'ERFURT', 'Thilo-Moechlichen-Weg', 1),
(108, '66545', 'ERFURT', 'Ingetraut-Ruppert-Allee', 1),
(109, '91149', 'ERFURT', 'Friedrich-Wilhelm-Drubin-Ring', 1),
(110, '46741', 'ERFURT', 'Kristiane-Benthin-Allee', 1),
(111, '34441', 'ERFURT', 'Rittergasse', 1),
(112, '77460', 'ERFURT', 'Beckmannring', 0),
(113, '63953', 'ERFURT', 'Lorenz-auch Schlauchin-Ring', 0),
(114, '77099', 'ERFURT', 'Thanelplatz', 0),
(115, '88157', 'ERFURT', 'Scheuermannallee', 0),
(116, '50170', 'ERFURT', 'Ingolf-Barth-Allee', 0),
(117, '29585', 'ERFURT', 'Murat-Fischer-Strasse', 0),
(118, '51367', 'ERFURT', 'Gordana-Werner-Weg', 0),
(119, '75948', 'ERFURT', 'Ullmanngasse', 0),
(120, '95669', 'ERFURT', 'Heidrichweg', 0),
(121, '10643', 'ERFURT', 'Gotthold-Schacht-Weg', 0),
(122, '17007', 'ERFURT', 'Heuserstrasse', 0),
(123, '43570', 'ERFURT', 'Hessestr.', 0),
(124, '01301', 'ERFURT', 'Tillmann-Trupp-Weg', 0),
(125, '60413', 'ERFURT', 'Wilmsstrasse', 0),
(126, '70242', 'ERFURT', 'Harloffgasse', 0),
(127, '34212', 'ERFURT', 'Beckmannstr.', 0),
(128, '41254', 'ERFURT', 'Ruststr.', 0),
(129, '01025', 'ERFURT', 'Pero-Stiebitz-Allee', 0),
(130, '08981', 'ERFURT', 'Ruthild-Anders-Allee', 0),
(131, '78338', 'ERFURT', 'Hiltraud-Gotthard-Weg', 0),
(132, '46805', 'ERFURT', 'Franz-Xaver-Beckmann-Allee', 0),
(133, '37178', 'ERFURT', 'Oestrovskyring', 0),
(134, '52738', 'ERFURT', 'Waldtraut-Zirme-Strasse', 0),
(135, '75622', 'ERFURT', 'Krokerring', 0),
(136, '39677', 'ERFURT', 'Gertraud-Heidrich-Ring', 0),
(137, '86470', 'ERFURT', 'Isabel-Kraushaar-Allee', 0),
(138, '71554', 'ERFURT', 'Cathrin-Gehringer-Allee', 0),
(139, '22706', 'ERFURT', 'Dussen vangasse', 0),
(140, '74957', 'ERFURT', 'Loosring', 0),
(141, '60831', 'ERFURT', 'Junkenallee', 0),
(142, '97256', 'ERFURT', 'Mudeallee', 0),
(143, '33846', 'ERFURT', 'Jaentschgasse', 0),
(144, '17652', 'ERFURT', 'Kuno-Vogt-Weg', 0),
(145, '02308', 'ERFURT', 'Wagenknechtplatz', 0),
(146, '50284', 'ERFURT', 'Doerschnerring', 0),
(147, '08901', 'ERFURT', 'Helena-Eberhardt-Allee', 0),
(148, '87644', 'ERFURT', 'Hermine-Weiss-Gasse', 0),
(149, '86747', 'ERFURT', 'Schuchhardtallee', 0),
(150, '28347', 'ERFURT', 'Hubertine-Heinz-Platz', 0),
(151, '71887', 'FRANKFURT AM MAIN', 'Friederike-Schueler-Strasse', 0),
(152, '91564', 'FRANKFURT AM MAIN', 'Stavros-Schuchhardt-Gasse', 1),
(153, '91738', 'FRANKFURT AM MAIN', 'Schollring', 1),
(154, '76586', 'FRANKFURT AM MAIN', 'Budigstr.', 1),
(155, '73116', 'FRANKFURT AM MAIN', 'Gertrude-Rose-Gasse', 1),
(156, '30181', 'FRANKFURT AM MAIN', 'Dagobert-Schinke-Strasse', 1),
(157, '18283', 'FRANKFURT AM MAIN', 'Schmidtweg', 1),
(158, '91099', 'FRANKFURT AM MAIN', 'Edelbert-Trueb-Platz', 1),
(159, '08986', 'FRANKFURT AM MAIN', 'Losekannring', 1),
(160, '48633', 'FRANKFURT AM MAIN', 'Junitzstr.', 1),
(161, '28460', 'FRANKFURT AM MAIN', 'Arzu-Klotz-Gasse', 1),
(162, '77972', 'FRANKFURT AM MAIN', 'Johan-Roehricht-Weg', 0),
(163, '51990', 'FRANKFURT AM MAIN', 'Friederike-Koester-Allee', 0),
(164, '03793', 'FRANKFURT AM MAIN', 'Mansstr.', 0),
(165, '65002', 'FRANKFURT AM MAIN', 'Beckergasse', 0),
(166, '33635', 'FRANKFURT AM MAIN', 'Kabusweg', 0),
(167, '68378', 'FRANKFURT AM MAIN', 'Hessestr.', 0),
(168, '49422', 'FRANKFURT AM MAIN', 'Britta-Kallert-Strasse', 0),
(169, '06324', 'FRANKFURT AM MAIN', 'Rustgasse', 0),
(170, '01788', 'FRANKFURT AM MAIN', 'Gunda-Mentzel-Ring', 0),
(171, '36372', 'FRANKFURT AM MAIN', 'Hertrampfgasse', 0),
(172, '48798', 'FRANKFURT AM MAIN', 'Wagnerring', 0),
(173, '55362', 'FRANKFURT AM MAIN', 'Benthinallee', 0),
(174, '18283', 'FRANKFURT AM MAIN', 'Mareike-Pruschke-Allee', 0),
(175, '11211', 'FRANKFURT AM MAIN', 'Francoise-Hahn-Ring', 0),
(176, '81856', 'FRANKFURT AM MAIN', 'Torsten-Henck-Allee', 0),
(177, '00954', 'FRANKFURT AM MAIN', 'Guteplatz', 0),
(178, '13904', 'FRANKFURT AM MAIN', 'Hartungring', 0),
(179, '14043', 'FRANKFURT AM MAIN', 'Reisingstr.', 0),
(180, '69920', 'FRANKFURT AM MAIN', 'Bianka-Pohl-Ring', 0),
(181, '50857', 'FRANKFURT AM MAIN', 'William-Faust-Platz', 0),
(182, '54971', 'FRANKFURT AM MAIN', 'Fredy-Hofmann-Strasse', 0),
(183, '98945', 'FRANKFURT AM MAIN', 'Strohstr.', 0),
(184, '14596', 'FRANKFURT AM MAIN', 'Annegret-Junck-Gasse', 0),
(185, '94158', 'FRANKFURT AM MAIN', 'Hellwigplatz', 0),
(186, '41049', 'FRANKFURT AM MAIN', 'Pauline-Heinrich-Allee', 0),
(187, '52181', 'FRANKFURT AM MAIN', 'Luigi-Kohl-Platz', 0),
(188, '75757', 'FRANKFURT AM MAIN', 'Junitzweg', 0),
(189, '73556', 'FRANKFURT AM MAIN', 'Bohlanderplatz', 0),
(190, '22868', 'FRANKFURT AM MAIN', 'Immo-Stolze-Gasse', 0),
(191, '43518', 'FRANKFURT AM MAIN', 'Wielochplatz', 0),
(192, '78690', 'FRANKFURT AM MAIN', 'Hauffergasse', 0),
(193, '95295', 'FRANKFURT AM MAIN', 'Giesela-Knappe-Ring', 0),
(194, '50223', 'FRANKFURT AM MAIN', 'Kuhlweg', 0),
(195, '56037', 'FRANKFURT AM MAIN', 'Olivia-Seip-Platz', 0),
(196, '70976', 'FRANKFURT AM MAIN', 'Nohlmansstr.', 0),
(197, '36028', 'FRANKFURT AM MAIN', 'Rohtallee', 0),
(198, '33086', 'FRANKFURT AM MAIN', 'Schaeferplatz', 0),
(199, '43285', 'FRANKFURT AM MAIN', 'Waehnerring', 0),
(200, '62111', 'FRANKFURT AM MAIN', 'Ronald-Ernst-Platz', 0),
(201, '98614', 'MUENCHEN', 'Jockelplatz', 0),
(202, '16914', 'MUENCHEN', 'Iwona-Henk-Ring', 1),
(203, '36453', 'MUENCHEN', 'Thomas-Kusch-Strasse', 1),
(204, '73948', 'MUENCHEN', 'Eigenwilligweg', 1),
(205, '20050', 'MUENCHEN', 'Niko-Stroh-Weg', 1),
(206, '07257', 'MUENCHEN', 'Victor-Steinberg-Allee', 1),
(207, '70658', 'MUENCHEN', 'Janette-Drub-Allee', 1),
(208, '80836', 'MUENCHEN', 'Brigitte-Scholtz-Platz', 1),
(209, '65147', 'MUENCHEN', 'Daniela-Roemer-Allee', 1),
(210, '65221', 'MUENCHEN', 'Gustav-Holt-Weg', 1),
(211, '04877', 'MUENCHEN', 'Liebeltstrasse', 1),
(212, '70703', 'MUENCHEN', 'Cordula-Zaenker-Gasse', 0),
(213, '39122', 'MUENCHEN', 'Haasestrasse', 0),
(214, '72792', 'MUENCHEN', 'Vesna-Misicher-Ring', 0),
(215, '12380', 'MUENCHEN', 'Katerina-Giess-Weg', 0),
(216, '37171', 'MUENCHEN', 'Paffrathstr.', 0),
(217, '08906', 'MUENCHEN', 'Ackermannallee', 0),
(218, '04300', 'MUENCHEN', 'Hermann-Schmiedt-Gasse', 0),
(219, '36189', 'MUENCHEN', 'Kemal-Adler-Gasse', 0),
(220, '67120', 'MUENCHEN', 'Eimerstr.', 0),
(221, '85675', 'MUENCHEN', 'Veronique-Mohaupt-Strasse', 0),
(222, '47478', 'MUENCHEN', 'van der Dussenstrasse', 0),
(223, '69531', 'MUENCHEN', 'Rittergasse', 0),
(224, '37011', 'MUENCHEN', 'Rocco-Hoerle-Ring', 0),
(225, '26784', 'MUENCHEN', 'Ortmannstr.', 0),
(226, '62929', 'MUENCHEN', 'Gunpfring', 0),
(227, '69928', 'MUENCHEN', 'Yvette-Stey-Gasse', 0),
(228, '11381', 'MUENCHEN', 'Emanuel-Rust-Platz', 0),
(229, '42368', 'MUENCHEN', 'Doehnplatz', 0),
(230, '84456', 'MUENCHEN', 'Putzweg', 0),
(231, '58752', 'MUENCHEN', 'Metzring', 0),
(232, '58473', 'MUENCHEN', 'Roerrichtplatz', 0),
(233, '93441', 'MUENCHEN', 'Eimerstr.', 0),
(234, '53147', 'MUENCHEN', 'Suessebierallee', 0),
(235, '09075', 'MUENCHEN', 'Ruppersbergergasse', 0),
(236, '97722', 'MUENCHEN', 'Loechelweg', 0),
(237, '98220', 'MUENCHEN', 'Bruderring', 0),
(238, '14785', 'MUENCHEN', 'Loewerweg', 0),
(239, '53557', 'MUENCHEN', 'Benderstrasse', 0),
(240, '32774', 'MUENCHEN', 'Schollstrasse', 0),
(241, '93821', 'MUENCHEN', 'Steinbergweg', 0),
(242, '31946', 'MUENCHEN', 'Dagmar-Ehlert-Gasse', 0),
(243, '05045', 'MUENCHEN', 'Haufferstrasse', 0),
(244, '82938', 'MUENCHEN', 'Schomberring', 0),
(245, '55224', 'MUENCHEN', 'Klingelhoeferweg', 0),
(246, '48593', 'MUENCHEN', 'Hertrampfstr.', 0),
(247, '86992', 'MUENCHEN', 'Klotzstrasse', 0),
(248, '94902', 'MUENCHEN', 'Freudenbergerring', 0),
(249, '99208', 'MUENCHEN', 'Killerplatz', 0),
(250, '83124', 'MUENCHEN', 'Schuchhardtstrasse', 0),
(251, '83724', 'HAMBURG', 'Textorweg', 0),
(252, '14142', 'HAMBURG', 'Asta-Mueller-Gasse', 0),
(253, '30426', 'HAMBURG', 'Thea-Knappe-Gasse', 0),
(254, '00514', 'HAMBURG', 'Rohlederweg', 0),
(255, '11181', 'HAMBURG', 'Genoveva-Schleich-Weg', 0),
(256, '09937', 'HAMBURG', 'Anastasia-Kaester-Gasse', 0),
(257, '23506', 'HAMBURG', 'Sylke-Rust-Ring', 0),
(258, '26492', 'HAMBURG', 'Abram-Riehl-Ring', 0),
(259, '19179', 'HAMBURG', 'Bayram-Schwital-Platz', 0),
(260, '38271', 'HAMBURG', 'Wieland-Kraushaar-Ring', 0),
(261, '48847', 'HAMBURG', 'Miroslav-Holzapfel-Ring', 0),
(262, '79980', 'HAMBURG', 'Bohnbachgasse', 0),
(263, '60954', 'HAMBURG', 'Wigbert-Schinke-Strasse', 0),
(264, '99306', 'HAMBURG', 'Necati-Kobelt-Weg', 0),
(265, '21413', 'HAMBURG', 'Nohlmansgasse', 0),
(266, '87976', 'HAMBURG', 'Theodoros-Reinhardt-Strasse', 0),
(267, '60119', 'HAMBURG', 'Stollgasse', 0),
(268, '12452', 'HAMBURG', 'Alfredo-Jopich-Allee', 0),
(269, '28807', 'HAMBURG', 'Metzweg', 0),
(270, '64572', 'HAMBURG', 'Wesackplatz', 0),
(271, '44420', 'HAMBURG', 'Insa-Doehn-Platz', 0),
(272, '33334', 'HAMBURG', 'Alina-Henschel-Allee', 0),
(273, '53992', 'HAMBURG', 'Haufferallee', 0),
(274, '84965', 'HAMBURG', 'Benedikt-Baum-Strasse', 0),
(275, '77218', 'HAMBURG', 'Baererweg', 0),
(276, '52076', 'HAMBURG', 'Natascha-Loeffler-Allee', 0),
(277, '72609', 'HAMBURG', 'Wagenknechtallee', 0),
(278, '10237', 'HAMBURG', 'Baumweg', 0),
(279, '85532', 'HAMBURG', 'Schmidtkegasse', 0),
(280, '65694', 'HAMBURG', 'Ditmar-Giess-Platz', 0),
(281, '50808', 'HAMBURG', 'Schachtstr.', 0),
(282, '33189', 'HAMBURG', 'Burkard-Hess-Ring', 0),
(283, '42520', 'HAMBURG', 'Truballee', 0),
(284, '30367', 'HAMBURG', 'Bastian-Gude-Platz', 0),
(285, '60762', 'HAMBURG', 'Pergandeplatz', 0),
(286, '81757', 'HAMBURG', 'Marina-Klotz-Strasse', 0),
(287, '91038', 'HAMBURG', 'Kaesterplatz', 0),
(288, '58137', 'HAMBURG', 'Hahnstr.', 0),
(289, '80016', 'HAMBURG', 'Reisingweg', 0),
(290, '61861', 'HAMBURG', 'Warmerplatz', 0),
(291, '78442', 'HAMBURG', 'Carmela-Thanel-Weg', 0),
(292, '08616', 'HAMBURG', 'Yilmaz-Poelitz-Weg', 0),
(293, '93952', 'HAMBURG', 'Hendriksgasse', 0),
(294, '68247', 'HAMBURG', 'Peukertweg', 0),
(295, '82046', 'HAMBURG', 'Jesselallee', 0),
(296, '53135', 'HAMBURG', 'Scheelallee', 0),
(297, '84045', 'HAMBURG', 'Frank-Michael-Baum-Platz', 0),
(298, '84946', 'HAMBURG', 'Marisa-Karge-Platz', 0),
(299, '52379', 'HAMBURG', 'Killergasse', 0),
(300, '60209', 'HAMBURG', 'Urszula-Ziegert-Platz', 0),
(301, '83408', 'HAMBURG', 'Pruschkering', 0),
(302, '59691', 'HAMBURG', 'Doerthe-Liebelt-Strasse', 0),
(303, '40428', 'HAMBURG', 'Ottoring', 0),
(304, '13868', 'HAMBURG', 'Roskothstr.', 0),
(305, '60012', 'HAMBURG', 'Marten-Oestrovsky-Allee', 0),
(306, '93800', 'HAMBURG', 'Trappstrasse', 0),
(307, '58371', 'HAMBURG', 'Tlustekweg', 0),
(308, '48851', 'HAMBURG', 'Siegried-Haering-Weg', 0),
(309, '42204', 'HAMBURG', 'Theodor-Birnbaum-Ring', 0),
(310, '21163', 'HAMBURG', 'Heinweg', 0),
(311, '50523', 'HAMBURG', 'Alice-Hoefig-Gasse', 0),
(312, '39290', 'HAMBURG', 'Dominic-Ortmann-Platz', 0),
(313, '56956', 'HAMBURG', 'Ercan-Geissler-Weg', 0),
(314, '62715', 'HAMBURG', 'Trubingasse', 0),
(315, '99403', 'HAMBURG', 'Roehrdanzallee', 0),
(316, '00380', 'HAMBURG', 'Troestgasse', 0),
(317, '33224', 'HAMBURG', 'Rebecca-Graf-Strasse', 0),
(318, '69792', 'HAMBURG', 'Guelay-Renner-Weg', 0),
(319, '88377', 'HAMBURG', 'Holstenallee', 0),
(320, '80167', 'HAMBURG', 'Hans-Detlef-Weitzel-Platz', 0),
(321, '33185', 'HAMBURG', 'Nadia-Ring-Weg', 0),
(322, '71145', 'HAMBURG', 'Hans-Otto-Dussen van-Platz', 0),
(323, '40637', 'HAMBURG', 'Trappstrasse', 0),
(324, '71832', 'HAMBURG', 'Textorstr.', 0),
(325, '83880', 'HAMBURG', 'Ernst-Scheibe-Gasse', 0),
(326, '52096', 'HAMBURG', 'Junckstr.', 0),
(327, '82165', 'HAMBURG', 'Heribert-Davids-Platz', 0),
(328, '62268', 'HAMBURG', 'Liselotte-Heinrich-Allee', 0),
(329, '17593', 'HAMBURG', 'Striebitzplatz', 0),
(330, '23277', 'HAMBURG', 'Hans-Ludwig-Haering-Gasse', 0),
(331, '95321', 'HAMBURG', 'Irmingard-Kaester-Strasse', 0),
(332, '69630', 'HAMBURG', 'Margaret-Davids-Platz', 0),
(333, '21107', 'HAMBURG', 'Seifertgasse', 0),
(334, '07266', 'HAMBURG', 'Reichmanngasse', 0),
(335, '61310', 'HAMBURG', 'Helen-Steinberg-Weg', 0),
(336, '41722', 'HAMBURG', 'Enno-Flantz-Gasse', 0),
(337, '09918', 'HAMBURG', 'Schoenlandweg', 0),
(338, '19878', 'HAMBURG', 'Luciano-Saeuberlich-Platz', 0),
(339, '05444', 'HAMBURG', 'Curt-Roskoth-Ring', 0),
(340, '13730', 'HAMBURG', 'Ruppertstr.', 0),
(341, '69451', 'HAMBURG', 'Kuschplatz', 0),
(342, '08703', 'HAMBURG', 'Atzlerstrasse', 0),
(343, '43389', 'HAMBURG', 'Schaeferallee', 0),
(344, '75523', 'HAMBURG', 'Speerallee', 0),
(345, '61755', 'HAMBURG', 'Eitel-Lorch-Weg', 0),
(346, '47413', 'HAMBURG', 'Birgitta-Ladeck-Weg', 0),
(347, '17449', 'HAMBURG', 'Yilmaz-Keudel-Strasse', 0),
(348, '16343', 'HAMBURG', 'Scheibeplatz', 0),
(349, '69620', 'HAMBURG', 'Jurij-Meyer-Ring', 0),
(350, '21721', 'HAMBURG', 'Finkeplatz', 0),
(351, '51014', 'HAMBURG', 'Zorbachgasse', 0),
(352, '68004', 'HAMBURG', 'Osman-Kaester-Gasse', 0),
(353, '37897', 'HAMBURG', 'Natalie-Liebelt-Platz', 0),
(354, '16685', 'HAMBURG', 'Eberhard-Heinrich-Allee', 0),
(355, '58465', 'HAMBURG', 'Therese-Benthin-Weg', 0),
(356, '98997', 'HAMBURG', 'Baerbel-Roht-Platz', 0),
(357, '09549', 'HAMBURG', 'Jesselweg', 0),
(358, '81491', 'HAMBURG', 'Steckelstrasse', 0),
(359, '51036', 'HAMBURG', 'Hettnergasse', 0),
(360, '56871', 'HAMBURG', 'Karina-Gertz-Weg', 0),
(361, '85986', 'HAMBURG', 'Roerrichtring', 0),
(362, '33582', 'HAMBURG', 'Baumstr.', 0),
(363, '95426', 'HAMBURG', 'Schenkring', 0),
(364, '77183', 'HAMBURG', 'Riehlgasse', 0),
(365, '66936', 'HAMBURG', 'Aleksander-Gute-Ring', 0),
(366, '24271', 'HAMBURG', 'Edda-Schweitzer-Ring', 0),
(367, '86224', 'HAMBURG', 'Annerose-Graf-Weg', 0),
(368, '32809', 'HAMBURG', 'Erica-Maelzer-Weg', 0),
(369, '57826', 'HAMBURG', 'Raphael-Nohlmans-Strasse', 0),
(370, '11276', 'HAMBURG', 'Erdogan-Rose-Ring', 0),
(371, '64333', 'HAMBURG', 'Juergen-Weiss-Strasse', 0),
(372, '81550', 'HAMBURG', 'Kaesterring', 0),
(373, '31020', 'HAMBURG', 'Wiekweg', 0),
(374, '11885', 'HAMBURG', 'Giessweg', 0),
(375, '94678', 'HAMBURG', 'Rosel-Ladeck-Weg', 0),
(376, '54992', 'HAMBURG', 'Hiltrud-Girschner-Weg', 0),
(377, '84957', 'HAMBURG', 'Alexandros-Werner-Ring', 0),
(378, '74545', 'HAMBURG', 'Jaroslav-Henk-Weg', 0),
(379, '98016', 'HAMBURG', 'Ewald-Geisler-Strasse', 0),
(380, '65153', 'HAMBURG', 'Hornichgasse', 0),
(381, '42685', 'HAMBURG', 'Karl-Peter-Wilms-Weg', 0),
(382, '48980', 'HAMBURG', 'Vito-Drubin-Weg', 0),
(383, '83140', 'HAMBURG', 'Soedinggasse', 0),
(384, '99414', 'HAMBURG', 'Beckmannweg', 0),
(385, '10337', 'HAMBURG', 'Rustweg', 0),
(386, '13166', 'HAMBURG', 'Andre-Koch II-Platz', 0),
(387, '03932', 'HAMBURG', 'Junckenstrasse', 0),
(388, '54711', 'HAMBURG', 'Junkgasse', 0),
(389, '89916', 'HAMBURG', 'Annett-Gierschner-Platz', 0),
(390, '13547', 'HAMBURG', 'Muelichenplatz', 0),
(391, '74433', 'HAMBURG', 'Maria-Theresia-Trubin-Platz', 0),
(392, '98436', 'HAMBURG', 'Kati-Klemt-Weg', 0),
(393, '55817', 'HAMBURG', 'Koehlerstrasse', 0),
(394, '38261', 'HAMBURG', 'Ortmannplatz', 0),
(395, '01262', 'HAMBURG', 'Franca-Hecker-Platz', 0),
(396, '07246', 'HAMBURG', 'Patbergallee', 0),
(397, '80993', 'HAMBURG', 'Klemmring', 0),
(398, '81104', 'HAMBURG', 'Hoefigstr.', 0),
(399, '15074', 'HAMBURG', 'Gabi-Jockel-Gasse', 0),
(400, '92725', 'HAMBURG', 'Hannah-Steckel-Allee', 0),
(401, '30326', 'HAMBURG', 'Gorlitzweg', 0),
(402, '53382', 'HAMBURG', 'Schmidtweg', 0),
(403, '00682', 'HAMBURG', 'Gilbert-Thies-Gasse', 0),
(404, '66758', 'HAMBURG', 'Schleichstrasse', 0),
(405, '03506', 'HAMBURG', 'Annelore-van der Dussen-Platz', 0),
(406, '84887', 'HAMBURG', 'Naserstr.', 0),
(407, '71110', 'HAMBURG', 'Angelika-Johann-Strasse', 0),
(408, '92766', 'HAMBURG', 'Sagerplatz', 0),
(409, '97118', 'HAMBURG', 'Ackermannstrasse', 0),
(410, '44531', 'HAMBURG', 'Geiselstrasse', 0),
(411, '93057', 'HAMBURG', 'Junkstr.', 0),
(412, '29624', 'HAMBURG', 'Muehlestrasse', 0),
(413, '64212', 'HAMBURG', 'Schmidtgasse', 0),
(414, '32566', 'HAMBURG', 'Schmidtkeplatz', 0),
(415, '90465', 'HAMBURG', 'Emilia-Bruder-Strasse', 0),
(416, '15974', 'HAMBURG', 'Gerlinde-Mangold-Gasse', 0),
(417, '59609', 'HAMBURG', 'Hubertus-Stiebitz-Weg', 0),
(418, '23255', 'HAMBURG', 'Willy-Rust-Strasse', 0),
(419, '76823', 'HAMBURG', 'Schinkeweg', 0),
(420, '08428', 'HAMBURG', 'Horst-Dieter-Meister-Platz', 0),
(421, '80199', 'HAMBURG', 'Leszek-Fiebig-Platz', 0),
(422, '56970', 'HAMBURG', 'Mirco-Roemer-Platz', 0),
(423, '71736', 'HAMBURG', 'Foersterplatz', 0),
(424, '09483', 'HAMBURG', 'Bastian-Oderwald-Ring', 0),
(425, '81232', 'HAMBURG', 'Paolo-Mangold-Strasse', 0),
(426, '28508', 'HAMBURG', 'Jens-Uwe-Hethur-Weg', 0),
(427, '08553', 'HAMBURG', 'Julius-Bachmann-Ring', 0),
(428, '05813', 'HAMBURG', 'Bogdan-Hesse-Ring', 0),
(429, '31185', 'HAMBURG', 'Gerald-Hendriks-Ring', 0),
(430, '26048', 'HAMBURG', 'Eigenwilligstrasse', 0),
(431, '17176', 'HAMBURG', 'Lorchallee', 0),
(432, '46193', 'HAMBURG', 'Rafael-Etzold-Strasse', 0),
(433, '92377', 'HAMBURG', 'Rosalinde-Muehle-Gasse', 0),
(434, '95545', 'HAMBURG', 'Schenkplatz', 0),
(435, '63753', 'HAMBURG', 'Koch IIstrasse', 0),
(436, '83448', 'HAMBURG', 'Sigmar-Suessebier-Platz', 0),
(437, '04717', 'HAMBURG', 'Aleksej-Fischer-Platz', 0),
(438, '78518', 'HAMBURG', 'Doehnstrasse', 0),
(439, '58456', 'HAMBURG', 'Eberhardtweg', 0),
(440, '72923', 'HAMBURG', 'Malte-Suessebier-Strasse', 0),
(441, '99899', 'HAMBURG', 'Raphael-Trupp-Strasse', 0),
(442, '94666', 'HAMBURG', 'Scheibegasse', 0),
(443, '32995', 'HAMBURG', 'Hubert-Dowerg-Ring', 0),
(444, '28173', 'HAMBURG', 'Bozena-Drub-Allee', 0),
(445, '63250', 'HAMBURG', 'Junckplatz', 0),
(446, '32508', 'HAMBURG', 'Harloffgasse', 0),
(447, '90100', 'HAMBURG', 'Annett-Freudenberger-Strasse', 0),
(448, '25385', 'HAMBURG', 'Gino-Hande-Allee', 0),
(449, '34030', 'HAMBURG', 'Rennerallee', 0),
(450, '04057', 'HAMBURG', 'Evangelos-Schleich-Weg', 0),
(451, '59588', 'BERLIN', 'Osman-Suessebier-Strasse', 0),
(452, '75210', 'BERLIN', 'Vollbrechtallee', 0),
(453, '73923', 'BERLIN', 'Eigenwilligweg', 0),
(454, '21238', 'BERLIN', 'Bernt-Zahn-Weg', 0),
(455, '44441', 'BERLIN', 'Koch IIgasse', 0),
(456, '24431', 'BERLIN', 'Miriam-Koch-Allee', 0),
(457, '35507', 'BERLIN', 'Vincenzo-Geisler-Platz', 0),
(458, '13885', 'BERLIN', 'Carstengasse', 0),
(459, '98731', 'BERLIN', 'Klaere-Schleich-Platz', 0),
(460, '12474', 'BERLIN', 'Kargestrasse', 0),
(461, '85240', 'BERLIN', 'Geislergasse', 0),
(462, '75804', 'BERLIN', 'Klaus-Dieter-Scheibe-Gasse', 0),
(463, '61529', 'BERLIN', 'Klemmstr.', 0),
(464, '88572', 'BERLIN', 'Galina-Margraf-Weg', 0),
(465, '32892', 'BERLIN', 'Gerfried-Gumprich-Allee', 0),
(466, '12613', 'BERLIN', 'Jungferstrasse', 0),
(467, '67783', 'BERLIN', 'Heydrichring', 0),
(468, '92297', 'BERLIN', 'Kathleen-Conradi-Allee', 0),
(469, '16171', 'BERLIN', 'Rosalie-Kitzmann-Gasse', 0),
(470, '05166', 'BERLIN', 'Tatjana-Putz-Ring', 0),
(471, '96581', 'BERLIN', 'Karl-Dippel-Gasse', 0),
(472, '46250', 'BERLIN', 'Rohtring', 0),
(473, '98858', 'BERLIN', 'Juan-Oestrovsky-Weg', 0),
(474, '45556', 'BERLIN', 'Bernadette-Adolph-Strasse', 0),
(475, '54874', 'BERLIN', 'Vesna-Loechel-Platz', 0),
(476, '04560', 'BERLIN', 'Paertzeltplatz', 0),
(477, '75143', 'BERLIN', 'Gretchen-Beier-Platz', 0),
(478, '99037', 'BERLIN', 'Bachmannring', 0),
(479, '29384', 'BERLIN', 'Haeringplatz', 0),
(480, '69111', 'BERLIN', 'Briemergasse', 0),
(481, '39658', 'BERLIN', 'Dragica-Hentschel-Platz', 0),
(482, '52208', 'BERLIN', 'Jens-Drubin-Weg', 0),
(483, '37033', 'BERLIN', 'Hasso-Gierschner-Ring', 0),
(484, '71783', 'BERLIN', 'Brunhilde-Baehr-Strasse', 0),
(485, '65396', 'BERLIN', 'Silvester-Lange-Strasse', 0),
(486, '71748', 'BERLIN', 'Grafring', 0),
(487, '09864', 'BERLIN', 'Huhngasse', 0),
(488, '44740', 'BERLIN', 'Tino-Schleich-Strasse', 0),
(489, '58103', 'BERLIN', 'Faustgasse', 0),
(490, '14719', 'BERLIN', 'Karl-Otto-Holsten-Allee', 0),
(491, '68388', 'BERLIN', 'Conradiweg', 0),
(492, '53567', 'BERLIN', 'Klingelhoeferstrasse', 0),
(493, '83126', 'BERLIN', 'Mia-Luebs-Gasse', 0),
(494, '27755', 'BERLIN', 'Traudel-Kallert-Allee', 0),
(495, '93884', 'BERLIN', 'Dan-Wernecke-Weg', 0),
(496, '88034', 'BERLIN', 'Sauerplatz', 0),
(497, '76083', 'BERLIN', 'Anika-Doerr-Allee', 0),
(498, '81791', 'BERLIN', 'Gina-Gunpf-Allee', 0),
(499, '75000', 'BERLIN', 'Karl-August-Doerr-Ring', 0),
(500, '74812', 'BERLIN', 'Jaentschgasse', 0),
(501, '85418', 'BERLIN', 'Antonino-Geissler-Platz', 0),
(502, '47430', 'BERLIN', 'Pascale-Waehner-Platz', 0),
(503, '54667', 'BERLIN', 'Hoefigplatz', 0),
(504, '96021', 'BERLIN', 'Scheelplatz', 0),
(505, '17752', 'BERLIN', 'Robert-Binner-Weg', 0),
(506, '43019', 'BERLIN', 'Elzbieta-Naser-Strasse', 0),
(507, '67455', 'BERLIN', 'Froehlichgasse', 0),
(508, '30475', 'BERLIN', 'Norman-Ruppert-Strasse', 0),
(509, '22502', 'BERLIN', 'Haeringring', 0),
(510, '26779', 'BERLIN', 'Thanelallee', 0),
(511, '23174', 'BERLIN', 'Heintzeallee', 0),
(512, '69984', 'BERLIN', 'Benderplatz', 0),
(513, '00788', 'BERLIN', 'Steinbergstr.', 0),
(514, '24168', 'BERLIN', 'Ernst-Raedel-Weg', 0),
(515, '50243', 'BERLIN', 'Steyring', 0),
(516, '25295', 'BERLIN', 'Weimerplatz', 0),
(517, '60709', 'BERLIN', 'Hans-J.-Schmiedt-Weg', 0),
(518, '26484', 'BERLIN', 'Kristine-Baerer-Weg', 0),
(519, '34936', 'BERLIN', 'Waltraud-Barth-Strasse', 0),
(520, '71091', 'BERLIN', 'Kramerweg', 0),
(521, '86901', 'BERLIN', 'Alexandre-Roehrdanz-Weg', 0),
(522, '12331', 'BERLIN', 'Metzweg', 0),
(523, '97208', 'BERLIN', 'Gunpfgasse', 0),
(524, '39770', 'BERLIN', 'Bernhardine-Rudolph-Ring', 0),
(525, '77887', 'BERLIN', 'Wera-Koester-Weg', 0),
(526, '46412', 'BERLIN', 'Ria-Butte-Platz', 0),
(527, '77530', 'BERLIN', 'Saeuberlichgasse', 0),
(528, '87858', 'BERLIN', 'Adlergasse', 0),
(529, '39834', 'BERLIN', 'Barkholzweg', 0),
(530, '94469', 'BERLIN', 'Spiessstrasse', 0),
(531, '70606', 'BERLIN', 'Scheuermannallee', 0),
(532, '79350', 'BERLIN', 'Seifertplatz', 0),
(533, '87513', 'BERLIN', 'Anika-Trupp-Allee', 0),
(534, '68088', 'BERLIN', 'Ignaz-Hartmann-Strasse', 0),
(535, '58416', 'BERLIN', 'Bauerstr.', 0),
(536, '49147', 'BERLIN', 'Ziegertweg', 0),
(537, '88546', 'BERLIN', 'auch Schlauchinplatz', 0),
(538, '31460', 'BERLIN', 'Zita-Matthaei-Gasse', 0),
(539, '68192', 'BERLIN', 'Junckweg', 0),
(540, '36030', 'BERLIN', 'Gisela-Reuter-Gasse', 0),
(541, '98517', 'BERLIN', 'Genoveva-Davids-Allee', 0),
(542, '86926', 'BERLIN', 'Steinbergstr.', 0),
(543, '73844', 'BERLIN', 'Scheuermannring', 0),
(544, '75260', 'BERLIN', 'Tom-Butte-Gasse', 0),
(545, '74341', 'BERLIN', 'Tilly-Koehler-Ring', 0),
(546, '76262', 'BERLIN', 'Wellerweg', 0),
(547, '99972', 'BERLIN', 'Hofmannstrasse', 0),
(548, '30956', 'BERLIN', 'Frankeplatz', 0),
(549, '84570', 'BERLIN', 'Gertzstr.', 0),
(550, '06935', 'BERLIN', 'Jacobgasse', 0),
(551, '84749', 'BERLIN', 'Schulzweg', 0),
(552, '05933', 'BERLIN', 'Veronika-Wirth-Weg', 0),
(553, '40859', 'BERLIN', 'Sarina-Peukert-Strasse', 0),
(554, '26023', 'BERLIN', 'Rosemarie-Austermuehle-Ring', 0),
(555, '13803', 'BERLIN', 'Margarethe-Troest-Allee', 0),
(556, '15285', 'BERLIN', 'Scheelgasse', 0),
(557, '45820', 'BERLIN', 'Ramazan-Mueller-Allee', 0),
(558, '53974', 'BERLIN', 'Willfried-Schmidtke-Allee', 0),
(559, '64857', 'BERLIN', 'Karl-Heinz-Plath-Strasse', 0),
(560, '77349', 'BERLIN', 'Elfi-Stoll-Gasse', 0),
(561, '92568', 'BERLIN', 'Keudelring', 0),
(562, '49782', 'BERLIN', 'Dana-Stroh-Ring', 0),
(563, '88225', 'BERLIN', 'Kata-Renner-Gasse', 0),
(564, '44894', 'BERLIN', 'Kargestr.', 0),
(565, '14519', 'BERLIN', 'Franjo-Junitz-Allee', 0),
(566, '40332', 'BERLIN', 'Annie-Weitzel-Ring', 0),
(567, '08172', 'BERLIN', 'Krausestrasse', 0),
(568, '74847', 'BERLIN', 'Alexander-Sontag-Ring', 0),
(569, '59816', 'BERLIN', 'Drubinring', 0),
(570, '01717', 'BERLIN', 'Roerrichtstr.', 0),
(571, '86948', 'BERLIN', 'Froehlichstrasse', 0),
(572, '77569', 'BERLIN', 'Rupert-Noack-Strasse', 0),
(573, '77860', 'BERLIN', 'Holtgasse', 0),
(574, '22726', 'BERLIN', 'Trubring', 0),
(575, '95779', 'BERLIN', 'Piepergasse', 0),
(576, '30418', 'BERLIN', 'Torben-Weimer-Ring', 0),
(577, '16797', 'BERLIN', 'Trudel-Ruppersberger-Allee', 0),
(578, '82587', 'BERLIN', 'Geisslerstrasse', 0),
(579, '32884', 'BERLIN', 'Kambsstrasse', 0),
(580, '34958', 'BERLIN', 'Tibor-Renner-Gasse', 0),
(581, '21117', 'BERLIN', 'Birnbaumstr.', 0),
(582, '93239', 'BERLIN', 'Gierschnerring', 0),
(583, '77894', 'BERLIN', 'Budigallee', 0),
(584, '08599', 'BERLIN', 'Irina-Plath-Platz', 0),
(585, '05613', 'BERLIN', 'Mendeweg', 0),
(586, '94898', 'BERLIN', 'Muehleallee', 0),
(587, '50155', 'BERLIN', 'Jacobi Jaeckelplatz', 0),
(588, '71941', 'BERLIN', 'Maurice-Dippel-Strasse', 0),
(589, '78804', 'BERLIN', 'Viktoria-Holzapfel-Strasse', 0),
(590, '96239', 'BERLIN', 'Ismet-Wulf-Ring', 0),
(591, '46060', 'BERLIN', 'Baererallee', 0),
(592, '38096', 'BERLIN', 'Mansring', 0),
(593, '98403', 'BERLIN', 'Schmiedeckegasse', 0),
(594, '93694', 'BERLIN', 'Heidrichplatz', 0),
(595, '82164', 'BERLIN', 'Lorchring', 0),
(596, '76437', 'BERLIN', 'Manuel-Heidrich-Weg', 0),
(597, '01483', 'BERLIN', 'Hertrampfstr.', 0),
(598, '22509', 'BERLIN', 'Manuel-Kensy-Weg', 0),
(599, '60661', 'BERLIN', 'Samir-Hoefig-Platz', 0),
(600, '61235', 'BERLIN', 'Ackermannstrasse', 0),
(601, '09040', 'BERLIN', 'Janet-Scheel-Allee', 0),
(602, '47132', 'BERLIN', 'Rennerstr.', 0),
(603, '40979', 'BERLIN', 'Kruschwitzstr.', 0),
(604, '59013', 'BERLIN', 'Sarina-Etzler-Platz', 0),
(605, '03771', 'BERLIN', 'Roehrichtstr.', 0),
(606, '64467', 'BERLIN', 'Luzie-Boerner-Allee', 0),
(607, '54266', 'BERLIN', 'Kranzstrasse', 0),
(608, '98607', 'BERLIN', 'Walentina-Kallert-Strasse', 0),
(609, '93209', 'BERLIN', 'Geiselstrasse', 0),
(610, '73415', 'BERLIN', 'Ziegertstrasse', 0),
(611, '62352', 'BERLIN', 'Zobelstr.', 0),
(612, '94974', 'BERLIN', 'Roerrichtring', 0),
(613, '60474', 'BERLIN', 'Mosemannplatz', 0),
(614, '08751', 'BERLIN', 'Ria-Juettner-Strasse', 0),
(615, '95288', 'BERLIN', 'Norma-Klemm-Strasse', 0),
(616, '61391', 'BERLIN', 'Ilka-Mosemann-Strasse', 0),
(617, '37532', 'BERLIN', 'Nettestr.', 0),
(618, '06389', 'BERLIN', 'Schenkallee', 0),
(619, '51860', 'BERLIN', 'Kitzmannring', 0),
(620, '57608', 'BERLIN', 'Kreinring', 0),
(621, '52746', 'BERLIN', 'Keudelring', 0),
(622, '58574', 'BERLIN', 'Anica-Keudel-Ring', 0),
(623, '94556', 'BERLIN', 'Schomberallee', 0),
(624, '84537', 'BERLIN', 'Bianka-Ullrich-Gasse', 0),
(625, '05227', 'BERLIN', 'Wellerstr.', 0),
(626, '38610', 'BERLIN', 'Weinholdplatz', 0),
(627, '00799', 'BERLIN', 'Rosemannallee', 0),
(628, '44167', 'BERLIN', 'Nuray-Wilmsen-Platz', 0),
(629, '53122', 'BERLIN', 'Zaenkerplatz', 0),
(630, '72805', 'BERLIN', 'Ljiljana-Schmidt-Gasse', 0),
(631, '20759', 'BERLIN', 'Orhan-Bonbach-Platz', 0),
(632, '43209', 'BERLIN', 'Roehrichtplatz', 0),
(633, '56003', 'BERLIN', 'Bohnbachgasse', 0),
(634, '75635', 'BERLIN', 'Segebahngasse', 0),
(635, '72747', 'BERLIN', 'Stanislav-Drub-Allee', 0),
(636, '83302', 'BERLIN', 'Danica-Gotthard-Strasse', 0),
(637, '75790', 'BERLIN', 'Dagobert-Bolander-Strasse', 0),
(638, '26043', 'BERLIN', 'Wesackstrasse', 0),
(639, '00535', 'BERLIN', 'Constance-Raedel-Ring', 0),
(640, '26346', 'BERLIN', 'Mary-Taesche-Strasse', 0),
(641, '61982', 'BERLIN', 'Ernestine-Mueller-Platz', 0),
(642, '55847', 'BERLIN', 'Murat-Gnatz-Platz', 0),
(643, '74986', 'BERLIN', 'Cathleen-Gude-Platz', 0),
(644, '77611', 'BERLIN', 'Wulf-Rosemann-Weg', 0),
(645, '61765', 'BERLIN', 'Ottokar-Eberth-Gasse', 0),
(646, '97852', 'BERLIN', 'Karl-Friedrich-Cichorius-Weg', 0),
(647, '51246', 'BERLIN', 'Kambsplatz', 0),
(648, '16685', 'BERLIN', 'Naserstr.', 0),
(649, '54171', 'BERLIN', 'Inka-Seifert-Gasse', 0),
(650, '39426', 'BERLIN', 'Isolde-Weinhold-Platz', 0),
(651, '72914', 'ERFURT', 'Lachmannstr.', 0),
(652, '55253', 'ERFURT', 'Gunter-Walter-Ring', 0),
(653, '29224', 'ERFURT', 'Viktor-Dobes-Gasse', 0),
(654, '95703', 'ERFURT', 'Paul-Gerhard-Scholz-Strasse', 0),
(655, '87306', 'ERFURT', 'Baehrstr.', 0),
(656, '15702', 'ERFURT', 'Marianne-Schinke-Strasse', 0),
(657, '07248', 'ERFURT', 'Raedelstr.', 0),
(658, '28480', 'ERFURT', 'Bauerweg', 0),
(659, '32415', 'ERFURT', 'Casparplatz', 0),
(660, '39654', 'ERFURT', 'Waehnerstrasse', 0),
(661, '75405', 'ERFURT', 'Mangoldplatz', 0),
(662, '80187', 'ERFURT', 'Bonbachstrasse', 0),
(663, '53701', 'ERFURT', 'Beerring', 0),
(664, '45828', 'ERFURT', 'Klingelhoeferweg', 0),
(665, '24664', 'ERFURT', 'Anneke-auch Schlauchin-Platz', 0),
(666, '69101', 'ERFURT', 'Miesstr.', 0),
(667, '98355', 'ERFURT', 'Schmidtstr.', 0),
(668, '42192', 'ERFURT', 'Nicolai-Warmer-Platz', 0),
(669, '68011', 'ERFURT', 'Isa-Renner-Gasse', 0),
(670, '02548', 'ERFURT', 'Paffrathstr.', 0),
(671, '17619', 'ERFURT', 'Waehnerring', 0),
(672, '78441', 'ERFURT', 'Alice-Lorch-Allee', 0),
(673, '84730', 'ERFURT', 'Hermighausengasse', 0),
(674, '75635', 'ERFURT', 'Michelle-Schmidt-Weg', 0),
(675, '91432', 'ERFURT', 'Anatoli-Peukert-Weg', 0),
(676, '04522', 'ERFURT', 'Wagenknechtweg', 0),
(677, '76104', 'ERFURT', 'Christophring', 0),
(678, '96301', 'ERFURT', 'Doerrstr.', 0),
(679, '05973', 'ERFURT', 'Giessring', 0),
(680, '45245', 'ERFURT', 'Bolnbachweg', 0),
(681, '01865', 'ERFURT', 'Truebring', 0),
(682, '91022', 'ERFURT', 'Koch IIallee', 0),
(683, '70509', 'ERFURT', 'Mina-Jaentsch-Weg', 0),
(684, '52043', 'ERFURT', 'Haasering', 0),
(685, '70779', 'ERFURT', 'Elli-Renner-Platz', 0),
(686, '89043', 'ERFURT', 'Schoenlandring', 0),
(687, '62575', 'ERFURT', 'Susanne-Roemer-Gasse', 0),
(688, '91689', 'ERFURT', 'Marianna-Soeding-Allee', 0),
(689, '72592', 'ERFURT', 'Freudenbergerweg', 0),
(690, '09293', 'ERFURT', 'Lilo-Becker-Ring', 0),
(691, '56231', 'ERFURT', 'Hettnerring', 0),
(692, '45540', 'ERFURT', 'Klaus Dieter-Klapp-Ring', 0),
(693, '34144', 'ERFURT', 'Margrit-Mans-Ring', 0),
(694, '59413', 'ERFURT', 'Junckenweg', 0),
(695, '76762', 'ERFURT', 'Franz-Xaver-Sauer-Strasse', 0),
(696, '56179', 'ERFURT', 'Baehrstr.', 0),
(697, '55796', 'ERFURT', 'Stiffelplatz', 0),
(698, '08913', 'ERFURT', 'Ingetraut-Becker-Weg', 0),
(699, '93825', 'ERFURT', 'Bergerstr.', 0),
(700, '36714', 'ERFURT', 'Ahmed-Jungfer-Weg', 0),
(701, '72296', 'ERFURT', 'Muharrem-Rogner-Gasse', 0),
(702, '59696', 'ERFURT', 'Dehmelring', 0),
(703, '69712', 'ERFURT', 'Kreingasse', 0),
(704, '61375', 'ERFURT', 'Pruschkeweg', 0),
(705, '16413', 'ERFURT', 'Marleen-Hiller-Weg', 0),
(706, '82744', 'ERFURT', 'Kargering', 0),
(707, '22317', 'ERFURT', 'Austermuehlestr.', 0),
(708, '90885', 'ERFURT', 'Karl-Ernst-Sauer-Strasse', 0),
(709, '08776', 'ERFURT', 'Lieselotte-Wirth-Ring', 0),
(710, '00689', 'ERFURT', 'Rosalinde-Jessel-Platz', 0),
(711, '32291', 'ERFURT', 'Paul-Knappe-Gasse', 0),
(712, '75376', 'ERFURT', 'Adolphplatz', 0),
(713, '77444', 'ERFURT', 'Klaus-Werner-Junken-Gasse', 0),
(714, '43319', 'ERFURT', 'Gierschnerallee', 0),
(715, '60436', 'ERFURT', 'Etta-Ditschlerin-Strasse', 0),
(716, '46680', 'ERFURT', 'Wendeplatz', 0),
(717, '99135', 'ERFURT', 'Oderwaldgasse', 0),
(718, '44589', 'ERFURT', 'Claudius-Caspar-Ring', 0),
(719, '29924', 'ERFURT', 'Schuelergasse', 0),
(720, '72763', 'ERFURT', 'Josefine-Austermuehle-Ring', 0),
(721, '21406', 'ERFURT', 'Soelzerallee', 0),
(722, '65451', 'ERFURT', 'Werneckestr.', 0),
(723, '64983', 'ERFURT', 'Wernerallee', 0),
(724, '33977', 'ERFURT', 'Jopichgasse', 0),
(725, '54313', 'ERFURT', 'Schombergasse', 0),
(726, '35732', 'ERFURT', 'Groettnerring', 0),
(727, '16199', 'ERFURT', 'Roemerstr.', 0),
(728, '18816', 'ERFURT', 'Aurelia-Junck-Gasse', 0),
(729, '90947', 'ERFURT', 'Andrzej-Suessebier-Ring', 0),
(730, '37157', 'ERFURT', 'Kambsstrasse', 0),
(731, '25411', 'ERFURT', 'Gabriele-Scholl-Allee', 0),
(732, '96745', 'ERFURT', 'Eimerweg', 0),
(733, '70674', 'ERFURT', 'Marietta-Mohaupt-Strasse', 0),
(734, '41638', 'ERFURT', 'Cecilia-Drubin-Strasse', 0),
(735, '80336', 'ERFURT', 'Elisa-Juettner-Strasse', 0),
(736, '72662', 'ERFURT', 'Gerwin-Wieloch-Gasse', 0),
(737, '00977', 'ERFURT', 'Heuserstr.', 0),
(738, '56318', 'ERFURT', 'Erkan-Boucsein-Platz', 0),
(739, '88704', 'ERFURT', 'Luebsstr.', 0),
(740, '51850', 'ERFURT', 'Nermin-Keudel-Gasse', 0),
(741, '94993', 'ERFURT', 'Weissstr.', 0),
(742, '53845', 'ERFURT', 'Antonia-Eckbauer-Weg', 0),
(743, '05238', 'ERFURT', 'Scheelstr.', 0),
(744, '16314', 'ERFURT', 'Etzlerstrasse', 0),
(745, '07332', 'ERFURT', 'Sami-Scheuermann-Allee', 0),
(746, '48365', 'ERFURT', 'Rena-Naser-Gasse', 0),
(747, '16633', 'ERFURT', 'Sabine-Wirth-Weg', 0),
(748, '97838', 'ERFURT', 'Carstenring', 0),
(749, '22162', 'ERFURT', 'Mariele-Scheibe-Gasse', 0),
(750, '28010', 'ERFURT', 'Muellerweg', 0),
(751, '53675', 'ERFURT', 'Georgine-Stolze-Gasse', 0),
(752, '58364', 'ERFURT', 'Bruni-Butte-Gasse', 0),
(753, '11642', 'ERFURT', 'Mariele-Doerr-Gasse', 0),
(754, '38225', 'ERFURT', 'Angelique-Adler-Platz', 0),
(755, '16906', 'ERFURT', 'Stolzegasse', 0),
(756, '51142', 'ERFURT', 'Neureutherweg', 0),
(757, '05202', 'ERFURT', 'Etzlerstrasse', 0),
(758, '71508', 'ERFURT', 'Ingeborg-Dehmel-Gasse', 0),
(759, '65225', 'ERFURT', 'Steinbergstr.', 0),
(760, '89225', 'ERFURT', 'Hornichgasse', 0),
(761, '01878', 'ERFURT', 'Ladeckplatz', 0),
(762, '46528', 'ERFURT', 'Veronika-Kaul-Platz', 0),
(763, '55647', 'ERFURT', 'Mansring', 0),
(764, '66397', 'ERFURT', 'Freya-Seifert-Allee', 0),
(765, '74408', 'ERFURT', 'Karzgasse', 0),
(766, '80105', 'ERFURT', 'Annette-Seifert-Weg', 0),
(767, '45992', 'ERFURT', 'Sigrid-Birnbaum-Strasse', 0),
(768, '32070', 'ERFURT', 'Weitzelstr.', 0),
(769, '30821', 'ERFURT', 'Davidsring', 0),
(770, '88616', 'ERFURT', 'Scholtzstrasse', 0),
(771, '84952', 'ERFURT', 'Miesstrasse', 0),
(772, '13594', 'ERFURT', 'Tilmann-Haenel-Gasse', 0),
(773, '98185', 'ERFURT', 'Cilli-Heinrich-Platz', 0),
(774, '75429', 'ERFURT', 'Gertraud-Kaester-Allee', 0),
(775, '06008', 'ERFURT', 'Schmidtkering', 0),
(776, '32643', 'ERFURT', 'Wirthgasse', 0),
(777, '52884', 'ERFURT', 'Jochen-Hoerle-Platz', 0),
(778, '38377', 'ERFURT', 'Hans-Adolf-Junitz-Platz', 0),
(779, '52845', 'ERFURT', 'Gumprichring', 0),
(780, '11537', 'ERFURT', 'Haasering', 0),
(781, '98675', 'ERFURT', 'Karl-Hermann-Zahn-Ring', 0),
(782, '19226', 'ERFURT', 'Nicole-Albers-Platz', 0),
(783, '76725', 'ERFURT', 'Gordon-Nohlmans-Allee', 0),
(784, '83882', 'ERFURT', 'Erich-Bloch-Allee', 0),
(785, '31917', 'ERFURT', 'Strohweg', 0),
(786, '45436', 'ERFURT', 'Beerstr.', 0),
(787, '73023', 'ERFURT', 'Kristian-Schomber-Weg', 0),
(788, '71127', 'ERFURT', 'Ann-Bloch-Strasse', 0),
(789, '03930', 'ERFURT', 'Matthias-Roehrdanz-Weg', 0),
(790, '50906', 'ERFURT', 'Valentine-Hethur-Ring', 0),
(791, '65480', 'ERFURT', 'Birnbaumgasse', 0),
(792, '93242', 'ERFURT', 'Eberthstr.', 0),
(793, '08827', 'ERFURT', 'Hedi-Tschentscher-Gasse', 0),
(794, '40094', 'ERFURT', 'Johannweg', 0),
(795, '23063', 'ERFURT', 'Vincenzo-Eimer-Gasse', 0),
(796, '60071', 'ERFURT', 'Vera-Hahn-Allee', 0),
(797, '10262', 'ERFURT', 'Elvira-Hermighausen-Strasse', 0),
(798, '87931', 'ERFURT', 'Adlerallee', 0),
(799, '44475', 'ERFURT', 'Dowerggasse', 0),
(800, '94449', 'ERFURT', 'Niemeierstrasse', 0),
(801, '01104', 'ERFURT', 'Knappegasse', 0),
(802, '78248', 'ERFURT', 'Alwina-Carsten-Ring', 0),
(803, '35214', 'ERFURT', 'Filiz-Gorlitz-Gasse', 0),
(804, '91797', 'ERFURT', 'Karzplatz', 0),
(805, '70852', 'ERFURT', 'Tamara-Thies-Ring', 0),
(806, '31710', 'ERFURT', 'Hans Josef-Buchholz-Allee', 0),
(807, '15984', 'ERFURT', 'Goetz-Geisel-Weg', 0),
(808, '87662', 'ERFURT', 'Kreinallee', 0),
(809, '94101', 'ERFURT', 'Nora-Schmiedecke-Weg', 0),
(810, '03779', 'ERFURT', 'Freudenbergerstrasse', 0),
(811, '28948', 'ERFURT', 'Seifertallee', 0),
(812, '51199', 'ERFURT', 'Schottinring', 0),
(813, '55788', 'ERFURT', 'Heinz-Dieter-Kobelt-Platz', 0),
(814, '00982', 'ERFURT', 'Erika-Ruppersberger-Weg', 0),
(815, '42143', 'ERFURT', 'Harloffweg', 0),
(816, '60837', 'ERFURT', 'Hans-Eberhard-Ortmann-Weg', 0),
(817, '33501', 'ERFURT', 'Hans D.-Doerschner-Strasse', 0),
(818, '06643', 'ERFURT', 'Liesel-Karz-Allee', 0),
(819, '71346', 'ERFURT', 'Paulo-Meister-Platz', 0),
(820, '14192', 'ERFURT', 'Erhardt-Reinhardt-Weg', 0),
(821, '77595', 'ERFURT', 'Ren?-Eigenwillig-Weg', 0),
(822, '37148', 'ERFURT', 'Kreszentia-Austermuehle-Strass', 0),
(823, '34551', 'ERFURT', 'Eberthweg', 0),
(824, '04756', 'ERFURT', 'Traute-Beier-Strasse', 0),
(825, '28995', 'ERFURT', 'Sabina-Rudolph-Platz', 0),
(826, '54922', 'ERFURT', 'Monika-Wohlgemut-Gasse', 0),
(827, '40653', 'ERFURT', 'Jadwiga-Scholtz-Strasse', 0),
(828, '12453', 'ERFURT', 'Stavros-Mielcarek-Weg', 0),
(829, '76028', 'ERFURT', 'Magrit-Stoll-Platz', 0),
(830, '64071', 'ERFURT', 'Stiffelweg', 0),
(831, '07875', 'ERFURT', 'Kitzmanngasse', 0),
(832, '49142', 'ERFURT', 'Traugott-Doehn-Strasse', 0),
(833, '16513', 'ERFURT', 'Troeststr.', 0),
(834, '89620', 'ERFURT', 'Wirthstrasse', 0),
(835, '26311', 'ERFURT', 'Roehrichtweg', 0),
(836, '44481', 'ERFURT', 'Baldur-Meyer-Allee', 0),
(837, '27572', 'ERFURT', 'Schmidtgasse', 0),
(838, '74705', 'ERFURT', 'Beckerallee', 0),
(839, '25197', 'ERFURT', 'Vladimir-Schleich-Ring', 0),
(840, '31276', 'ERFURT', 'Heide-Marie-Kaul-Platz', 0),
(841, '45273', 'ERFURT', 'Evelin-Meister-Strasse', 0),
(842, '16382', 'ERFURT', 'Freya-Sorgatz-Weg', 0),
(843, '91273', 'ERFURT', 'Francisco-Ruppert-Strasse', 0),
(844, '29707', 'ERFURT', 'Krokerweg', 0),
(845, '98012', 'ERFURT', 'Sieringweg', 0),
(846, '35482', 'ERFURT', 'Fischerallee', 0),
(847, '92071', 'ERFURT', 'Plathstr.', 0),
(848, '64340', 'ERFURT', 'Ingetraud-Mangold-Gasse', 0),
(849, '64477', 'ERFURT', 'Johannweg', 0),
(850, '14094', 'ERFURT', 'Reimer-Birnbaum-Gasse', 0),
(851, '33451', 'FRANKFURT AM MAIN', 'Bertha-Wagenknecht-Gasse', 0),
(852, '09542', 'FRANKFURT AM MAIN', 'Koehlerweg', 0),
(853, '86869', 'FRANKFURT AM MAIN', 'Budiggasse', 0),
(854, '80034', 'FRANKFURT AM MAIN', 'Boucseinallee', 0),
(855, '65869', 'FRANKFURT AM MAIN', 'Justina-Hahn-Platz', 0),
(856, '28295', 'FRANKFURT AM MAIN', 'Ruppertgasse', 0),
(857, '78176', 'FRANKFURT AM MAIN', 'Dehmelstr.', 0),
(858, '55652', 'FRANKFURT AM MAIN', 'Grafplatz', 0),
(859, '58971', 'FRANKFURT AM MAIN', 'Zimmerring', 0),
(860, '97498', 'FRANKFURT AM MAIN', 'Kochstr.', 0),
(861, '77670', 'FRANKFURT AM MAIN', 'Schottinring', 0),
(862, '57776', 'FRANKFURT AM MAIN', 'Froehlichweg', 0),
(863, '86412', 'FRANKFURT AM MAIN', 'Carmen-Dehmel-Weg', 0),
(864, '97086', 'FRANKFURT AM MAIN', 'Alla-Hofmann-Strasse', 0),
(865, '55622', 'FRANKFURT AM MAIN', 'Marek-Beer-Platz', 0),
(866, '33671', 'FRANKFURT AM MAIN', 'Schuchhardtring', 0),
(867, '02075', 'FRANKFURT AM MAIN', 'Elise-Hoffmann-Allee', 0),
(868, '69014', 'FRANKFURT AM MAIN', 'Gunda-Walter-Platz', 0),
(869, '94159', 'FRANKFURT AM MAIN', 'Charlotte-Hofmann-Weg', 0),
(870, '89425', 'FRANKFURT AM MAIN', 'Hoevelstrasse', 0),
(871, '88333', 'FRANKFURT AM MAIN', 'Doeringstr.', 0),
(872, '17325', 'FRANKFURT AM MAIN', 'Telse-Schwital-Strasse', 0),
(873, '13167', 'FRANKFURT AM MAIN', 'Flantzstrasse', 0),
(874, '38121', 'FRANKFURT AM MAIN', 'Eva-Marie-Heidrich-Strasse', 0),
(875, '70018', 'FRANKFURT AM MAIN', 'Ingelore-Tschentscher-Ring', 0),
(876, '97995', 'FRANKFURT AM MAIN', 'Salzgasse', 0),
(877, '84898', 'FRANKFURT AM MAIN', 'Erna-Hentschel-Strasse', 0),
(878, '69031', 'FRANKFURT AM MAIN', 'Wagnerstrasse', 0),
(879, '61562', 'FRANKFURT AM MAIN', 'Klemens-Walter-Platz', 0),
(880, '90647', 'FRANKFURT AM MAIN', 'Steckelstrasse', 0),
(881, '19858', 'FRANKFURT AM MAIN', 'Gorlitzstrasse', 0),
(882, '73160', 'FRANKFURT AM MAIN', 'Schaafweg', 0),
(883, '64564', 'FRANKFURT AM MAIN', 'Heinstrasse', 0),
(884, '85394', 'FRANKFURT AM MAIN', 'Wulfallee', 0),
(885, '48514', 'FRANKFURT AM MAIN', 'Austermuehlering', 0),
(886, '86597', 'FRANKFURT AM MAIN', 'Augusta-Sager-Weg', 0),
(887, '22469', 'FRANKFURT AM MAIN', 'Anna-Lena-Schulz-Ring', 0),
(888, '42737', 'FRANKFURT AM MAIN', 'Schmiedtplatz', 0),
(889, '16337', 'FRANKFURT AM MAIN', 'Johanna-Suessebier-Gasse', 0),
(890, '12174', 'FRANKFURT AM MAIN', 'Rohtgasse', 0),
(891, '86002', 'FRANKFURT AM MAIN', 'Ruth-Stiebitz-Weg', 0),
(892, '54141', 'FRANKFURT AM MAIN', 'Walterweg', 0),
(893, '97622', 'FRANKFURT AM MAIN', 'Gero-Oestrovsky-Allee', 0),
(894, '14014', 'FRANKFURT AM MAIN', 'Tintzmannweg', 0),
(895, '18403', 'FRANKFURT AM MAIN', 'Heidrichplatz', 0),
(896, '72871', 'FRANKFURT AM MAIN', 'Kraushaarstr.', 0),
(897, '78146', 'FRANKFURT AM MAIN', 'Mark-Hande-Platz', 0),
(898, '09126', 'FRANKFURT AM MAIN', 'Geiselallee', 0),
(899, '44753', 'FRANKFURT AM MAIN', 'Valentin-Wulf-Allee', 0),
(900, '58898', 'FRANKFURT AM MAIN', 'Bohnbachweg', 0),
(901, '32687', 'FRANKFURT AM MAIN', 'Tadeusz-Lindner-Platz', 0),
(902, '97394', 'FRANKFURT AM MAIN', 'Zaenkergasse', 0),
(903, '57370', 'FRANKFURT AM MAIN', 'Gertraud-Dietz-Gasse', 0),
(904, '87649', 'FRANKFURT AM MAIN', 'Valentine-Plath-Ring', 0),
(905, '60763', 'FRANKFURT AM MAIN', 'Gudestrasse', 0),
(906, '89589', 'FRANKFURT AM MAIN', 'Soedingweg', 0),
(907, '22193', 'FRANKFURT AM MAIN', 'Gesa-Graf-Allee', 0),
(908, '12636', 'FRANKFURT AM MAIN', 'Hans-Guenther-Eberhardt-Ring', 0),
(909, '97938', 'FRANKFURT AM MAIN', 'Heidelinde-Wieloch-Gasse', 0),
(910, '54787', 'FRANKFURT AM MAIN', 'Katja-Adolph-Ring', 0),
(911, '05291', 'FRANKFURT AM MAIN', 'Bolnbachgasse', 0),
(912, '97703', 'FRANKFURT AM MAIN', 'H.-Dieter-Etzold-Ring', 0),
(913, '39954', 'FRANKFURT AM MAIN', 'Hessstrasse', 0),
(914, '73103', 'FRANKFURT AM MAIN', 'Peukertstrasse', 0),
(915, '17789', 'FRANKFURT AM MAIN', 'Peukertplatz', 0),
(916, '95280', 'FRANKFURT AM MAIN', 'Julia-Bien-Platz', 0),
(917, '21430', 'FRANKFURT AM MAIN', 'Koehlerring', 0),
(918, '04417', 'FRANKFURT AM MAIN', 'Mentzelring', 0),
(919, '61221', 'FRANKFURT AM MAIN', 'Martha-Kuehnert-Platz', 0),
(920, '43776', 'FRANKFURT AM MAIN', 'Deborah-Beer-Ring', 0),
(921, '99165', 'FRANKFURT AM MAIN', 'Dietzweg', 0),
(922, '09054', 'FRANKFURT AM MAIN', 'Kristiane-Freudenberger-Ring', 0),
(923, '60376', 'FRANKFURT AM MAIN', 'Gnatzweg', 0),
(924, '25841', 'FRANKFURT AM MAIN', 'Bayram-Holsten-Platz', 0),
(925, '51293', 'FRANKFURT AM MAIN', 'Dietzweg', 0),
(926, '28310', 'FRANKFURT AM MAIN', 'Pohlring', 0),
(927, '41385', 'FRANKFURT AM MAIN', 'Eleni-Henk-Allee', 0),
(928, '55984', 'FRANKFURT AM MAIN', 'Doehnstr.', 0),
(929, '60302', 'FRANKFURT AM MAIN', 'Keudelstrasse', 0),
(930, '59386', 'FRANKFURT AM MAIN', 'Marianne-Baerer-Weg', 0),
(931, '84139', 'FRANKFURT AM MAIN', 'Danica-Oestrovsky-Platz', 0),
(932, '40584', 'FRANKFURT AM MAIN', 'Kruschwitzallee', 0),
(933, '67785', 'FRANKFURT AM MAIN', 'Pauline-Heser-Allee', 0),
(934, '26722', 'FRANKFURT AM MAIN', 'Blochweg', 0),
(935, '23619', 'FRANKFURT AM MAIN', 'Hans-Friedrich-Stumpf-Ring', 0),
(936, '69125', 'FRANKFURT AM MAIN', 'Beierstr.', 0),
(937, '86097', 'FRANKFURT AM MAIN', 'Schusterallee', 0),
(938, '94267', 'FRANKFURT AM MAIN', 'Wielochallee', 0),
(939, '74032', 'FRANKFURT AM MAIN', 'Jane-Wesack-Platz', 0),
(940, '03903', 'FRANKFURT AM MAIN', 'Trude-Neuschaefer-Ring', 0),
(941, '53591', 'FRANKFURT AM MAIN', 'Vera-Lange-Weg', 0),
(942, '40828', 'FRANKFURT AM MAIN', 'Alwin-Stey-Allee', 0),
(943, '95292', 'FRANKFURT AM MAIN', 'Gunhild-Huebel-Allee', 0),
(944, '61380', 'FRANKFURT AM MAIN', 'Cindy-Etzold-Platz', 0),
(945, '33237', 'FRANKFURT AM MAIN', 'Heckergasse', 0),
(946, '70959', 'FRANKFURT AM MAIN', 'Ebertstr.', 0),
(947, '90676', 'FRANKFURT AM MAIN', 'Klotzgasse', 0),
(948, '16779', 'FRANKFURT AM MAIN', 'Winklerring', 0),
(949, '19754', 'FRANKFURT AM MAIN', 'Aloisia-Austermuehle-Allee', 0),
(950, '42529', 'FRANKFURT AM MAIN', 'Kambsstr.', 0),
(951, '05393', 'FRANKFURT AM MAIN', 'Xaver-Christoph-Weg', 0),
(952, '84856', 'FRANKFURT AM MAIN', 'Brian-Bolzmann-Ring', 0),
(953, '27724', 'FRANKFURT AM MAIN', 'Gitta-Franke-Platz', 0),
(954, '36479', 'FRANKFURT AM MAIN', 'Lia-Henschel-Gasse', 0),
(955, '51913', 'FRANKFURT AM MAIN', 'Groettnerweg', 0),
(956, '88386', 'FRANKFURT AM MAIN', 'Heuserplatz', 0),
(957, '99013', 'FRANKFURT AM MAIN', 'Marianne-Werner-Platz', 0),
(958, '99861', 'FRANKFURT AM MAIN', 'Luebsplatz', 0),
(959, '72565', 'FRANKFURT AM MAIN', 'Riehlgasse', 0),
(960, '65595', 'FRANKFURT AM MAIN', 'Ljudmila-Taesche-Gasse', 0),
(961, '85642', 'FRANKFURT AM MAIN', 'Rolf-Dieter-Vogt-Allee', 0),
(962, '55264', 'FRANKFURT AM MAIN', 'Reimund-Haenel-Weg', 0),
(963, '36869', 'FRANKFURT AM MAIN', 'Marvin-Maelzer-Ring', 0),
(964, '43383', 'FRANKFURT AM MAIN', 'Drewesstr.', 0),
(965, '15618', 'FRANKFURT AM MAIN', 'Pascale-Holzapfel-Strasse', 0),
(966, '28504', 'FRANKFURT AM MAIN', 'Ortmannweg', 0),
(967, '34635', 'FRANKFURT AM MAIN', 'Gudeweg', 0),
(968, '60009', 'FRANKFURT AM MAIN', 'Irmi-Holsten-Allee', 0),
(969, '98088', 'FRANKFURT AM MAIN', 'Thorsten-Hethur-Gasse', 0),
(970, '27890', 'FRANKFURT AM MAIN', 'Fatma-Ullrich-Ring', 0),
(971, '80752', 'FRANKFURT AM MAIN', 'Siegrun-Ullrich-Allee', 0),
(972, '40240', 'FRANKFURT AM MAIN', 'Gottlob-Schmiedecke-Weg', 0),
(973, '92972', 'FRANKFURT AM MAIN', 'Herrmanngasse', 0),
(974, '36519', 'FRANKFURT AM MAIN', 'Henckstr.', 0),
(975, '93287', 'FRANKFURT AM MAIN', 'Kilian-Salz-Weg', 0),
(976, '46955', 'FRANKFURT AM MAIN', 'Fechnerring', 0),
(977, '74250', 'FRANKFURT AM MAIN', 'Birgid-Kruschwitz-Gasse', 0),
(978, '35106', 'FRANKFURT AM MAIN', 'Jolanthe-Wohlgemut-Gasse', 0),
(979, '15912', 'FRANKFURT AM MAIN', 'Jaentschplatz', 0),
(980, '14399', 'FRANKFURT AM MAIN', 'Walterring', 0),
(981, '92396', 'FRANKFURT AM MAIN', 'Thiesstrasse', 0),
(982, '02004', 'FRANKFURT AM MAIN', 'Herrmannplatz', 0),
(983, '25827', 'FRANKFURT AM MAIN', 'Hamanngasse', 0),
(984, '89755', 'FRANKFURT AM MAIN', 'Warmerstrasse', 0),
(985, '32453', 'FRANKFURT AM MAIN', 'Rosenowallee', 0),
(986, '63447', 'FRANKFURT AM MAIN', 'Kadeallee', 0),
(987, '52665', 'FRANKFURT AM MAIN', 'Mentzelallee', 0),
(988, '97217', 'FRANKFURT AM MAIN', 'Rognerweg', 0),
(989, '62561', 'FRANKFURT AM MAIN', 'Karzallee', 0),
(990, '99605', 'FRANKFURT AM MAIN', 'Geislerstrasse', 0),
(991, '45058', 'FRANKFURT AM MAIN', 'Mohauptweg', 0),
(992, '63416', 'FRANKFURT AM MAIN', 'Roggestr.', 0),
(993, '21983', 'FRANKFURT AM MAIN', 'Jaehnallee', 0),
(994, '26505', 'FRANKFURT AM MAIN', 'Koch IIstrasse', 0),
(995, '91514', 'FRANKFURT AM MAIN', 'Hans-Helmut-Kaul-Weg', 0),
(996, '18224', 'FRANKFURT AM MAIN', 'Alida-Putz-Weg', 0),
(997, '83329', 'FRANKFURT AM MAIN', 'Hillerstr.', 0),
(998, '40911', 'FRANKFURT AM MAIN', 'Ehlertgasse', 0),
(999, '43582', 'FRANKFURT AM MAIN', 'Andrej-Sorgatz-Allee', 0),
(1000, '32316', 'FRANKFURT AM MAIN', 'Maren-Graf-Weg', 0),
(1001, '55936', 'FRANKFURT AM MAIN', 'Kurt-Weitzel-Weg', 0),
(1002, '25612', 'FRANKFURT AM MAIN', 'Zirmegasse', 0),
(1003, '56956', 'FRANKFURT AM MAIN', 'Tilman-Gotthard-Strasse', 0),
(1004, '05646', 'FRANKFURT AM MAIN', 'Philippe-Junk-Gasse', 0),
(1005, '64128', 'FRANKFURT AM MAIN', 'Scholtzring', 0),
(1006, '68984', 'FRANKFURT AM MAIN', 'Heringring', 0),
(1007, '29565', 'FRANKFURT AM MAIN', 'Andreas-Schlosser-Weg', 0),
(1008, '36426', 'FRANKFURT AM MAIN', 'Martinallee', 0),
(1009, '13304', 'FRANKFURT AM MAIN', 'Sofia-Schaaf-Ring', 0),
(1010, '76195', 'FRANKFURT AM MAIN', 'Heserstrasse', 0),
(1011, '30251', 'FRANKFURT AM MAIN', 'Wendering', 0),
(1012, '43764', 'FRANKFURT AM MAIN', 'Andersgasse', 0),
(1013, '08848', 'FRANKFURT AM MAIN', 'Kabusallee', 0);
INSERT INTO `standort` (`StandortID`, `PLZ`, `Stadt`, `Strasse`, `Sammelpunkt`) VALUES
(1014, '51602', 'FRANKFURT AM MAIN', 'Meinolf-Drewes-Strasse', 0),
(1015, '18968', 'FRANKFURT AM MAIN', 'Gordon-Zahn-Weg', 0),
(1016, '78899', 'FRANKFURT AM MAIN', 'Mirko-Ritter-Allee', 0),
(1017, '38539', 'FRANKFURT AM MAIN', 'Jane-Schaefer-Strasse', 0),
(1018, '11475', 'FRANKFURT AM MAIN', 'Killerring', 0),
(1019, '32987', 'FRANKFURT AM MAIN', 'Trude-Ritter-Platz', 0),
(1020, '37179', 'FRANKFURT AM MAIN', 'Ruppersbergerstrasse', 0),
(1021, '16692', 'FRANKFURT AM MAIN', 'Dittmar-Schwital-Strasse', 0),
(1022, '07232', 'FRANKFURT AM MAIN', 'Koestergasse', 0),
(1023, '03424', 'FRANKFURT AM MAIN', 'Cornelius-Scheuermann-Weg', 0),
(1024, '94800', 'FRANKFURT AM MAIN', 'Petar-Heuser-Strasse', 0),
(1025, '21724', 'FRANKFURT AM MAIN', 'Gretl-Rose-Allee', 0),
(1026, '18164', 'FRANKFURT AM MAIN', 'Sieringplatz', 0),
(1027, '01447', 'FRANKFURT AM MAIN', 'Rosemannring', 0),
(1028, '90105', 'FRANKFURT AM MAIN', 'Anica-Loeffler-Platz', 0),
(1029, '28196', 'FRANKFURT AM MAIN', 'Mohauptring', 0),
(1030, '88704', 'FRANKFURT AM MAIN', 'Maelzerstr.', 0),
(1031, '68945', 'FRANKFURT AM MAIN', 'Boucseingasse', 0),
(1032, '10602', 'FRANKFURT AM MAIN', 'Else-Rust-Platz', 0),
(1033, '82314', 'FRANKFURT AM MAIN', 'Rosenowring', 0),
(1034, '55921', 'FRANKFURT AM MAIN', 'Mathilde-Jopich-Strasse', 0),
(1035, '35173', 'FRANKFURT AM MAIN', 'Christof-Stey-Gasse', 0),
(1036, '28570', 'FRANKFURT AM MAIN', 'Zimmerplatz', 0),
(1037, '69365', 'FRANKFURT AM MAIN', 'Alexej-Schmidt-Platz', 0),
(1038, '14821', 'FRANKFURT AM MAIN', 'Hermannstr.', 0),
(1039, '90712', 'FRANKFURT AM MAIN', 'Riehlweg', 0),
(1040, '63418', 'FRANKFURT AM MAIN', 'Sofia-Putz-Allee', 0),
(1041, '48395', 'FRANKFURT AM MAIN', 'Neuschaefergasse', 0),
(1042, '65049', 'FRANKFURT AM MAIN', 'Hans-Gerd-Mueller-Ring', 0),
(1043, '49328', 'FRANKFURT AM MAIN', 'Sigurd-Doerschner-Gasse', 0),
(1044, '68520', 'FRANKFURT AM MAIN', 'Grein Grothgasse', 0),
(1045, '96008', 'FRANKFURT AM MAIN', 'Mechtild-Drubin-Ring', 0),
(1046, '59508', 'FRANKFURT AM MAIN', 'Dietzring', 0),
(1047, '77799', 'FRANKFURT AM MAIN', 'Kuhlring', 0),
(1048, '89411', 'FRANKFURT AM MAIN', 'Ritterplatz', 0),
(1049, '19349', 'FRANKFURT AM MAIN', 'Vogtstrasse', 0),
(1050, '70800', 'FRANKFURT AM MAIN', 'Steygasse', 0),
(1051, '64775', 'MUENCHEN', 'Bianca-Textor-Allee', 0),
(1052, '55860', 'MUENCHEN', 'Ottoring', 0),
(1053, '06209', 'MUENCHEN', 'Margrafweg', 0),
(1054, '08318', 'MUENCHEN', 'Thiesstr.', 0),
(1055, '26247', 'MUENCHEN', 'Lisa-Rohleder-Platz', 0),
(1056, '41234', 'MUENCHEN', 'Patrizia-Trubin-Strasse', 0),
(1057, '24714', 'MUENCHEN', 'Minna-Ditschlerin-Ring', 0),
(1058, '67577', 'MUENCHEN', 'Jose-Adolph-Gasse', 0),
(1059, '38253', 'MUENCHEN', 'Marita-Schwital-Strasse', 0),
(1060, '27912', 'MUENCHEN', 'Mohamed-Berger-Allee', 0),
(1061, '08678', 'MUENCHEN', 'Robby-Ullmann-Allee', 0),
(1062, '81696', 'MUENCHEN', 'Mitschkeweg', 0),
(1063, '35627', 'MUENCHEN', 'Jacobi Jaeckelplatz', 0),
(1064, '87616', 'MUENCHEN', 'Heinallee', 0),
(1065, '47415', 'MUENCHEN', 'auch Schlauchinallee', 0),
(1066, '93435', 'MUENCHEN', 'Lindaustrasse', 0),
(1067, '15069', 'MUENCHEN', 'Ingmar-van der Dussen-Weg', 0),
(1068, '91757', 'MUENCHEN', 'Klaus-Dieter-Juncken-Allee', 0),
(1069, '38496', 'MUENCHEN', 'Dennis-Seip-Allee', 0),
(1070, '73684', 'MUENCHEN', 'Thoralf-Gude-Gasse', 0),
(1071, '45371', 'MUENCHEN', 'Diether-Heuser-Strasse', 0),
(1072, '16567', 'MUENCHEN', 'Naserplatz', 0),
(1073, '29439', 'MUENCHEN', 'Beyerplatz', 0),
(1074, '20709', 'MUENCHEN', 'Kostolzinplatz', 0),
(1075, '03662', 'MUENCHEN', 'Kitzmannring', 0),
(1076, '97514', 'MUENCHEN', 'Krzysztof-Baum-Ring', 0),
(1077, '11931', 'MUENCHEN', 'Pohlstr.', 0),
(1078, '65598', 'MUENCHEN', 'Junkenring', 0),
(1079, '38586', 'MUENCHEN', 'Henschelgasse', 0),
(1080, '90805', 'MUENCHEN', 'Thea-Rogner-Weg', 0),
(1081, '35212', 'MUENCHEN', 'Ditschlerinstr.', 0),
(1082, '64077', 'MUENCHEN', 'Pia-Fiebig-Allee', 0),
(1083, '67426', 'MUENCHEN', 'Marc-Zimmer-Weg', 0),
(1084, '80288', 'MUENCHEN', 'Dariusz-Sauer-Gasse', 0),
(1085, '44352', 'MUENCHEN', 'Linkeplatz', 0),
(1086, '60852', 'MUENCHEN', 'Gnatzallee', 0),
(1087, '51334', 'MUENCHEN', 'Hendriksallee', 0),
(1088, '62372', 'MUENCHEN', 'Zaenkerstrasse', 0),
(1089, '36793', 'MUENCHEN', 'Sahin-Hertrampf-Strasse', 0),
(1090, '37794', 'MUENCHEN', 'Leonhard-Seifert-Allee', 0),
(1091, '71279', 'MUENCHEN', 'Hans-Karl-Albers-Platz', 0),
(1092, '27418', 'MUENCHEN', 'Preissgasse', 0),
(1093, '86557', 'MUENCHEN', 'Gierschnerstrasse', 0),
(1094, '15452', 'MUENCHEN', 'Valeska-Herrmann-Ring', 0),
(1095, '10717', 'MUENCHEN', 'Wenzel-Bachmann-Allee', 0),
(1096, '32849', 'MUENCHEN', 'Giessstrasse', 0),
(1097, '10994', 'MUENCHEN', 'Romana-Loeffler-Gasse', 0),
(1098, '36078', 'MUENCHEN', 'Karola-Patberg-Platz', 0),
(1099, '08098', 'MUENCHEN', 'Hermann-Josef-Hecker-Gasse', 0),
(1100, '46582', 'MUENCHEN', 'Hettnerweg', 0),
(1101, '11845', 'MUENCHEN', 'Marlies-Kruschwitz-Gasse', 0),
(1102, '77068', 'MUENCHEN', 'Kasimir-Bohnbach-Ring', 0),
(1103, '60054', 'MUENCHEN', 'Heinrich-Gehringer-Gasse', 0),
(1104, '86415', 'MUENCHEN', 'Krokergasse', 0),
(1105, '55484', 'MUENCHEN', 'Doerschnerring', 0),
(1106, '81661', 'MUENCHEN', 'Zimmerweg', 0),
(1107, '44385', 'MUENCHEN', 'Textorallee', 0),
(1108, '33550', 'MUENCHEN', 'Kostolzinstrasse', 0),
(1109, '79289', 'MUENCHEN', 'Schuchhardtweg', 0),
(1110, '19355', 'MUENCHEN', 'Hans Joerg-Lindau-Allee', 0),
(1111, '21254', 'MUENCHEN', 'Ricarda-Rosemann-Strasse', 0),
(1112, '52537', 'MUENCHEN', 'Adele-Kostolzin-Weg', 0),
(1113, '57232', 'MUENCHEN', 'Rustallee', 0),
(1114, '88562', 'MUENCHEN', 'Gerlachgasse', 0),
(1115, '75198', 'MUENCHEN', 'Wieslaw-Rohleder-Strasse', 0),
(1116, '65284', 'MUENCHEN', 'Hedda-Lindner-Ring', 0),
(1117, '62769', 'MUENCHEN', 'Weimerstrasse', 0),
(1118, '40238', 'MUENCHEN', 'Lilo-Walter-Allee', 0),
(1119, '55053', 'MUENCHEN', 'Dehmelplatz', 0),
(1120, '02255', 'MUENCHEN', 'Naserring', 0),
(1121, '37777', 'MUENCHEN', 'Noackweg', 0),
(1122, '20276', 'MUENCHEN', 'Misicherring', 0),
(1123, '10329', 'MUENCHEN', 'Haenelplatz', 0),
(1124, '63234', 'MUENCHEN', 'Benthinallee', 0),
(1125, '95869', 'MUENCHEN', 'Trudi-Aumann-Allee', 0),
(1126, '65892', 'MUENCHEN', 'Magdalena-Oderwald-Ring', 0),
(1127, '60398', 'MUENCHEN', 'Trubstrasse', 0),
(1128, '71578', 'MUENCHEN', 'Maike-Warmer-Strasse', 0),
(1129, '49182', 'MUENCHEN', 'Foersterstrasse', 0),
(1130, '85338', 'MUENCHEN', 'Louise-Eckbauer-Allee', 0),
(1131, '50909', 'MUENCHEN', 'Lehmanngasse', 0),
(1132, '26548', 'MUENCHEN', 'Cemil-Hess-Allee', 0),
(1133, '29276', 'MUENCHEN', 'Ahmad-Klemm-Allee', 0),
(1134, '71808', 'MUENCHEN', 'Hanne-Hande-Weg', 0),
(1135, '51724', 'MUENCHEN', 'Geisslerallee', 0),
(1136, '71737', 'MUENCHEN', 'Francis-auch Schlauchin-Strass', 0),
(1137, '34146', 'MUENCHEN', 'Birnbaumgasse', 0),
(1138, '67372', 'MUENCHEN', 'Ditschlerinweg', 0),
(1139, '64745', 'MUENCHEN', 'Ron-Eberth-Weg', 0),
(1140, '01458', 'MUENCHEN', 'Luzie-Bauer-Gasse', 0),
(1141, '99939', 'MUENCHEN', 'Roggeweg', 0),
(1142, '21429', 'MUENCHEN', 'Taescheallee', 0),
(1143, '89270', 'MUENCHEN', 'Kambsplatz', 0),
(1144, '81689', 'MUENCHEN', 'Warmerring', 0),
(1145, '35614', 'MUENCHEN', 'Brudergasse', 0),
(1146, '71193', 'MUENCHEN', 'Haeringplatz', 0),
(1147, '05073', 'MUENCHEN', 'Scheelring', 0),
(1148, '49589', 'MUENCHEN', 'Grafstr.', 0),
(1149, '92532', 'MUENCHEN', 'Karl-Ludwig-Hornich-Gasse', 0),
(1150, '81113', 'MUENCHEN', 'Felicia-Doerr-Gasse', 0),
(1151, '02852', 'MUENCHEN', 'Kreingasse', 0),
(1152, '23739', 'MUENCHEN', 'Cord-Doering-Platz', 0),
(1153, '67360', 'MUENCHEN', 'Hoerlering', 0),
(1154, '44141', 'MUENCHEN', 'Kraushaarring', 0),
(1155, '45572', 'MUENCHEN', 'Fabian-Dippel-Strasse', 0),
(1156, '48922', 'MUENCHEN', 'Gabriele-Wende-Gasse', 0),
(1157, '63300', 'MUENCHEN', 'Elzbieta-Suessebier-Weg', 0),
(1158, '74273', 'MUENCHEN', 'Schweitzerweg', 0),
(1159, '56462', 'MUENCHEN', 'Katharine-Scholtz-Allee', 0),
(1160, '04933', 'MUENCHEN', 'Nancy-Adler-Ring', 0),
(1161, '98794', 'MUENCHEN', 'Ria-Luebs-Weg', 0),
(1162, '24622', 'MUENCHEN', 'Dietlind-Trapp-Weg', 0),
(1163, '74001', 'MUENCHEN', 'Francoise-Boerner-Strasse', 0),
(1164, '51761', 'MUENCHEN', 'Gerhart-Kusch-Ring', 0),
(1165, '53592', 'MUENCHEN', 'Annelore-Junken-Weg', 0),
(1166, '42834', 'MUENCHEN', 'Amalia-Neuschaefer-Strasse', 0),
(1167, '96937', 'MUENCHEN', 'Strohring', 0),
(1168, '23611', 'MUENCHEN', 'Theodor-Wulf-Ring', 0),
(1169, '26585', 'MUENCHEN', 'Rupert-Reising-Strasse', 0),
(1170, '91780', 'MUENCHEN', 'Baumstrasse', 0),
(1171, '29262', 'MUENCHEN', 'Mariele-Liebelt-Strasse', 0),
(1172, '31449', 'MUENCHEN', 'Lachmannweg', 0),
(1173, '31017', 'MUENCHEN', 'Niemeierstr.', 0),
(1174, '47382', 'MUENCHEN', 'Gerhard-Mangold-Platz', 0),
(1175, '86866', 'MUENCHEN', 'Doerschnerstr.', 0),
(1176, '11805', 'MUENCHEN', 'Henrike-Gehringer-Allee', 0),
(1177, '22147', 'MUENCHEN', 'Schaefergasse', 0),
(1178, '69635', 'MUENCHEN', 'Hella-Kambs-Weg', 0),
(1179, '33423', 'MUENCHEN', 'Johanna-Briemer-Ring', 0),
(1180, '03233', 'MUENCHEN', 'Jeanette-Kuehnert-Strasse', 0),
(1181, '76723', 'MUENCHEN', 'Albersring', 0),
(1182, '32954', 'MUENCHEN', 'Hansgeorg-Lindner-Allee', 0),
(1183, '34723', 'MUENCHEN', 'Wagenknechtallee', 0),
(1184, '94367', 'MUENCHEN', 'Michaele-Vogt-Ring', 0),
(1185, '91081', 'MUENCHEN', 'Desiree-Weller-Weg', 0),
(1186, '66374', 'MUENCHEN', 'Dorothee-Graf-Weg', 0),
(1187, '61153', 'MUENCHEN', 'Wiekstr.', 0),
(1188, '20964', 'MUENCHEN', 'Ernststrasse', 0),
(1189, '79146', 'MUENCHEN', 'Truebstrasse', 0),
(1190, '09973', 'MUENCHEN', 'Amanda-Tintzmann-Strasse', 0),
(1191, '28759', 'MUENCHEN', 'Schinkegasse', 0),
(1192, '18112', 'MUENCHEN', 'Hesseweg', 0),
(1193, '22368', 'MUENCHEN', 'Harloffstr.', 0),
(1194, '70274', 'MUENCHEN', 'Klothilde-Niemeier-Strasse', 0),
(1195, '91209', 'MUENCHEN', 'Annelie-Ehlert-Platz', 0),
(1196, '21989', 'MUENCHEN', 'Paul-Wagner-Gasse', 0),
(1197, '19313', 'MUENCHEN', 'Vincent-Rudolph-Ring', 0),
(1198, '32562', 'MUENCHEN', 'Kenneth-Kabus-Ring', 0),
(1199, '48636', 'MUENCHEN', 'Desiree-Kruschwitz-Allee', 0),
(1200, '29017', 'MUENCHEN', 'Isabel-Schweitzer-Platz', 0),
(1201, '37261', 'MUENCHEN', 'Aribert-Mude-Weg', 0),
(1202, '89669', 'MUENCHEN', 'Schmidtgasse', 0),
(1203, '02734', 'MUENCHEN', 'Laszlo-Haenel-Allee', 0),
(1204, '71192', 'MUENCHEN', 'Hoffmannplatz', 0),
(1205, '49828', 'MUENCHEN', 'Hermannweg', 0),
(1206, '40533', 'MUENCHEN', 'Heinrichplatz', 0),
(1207, '79650', 'MUENCHEN', 'Emilie-Nette-Allee', 0),
(1208, '55969', 'MUENCHEN', 'Hoevelplatz', 0),
(1209, '17262', 'MUENCHEN', 'Zirmering', 0),
(1210, '10654', 'MUENCHEN', 'Mario-Heinz-Gasse', 0),
(1211, '46958', 'MUENCHEN', 'Ernst-Trueb-Ring', 0),
(1212, '83172', 'MUENCHEN', 'Cindy-Pohl-Platz', 0),
(1213, '99669', 'MUENCHEN', 'Reisingweg', 0),
(1214, '27365', 'MUENCHEN', 'Stefani-Bolzmann-Ring', 0),
(1215, '94648', 'MUENCHEN', 'Christof-Gertz-Ring', 0),
(1216, '67551', 'MUENCHEN', 'Wendelin-Patberg-Gasse', 0),
(1217, '56150', 'MUENCHEN', 'Jaehnallee', 0),
(1218, '80458', 'MUENCHEN', 'Sylvia-Poelitz-Gasse', 0),
(1219, '98178', 'MUENCHEN', 'Tadeusz-Kaester-Weg', 0),
(1220, '89605', 'MUENCHEN', 'Maike-Weimer-Allee', 0),
(1221, '88618', 'MUENCHEN', 'Muehlegasse', 0),
(1222, '05217', 'MUENCHEN', 'Meisterweg', 0),
(1223, '58608', 'MUENCHEN', 'Eveline-Kabus-Platz', 0),
(1224, '74101', 'MUENCHEN', 'Holtgasse', 0),
(1225, '07453', 'MUENCHEN', 'Rupert-Ruppert-Weg', 0),
(1226, '72368', 'MUENCHEN', 'Karolina-Henk-Gasse', 0),
(1227, '17266', 'MUENCHEN', 'Casparallee', 0),
(1228, '50136', 'MUENCHEN', 'Heide-Mentzel-Ring', 0),
(1229, '60394', 'MUENCHEN', 'Martina-Hauffer-Ring', 0),
(1230, '61167', 'MUENCHEN', 'Netteplatz', 0),
(1231, '17648', 'MUENCHEN', 'German-Hertrampf-Platz', 0),
(1232, '66891', 'MUENCHEN', 'Biggengasse', 0),
(1233, '51312', 'MUENCHEN', 'Gertzstrasse', 0),
(1234, '08812', 'MUENCHEN', 'Isabella-Bonbach-Weg', 0),
(1235, '58025', 'MUENCHEN', 'Thoralf-Stahr-Allee', 0),
(1236, '46571', 'MUENCHEN', 'Trommlerplatz', 0),
(1237, '72458', 'MUENCHEN', 'Mahmut-Schmiedecke-Strasse', 0),
(1238, '50989', 'MUENCHEN', 'Birgit-Wieloch-Allee', 0),
(1239, '94776', 'MUENCHEN', 'Eleonore-Roehrdanz-Weg', 0),
(1240, '48595', 'MUENCHEN', 'Huebelring', 0),
(1241, '09693', 'MUENCHEN', 'Steinbergplatz', 0),
(1242, '61676', 'MUENCHEN', 'Muehleallee', 0),
(1243, '58830', 'MUENCHEN', 'Jesselgasse', 0),
(1244, '69945', 'MUENCHEN', 'Christos-Ring-Strasse', 0),
(1245, '28783', 'MUENCHEN', 'Amir-Girschner-Strasse', 0),
(1246, '82963', 'MUENCHEN', 'Bauerweg', 0),
(1247, '12759', 'MUENCHEN', 'Schmidtstrasse', 0),
(1248, '73156', 'MUENCHEN', 'Roehrichtstrasse', 0),
(1249, '32286', 'MUENCHEN', 'Neuschaeferweg', 0),
(1250, '51850', 'MUENCHEN', 'Gierschnerstr.', 0);

-- --------------------------------------------------------

--
-- Tabellenstruktur für Tabelle `warenausgabe`
--

CREATE TABLE `warenausgabe` (
  `WarenausgabeID` int(11) NOT NULL,
  `AnzahlDerTeile` int(11) NOT NULL,
  `ReparaturID` int(11) NOT NULL,
  `EinzelteileID` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Daten für Tabelle `warenausgabe`
--

INSERT INTO `warenausgabe` (`WarenausgabeID`, `AnzahlDerTeile`, `ReparaturID`, `EinzelteileID`) VALUES
(1, 8, 1, 25),
(2, 5, 2, 17),
(3, 1, 3, 23),
(4, 10, 4, 12),
(5, 6, 5, 17),
(6, 9, 6, 30),
(7, 8, 7, 1),
(8, 5, 8, 44),
(9, 3, 9, 48),
(10, 7, 10, 39),
(11, 6, 11, 17),
(12, 3, 12, 38),
(13, 7, 13, 28),
(14, 9, 14, 51),
(15, 3, 15, 15),
(16, 3, 16, 37),
(17, 6, 17, 9),
(18, 9, 18, 22),
(19, 8, 19, 34),
(20, 4, 20, 36),
(21, 2, 21, 40),
(22, 7, 22, 51),
(23, 9, 23, 49),
(24, 6, 24, 4),
(25, 7, 25, 6),
(26, 7, 26, 38),
(27, 7, 27, 33),
(28, 9, 28, 38),
(29, 1, 29, 50),
(30, 9, 30, 43),
(31, 5, 31, 16),
(32, 5, 32, 15),
(33, 2, 33, 26),
(34, 2, 34, 32),
(35, 4, 35, 2),
(36, 4, 36, 33),
(37, 7, 37, 23),
(38, 2, 38, 30),
(39, 3, 39, 21),
(40, 5, 40, 44),
(41, 5, 41, 26),
(42, 7, 42, 24),
(43, 7, 43, 18),
(44, 1, 44, 19),
(45, 8, 45, 50),
(46, 6, 46, 36),
(47, 4, 47, 19),
(48, 8, 48, 9),
(49, 2, 49, 43),
(50, 1, 50, 1),
(51, 1, 51, 22),
(52, 9, 52, 17),
(53, 5, 53, 6),
(54, 3, 54, 11),
(55, 3, 55, 11),
(56, 2, 56, 20),
(57, 8, 57, 30),
(58, 8, 58, 27),
(59, 3, 59, 49),
(60, 5, 60, 40),
(61, 8, 61, 12),
(62, 6, 62, 23),
(63, 5, 63, 14),
(64, 6, 64, 38),
(65, 6, 65, 4),
(66, 8, 66, 20),
(67, 5, 67, 5),
(68, 1, 68, 17),
(69, 6, 69, 51),
(70, 10, 70, 9),
(71, 6, 71, 31),
(72, 10, 72, 24),
(73, 6, 73, 15),
(74, 7, 74, 1),
(75, 9, 75, 45),
(76, 1, 76, 7),
(77, 4, 77, 26),
(78, 1, 78, 16),
(79, 3, 79, 44),
(80, 10, 80, 19),
(81, 10, 81, 43),
(82, 6, 82, 51),
(83, 8, 83, 7),
(84, 4, 84, 2),
(85, 9, 85, 22),
(86, 5, 86, 12),
(87, 9, 87, 25),
(88, 4, 88, 44),
(89, 1, 89, 49),
(90, 10, 90, 18),
(91, 4, 91, 11),
(92, 9, 92, 39),
(93, 10, 93, 50),
(94, 8, 94, 4),
(95, 7, 95, 44),
(96, 8, 96, 50),
(97, 2, 97, 40),
(98, 3, 98, 10),
(99, 8, 99, 25),
(100, 6, 100, 10);

-- --------------------------------------------------------

--
-- Tabellenstruktur für Tabelle `zahlung`
--

CREATE TABLE `zahlung` (
  `ZahlungID` int(11) NOT NULL,
  `GesamtPreis` decimal(6,2) NOT NULL,
  `BestellERID` int(11) NOT NULL,
  `ZMethodID` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Daten für Tabelle `zahlung`
--

INSERT INTO `zahlung` (`ZahlungID`, `GesamtPreis`, `BestellERID`, `ZMethodID`) VALUES
(1, 5.20, 1, 1),
(2, 1.44, 2, 2),
(3, 3.80, 3, 1),
(4, 0.40, 4, 1),
(5, 4.00, 5, 1),
(6, 4.50, 6, 2),
(7, 1.00, 7, 1),
(8, 1.62, 8, 2),
(9, 1.60, 9, 1),
(10, 2.60, 10, 1),
(11, 4.60, 11, 1),
(12, 4.00, 12, 1),
(13, 0.00, 13, 2),
(14, 5.04, 14, 2),
(15, 3.78, 15, 2),
(16, 3.40, 16, 1),
(17, 5.00, 17, 1),
(18, 3.00, 18, 1),
(19, 1.98, 19, 2),
(20, 4.20, 20, 1),
(21, 2.40, 21, 1),
(22, 5.40, 22, 2),
(23, 3.40, 23, 1),
(24, 4.80, 24, 1),
(25, 0.72, 25, 2),
(26, 5.00, 26, 1),
(27, 1.26, 27, 2),
(28, 5.40, 28, 1),
(29, 2.34, 29, 2),
(30, 3.00, 30, 1),
(31, 2.80, 31, 1),
(32, 1.62, 32, 2),
(33, 0.40, 33, 1),
(34, 2.34, 34, 2),
(35, 1.62, 35, 2),
(36, 2.80, 36, 1),
(37, 5.80, 37, 1),
(38, 5.22, 38, 2),
(39, 3.60, 39, 1),
(40, 4.32, 40, 2),
(41, 0.00, 41, 2),
(42, 2.88, 42, 2),
(43, 4.20, 43, 1),
(44, 3.42, 44, 2),
(45, 0.36, 45, 2),
(46, 0.36, 46, 2),
(47, 2.00, 47, 1),
(48, 2.70, 48, 2),
(49, 0.72, 49, 2),
(50, 2.40, 50, 1),
(51, 6.00, 51, 1),
(52, 0.90, 52, 2),
(53, 3.96, 53, 2),
(54, 2.80, 54, 1),
(55, 5.80, 55, 1),
(56, 0.40, 56, 1),
(57, 4.80, 57, 1),
(58, 4.00, 58, 1),
(59, 4.86, 59, 2),
(60, 3.80, 60, 1),
(61, 5.80, 61, 1),
(62, 5.20, 62, 1),
(63, 0.36, 63, 2),
(64, 4.80, 64, 1),
(65, 4.14, 65, 2),
(66, 0.60, 66, 1),
(67, 4.80, 67, 1),
(68, 4.32, 68, 2),
(69, 0.20, 69, 1),
(70, 0.72, 70, 2),
(71, 1.20, 71, 1),
(72, 0.72, 72, 2),
(73, 1.44, 73, 2),
(74, 4.14, 74, 2),
(75, 3.06, 75, 2),
(76, 4.80, 76, 1),
(77, 5.04, 77, 2),
(78, 5.80, 78, 1),
(79, 3.06, 79, 2),
(80, 2.00, 80, 1),
(81, 2.60, 81, 1),
(82, 0.40, 82, 1),
(83, 3.00, 83, 1),
(84, 0.54, 84, 2),
(85, 2.70, 85, 2),
(86, 1.26, 86, 2),
(87, 5.40, 87, 2),
(88, 5.00, 88, 1),
(89, 4.00, 89, 1),
(90, 3.00, 90, 1),
(91, 3.80, 91, 1),
(92, 0.36, 92, 2),
(93, 3.96, 93, 2),
(94, 4.20, 94, 1),
(95, 0.00, 95, 2),
(96, 5.20, 96, 1),
(97, 4.40, 97, 1),
(98, 5.00, 98, 1),
(99, 4.50, 99, 2),
(100, 0.00, 100, 1),
(101, 1.26, 101, 2),
(102, 3.80, 102, 1),
(103, 2.52, 103, 2),
(104, 4.40, 104, 1),
(105, 1.80, 105, 2),
(106, 1.00, 106, 1),
(107, 4.86, 107, 2),
(108, 3.40, 108, 1),
(109, 3.78, 109, 2),
(110, 3.60, 110, 1),
(111, 4.80, 111, 1),
(112, 4.68, 112, 2),
(113, 0.54, 113, 2),
(114, 1.62, 114, 2),
(115, 1.20, 115, 1),
(116, 1.60, 116, 1),
(117, 5.60, 117, 1),
(118, 3.06, 118, 2),
(119, 1.08, 119, 2),
(120, 1.80, 120, 1),
(121, 4.86, 121, 2),
(122, 2.20, 122, 1),
(123, 2.80, 123, 1),
(124, 1.80, 124, 1),
(125, 3.20, 125, 1),
(126, 4.86, 126, 2),
(127, 1.60, 127, 1),
(128, 4.68, 128, 2),
(129, 5.00, 129, 1),
(130, 4.20, 130, 1),
(131, 6.00, 131, 1),
(132, 5.22, 132, 2),
(133, 3.80, 133, 1),
(134, 2.16, 134, 2),
(135, 4.68, 135, 2),
(136, 4.86, 136, 2),
(137, 5.04, 137, 2),
(138, 1.80, 138, 2),
(139, 5.40, 139, 1),
(140, 4.80, 140, 1),
(141, 5.22, 141, 2),
(142, 4.80, 142, 1),
(143, 5.40, 143, 2),
(144, 2.40, 144, 1),
(145, 1.62, 145, 2),
(146, 2.34, 146, 2),
(147, 5.04, 147, 2),
(148, 4.40, 148, 1),
(149, 0.36, 149, 2),
(150, 0.18, 150, 2),
(151, 5.40, 151, 1),
(152, 0.90, 152, 2),
(153, 2.00, 153, 1),
(154, 0.18, 154, 2),
(155, 2.70, 155, 2),
(156, 1.20, 156, 1),
(157, 5.22, 157, 2),
(158, 3.40, 158, 1),
(159, 5.80, 159, 1),
(160, 2.60, 160, 1),
(161, 1.80, 161, 1),
(162, 2.20, 162, 1),
(163, 0.54, 163, 2),
(164, 5.40, 164, 2),
(165, 2.80, 165, 1),
(166, 4.60, 166, 1),
(167, 1.40, 167, 1),
(168, 2.00, 168, 1),
(169, 3.42, 169, 2),
(170, 0.54, 170, 2),
(171, 0.20, 171, 1),
(172, 6.00, 172, 1),
(173, 3.96, 173, 2),
(174, 5.40, 174, 1),
(175, 1.08, 175, 2),
(176, 1.00, 176, 1),
(177, 4.32, 177, 2),
(178, 0.60, 178, 1),
(179, 3.40, 179, 1),
(180, 3.24, 180, 2),
(181, 0.20, 181, 1),
(182, 1.80, 182, 1),
(183, 2.88, 183, 2),
(184, 3.00, 184, 1),
(185, 1.60, 185, 1),
(186, 4.80, 186, 1),
(187, 4.40, 187, 1),
(188, 2.16, 188, 2),
(189, 2.34, 189, 2),
(190, 5.80, 190, 1),
(191, 1.44, 191, 2),
(192, 0.18, 192, 2),
(193, 0.72, 193, 2),
(194, 4.00, 194, 1),
(195, 5.60, 195, 1),
(196, 3.40, 196, 1),
(197, 0.20, 197, 1),
(198, 2.60, 198, 1),
(199, 1.20, 199, 1),
(200, 1.98, 200, 2),
(201, 1.80, 201, 2),
(202, 1.44, 202, 2),
(203, 4.14, 203, 2),
(204, 1.08, 204, 2),
(205, 2.60, 205, 1),
(206, 5.40, 206, 1),
(207, 3.24, 207, 2),
(208, 1.80, 208, 1),
(209, 2.52, 209, 2),
(210, 2.16, 210, 2),
(211, 3.06, 211, 2),
(212, 5.60, 212, 1),
(213, 2.34, 213, 2),
(214, 3.80, 214, 1),
(215, 3.60, 215, 1),
(216, 0.00, 216, 2),
(217, 3.06, 217, 2),
(218, 0.00, 218, 2),
(219, 5.20, 219, 1),
(220, 2.70, 220, 2),
(221, 2.52, 221, 2),
(222, 3.60, 222, 2),
(223, 2.16, 223, 2),
(224, 4.86, 224, 2),
(225, 1.00, 225, 1),
(226, 5.22, 226, 2),
(227, 0.60, 227, 1),
(228, 2.88, 228, 2),
(229, 1.00, 229, 1),
(230, 1.26, 230, 2),
(231, 4.40, 231, 1),
(232, 5.40, 232, 1),
(233, 5.40, 233, 1),
(234, 5.60, 234, 1),
(235, 2.40, 235, 1),
(236, 1.62, 236, 2),
(237, 5.40, 237, 1),
(238, 3.60, 238, 2),
(239, 3.60, 239, 2),
(240, 1.40, 240, 1),
(241, 0.18, 241, 2),
(242, 4.14, 242, 2),
(243, 3.80, 243, 1),
(244, 0.00, 244, 1),
(245, 3.40, 245, 1),
(246, 5.00, 246, 1),
(247, 1.98, 247, 2),
(248, 0.80, 248, 1),
(249, 4.80, 249, 1),
(250, 2.40, 250, 1),
(251, 2.60, 251, 1),
(252, 5.00, 252, 1),
(253, 5.00, 253, 1),
(254, 3.24, 254, 2),
(255, 2.34, 255, 2),
(256, 2.16, 256, 2),
(257, 4.50, 257, 2),
(258, 5.20, 258, 1),
(259, 3.80, 259, 1),
(260, 1.60, 260, 1),
(261, 1.44, 261, 2),
(262, 0.18, 262, 2),
(263, 2.88, 263, 2),
(264, 1.00, 264, 1),
(265, 0.90, 265, 2),
(266, 0.18, 266, 2),
(267, 4.14, 267, 2),
(268, 4.86, 268, 2),
(269, 0.00, 269, 1),
(270, 4.60, 270, 1),
(271, 2.52, 271, 2),
(272, 2.52, 272, 2),
(273, 1.80, 273, 1),
(274, 2.88, 274, 2),
(275, 3.80, 275, 1),
(276, 5.40, 276, 1),
(277, 4.50, 277, 2),
(278, 1.00, 278, 1),
(279, 3.42, 279, 2),
(280, 4.86, 280, 2),
(281, 1.60, 281, 1),
(282, 2.20, 282, 1),
(283, 3.60, 283, 2),
(284, 0.60, 284, 1),
(285, 1.98, 285, 2),
(286, 2.60, 286, 1),
(287, 0.00, 287, 1),
(288, 2.70, 288, 2),
(289, 1.08, 289, 2),
(290, 0.80, 290, 1),
(291, 3.60, 291, 2),
(292, 2.40, 292, 1),
(293, 5.40, 293, 1),
(294, 3.40, 294, 1),
(295, 5.22, 295, 2),
(296, 1.80, 296, 2),
(297, 2.40, 297, 1),
(298, 1.80, 298, 1),
(299, 2.88, 299, 2),
(300, 0.54, 300, 2),
(301, 3.06, 301, 2),
(302, 4.86, 302, 2),
(303, 4.60, 303, 1),
(304, 4.68, 304, 2),
(305, 4.40, 305, 1),
(306, 0.00, 306, 1),
(307, 2.00, 307, 1),
(308, 2.34, 308, 2),
(309, 3.80, 309, 1),
(310, 3.00, 310, 1),
(311, 2.88, 311, 2),
(312, 3.06, 312, 2),
(313, 0.54, 313, 2),
(314, 2.00, 314, 1),
(315, 2.00, 315, 1),
(316, 4.68, 316, 2),
(317, 1.62, 317, 2),
(318, 1.20, 318, 1),
(319, 4.20, 319, 1),
(320, 2.60, 320, 1),
(321, 1.08, 321, 2),
(322, 5.00, 322, 1),
(323, 5.40, 323, 1),
(324, 2.00, 324, 1),
(325, 3.00, 325, 1),
(326, 5.20, 326, 1),
(327, 2.70, 327, 2),
(328, 1.40, 328, 1),
(329, 1.26, 329, 2),
(330, 2.60, 330, 1),
(331, 4.80, 331, 1),
(332, 3.60, 332, 2),
(333, 0.40, 333, 1),
(334, 3.24, 334, 2),
(335, 4.60, 335, 1),
(336, 2.16, 336, 2),
(337, 4.86, 337, 2),
(338, 3.24, 338, 2),
(339, 4.00, 339, 1),
(340, 3.00, 340, 1),
(341, 4.50, 341, 2),
(342, 0.90, 342, 2),
(343, 0.80, 343, 1),
(344, 0.60, 344, 1),
(345, 0.90, 345, 2),
(346, 2.40, 346, 1),
(347, 0.00, 347, 2),
(348, 1.60, 348, 1),
(349, 1.60, 349, 1),
(350, 1.44, 350, 2),
(351, 3.80, 351, 1),
(352, 5.80, 352, 1),
(353, 1.98, 353, 2),
(354, 1.40, 354, 1),
(355, 3.60, 355, 2),
(356, 0.20, 356, 1),
(357, 5.40, 357, 2),
(358, 3.06, 358, 2),
(359, 0.90, 359, 2),
(360, 5.40, 360, 2),
(361, 0.18, 361, 2),
(362, 3.24, 362, 2),
(363, 4.68, 363, 2),
(364, 3.06, 364, 2),
(365, 1.80, 365, 2),
(366, 5.00, 366, 1),
(367, 3.80, 367, 1),
(368, 2.00, 368, 1),
(369, 1.98, 369, 2),
(370, 1.62, 370, 2),
(371, 5.00, 371, 1),
(372, 2.40, 372, 1),
(373, 1.26, 373, 2),
(374, 1.44, 374, 2),
(375, 5.40, 375, 1),
(376, 4.80, 376, 1),
(377, 3.96, 377, 2),
(378, 1.80, 378, 2),
(379, 2.80, 379, 1),
(380, 3.60, 380, 1),
(381, 0.90, 381, 2),
(382, 1.44, 382, 2),
(383, 3.06, 383, 2),
(384, 3.60, 384, 1),
(385, 3.20, 385, 1),
(386, 0.36, 386, 2),
(387, 1.80, 387, 2),
(388, 5.40, 388, 2),
(389, 2.88, 389, 2),
(390, 1.80, 390, 1),
(391, 5.04, 391, 2),
(392, 3.06, 392, 2),
(393, 5.20, 393, 1),
(394, 3.60, 394, 2),
(395, 1.40, 395, 1),
(396, 5.80, 396, 1),
(397, 3.80, 397, 1),
(398, 2.40, 398, 1),
(399, 4.50, 399, 2),
(400, 0.00, 400, 1),
(401, 5.20, 401, 1),
(402, 5.04, 402, 2),
(403, 5.20, 403, 1),
(404, 1.80, 404, 1),
(405, 0.40, 405, 1),
(406, 1.26, 406, 2),
(407, 4.32, 407, 2),
(408, 3.78, 408, 2),
(409, 1.80, 409, 2),
(410, 1.26, 410, 2),
(411, 0.40, 411, 1),
(412, 4.50, 412, 2),
(413, 5.04, 413, 2),
(414, 1.26, 414, 2),
(415, 4.14, 415, 2),
(416, 3.42, 416, 2),
(417, 4.50, 417, 2),
(418, 1.80, 418, 1),
(419, 1.20, 419, 1),
(420, 5.40, 420, 2),
(421, 3.24, 421, 2),
(422, 3.60, 422, 1),
(423, 0.00, 423, 2),
(424, 1.80, 424, 2),
(425, 1.80, 425, 2),
(426, 3.24, 426, 2),
(427, 3.40, 427, 1),
(428, 0.00, 428, 2),
(429, 5.20, 429, 1),
(430, 3.20, 430, 1),
(431, 1.08, 431, 2),
(432, 5.20, 432, 1),
(433, 0.00, 433, 1),
(434, 3.60, 434, 2),
(435, 0.20, 435, 1),
(436, 2.52, 436, 2),
(437, 0.36, 437, 2),
(438, 0.18, 438, 2),
(439, 5.40, 439, 1),
(440, 4.00, 440, 1),
(441, 5.00, 441, 1),
(442, 2.20, 442, 1),
(443, 0.00, 443, 2),
(444, 5.80, 444, 1),
(445, 2.00, 445, 1),
(446, 1.08, 446, 2),
(447, 3.78, 447, 2),
(448, 0.00, 448, 2),
(449, 5.40, 449, 2),
(450, 5.80, 450, 1),
(451, 2.00, 451, 1),
(452, 5.20, 452, 1),
(453, 4.32, 453, 2),
(454, 2.34, 454, 2),
(455, 4.20, 455, 1),
(456, 2.52, 456, 2),
(457, 4.40, 457, 1),
(458, 5.40, 458, 2),
(459, 0.60, 459, 1),
(460, 3.20, 460, 1),
(461, 6.00, 461, 1),
(462, 4.14, 462, 2),
(463, 5.60, 463, 1),
(464, 2.80, 464, 1),
(465, 0.40, 465, 1),
(466, 4.50, 466, 2),
(467, 3.60, 467, 2),
(468, 1.62, 468, 2),
(469, 4.00, 469, 1),
(470, 1.80, 470, 1),
(471, 5.00, 471, 1),
(472, 4.60, 472, 1),
(473, 5.40, 473, 2),
(474, 3.60, 474, 2),
(475, 4.60, 475, 1),
(476, 2.88, 476, 2),
(477, 1.08, 477, 2),
(478, 4.80, 478, 1),
(479, 5.22, 479, 2),
(480, 4.14, 480, 2),
(481, 4.68, 481, 2),
(482, 1.00, 482, 1),
(483, 2.70, 483, 2),
(484, 4.86, 484, 2),
(485, 0.20, 485, 1),
(486, 3.60, 486, 2),
(487, 0.90, 487, 2),
(488, 1.26, 488, 2),
(489, 5.00, 489, 1),
(490, 4.20, 490, 1),
(491, 4.40, 491, 1),
(492, 3.78, 492, 2),
(493, 3.24, 493, 2),
(494, 0.00, 494, 2),
(495, 1.26, 495, 2),
(496, 1.60, 496, 1),
(497, 1.62, 497, 2),
(498, 4.14, 498, 2),
(499, 0.54, 499, 2),
(500, 0.40, 500, 1);

-- --------------------------------------------------------

--
-- Tabellenstruktur für Tabelle `zahlungsmethode`
--

CREATE TABLE `zahlungsmethode` (
  `ZMethodID` int(11) NOT NULL,
  `MinutenSatz` int(11) NOT NULL,
  `ZahlungsType` enum('K','A') NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Daten für Tabelle `zahlungsmethode`
--

INSERT INTO `zahlungsmethode` (`ZMethodID`, `MinutenSatz`, `ZahlungsType`) VALUES
(1, 20, 'A'),
(2, 18, 'K');

--
-- Indizes der exportierten Tabellen
--

--
-- Indizes für die Tabelle `abteilung`
--
ALTER TABLE `abteilung`
  ADD PRIMARY KEY (`AbteilungID`),
  ADD UNIQUE KEY `AbteilungName` (`AbteilungName`);

--
-- Indizes für die Tabelle `bestellung_eroller`
--
ALTER TABLE `bestellung_eroller`
  ADD PRIMARY KEY (`BestellERID`),
  ADD KEY `bestell_eroller_kunde_fk` (`KundeID`),
  ADD KEY `bestell_eroller_eroller_fk` (`ERollerID`),
  ADD KEY `bestell_eroller_standort_fk1` (`StartPunktID`),
  ADD KEY `bestell_eroller_standort_fk2` (`EndPunktID`);

--
-- Indizes für die Tabelle `defekt`
--
ALTER TABLE `defekt`
  ADD PRIMARY KEY (`DefektID`),
  ADD KEY `defekt_eroller_fk` (`ERollerID`);

--
-- Indizes für die Tabelle `einzelteile`
--
ALTER TABLE `einzelteile`
  ADD PRIMARY KEY (`EinzelteileID`);

--
-- Indizes für die Tabelle `eroller`
--
ALTER TABLE `eroller`
  ADD PRIMARY KEY (`ERollerID`),
  ADD KEY `eroller_standort_fk` (`StandortID`),
  ADD KEY `eroller_lager_fk` (`LagerID`),
  ADD KEY `eroller_haltepunkt_fk` (`HaltepunktID`);

--
-- Indizes für die Tabelle `fahrtenbuch`
--
ALTER TABLE `fahrtenbuch`
  ADD PRIMARY KEY (`FahrtenbuchID`),
  ADD KEY `fahrtenbuch_fuhrpark_fk` (`FirmenwagenID`),
  ADD KEY `fahrtenbuch_mitarbeiter_fk` (`MitarbeiterID`);

--
-- Indizes für die Tabelle `fuhrpark`
--
ALTER TABLE `fuhrpark`
  ADD PRIMARY KEY (`FirmenwagenID`),
  ADD KEY `fuhrpark_lager_fk` (`LagerID`);

--
-- Indizes für die Tabelle `haltepunkt`
--
ALTER TABLE `haltepunkt`
  ADD PRIMARY KEY (`HaltepunktID`),
  ADD KEY `haltepunkt_fahrtenbuch_fk` (`FahrtenbuchID`),
  ADD KEY `haltepunkt_standort_fk` (`StandortID`);

--
-- Indizes für die Tabelle `kunde`
--
ALTER TABLE `kunde`
  ADD PRIMARY KEY (`KundeID`),
  ADD UNIQUE KEY `EmailAdress` (`EmailAdress`),
  ADD UNIQUE KEY `Mobilnummer` (`Mobilnummer`),
  ADD KEY `kunde_kundenkonto_fk` (`KKontoID`),
  ADD KEY `kunde_standort_fk` (`WohnortID`);

--
-- Indizes für die Tabelle `kundenkonto`
--
ALTER TABLE `kundenkonto`
  ADD PRIMARY KEY (`KKontoID`);

--
-- Indizes für die Tabelle `lager`
--
ALTER TABLE `lager`
  ADD PRIMARY KEY (`LagerID`),
  ADD KEY `lager_region_fk` (`RegionID`),
  ADD KEY `lager_standort_fk` (`StandortID`);

--
-- Indizes für die Tabelle `lager_einzelteile`
--
ALTER TABLE `lager_einzelteile`
  ADD PRIMARY KEY (`Lager_EteileID`),
  ADD KEY `lager_einzelteile_lager_fk` (`LagerID`),
  ADD KEY `lager_einzelteile_fk` (`EinzelteileID`);

--
-- Indizes für die Tabelle `lager_lieferant`
--
ALTER TABLE `lager_lieferant`
  ADD PRIMARY KEY (`Lager_LieferID`),
  ADD KEY `lager_lieferant_lager_fk` (`LagerID`),
  ADD KEY `lager_lieferant_lieferant_fk` (`LieferantID`);

--
-- Indizes für die Tabelle `lieferant`
--
ALTER TABLE `lieferant`
  ADD PRIMARY KEY (`LieferantID`),
  ADD UNIQUE KEY `LieferantName` (`LieferantName`);

--
-- Indizes für die Tabelle `lieferdetails`
--
ALTER TABLE `lieferdetails`
  ADD PRIMARY KEY (`LieferdetailsID`),
  ADD KEY `lieferdetails_lager_lieferant_fk` (`Lager_LieferID`),
  ADD KEY `lieferdetails_einzelteile_fk` (`EinzelteileID`);

--
-- Indizes für die Tabelle `lieferung`
--
ALTER TABLE `lieferung`
  ADD PRIMARY KEY (`LieferungID`),
  ADD KEY `lieferung_lieferdetails_fk` (`LieferdetailsID`);

--
-- Indizes für die Tabelle `mitarbeiter`
--
ALTER TABLE `mitarbeiter`
  ADD PRIMARY KEY (`MitarbeiterID`),
  ADD UNIQUE KEY `BusinessEmail` (`BusinessEmail`),
  ADD KEY `mitarbeiter_manager_fk` (`ManagerID`),
  ADD KEY `mitarbeiter_privatinfo_fk` (`PrivatinfoID`),
  ADD KEY `mitarbeiter_standort_fk` (`ArbeitsortID`),
  ADD KEY `mitarbeiter_abteilung_fk` (`AbteilungID`);

--
-- Indizes für die Tabelle `privatinfo`
--
ALTER TABLE `privatinfo`
  ADD PRIMARY KEY (`PrivatInfoID`),
  ADD UNIQUE KEY `Mobilnummer` (`Mobilnummer`),
  ADD UNIQUE KEY `EmailPrivate` (`EmailPrivate`),
  ADD KEY `privatinfo_standort_fk` (`WohnortID`);

--
-- Indizes für die Tabelle `region`
--
ALTER TABLE `region`
  ADD PRIMARY KEY (`RegionID`);

--
-- Indizes für die Tabelle `reparatur`
--
ALTER TABLE `reparatur`
  ADD PRIMARY KEY (`ReparaturID`),
  ADD KEY `reparatur_defekt_fk` (`DefektID`),
  ADD KEY `reparatur_mitarbeiter_fk` (`BearbeiterID`),
  ADD KEY `reparatur_lager_fk` (`LagerID`);

--
-- Indizes für die Tabelle `standort`
--
ALTER TABLE `standort`
  ADD PRIMARY KEY (`StandortID`);

--
-- Indizes für die Tabelle `warenausgabe`
--
ALTER TABLE `warenausgabe`
  ADD PRIMARY KEY (`WarenausgabeID`),
  ADD KEY `warenausgabe_reparatur_fk` (`ReparaturID`),
  ADD KEY `warenausgabe_einzelteile_fk` (`EinzelteileID`);

--
-- Indizes für die Tabelle `zahlung`
--
ALTER TABLE `zahlung`
  ADD PRIMARY KEY (`ZahlungID`),
  ADD KEY `zahlung_bestell_eroller_fk` (`BestellERID`),
  ADD KEY `zahlung_zmethod_fk` (`ZMethodID`);

--
-- Indizes für die Tabelle `zahlungsmethode`
--
ALTER TABLE `zahlungsmethode`
  ADD PRIMARY KEY (`ZMethodID`);

--
-- AUTO_INCREMENT für exportierte Tabellen
--

--
-- AUTO_INCREMENT für Tabelle `bestellung_eroller`
--
ALTER TABLE `bestellung_eroller`
  MODIFY `BestellERID` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=512;

--
-- AUTO_INCREMENT für Tabelle `defekt`
--
ALTER TABLE `defekt`
  MODIFY `DefektID` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=128;

--
-- AUTO_INCREMENT für Tabelle `einzelteile`
--
ALTER TABLE `einzelteile`
  MODIFY `EinzelteileID` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=55;

--
-- AUTO_INCREMENT für Tabelle `eroller`
--
ALTER TABLE `eroller`
  MODIFY `ERollerID` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=1024;

--
-- AUTO_INCREMENT für Tabelle `fahrtenbuch`
--
ALTER TABLE `fahrtenbuch`
  MODIFY `FahrtenbuchID` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=101;

--
-- AUTO_INCREMENT für Tabelle `haltepunkt`
--
ALTER TABLE `haltepunkt`
  MODIFY `HaltepunktID` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=512;

--
-- AUTO_INCREMENT für Tabelle `kunde`
--
ALTER TABLE `kunde`
  MODIFY `KundeID` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=512;

--
-- AUTO_INCREMENT für Tabelle `kundenkonto`
--
ALTER TABLE `kundenkonto`
  MODIFY `KKontoID` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=512;

--
-- AUTO_INCREMENT für Tabelle `lager_einzelteile`
--
ALTER TABLE `lager_einzelteile`
  MODIFY `Lager_EteileID` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=260;

--
-- AUTO_INCREMENT für Tabelle `lager_lieferant`
--
ALTER TABLE `lager_lieferant`
  MODIFY `Lager_LieferID` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=379;

--
-- AUTO_INCREMENT für Tabelle `lieferant`
--
ALTER TABLE `lieferant`
  MODIFY `LieferantID` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=79;

--
-- AUTO_INCREMENT für Tabelle `lieferdetails`
--
ALTER TABLE `lieferdetails`
  MODIFY `LieferdetailsID` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=406;

--
-- AUTO_INCREMENT für Tabelle `lieferung`
--
ALTER TABLE `lieferung`
  MODIFY `LieferungID` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=406;

--
-- AUTO_INCREMENT für Tabelle `mitarbeiter`
--
ALTER TABLE `mitarbeiter`
  MODIFY `MitarbeiterID` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=52;

--
-- AUTO_INCREMENT für Tabelle `privatinfo`
--
ALTER TABLE `privatinfo`
  MODIFY `PrivatInfoID` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=52;

--
-- AUTO_INCREMENT für Tabelle `reparatur`
--
ALTER TABLE `reparatur`
  MODIFY `ReparaturID` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=128;

--
-- AUTO_INCREMENT für Tabelle `standort`
--
ALTER TABLE `standort`
  MODIFY `StandortID` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=2048;

--
-- AUTO_INCREMENT für Tabelle `warenausgabe`
--
ALTER TABLE `warenausgabe`
  MODIFY `WarenausgabeID` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=128;

--
-- AUTO_INCREMENT für Tabelle `zahlung`
--
ALTER TABLE `zahlung`
  MODIFY `ZahlungID` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=512;

--
-- Constraints der exportierten Tabellen
--

--
-- Constraints der Tabelle `bestellung_eroller`
--
ALTER TABLE `bestellung_eroller`
  ADD CONSTRAINT `bestell_eroller_eroller_fk` FOREIGN KEY (`ERollerID`) REFERENCES `eroller` (`ERollerID`),
  ADD CONSTRAINT `bestell_eroller_kunde_fk` FOREIGN KEY (`KundeID`) REFERENCES `kunde` (`KundeID`),
  ADD CONSTRAINT `bestell_eroller_standort_fk1` FOREIGN KEY (`StartPunktID`) REFERENCES `standort` (`StandortID`),
  ADD CONSTRAINT `bestell_eroller_standort_fk2` FOREIGN KEY (`EndPunktID`) REFERENCES `standort` (`StandortID`);

--
-- Constraints der Tabelle `defekt`
--
ALTER TABLE `defekt`
  ADD CONSTRAINT `defekt_eroller_fk` FOREIGN KEY (`ERollerID`) REFERENCES `eroller` (`ERollerID`);

--
-- Constraints der Tabelle `eroller`
--
ALTER TABLE `eroller`
  ADD CONSTRAINT `eroller_haltepunkt_fk` FOREIGN KEY (`HaltepunktID`) REFERENCES `haltepunkt` (`HaltepunktID`),
  ADD CONSTRAINT `eroller_lager_fk` FOREIGN KEY (`LagerID`) REFERENCES `lager` (`LagerID`),
  ADD CONSTRAINT `eroller_standort_fk` FOREIGN KEY (`StandortID`) REFERENCES `standort` (`StandortID`);

--
-- Constraints der Tabelle `fahrtenbuch`
--
ALTER TABLE `fahrtenbuch`
  ADD CONSTRAINT `fahrtenbuch_fuhrpark_fk` FOREIGN KEY (`FirmenwagenID`) REFERENCES `fuhrpark` (`FirmenwagenID`),
  ADD CONSTRAINT `fahrtenbuch_mitarbeiter_fk` FOREIGN KEY (`MitarbeiterID`) REFERENCES `mitarbeiter` (`MitarbeiterID`);

--
-- Constraints der Tabelle `fuhrpark`
--
ALTER TABLE `fuhrpark`
  ADD CONSTRAINT `fuhrpark_lager_fk` FOREIGN KEY (`LagerID`) REFERENCES `lager` (`LagerID`);

--
-- Constraints der Tabelle `haltepunkt`
--
ALTER TABLE `haltepunkt`
  ADD CONSTRAINT `haltepunkt_fahrtenbuch_fk` FOREIGN KEY (`FahrtenbuchID`) REFERENCES `fahrtenbuch` (`FahrtenbuchID`),
  ADD CONSTRAINT `haltepunkt_standort_fk` FOREIGN KEY (`StandortID`) REFERENCES `standort` (`StandortID`);

--
-- Constraints der Tabelle `kunde`
--
ALTER TABLE `kunde`
  ADD CONSTRAINT `kunde_kundenkonto_fk` FOREIGN KEY (`KKontoID`) REFERENCES `kundenkonto` (`KKontoID`),
  ADD CONSTRAINT `kunde_standort_fk` FOREIGN KEY (`WohnortID`) REFERENCES `standort` (`StandortID`);

--
-- Constraints der Tabelle `lager`
--
ALTER TABLE `lager`
  ADD CONSTRAINT `lager_region_fk` FOREIGN KEY (`RegionID`) REFERENCES `region` (`RegionID`),
  ADD CONSTRAINT `lager_standort_fk` FOREIGN KEY (`StandortID`) REFERENCES `standort` (`StandortID`);

--
-- Constraints der Tabelle `lager_einzelteile`
--
ALTER TABLE `lager_einzelteile`
  ADD CONSTRAINT `lager_einzelteile_fk` FOREIGN KEY (`EinzelteileID`) REFERENCES `einzelteile` (`EinzelteileID`),
  ADD CONSTRAINT `lager_einzelteile_lager_fk` FOREIGN KEY (`LagerID`) REFERENCES `lager` (`LagerID`);

--
-- Constraints der Tabelle `lager_lieferant`
--
ALTER TABLE `lager_lieferant`
  ADD CONSTRAINT `lager_lieferant_lager_fk` FOREIGN KEY (`LagerID`) REFERENCES `lager` (`LagerID`),
  ADD CONSTRAINT `lager_lieferant_lieferant_fk` FOREIGN KEY (`LieferantID`) REFERENCES `lieferant` (`LieferantID`);

--
-- Constraints der Tabelle `lieferdetails`
--
ALTER TABLE `lieferdetails`
  ADD CONSTRAINT `lieferdetails_einzelteile_fk` FOREIGN KEY (`EinzelteileID`) REFERENCES `einzelteile` (`EinzelteileID`),
  ADD CONSTRAINT `lieferdetails_lager_lieferant_fk` FOREIGN KEY (`Lager_LieferID`) REFERENCES `lager_lieferant` (`Lager_LieferID`);

--
-- Constraints der Tabelle `lieferung`
--
ALTER TABLE `lieferung`
  ADD CONSTRAINT `lieferung_lieferdetails_fk` FOREIGN KEY (`LieferdetailsID`) REFERENCES `lieferdetails` (`LieferdetailsID`);

--
-- Constraints der Tabelle `mitarbeiter`
--
ALTER TABLE `mitarbeiter`
  ADD CONSTRAINT `mitarbeiter_abteilung_fk` FOREIGN KEY (`AbteilungID`) REFERENCES `abteilung` (`AbteilungID`),
  ADD CONSTRAINT `mitarbeiter_manager_fk` FOREIGN KEY (`ManagerID`) REFERENCES `mitarbeiter` (`MitarbeiterID`),
  ADD CONSTRAINT `mitarbeiter_privatinfo_fk` FOREIGN KEY (`PrivatinfoID`) REFERENCES `privatinfo` (`PrivatInfoID`),
  ADD CONSTRAINT `mitarbeiter_standort_fk` FOREIGN KEY (`ArbeitsortID`) REFERENCES `standort` (`StandortID`);

--
-- Constraints der Tabelle `privatinfo`
--
ALTER TABLE `privatinfo`
  ADD CONSTRAINT `privatinfo_standort_fk` FOREIGN KEY (`WohnortID`) REFERENCES `standort` (`StandortID`);

--
-- Constraints der Tabelle `reparatur`
--
ALTER TABLE `reparatur`
  ADD CONSTRAINT `reparatur_defekt_fk` FOREIGN KEY (`DefektID`) REFERENCES `defekt` (`DefektID`),
  ADD CONSTRAINT `reparatur_lager_fk` FOREIGN KEY (`LagerID`) REFERENCES `lager` (`LagerID`),
  ADD CONSTRAINT `reparatur_mitarbeiter_fk` FOREIGN KEY (`BearbeiterID`) REFERENCES `mitarbeiter` (`MitarbeiterID`);

--
-- Constraints der Tabelle `warenausgabe`
--
ALTER TABLE `warenausgabe`
  ADD CONSTRAINT `warenausgabe_einzelteile_fk` FOREIGN KEY (`EinzelteileID`) REFERENCES `einzelteile` (`EinzelteileID`),
  ADD CONSTRAINT `warenausgabe_reparatur_fk` FOREIGN KEY (`ReparaturID`) REFERENCES `reparatur` (`ReparaturID`);

--
-- Constraints der Tabelle `zahlung`
--
ALTER TABLE `zahlung`
  ADD CONSTRAINT `zahlung_bestell_eroller_fk` FOREIGN KEY (`BestellERID`) REFERENCES `bestellung_eroller` (`BestellERID`),
  ADD CONSTRAINT `zahlung_zmethod_fk` FOREIGN KEY (`ZMethodID`) REFERENCES `zahlungsmethode` (`ZMethodID`);
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
