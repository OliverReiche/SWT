-- 
-- Datenbank: ew_db 
-- erstellt am 02.07.2023
-- durch Projektgruppe C5
-- Datenbank mit Tabellen für EcoWheels Verwaltungssystem

-- --------------------------------------------------------


DROP DATABASE IF EXISTS EW_DB;
CREATE DATABASE IF NOT EXISTS EW_DB 
DEFAULT CHARACTER SET utf8mb4 
COLLATE utf8mb4_general_ci;
USE EW_DB;


DROP TABLE IF EXISTS ZAHLUNGSMETHODE;
CREATE TABLE IF NOT EXISTS ZAHLUNGSMETHODE 
(
     ZMethodID          integer	        not null
    ,MinutenSatz	    integer	        not null
    ,ZahlungsType	    enum('K','A')	not null
    ,CONSTRAINT zmethod_pk PRIMARY KEY (ZMethodID)
);

DROP TABLE IF EXISTS ZAHLUNG;
CREATE TABLE IF NOT EXISTS ZAHLUNG 
(
     ZahlungID	        integer	        not null	AUTO_INCREMENT
    ,GesamtPreis	    decimal(6,2)	not null	-- Berechnet: Bestellung_ERoller.NutzungsZeit * Zahlungsmethode.MinutenSatz
    ,BestellERID	    integer	        not null	-- FK, Referenz auf Bestellung_ERoller.BestellERID
    ,ZMethodID	        integer	        not null	-- FK, Referenz auf Zahlungsmethode.ZMethodID
    ,CONSTRAINT zahlung_pk PRIMARY KEY (ZahlungID)
);


DROP TABLE IF EXISTS KUNDENKONTO;
CREATE TABLE IF NOT EXISTS KUNDENKONTO
(
     KKontoID	        integer	        not null	AUTO_INCREMENT
    ,Guthaben	        decimal(5,2)	not null	
    ,LetzteZahlung	    Date	            null	
    ,CONSTRAINT kundenkonto_pk PRIMARY KEY (KKontoID)
);


DROP TABLE IF EXISTS KUNDE;
CREATE TABLE IF NOT EXISTS KUNDE 
(
     KundeID	        integer	        not null	AUTO_INCREMENT
    ,Nachname	        varchar(30)	    not null	
    ,Vorname	        varchar(30)	    not null	
    ,EmailAdress	    varchar(100)	not null	Unique
    ,Mobilnummer	    varchar(30) 	not null	Unique
    ,Geschlecht	        enum('M','W','D')	null	-- Werte:M (männlich),W (weiblich),D (divers)
    ,LetzteNutzung	    Date	        not null	
    ,Inaktiv	        boolean	        not null	
    ,KKontoID	        integer	        not null	-- FK, Referenz auf Kundenkonto.KKontoID
    ,WohnortID	        integer	        not null	-- FK, Referenz auf Standort.StandortID
    ,CONSTRAINT kunde_pk PRIMARY KEY (KundeID)
);


DROP TABLE IF EXISTS STANDORT;
CREATE TABLE IF NOT EXISTS STANDORT
(	
	 StandortID	        integer	        not null	AUTO_INCREMENT
    ,PLZ	            char(5)	        not null	
    ,Stadt	            varchar(30)	    not null	
    ,Strasse	        varchar(30)	    not null	
    ,Sammelpunkt	    boolean         	null
    ,CONSTRAINT standort_pk PRIMARY KEY (StandortID)
);


DROP TABLE IF EXISTS BESTELLUNG_EROLLER;
CREATE TABLE IF NOT EXISTS BESTELLUNG_EROLLER 
(
     BestellERID	    integer	        not null	AUTO_INCREMENT
    ,Nutzdauer	        time	        not null	
    ,StartPunktID	    integer	        not null	-- FK, Referenz auf Standort.StandortID
    ,EndPunktID	        integer	        not null	-- FK, Referenz auf Standort.StandortID
    ,GesamtFahrstecke	integer	        not null	
    ,KundeID	        integer	        not null	-- FK, Referenz auf kunde.KundeID
    ,ERollerID	        integer	        not null	-- FK, Referenz auf ERoller.ERollerID
    ,CONSTRAINT bestell_er_pk PRIMARY KEY (BestellERID)
);


