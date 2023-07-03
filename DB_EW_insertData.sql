-- 
-- Datenbank: EcoWheels 
-- erstellt am 
-- durch Projektgruppe C5
-- Datenbank mit Tabellen für EcoWheels Verwaltungssystem
-- Importskript für Testdaten

-- --------------------------------------------------------

USE EW_DB;

--
-- Daten für Tabelle Departments
--

insert into ABTEILUNG values
(10, 'MANAGEMENT'),
(30, 'HUMAN RESOURCE'),
(50, 'CUSTOMER SERVICE'),
(60, 'FIRMENORGANISATION'),
(70, 'WAREHOUSING'),
(71, 'KFZ'),
(72, 'WARTUNG AKKU'),
(110, 'SOCIAL MEDIA')
;

-- --------------------------------------------------------

--
-- Daten für Tabelle Region
--

insert into REGION values
(1, 'NORTH'),
(2, 'SOUTH'),
(3, 'WEST'),
(4, 'EAST'),
(5, 'MIDDLE');


-- --------------------------------------------------------

--
-- Daten für Tabelle ZAHLUNGSMETHODE
--

insert into ZAHLUNGSMETHODE values
(1, 20, 'A'),
(2, 18, 'K');

-- --------------------------------------------------------

--
-- Daten für Tabelle STANDORT
-- Import erfolgt über Bulk Import
-- beim ausführen des Befehls Pfad anpassen!

LOAD DATA INFILE 'standorte.csv' 
INTO TABLE STANDORT
FIELDS TERMINATED BY ',' LINES TERMINATED BY '\r\n'(PLZ, Stadt, Strasse, Sammelpunkt);

-- Übersicht STANDORT:
-- 1  - 50  + 251  - 450   = Hamburg
-- 51 - 100 + 451  - 650   = Berlin
-- 101- 150 + 651  - 850   = Erfurt
-- 151- 200 + 851  - 1050  = Frankfurt am Main
-- 201- 250 + 1051 - 1250 = München

-- STANDORTID für Lager: (jeweils erster Eintrag pro Stadt)
-- Headquarter      = 101 (Erfurt)  
-- Lager Erfurt     = 101           
-- Lager Berlin     = 51            
-- Lager Frankfurt  = 151           
-- Lager München    = 201           
-- Lager Hamburg    = 1             

-- Sammelplätze:
-- Erfurt	: 102-111
-- Berlin	: 52-61
-- Frankfurt: 152-161
-- München	: 202-211
-- Hamburg	: 2-11

-- --------------------------------------------------------

--
-- Daten für Tabelle Lager
--

insert into LAGER (LagerId, RegionId, StandortID)
values
(1, 5, 101),
(2, 4, 51 ),
(3, 3, 151),
(4, 2, 201),
(5, 1, 1  );

-- --------------------------------------------------------

--
-- Daten für Tabelle Privatinfo
--

