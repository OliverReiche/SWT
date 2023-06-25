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
-- Daten für Tabelle Privatinfo
--

insert into PRIVATINFO (Vorname, Nachname, Mobilnummer, EmailPrivate, WohnortID) 
values
('ALEXANDER'    ,'SCHMIDT'      ,'017612345678'     ,'a.schmidt@gmail.com'           ,102),    -- Erfurt
('BENJAMIN'     ,'MAYER'        ,'017623456789'     ,'b.mayer@gmail.com'             ,135),    -- Erfurt
('CHRISTOPHER'  ,'BAUER'        ,'017634567890'     ,'c.bauer@googlemail.com'        ,124),    -- Erfurt
('DANIEL'       ,'KELLER'       ,'017645678901'     ,'d.keller@googlemail.com'       ,144),    -- Erfurt
('ERIC'         ,'VOGEL'        ,'017656789012'     ,'e.vogel@googlemail.com'        ,89 ),    -- Berlin
('FLORIAN'      ,'BECKER'       ,'017667890123'     ,'f.becker@googlemail.com'       ,190),    -- Frankfurt
('GABRIEL'      ,'MÜLLER'       ,'017678901234'     ,'g.mueller@googlemail.com'      ,230),    -- München
('HENRY'        ,'SCHMITT'      ,'017689012345'     ,'h.schmitt@gmail.com'           ,5  ),    -- Hamburg
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
('ISABEL'       ,'BAUER'        ,'017699876543'     ,'i.bauer@googlemail.com'        ,111),    -- Erfurt
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

01-04-07-10