DROP TABLE IF EXISTS EROLLER;
CREATE TABLE IF NOT EXISTS EROLLER 
(
     ERollerID	        integer	        not null	AUTO_INCREMENT
    ,LetzteWartung	    Date	        not null	
    ,NaechsteWartung	Date	        not null	-- Berechnet: LetzteWartung + 7 Tage
    ,IstDefekt	        Boolean	        not null	-- True = Defekt, Flase = Nicht Defekt
    ,Batterie	        integer	        not null	
    ,StandortID	        integer	        not null	-- FK, Referenz auf Standort.StandortID
    ,LagerID	        integer	        not null	-- FK, Referenz auf Lager.LagerID
    ,HaltepunktID	    integer	            null	-- FK, Referenz auf Haltepunkt.HaltepunktID
    ,CONSTRAINT eroller_pk PRIMARY KEY (ERollerID)
);


DROP TABLE IF EXISTS DEFEKT;
CREATE TABLE IF NOT EXISTS DEFEKT 
(
     DefektID	        integer	        not null	AUTO_INCREMENT
    ,Defekts	        varchar(250)    not null		
    ,ERollerID	        integer	        not null	-- FK, Referenz auf ERoller.ERollerID
    ,CONSTRAINT defekt_pk PRIMARY KEY (DefektID)
);


DROP TABLE IF EXISTS REPARATUR;
CREATE TABLE IF NOT EXISTS REPARATUR 
(
     ReparaturID	    integer	        not null	AUTO_INCREMENT
    ,ReparaturDatum	    Date	        not null	
    ,ReparaturDauer	    integer	            null	
    ,Abgeschlossen	    Boolean	            null    -- True = Abgeschlossen, False = noch in Bearbeitung
    ,DefektID	        integer	        not null	-- FK, Referent auf Defekt.DefektID
    ,BearbeiterID	    integer	        not null	-- FK, Referenz auf Mitarbeiter.MitarbeiterID
    ,LagerID	        integer	        not null	-- FK, Referenz auf Lager.LagerID
    ,CONSTRAINT reparatur_pk PRIMARY KEY (ReparaturID)
);


DROP TABLE IF EXISTS LAGER;
CREATE TABLE IF NOT EXISTS LAGER 
(
     LagerID	        integer	        not null
    ,StandortID	        integer	        not null	-- FK, Referenz auf Standort.StandortID	
    ,RegionID	        integer		    not null	-- FK, Referenz auf Region.RegionID
    ,CONSTRAINT lager_pk PRIMARY KEY (LagerID)
);


DROP TABLE IF EXISTS LAGER_LIEFERANT;
CREATE TABLE IF NOT EXISTS LAGER_LIEFERANT 
(
     Lager_LieferID	    integer	        not null	AUTO_INCREMENT
    ,LieferantID	    integer	        not null	-- FK, Referenz auf Lieferant.LieferantID	
    ,LagerID	        integer	        not null	-- FK, Referenz auf Lager.LagerID
    ,CONSTRAINT lager_lieferant_pk PRIMARY KEY (Lager_LieferID)
);


DROP TABLE IF EXISTS LIEFERANT;
CREATE TABLE IF NOT EXISTS LIEFERANT 
(
     LieferantID	    integer	        not null	AUTO_INCREMENT
    ,LieferantName	    varchar(50)	    not null	Unique
    ,LetzteLieferung	date	        not null	
    ,CONSTRAINT liefernat_pk PRIMARY KEY (LieferantID)
);


DROP TABLE IF EXISTS LAGER_EINZELTEILE;
CREATE TABLE IF NOT EXISTS LAGER_EINZELTEILE
(
     Lager_EteileID	    integer	        not null AUTO_INCREMENT
    ,MinBestand	        integer	        not null	
    ,MaxBestand	        integer	        not null	
    ,Bestand	        integer	        not null
    ,LagerID	        integer	        not null	-- FK, Referenz auf Lager.LagerID
    ,EinzelteileID	    integer	        not null	-- FK, Referenz auf Einzelteile.EinzelteileID
    ,CONSTRAINT lager_eteile_pk PRIMARY KEY (Lager_EteileID)
);


DROP TABLE IF EXISTS EINZELTEILE;
CREATE TABLE IF NOT EXISTS EINZELTEILE 
(   
     EinzelteileID	    integer     	not null AUTO_INCREMENT
    ,EType	            varchar(50)     not null	
    ,EName	            varchar(100)    not null	
    ,Gewicht	        decimal(8,2)	not null	
    ,CONSTRAINT einzelteile_pk PRIMARY KEY (EinzelteileID)
);