insert into PRIVATINFO (Vorname, Nachname, Mobilnummer, EmailPrivate, WohnortID) 
values
('ALEXANDER'    ,'SCHMIDT'      ,'017612345678'     ,'a.schmidt@gmail.com'           ,123),    -- Erfurt
('BENJAMIN'     ,'MAYER'        ,'017623456789'     ,'b.mayer@gmail.com'             ,135),    -- Erfurt
('CHRISTOPHER'  ,'BAUER'        ,'017634567890'     ,'c.bauer@googlemail.com'        ,124),    -- Erfurt
('DANIEL'       ,'KELLER'       ,'017645678901'     ,'d.keller@googlemail.com'       ,144),    -- Erfurt
('ERIC'         ,'VOGEL'        ,'017656789012'     ,'e.vogel@googlemail.com'        ,89 ),    -- Berlin
('FLORIAN'      ,'BECKER'       ,'017667890123'     ,'f.becker@googlemail.com'       ,190),    -- Frankfurt
('GABRIEL'      ,'MÜLLER'       ,'017678901234'     ,'g.mueller@googlemail.com'      ,230),    -- München
('HENRY'        ,'SCHMITT'      ,'017689012345'     ,'h.schmitt@gmail.com'           ,42 ),    -- Hamburg
('IVAN'         ,'WAGNER'       ,'017600123456'     ,'i.wagner@gmail.com'            ,140),    -- Erfurt
('JONAS'        ,'HOFMANN'      ,'017611234567'     ,'j.hofmann@googlemail.com'      ,150),    -- Erfurt
('KAI'          ,'KRAUSE'       ,'017622345678'     ,'k.krause@googlemail.com'       ,132),    -- Erfurt
('LUKAS'        ,'SCHULZ'       ,'017633456789'     ,'l.schulz@googlemail.com'       ,117),    -- Erfurt
('MAXIMILIAN'   ,'FRANZ'        ,'017644567890'     ,'m.franz@googlemail.com'        ,88 ),    -- Berlin
('NICO'         ,'BAUMANN'      ,'017655678901'     ,'n.baumann@googlemail.com'      ,84 ),    -- Berlin
('OLIVER'       ,'MAIER'        ,'017666789012'     ,'o.maier@googlemail.com'        ,92 ),    -- Berlin
('PATRICK'      ,'OTT'          ,'017677890123'     ,'p.ott@gmail.com'               ,99 ),    -- Berlin
('QUENTIN'      ,'BERGER'       ,'017688901234'     ,'q.berger@gmail.com'            ,171),    -- Frankfurt
('RICHARD'      ,'KÜHN'         ,'017699012345'     ,'r.kuehn@gmail.com'             ,177),    -- Frankfurt
('SEBASTIAN'    ,'SCHNEIDER'    ,'017610123456'     ,'s.schneider@gmail.com'         ,180),    -- Frankfurt
('TIMO'         ,'GROß'         ,'017621234567'     ,'t.gross@googlemail.com'        ,182),    -- Frankfurt
('UWE'          ,'FRANK'        ,'017632345678'     ,'u.frank@googlemail.com'        ,250),    -- München
('VIKTOR'       ,'WOLF'         ,'017643456789'     ,'v.wolf@gmail.com'              ,240),    -- München
('WILHELM'      ,'SCHWARZ'      ,'017654567890'     ,'w.schwarz@gmail.com'           ,241),    -- München
('XAVER' ,      'BAUER'         ,'017665678901'     ,'x.bauer@gmail.com'             ,226),    -- München
('YANNICK'      ,'KOCH'         ,'017676789012'     ,'y.koch@gmail.com'              ,44 ),    -- Hamburg
('ANNA'         ,'SCHULZ'       ,'017687654321'     ,'a.schulz@gmail.com'            ,136),    -- Erfurt
('BIANCA'       ,'KOCH'         ,'017676543210'     ,'b.koch@gmail.com'              ,141),    -- Erfurt
('CAROLINA'     ,'WEISS'        ,'017665432109'     ,'c.weiss@gmail.com'             ,149),    -- Erfurt
('DENISE'       ,'LANG'         ,'017654321098'     ,'d.lang@gmail.com'              ,100),    -- Berlin
('EMILY'        ,'ROTH'         ,'017643210987'     ,'e.roth@googlemail.com'         ,190),    -- Frankfurt
('FRANZISKA'    ,'KAUFMANN'     ,'017632109876'     ,'f.kaufmann@googlemail.com'     ,210),    -- München
('GISELA'       ,'MAYER'        ,'017621098765'     ,'g.mayer@googlemail.com'        ,48 ),    -- Hamburg
('HANNAH'       ,'SCHÄFER'      ,'017610987654'     ,'h.schaefer@googlemail.com'     ,147),    -- Erfurt
('ISABEL'       ,'BAUER'        ,'017699876543'     ,'i.bauer@googlemail.com'        ,115),    -- Erfurt
('JULIA'        ,'KRÜGER'       ,'017688765432'     ,'j.krueger@gmail.com'           ,68 ),    -- Berlin
('KATHARINA'    ,'FRANK'        ,'017677654321'     ,'k.frank@gmail.com'             ,63 ),    -- Berlin
('LENA'         ,'RAUCH'        ,'017666543210'     ,'l.rauch@gmail.com'             ,196),    -- Frankfurt
('MARIE'        ,'MEIER'        ,'017655432109'     ,'m.meier@gmail.com'             ,198),    -- Frankfurt
('NADINE'       ,'SCHMIDT'      ,'017644321098'     ,'n.schmidt@gmail.com'           ,248),    -- München
('OLIVIA'       ,'WEISE'        ,'017633210987'     ,'o.weise@gmail.com'             ,239),    -- München
('PAULA'        ,'SCHREIBER'    ,'017622109876'     ,'p.schreiber@gmail.com'         ,33 ),    -- Hamburg
('QUEENIE'      ,'HOFFMANN'     ,'017611098765'     ,'q.hoffmann@EcoWheels.com'      ,36 ),    -- Hamburg
('REBEKKA'      ,'KAISER'       ,'017600987654'     ,'r.kaiser@gmail.com'            ,40 ),    -- Hamburg
('SOPHIA'       ,'ROSE'         ,'017589876543'     ,'s.rose@gmail.com'              ,47 ),    -- Hamburg
('TINA'         ,'VOGEL'        ,'017578765432'     ,'t.vogel@gmail.com'             ,29 ),    -- Hamburg
('EMILIAN'      ,'BEYER'        ,'017652622457'     ,'e.beyer@gmail.com'             ,122),    -- Erfurt
('ALEXANDER'    ,'MAIER'        ,'017567654321'     ,'a.maier@gmail.com'             ,120),    -- Erfurt
('BENJAMIN'     ,'HUBER'        ,'017556543210'     ,'b.huber@googlemail.com'        ,72 ),    -- Berlin
('CHRISTIAN'    ,'WEBER'        ,'017545432109'     ,'c.weber@googlemail.com'        ,200),    -- Frankfurt
('DAVID'        ,'SCHNEIDER'    ,'017534321098'     ,'d.schneider@googlemail.com'    ,228),    -- München
('ERIK'         ,'SCHULTE'      ,'017523210987'     ,'e.schulte@googlemail.com'      ,35 );    -- Hamburg

