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

insert into departments values
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

insert into region values
(1, 'NORTH'),
(2, 'SOUTH'),
(3, 'EAST'),
(4, 'WEST'),
(5, 'MIDDLE');

-- --------------------------------------------------------

--
-- Daten für Tabelle Privatinfo
--

insert into privateinfo (FirstName, LastName, Mobilnummer, EmailPrivate, WohnortID) 
values
('ALEXANDER' ,'SCHMIDT' ,'017612345678','a.schmidt@gmail.com'),
('BENJAMIN' ,'MAYER' ,'017623456789','b.mayer@gmail.com'),
('CHRISTOPHER' ,'BAUER' ,'017634567890','c.bauer@googlemail.com'),
('DANIEL' ,'KELLER' ,'017645678901','d.keller@googlemail.com'),
('ERIC' ,'VOGEL' ,'017656789012','e.vogel@googlemail.com'),
('FLORIAN' ,'BECKER' ,'017667890123','f.becker@googlemail.com'),
('GABRIEL' ,'MÜLLER' ,'017678901234','g.mueller@googlemail.com'),
('HENRY' ,'SCHMITT' ,'017689012345','h.schmitt@gmail.com'),
('IVAN' ,'WAGNER' ,'017600123456','i.wagner@gmail.com'),
('JONAS' ,'HOFMANN' ,'017611234567','j.hofmann@googlemail.com'),
('KAI' ,'KRAUSE' ,'017622345678','k.krause@googlemail.com'),
('LUKAS' ,'SCHULZ' ,'017633456789','l.schulz@googlemail.com'),
('MAXIMILIAN' ,'FRANZ' ,'017644567890','m.franz@googlemail.com'),
('NICO' ,'BAUMANN' ,'017655678901','n.baumann@googlemail.com'),
('OLIVER' ,'MAIER' ,'017666789012','o.maier@googlemail.com'),
('PATRICK' ,'OTT' ,'017677890123','p.ott@gmail.com'),
('QUENTIN' ,'BERGER' ,'017688901234','q.berger@gmail.com'),
('RICHARD' ,'KÜHN' ,'017699012345','r.kuehn@gmail.com'),
('SEBASTIAN' ,'SCHNEIDER' ,'017610123456','s.schneider@gmail.com'),
('TIMO' ,'GROß' ,'017621234567','t.gross@googlemail.com'),
('UWE' ,'FRANK' ,'017632345678','u.frank@googlemail.com'),
('VIKTOR' ,'WOLF' ,'017643456789','v.wolf@gmail.com'),
('WILHELM' ,'SCHWARZ' ,'017654567890','w.schwarz@gmail.com'),
('XAVER' ,'BAUER' ,'017665678901','x.bauer@gmail.com'),
('YANNICK' ,'KOCH' ,'017676789012','y.koch@gmail.com'),
('ANNA' ,'SCHULZ' ,'017687654321','a.schulz@gmail.com'),
('BIANCA' ,'KOCH' ,'017676543210','b.koch@gmail.com'),
('CAROLINA' ,'WEISS' ,'017665432109','c.weiss@gmail.com'),
('DENISE' ,'LANG' ,'017654321098','d.lang@gmail.com'),
('EMILY' ,'ROTH' ,'017643210987','e.roth@googlemail.com'),
('FRANZISKA' ,'KAUFMANN' ,'017632109876','f.kaufmann@googlemail.com'),
('GISELA' ,'MAYER' ,'017621098765','g.mayer@googlemail.com'),
('HANNAH' ,'SCHÄFER' ,'017610987654','h.schaefer@googlemail.com'),
('ISABEL' ,'BAUER' ,'017699876543','i.bauer@googlemail.com'),
('JULIA' ,'KRÜGER' ,'017688765432','j.krueger@gmail.com'),
('KATHARINA' ,'FRANK' ,'017677654321','k.frank@gmail.com'),
('LENA' ,'RAUCH' ,'017666543210','l.rauch@gmail.com'),
('MARIE' ,'MEIER' ,'017655432109','m.meier@gmail.com'),
('NADINE' ,'SCHMIDT' ,'017644321098','n.schmidt@gmail.com'),
('OLIVIA' ,'WEISE' ,'017633210987','o.weise@gmail.com'),
('PAULA' ,'SCHREIBER' ,'017622109876','p.schreiber@gmail.com'),
('QUEENIE' ,'HOFFMANN' ,'017611098765','q.hoffmann@googlemail.com'),
('REBEKKA' ,'KAISER' ,'017600987654','r.kaiser@gmail.com'),
('SOPHIA' ,'ROSE' ,'017589876543','s.rose@gmail.com'),
('TINA' ,'VOGEL' ,'017578765432','t.vogel@gmail.com'),
('EMILIAN' ,'BEYER' ,'017652622457','e.beyer@gmail.com'),
('ALEXANDER' ,'MAIER' ,'017567654321','a.maier@gmail.com'),
('BENJAMIN' ,'HUBER' ,'017556543210','b.huber@googlemail.com'),
('CHRISTIAN' ,'WEBER' ,'017545432109','c.weber@googlemail.com'),
('DAVID' ,'SCHNEIDER' ,'017534321098','d.schneider@googlemail.com'),
('ERIK' ,'SCHULTE' ,'017523210987','e.schulte@googlemail.com');

-- Wohnort ID fehlt noch, weil noch keine Location Tabelle implementiert ist!