DROP TABLE IF EXISTS LIEFERDETAILS;
CREATE TABLE IF NOT EXISTS LIEFERDETAILS 
(
     LieferdetailsID	integer	        not null	AUTO_INCREMENT
    ,Anzahl	            integer	        not null	
    ,Stueckpreis  	    decimal(8,2)	not null	
    ,Lager_LieferID	    integer	        not null	-- FK, Referenz auf lager_lieferant.Lager_LieferantID
    ,EinzelteileID	    integer     	not null	-- FK, Referenz auf Einzelteile.EinzelteileID
    ,CONSTRAINT lieferdetails_pk PRIMARY KEY (LieferdetailsID)
);


DROP TABLE IF EXISTS WARENAUSGABE;
CREATE TABLE IF NOT EXISTS WARENAUSGABE 
(
     WarenausgabeID	    integer	        not null	AUTO_INCREMENT
    ,AnzahlDerTeile     integer         not null
    ,ReparaturID	    integer	        not null	-- FK, Referenz auf Reparatur.ReparaturID
    ,EinzelteileID	    integer	        not null	-- FK, Referenz auf Einzelteile.EinzelteileID
    ,CONSTRAINT warenausgabe_pk PRIMARY KEY (WarenausgabeID)
);


DROP TABLE IF EXISTS LIEFERUNG;
CREATE TABLE IF NOT EXISTS LIEFERUNG 
(   
     LieferungID	    integer	        not null	AUTO_INCREMENT
    ,LieferDatum	    date	        not null	
    ,GesamtPreis	    decimal(8,2)	not null	
    ,LieferdetailsID	integer	        not null	-- FK, Referenz auf Lieferdetails.LieferdetailsID
    ,CONSTRAINT lieferung_pk PRIMARY KEY (LieferungID)
);


DROP TABLE IF EXISTS MITARBEITER;
CREATE TABLE IF NOT EXISTS MITARBEITER
(
     MitarbeiterID	    integer	        not null    AUTO_INCREMENT
    ,BusinessPhone	    varchar(30)	        null	
    ,BusinessEmail	    varchar(100)	not null	Unique  -- Format:Nachname.Vorname@ecowheels.com
    ,JobName	        varchar(30)	    not null	
    ,Einstelldatum	    date	        not null	
    ,ManagerID	        integer	            null	-- FK, Referenz auf Mitarbeiter.MitarbeiterID
    ,PrivatinfoID	    integer	        not null	-- FK, Referenz auf Privatinfo.PrivatinfoID
    ,ArbeitsortID	    integer	        not null	-- FK, Referenz auf Standort.StandortID
    ,AbteilungID	    integer	        not null	-- FK, Referenz auf Abteilung.AbteilungID
    ,CONSTRAINT mitarbeiter_pk PRIMARY KEY (MitarbeiterID)
);


DROP TABLE IF EXISTS ABTEILUNG;
CREATE TABLE IF NOT EXISTS ABTEILUNG
(
     AbteilungID	    integer	        not null
    ,AbteilungName	    varchar(30)	    not null	Unique
    ,CONSTRAINT abteilung_pk PRIMARY KEY (AbteilungID)
);


DROP TABLE IF EXISTS REGION;
CREATE TABLE IF NOT EXISTS REGION
(
     RegionID	        integer	        not null
    ,Region_Name	    varchar(30)	    not null
    ,CONSTRAINT region_pk PRIMARY KEY (RegionID)
);


DROP TABLE IF EXISTS PRIVATINFO;
CREATE TABLE IF NOT EXISTS PRIVATINFO
(
     PrivatInfoID	    integer	        not null	AUTO_INCREMENT
    ,Nachname	        varchar(30)	    not null	
    ,Vorname	        varchar(30)	    not null	
    ,Mobilnummer	    varchar(30)	    not null	Unique
    ,EmailPrivate	    varchar(100)	not null	Unique
    ,WohnortID	        integer	        not null	-- FK, Referenz auf Standort.StandortID
    ,CONSTRAINT privatinfo_pk PRIMARY KEY (PrivatInfoID)
);