-- Wohnort ID fehlt noch, weil noch keine Location Tabelle implementiert ist!
-- --------------------------------------------------------

--
-- Daten für Tabelle Employee
--
-- BusinessPhone weggelassen erstmal

insert into MITARBEITER (BusinessEmail, JobName, Einstelldatum, ManagerId, PrivatinfoID, ArbeitsortId, AbteilungID)
values
('a.schmidt@EcoWheels.com'      ,'President'            ,'2015-01-01', NULL ,1  ,101, 10), -- Erfurt
('b.mayer@EcoWheels.com'        ,'VP-Investement'       ,'2015-01-01', 1    ,2  ,101, 10), -- Erfurt
('c.bauer@EcoWheels.com'        ,'VP-Warehousing'       ,'2015-01-01', 1    ,3  ,101, 70), -- Erfurt
('d.keller@EcoWheels.com'       ,'Abteilungsleiter WH'  ,'2015-01-01', 3    ,4  ,101, 70), -- Erfurt
('e.vogel@EcoWheels.com'        ,'Abteilungsleiter WH'  ,'2017-04-01', 3    ,5  ,51 , 70), -- Berlin
('f.becker@EcoWheels.com'       ,'Abteilungsleiter WH'  ,'2016-04-01', 3    ,6  ,151, 70), -- Frankfurt
('g.mueller@EcoWheels.com'      ,'Abteilungsleiter WH'  ,'2019-04-01', 3    ,7  ,201, 70), -- München
('h.schmitt@EcoWheels.com'      ,'Abteilungsleiter WH'  ,'2016-04-01', 3    ,8  ,1  , 70), -- Hamburg
('i.wagner@EcoWheels.com'       ,'KFZ-WH'               ,'2015-01-01', 4    ,9  ,101, 71), -- Erfurt
('j.hofmann@EcoWheels.com'      ,'KFZ-WH'               ,'2015-01-01', 4    ,10 ,101, 71), -- Erfurt
('k.krause@EcoWheels.com'       ,'KFZ-WH'               ,'2015-01-01', 4    ,11 ,101, 71), -- Erfurt
('l.schulz@EcoWheels.com'       ,'KFZ-WH'               ,'2015-01-01', 4    ,12 ,101, 71), -- Erfurt
('m.franz@EcoWheels.com'        ,'KFZ-WH'               ,'2017-04-01', 5    ,13 ,51 , 71), -- Berlin
('n.baumann@EcoWheels.com'      ,'KFZ-WH'               ,'2017-04-01', 5    ,14 ,51 , 71), -- Berlin
('o.maier@EcoWheels.com'        ,'KFZ-WH'               ,'2017-07-01', 5    ,15 ,51 , 71), -- Berlin
('p.ott@EcoWheels.com'          ,'KFZ-WH'               ,'2017-10-01', 5    ,16 ,51 , 71), -- Berlin
('q.berger@EcoWheels.com'       ,'KFZ-WH'               ,'2016-04-01', 6    ,17 ,151, 71), -- Frankfurt
('r.kuehn@EcoWheels.com'        ,'KFZ-WH'               ,'2016-04-01', 6    ,18 ,151, 71), -- Frankfurt
('s.schneider@EcoWheels.com'    ,'KFZ-WH'               ,'2016-07-01', 6    ,19 ,151, 71), -- Frankfurt
('t.gross@EcoWheels.com'        ,'KFZ-WH'               ,'2016-10-01', 6    ,20 ,151, 71), -- Frankfurt
('u.frank@EcoWheels.com'        ,'KFZ-WH'               ,'2019-04-01', 7    ,21 ,201, 71), -- München
('v.wolf@EcoWheels.com'         ,'KFZ-WH'               ,'2019-04-01', 7    ,22 ,201, 71), -- München
('w.schwarz@EcoWheels.com'      ,'KFZ-WH'               ,'2019-07-01', 7    ,23 ,201, 71), -- München
('x.bauer@EcoWheels.com'        ,'KFZ-WH'               ,'2019-10-01', 7    ,24 ,201, 71), -- München
('y.koch@EcoWheels.com'         ,'KFZ-WH'               ,'2016-04-01', 8    ,25 ,1  , 71), -- Hamburg
('a.schulz@EcoWheels.com'       ,'Firmenorganisation'   ,'2015-01-01', 1    ,26 ,101, 10), -- Erfurt
('b.koch@EcoWheels.com'         ,'Human Ressource'      ,'2015-04-01', 26   ,27 ,101, 30), -- Erfurt
('c.weiss@EcoWheels.com'        ,'Human Ressource'      ,'2015-07-01', 26   ,28 ,101, 30), -- Erfurt
('d.lang@EcoWheels.com'         ,'Customer Service'     ,'2017-04-01', 26   ,29 ,51 , 50), -- Berlin
('e.roth@EcoWheels.com'         ,'Customer Service'     ,'2016-04-01', 26   ,30 ,151, 50), -- Frankfurt
('f.kaufmann@EcoWheels.com'     ,'Customer Service'     ,'2019-04-01', 26   ,31 ,201, 50), -- München
('g.mayer@EcoWheels.com'        ,'Customer Service'     ,'2016-04-01', 26   ,32 ,1  , 50), -- Hamburg
('h.schaefer@EcoWheels.com'     ,'Logistik'             ,'2015-01-01', 4    ,33 ,101, 70), -- Erfurt
('i.bauer@EcoWheels.com'        ,'Logistik'             ,'2015-10-01', 4    ,34 ,101, 70), -- Erfurt
('j.krueger@EcoWheels.com'      ,'Logistik'             ,'2017-04-01', 5    ,35 ,51 , 70), -- Berlin
('k.frank@EcoWheels.com'        ,'Logistik'             ,'2017-10-01', 5    ,36 ,51 , 70), -- Berlin
('l.rauch@EcoWheels.com'        ,'Logistik'             ,'2016-04-01', 6    ,37 ,151, 70), -- Frankfurt
('m.meier@EcoWheels.com'        ,'Logistik'             ,'2016-07-01', 6    ,38 ,151, 70), -- Frankfurt
('n.schmidt@EcoWheels.com'      ,'Logistik'             ,'2019-04-01', 7    ,39 ,201, 70), -- München
('o.weise@EcoWheels.com'        ,'Logistik'             ,'2019-10-01', 7    ,40 ,201, 70), -- München
('p.schreiber@EcoWheels.com'    ,'Logistik'             ,'2016-04-01', 8    ,41 ,1  , 70), -- Hamburg
('q.hoffmann@EcoWheels.com'     ,'Logistik'             ,'2016-10-01', 8    ,42 ,1  , 70), -- Hamburg
('r.kaiser@EcoWheels.com'       ,'KFZ-WH'               ,'2016-04-01', 8    ,43 ,1  , 71), -- Hamburg
('s.rose@EcoWheels.com'         ,'KFZ-WH'               ,'2016-07-01', 8    ,44 ,1  , 71), -- Hamburg
('t.vogel@EcoWheels.com'        ,'KFZ-WH'               ,'2016-10-01', 8    ,45 ,1  , 71), -- Hamburg
('e.beyer@EcoWheels.com'        ,'Social-Media'         ,'2018-04-01', 1    ,46 ,101, 110),-- Erfurt
('a.maier@EcoWheels.com'        ,'Akku-WH'              ,'2015-04-01', 4    ,47 ,101, 72), -- Erfurt
('b.huber@EcoWheels.com'        ,'Akku-WH'              ,'2017-04-01', 5    ,48 ,51 , 72), -- Berlin
('c.weber@EcoWheels.com'        ,'Akku-WH'              ,'2016-04-01', 6    ,49 ,151, 72), -- Frankfurt
('d.schneider@EcoWheels.com'    ,'Akku-WH'              ,'2019-04-01', 7    ,50 ,201, 72), -- München
('e.schulte@EcoWheels.com'      ,'Akku-WH'              ,'2016-04-01', 8    ,51 ,1  , 72); -- Hamburg