insert into MITARBEITER (BusinessEmail, JobTitle, Einstelldatum, ManagerId, PrivatinfoID, ArbeitsortId, AbteilungID)
values
('a.schmidt@EcoWheels.com'      ,'President'            ,'2015-01-01', NULL ,1  ,110, 10), -- Erfurt
('b.mayer@EcoWheels.com'        ,'VP-Investement'       ,'2015-01-01', 1    ,2  ,110, 10), -- Erfurt
('c.bauer@EcoWheels.com'        ,'VP-Warehousing'       ,'2015-01-01', 1    ,3  ,110, 70), -- Erfurt
('d.keller@EcoWheels.com'       ,'Abteilungsleiter WH'  ,'2015-01-01', 3    ,4  ,110, 70), -- Erfurt
('e.vogel@EcoWheels.com'        ,'Abteilungsleiter WH'  ,'2017-04-01', 3    ,5  ,52 , 70), -- Berlin
('f.becker@EcoWheels.com'       ,'Abteilungsleiter WH'  ,'2016-04-01', 3    ,6  ,151, 70), -- Frankfurt
('g.mueller@EcoWheels.com'      ,'Abteilungsleiter WH'  ,'2019-04-01', 3    ,7  ,203, 70), -- München
('h.schmitt@EcoWheels.com'      ,'Abteilungsleiter WH'  ,'2016-04-01', 3    ,8  ,4  , 70), -- Hamburg
('i.wagner@EcoWheels.com'       ,'KFZ-WH'               ,'2015-01-01', 4    ,9  ,110, 71), -- Erfurt
('j.hofmann@EcoWheels.com'      ,'KFZ-WH'               ,'2015-01-01', 4    ,10 ,110, 71), -- Erfurt
('k.krause@EcoWheels.com'       ,'KFZ-WH'               ,'2015-01-01', 4    ,11 ,110, 71), -- Erfurt
('l.schulz@EcoWheels.com'       ,'KFZ-WH'               ,'2015-01-01', 4    ,12 ,110, 71), -- Erfurt
('m.franz@EcoWheels.com'        ,'KFZ-WH'               ,'2017-04-01', 5    ,13 ,52 , 71), -- Berlin
('n.baumann@EcoWheels.com'      ,'KFZ-WH'               ,'2017-04-01', 5    ,14 ,52 , 71), -- Berlin
('o.maier@EcoWheels.com'        ,'KFZ-WH'               ,'2017-07-01', 5    ,15 ,52 , 71), -- Berlin
('p.ott@EcoWheels.com'          ,'KFZ-WH'               ,'2017-10-01', 5    ,16 ,52 , 71), -- Berlin
('q.berger@EcoWheels.com'       ,'KFZ-WH'               ,'2016-04-01', 6    ,17 ,151, 71), -- Frankfurt
('r.kuehn@EcoWheels.com'        ,'KFZ-WH'               ,'2016-04-01', 6    ,18 ,151, 71), -- Frankfurt
('s.schneider@EcoWheels.com'    ,'KFZ-WH'               ,'2016-07-01', 6    ,19 ,151, 71), -- Frankfurt
('t.gross@EcoWheels.com'        ,'KFZ-WH'               ,'2016-10-01', 6    ,20 ,151, 71), -- Frankfurt
('u.frank@EcoWheels.com'        ,'KFZ-WH'               ,'2019-04-01', 7    ,21 ,203, 71), -- München
('v.wolf@EcoWheels.com'         ,'KFZ-WH'               ,'2019-04-01', 7    ,22 ,203, 71), -- München
('w.schwarz@EcoWheels.com'      ,'KFZ-WH'               ,'2019-07-01', 7    ,23 ,203, 71), -- München
('x.bauer@EcoWheels.com'        ,'KFZ-WH'               ,'2019-10-01', 7    ,24 ,203, 71), -- München
('y.koch@EcoWheels.com'         ,'KFZ-WH'               ,'2016-04-01', 8    ,25 ,4  , 71), -- Hamburg
('a.schulz@EcoWheels.com'       ,'Firmenorganisation'   ,'2015-01-01', 1    ,26 ,110, 10), -- Erfurt
('b.koch@EcoWheels.com'         ,'Human Ressource'      ,'2015-04-01', 26   ,27 ,110, 30), -- Erfurt
('c.weiss@EcoWheels.com'        ,'Human Ressource'      ,'2015-07-01', 26   ,28 ,110, 30), -- Erfurt
('d.lang@EcoWheels.com'         ,'Customer Service'     ,'2017-04-01', 26   ,29 ,52 , 50), -- Berlin
('e.roth@EcoWheels.com'         ,'Customer Service'     ,'2016-04-01', 26   ,30 ,151, 50), -- Frankfurt
('f.kaufmann@EcoWheels.com'     ,'Customer Service'     ,'2019-04-01', 26   ,31 ,203, 50), -- München
('g.mayer@EcoWheels.com'        ,'Customer Service'     ,'2016-04-01', 26   ,32 ,4  , 50), -- Hamburg
('h.schaefer@EcoWheels.com'     ,'Logistik'             ,'2015-01-01', 4    ,33 ,110, 70), -- Erfurt
('i.bauer@EcoWheels.com'        ,'Logistik'             ,'2015-10-01', 4    ,34 ,110, 70), -- Erfurt
('j.krueger@EcoWheels.com'      ,'Logistik'             ,'2017-04-01', 5    ,35 ,52 , 70), -- Berlin
('k.frank@EcoWheels.com'        ,'Logistik'             ,'2017-10-01', 5    ,36 ,52 , 70), -- Berlin
('l.rauch@EcoWheels.com'        ,'Logistik'             ,'2016-04-01', 6    ,37 ,151, 70), -- Frankfurt
('m.meier@EcoWheels.com'        ,'Logistik'             ,'2016-07-01', 6    ,38 ,151, 70), -- Frankfurt
('n.schmidt@EcoWheels.com'      ,'Logistik'             ,'2019-04-01', 7    ,39 ,203, 70), -- München
('o.weise@EcoWheels.com'        ,'Logistik'             ,'2019-10-01', 7    ,40 ,203, 70), -- München
('p.schreiber@EcoWheels.com'    ,'Logistik'             ,'2016-04-01', 8    ,41 ,4  , 70), -- Hamburg
('q.hoffmann@EcoWheels.com'     ,'Logistik'             ,'2016-10-01', 8    ,42 ,4  , 70), -- Hamburg
('r.kaiser@EcoWheels.com'       ,'KFZ-WH'               ,'2016-04-01', 8    ,43 ,4  , 71), -- Hamburg
('s.rose@EcoWheels.com'         ,'KFZ-WH'               ,'2016-07-01', 8    ,44 ,4  , 71), -- Hamburg
('t.vogel@EcoWheels.com'        ,'KFZ-WH'               ,'2016-10-01', 8    ,45 ,4  , 71), -- Hamburg
('e.beyer@EcoWheels.com'        ,'Social-Media'         ,'2018-04-01', 1    ,46 ,110, 110),-- Erfurt
('a.maier@EcoWheels.com'        ,'Akku-WH'              ,'2015-04-01', 4    ,47 ,110, 72), -- Erfurt
('b.huber@EcoWheels.com'        ,'Akku-WH'              ,'2017-04-01', 5    ,48 ,52 , 72), -- Berlin
('c.weber@EcoWheels.com'        ,'Akku-WH'              ,'2016-04-01', 6    ,49 ,151, 72), -- Frankfurt
('d.schneider@EcoWheels.com'    ,'Akku-WH'              ,'2019-04-01', 7    ,50 ,203, 72), -- München
('e.schulte@EcoWheels.com'      ,'Akku-WH'              ,'2016-04-01', 8    ,51 ,4  , 72); -- Hamburg

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
INTO TABLE LOCATIONS
FIELDS TERMINATED BY ',' LINES TERMINATED BY '\r\n'(PLZ, City, Street, Sammelpunkt);