DROP TABLE IF EXISTS FUHRPARK;
CREATE TABLE IF NOT EXISTS FUHRPARK
(
     FirmenwagenID	    integer	        not null
    ,AutoType	        varchar(50)	    not null	
    ,NaechsteWartung	date	        not null	
    ,LagerID	        integer	        not null	-- FK, Referenz auf Lager.LagerID
    ,CONSTRAINT firmenwagen_pk PRIMARY KEY (FirmenwagenID)
);


DROP TABLE IF EXISTS FAHRTENBUCH;
CREATE TABLE IF NOT EXISTS FAHRTENBUCH
(
     FahrtenbuchID	    integer	        not null	AUTO_INCREMENT
    ,Fahrtstart	        timestamp	        null	-- Keine lust auf Automatisches ON UPDATE CURRENT_TIMESTAMP()
    ,Fahrtende	        timestamp	        null	
    ,Fahrtdauer	        time	            null	-- Berechnet: |Fahrtstart - Fahrtende|
    ,FirmenwagenID	    integer	        not null	-- FK, Referenz auf Fuhrpark.FirmenwagenID
    ,MitarbeiterID	    integer	        not null	-- FK, Referenz auf Mitarbeiter.MitarbeiterID
    ,RollerEingesamelt	integer	            null
    ,CONSTRAINT fahrtenbuch_pk PRIMARY KEY (FahrtenbuchID)
);


DROP TABLE IF EXISTS HALTEPUNKT;
CREATE TABLE IF NOT EXISTS HALTEPUNKT
(
     HaltepunktID	    integer         not null	AUTO_INCREMENT
    ,Zeitpunkt	        timestamp	    not null	
    ,FahrtenbuchID	    integer	        not null	-- FK, Referenz auf Fahrtenbuch.FahrtenbuchID
    ,StandortID	        integer	        not null	-- FK, Referenz auf Standort.StandortID
    ,CONSTRAINT haltepunkt_pk PRIMARY KEY (HaltepunktID)
);


-- insert FK

-- --------------------------------------------------------

USE ew_db;

ALTER TABLE ZAHLUNG
 ADD CONSTRAINT zahlung_bestell_eroller_fk FOREIGN KEY (BestellERID)
 REFERENCES BESTELLUNG_EROLLER(BestellERID)
 ,ADD CONSTRAINT zahlung_zmethod_fk FOREIGN KEY (ZMethodID)
 REFERENCES ZAHLUNGSMETHODE(ZMethodID)
;


ALTER TABLE KUNDE
 ADD CONSTRAINT kunde_kundenkonto_fk FOREIGN KEY (KKontoID)
 REFERENCES KUNDENKONTO(KKontoID)
 ,ADD CONSTRAINT kunde_standort_fk FOREIGN KEY (WohnortID)
 REFERENCES STANDORT(StandortID)
;


ALTER TABLE BESTELLUNG_EROLLER
 ADD CONSTRAINT bestell_eroller_kunde_fk FOREIGN KEY (KundeID)
 REFERENCES KUNDE(KundeID)
 ,ADD CONSTRAINT bestell_eroller_eroller_fk FOREIGN KEY (ERollerID)
 REFERENCES EROLLER(ERollerID)
 ,ADD CONSTRAINT bestell_eroller_standort_fk1 FOREIGN KEY (StartPunktID)
 REFERENCES STANDORT(StandortID)
 ,ADD CONSTRAINT bestell_eroller_standort_fk2 FOREIGN KEY (EndPunktID)
 REFERENCES STANDORT(StandortID)
;


ALTER TABLE EROLLER
 ADD CONSTRAINT eroller_standort_fk FOREIGN KEY (StandortID)
 REFERENCES STANDORT(StandortID)
 ,ADD CONSTRAINT eroller_lager_fk FOREIGN KEY (LagerID)
 REFERENCES LAGER(LagerID)
 ,ADD CONSTRAINT eroller_haltepunkt_fk FOREIGN KEY (HaltepunktID)
 REFERENCES HALTEPUNKT(HaltepunktID)
;


ALTER TABLE DEFEKT
 ADD CONSTRAINT defekt_eroller_fk FOREIGN KEY (ERollerID)
 REFERENCES EROLLER(ERollerID)
;


ALTER TABLE REPARATUR
 ADD CONSTRAINT reparatur_defekt_fk FOREIGN KEY (DefektID)
 REFERENCES DEFEKT(DefektID)
 ,ADD CONSTRAINT reparatur_mitarbeiter_fk FOREIGN KEY (BearbeiterID)
 REFERENCES MITARBEITER(MitarbeiterID)
 ,ADD CONSTRAINT reparatur_lager_fk FOREIGN KEY (LagerID)
 REFERENCES LAGER(LagerID)