-- --------------------------------------------------------

--
-- Daten für Tabelle Kundenkonto
--

LOAD DATA INFILE 'kundenkonto.csv' 
INTO TABLE kundenkonto
FIELDS TERMINATED BY ',' LINES TERMINATED BY '\r\n'(Guthaben);

-- --------------------------------------------------------

--
-- Daten für Tabelle Kunde
-- Import erfolgt über Bulk Import
-- beim ausführen des Befehls Pfad anpassen!

LOAD DATA INFILE 'kunden.csv' 
INTO TABLE kunde
FIELDS TERMINATED BY ',' LINES TERMINATED BY '\r\n'(Nachname, Vorname, EmailAdress, Mobilnummer, Geschlecht, LetzteNutzung, Inaktiv, KKontoID, WohnortID);

-- --------------------------------------------------------

--
-- Daten für Tabelle Lieferant
--

LOAD DATA INFILE 'Lieferant.csv'
INTO TABLE Lieferant
FIELDS TERMINATED BY ',' LINES TERMINATED BY '\r\n' (LieferantID, LieferantName, LetzteLieferung);

-- --------------------------------------------------------

--
-- Daten für Tabelle Roller
--

LOAD DATA INFILE 'Roller.csv'
INTO TABLE eroller
FIELDS TERMINATED BY ',' LINES TERMINATED BY '\r\n' (LetzteWartung, NaechsteWartung, IstDefekt, Batterie, LagerID, StandortID, HaltepunktID);