-- Übersicht STANDORT:
-- 1  - 50  = Hamburg
-- 51 - 100 = Berlin
-- 101- 150 = Erfurt
-- 151- 200 = Frankfurt am Main
-- 201- 250 = München

-- STANDORTID für Lager:
-- Headquarter      = 110 (Erfurt)  46741, ERFURT, Kristiane-Benthin-Allee
-- Lager Erfurt     = 110           46741, ERFURT, Kristiane-Benthin-Allee
-- Lager Berlin     = 52            41800, BERLIN, Gabor-Wähner-Platz
-- Lager Frankfurt  = 151           71887, FRANKFURT AM MAIN, Friederike-Schüler-Straße
-- Lager München    = 203           36453, MÜNCHEN, Thomas-Kusch-Straße
-- Lager Hamburg    = 4             91227, HAMBURG, Friedemann-Schenk-Straße

-- Sammelplätze:
-- Erfurt	:  101,103,104,105,106,107,108,109,113,114,
-- Berlin	: 53,54,60,61,62,64,66,67,69,70
-- Frankfurt: 153,154,155,157,160,161,164,166,167,170
-- München	: 201,202,204,211,213,214,215,218,219,220,
-- Hamburg	: 1,2,6,8,9,14,16,17,19,22

-- --------------------------------------------------------

--
-- Daten für Tabelle Lager
--

insert into LAGER (LagerId, RegionId, StandortID)
values
(1, 5, 110),
(2, 4, 52 ),
(3, 3, 151),
(4, 2, 203),
(5, 1, 4  );

-- --------------------------------------------------------

--
-- Daten für Tabelle Roller
--
--! Achtung Roller haben eine Verknüpfung zu Lager!
--! daher bei LocationID nur werte die zu der Region passen

-- --------------------------------------------------------

--
-- Daten für Tabelle Kunde
-- Import erfolgt über Bulk Import
-- beim ausführen des Befehls Pfad anpassen!

LOAD DATA INFILE 'kunden.csv' 
INTO TABLE LOCATIONS
FIELDS TERMINATED BY ',' LINES TERMINATED BY '\r\n'(Nachname, Vorname, EmailAdress, Mobilnummer, Geschlecht, LetzeNutzung, Inaktiv, KKontoID, WohnortID);
--! wenn Import funktioniert noch ändern, dass niemand in einem Lager wohnt zum Beispiel!

-- --------------------------------------------------------