;


ALTER TABLE LAGER
 ADD CONSTRAINT lager_region_fk FOREIGN KEY (RegionID)
 REFERENCES REGION(RegionID)
 ,ADD CONSTRAINT lager_standort_fk FOREIGN KEY (StandortID) 
 REFERENCES STANDORT(StandortID)
;


ALTER TABLE LAGER_LIEFERANT
 ADD CONSTRAINT lager_lieferant_lager_fk FOREIGN KEY (LagerID)
 REFERENCES LAGER(LagerID)
 ,ADD CONSTRAINT lager_lieferant_lieferant_fk FOREIGN KEY (LieferantID) 
 REFERENCES LIEFERANT(LieferantID)
;


ALTER TABLE LAGER_EINZELTEILE
 ADD CONSTRAINT lager_einzelteile_lager_fk FOREIGN KEY (LagerID)
 REFERENCES LAGER(LagerID)
 ,ADD CONSTRAINT lager_einzelteile_fk FOREIGN KEY (EinzelteileID)
 REFERENCES EINZELTEILE(EinzelteileID)
;


ALTER TABLE LIEFERDETAILS
 ADD CONSTRAINT lieferdetails_lager_lieferant_fk FOREIGN KEY (Lager_LieferID)
 REFERENCES Lager_Lieferant(Lager_LieferID)
 ,ADD CONSTRAINT lieferdetails_einzelteile_fk FOREIGN KEY (EinzelteileID)
 REFERENCES EINZELTEILE(EinzelteileID)
;


ALTER TABLE WARENAUSGABE
 ADD CONSTRAINT warenausgabe_reparatur_fk FOREIGN KEY (ReparaturID)
 REFERENCES REPARATUR(ReparaturID)
 ,ADD CONSTRAINT warenausgabe_einzelteile_fk FOREIGN KEY (EinzelteileID)
 REFERENCES EINZELTEILE(EinzelteileID)
;


ALTER TABLE LIEFERUNG
 ADD CONSTRAINT lieferung_lieferdetails_fk FOREIGN KEY (LieferdetailsID)
 REFERENCES LIEFERDETAILS(LieferdetailsID)
;


ALTER TABLE MITARBEITER
 ADD CONSTRAINT mitarbeiter_manager_fk FOREIGN KEY (ManagerID)
 REFERENCES MITARBEITER(MitarbeiterID)
 ,ADD CONSTRAINT mitarbeiter_privatinfo_fk FOREIGN KEY (PrivatinfoID)
 REFERENCES PRIVATINFO(PrivatinfoID)
 ,ADD CONSTRAINT mitarbeiter_standort_fk FOREIGN KEY (ArbeitsortID)
 REFERENCES STANDORT(StandortID)
 ,ADD CONSTRAINT mitarbeiter_abteilung_fk FOREIGN KEY (AbteilungID)
 REFERENCES ABTEILUNG(AbteilungID)
;


ALTER TABLE PRIVATINFO
 ADD CONSTRAINT privatinfo_standort_fk FOREIGN KEY (WohnortID)
 REFERENCES STANDORT(StandortID)
;


ALTER TABLE FUHRPARK
 ADD CONSTRAINT fuhrpark_lager_fk FOREIGN KEY (LagerID)
 REFERENCES LAGER(LagerID)
;


ALTER TABLE FAHRTENBUCH
 ADD CONSTRAINT fahrtenbuch_fuhrpark_fk FOREIGN KEY (FirmenwagenID)
 REFERENCES FUHRPARK(FirmenwagenID)
 ,ADD CONSTRAINT fahrtenbuch_mitarbeiter_fk FOREIGN KEY (MitarbeiterID)
 REFERENCES MITARBEITER(MitarbeiterID)
;


ALTER TABLE HALTEPUNKT
 ADD CONSTRAINT haltepunkt_fahrtenbuch_fk FOREIGN KEY (FahrtenbuchID)
 REFERENCES FAHRTENBUCH(FahrtenbuchID)
 ,ADD CONSTRAINT haltepunkt_standort_fk FOREIGN KEY (StandortID)
 REFERENCES STANDORT(StandortID)
;