-- --------------------------------------------------------

--
-- Daten für Tabelle Einzelteile
--

LOAD DATA INFILE 'Einzelteile.csv'
INTO TABLE Einzelteile
FIELDS TERMINATED BY ',' LINES TERMINATED BY '\r\n' (EinzelteileID, EType, EName, Gewicht);

-- --------------------------------------------------------

--
-- Daten für Tabelle Lager_Einzelteile
--

LOAD DATA INFILE 'lager_einzelteile.csv'
INTO TABLE lager_einzelteile
FIELDS TERMINATED BY ',' LINES TERMINATED BY '\r\n' (MinBestand, MaxBestand, Bestand, LagerID, EinzelteileID);

-- --------------------------------------------------------

--
-- Daten für Tabelle Lager_Lieferant
--

LOAD DATA INFILE 'lager_lieferant.csv'
INTO TABLE lager_lieferant
FIELDS TERMINATED BY ',' LINES TERMINATED BY '\r\n' (Lager_LieferID, LieferantID, LagerID);

-- --------------------------------------------------------

--
-- Daten für Tabelle bestellung_eroller
--

LOAD DATA INFILE 'bestellung_eroller.csv'
INTO TABLE bestellung_eroller
FIELDS TERMINATED BY ',' LINES TERMINATED BY '\r\n' (Nutzdauer, StartPunktID, EndPunktID, GesamtFahrstecke, KundeID, ERollerID);

-- --------------------------------------------------------

--
-- Daten für Tabelle Zahlung
--

LOAD DATA INFILE 'zahlung.csv'
INTO TABLE zahlung
FIELDS TERMINATED BY ',' LINES TERMINATED BY '\r\n' (GesamtPreis, BestellERID, ZMethodID);

-- --------------------------------------------------------

--
-- Daten für Tabelle Lieferdetails
--

LOAD DATA INFILE 'lieferdetails.csv'
INTO TABLE lieferdetails
FIELDS TERMINATED BY ',' LINES TERMINATED BY '\r\n' (Lager_LieferID, Anzahl,Stueckpreis, EinzelteileID);

-- --------------------------------------------------------

--
-- Daten für Tabelle Lieferung
--

LOAD DATA INFILE 'lieferung.csv'
INTO TABLE lieferung
FIELDS TERMINATED BY ',' LINES TERMINATED BY '\r\n' (LieferDatum, GesamtPreis, LieferdetailsID);


-- --------------------------------------------------------

--
-- Daten für Tabelle Defekt
--

LOAD DATA INFILE 'defekte.csv'
INTO TABLE defekt
FIELDS TERMINATED BY ',' LINES TERMINATED BY '\r\n' (Defekts, ERollerID);

-- --------------------------------------------------------

--
-- Daten für Tabelle Reparatur
--

LOAD DATA INFILE 'Reparatur.csv'
INTO TABLE Reparatur
FIELDS TERMINATED BY ',' LINES TERMINATED BY '\r\n' (ReparaturDatum,DefektID,BearbeiterID,LagerID);

-- --------------------------------------------------------

--
-- Daten für Tabelle Reparatur
--

LOAD DATA INFILE 'Warenausgabe.csv'
INTO TABLE Warenausgabe
FIELDS TERMINATED BY ',' LINES TERMINATED BY '\r\n' (AnzahlDerTeile,ReparaturID,EinzelteileID);

-- --------------------------------------------------------


--
-- Daten für Tabelle Fuhrpark
--


INSERT INTO FUHRPARK
VALUES
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


--
-- Daten für Tabelle Fahrtenbuch
--

LOAD DATA INFILE 'Fahrtenbuch.csv'
INTO TABLE Fahrtenbuch
FIELDS TERMINATED BY ',' LINES TERMINATED BY '\r\n' (Fahrtstart,Fahrtende,FirmenwagenID, MitarbeiterID, RollerEingesamelt);


--
-- Daten für Tabelle Haltepunkt
--

LOAD DATA INFILE 'Haltepunkt.csv'
INTO TABLE Haltepunkt
FIELDS TERMINATED BY ',' LINES TERMINATED BY '\r\n' (Zeitpunkt, FahrtenbuchID, StandortID);