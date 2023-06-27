-- phpMyAdmin SQL Dump
-- version 5.2.0
-- https://www.phpmyadmin.net/
--
-- Host: 127.0.0.1
-- Erstellungszeit: 27. Jun 2023 um 14:15
-- Server-Version: 10.4.24-MariaDB
-- PHP-Version: 8.1.6

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

-- --------------------------------------------------------

--
-- Tabellenstruktur für Tabelle `abteilung`
--

DROP TABLE IF EXISTS `abteilung`;
CREATE TABLE `abteilung` (
  `AbteilungID` int(11) NOT NULL,
  `AbteilungName` varchar(30) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

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

DROP TABLE IF EXISTS `bestellung_eroller`;
CREATE TABLE `bestellung_eroller` (
  `BestellERID` int(11) NOT NULL,
  `Nutzdauer` time NOT NULL,
  `StartPunktID` int(11) NOT NULL,
  `EndPunktID` int(11) NOT NULL,
  `GesamtFahrstecke` int(11) NOT NULL,
  `KundeID` int(11) NOT NULL,
  `ERollerID` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- --------------------------------------------------------

--
-- Tabellenstruktur für Tabelle `defekt`
--

DROP TABLE IF EXISTS `defekt`;
CREATE TABLE `defekt` (
  `DefektID` int(11) NOT NULL,
  `Defekts` varchar(250) NOT NULL,
  `ERollerID` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- --------------------------------------------------------

--
-- Tabellenstruktur für Tabelle `einzelteile`
--

DROP TABLE IF EXISTS `einzelteile`;
CREATE TABLE `einzelteile` (
  `EinzelteileID` int(11) NOT NULL,
  `EType` varchar(50) NOT NULL,
  `EName` int(11) NOT NULL,
  `Gewicht` decimal(8,2) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- --------------------------------------------------------

--
-- Tabellenstruktur für Tabelle `eroller`
--

DROP TABLE IF EXISTS `eroller`;
CREATE TABLE `eroller` (
  `ERollerID` int(11) NOT NULL,
  `LetzteWartung` date NOT NULL,
  `NaechsteWartung` date NOT NULL,
  `IstDefekt` tinyint(1) NOT NULL,
  `Batterie` int(11) NOT NULL,
  `StandortID` int(11) NOT NULL,
  `LagerID` int(11) NOT NULL,
  `HaltepunktID` int(11) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- --------------------------------------------------------

--
-- Tabellenstruktur für Tabelle `fahrtenbuch`
--

DROP TABLE IF EXISTS `fahrtenbuch`;
CREATE TABLE `fahrtenbuch` (
  `FahrtenbuchID` int(11) NOT NULL,
  `Fahrtstart` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  `Fahrtende` timestamp NOT NULL DEFAULT '0000-00-00 00:00:00',
  `Fahrtdauer` timestamp NOT NULL DEFAULT '0000-00-00 00:00:00',
  `FirmenwagenID` int(11) NOT NULL,
  `MitarbeiterID` int(11) NOT NULL,
  `RollerEingesamelt` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- --------------------------------------------------------

--
-- Tabellenstruktur für Tabelle `fuhrpark`
--

DROP TABLE IF EXISTS `fuhrpark`;
CREATE TABLE `fuhrpark` (
  `FirmenwagenID` int(11) NOT NULL,
  `AutoType` varchar(50) NOT NULL,
  `NächsteWartung` date NOT NULL,
  `LagerID` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- --------------------------------------------------------

--
-- Tabellenstruktur für Tabelle `haltepunkt`
--

DROP TABLE IF EXISTS `haltepunkt`;
CREATE TABLE `haltepunkt` (
  `HaltepunktID` int(11) NOT NULL,
  `Zeitpunkt` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  `FahrtenbuchID` int(11) NOT NULL,
  `StandortID` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- --------------------------------------------------------

--
-- Tabellenstruktur für Tabelle `kunde`
--

DROP TABLE IF EXISTS `kunde`;
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
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

--
-- Daten für Tabelle `kunde`
--

INSERT INTO `kunde` (`KundeID`, `Nachname`, `Vorname`, `EmailAdress`, `Mobilnummer`, `Geschlecht`, `LetzteNutzung`, `Inaktiv`, `KKontoID`, `WohnortID`) VALUES
(1534, 'Patterson', 'Eric', 'eric.patterson@gmail.com', '0123456789580', 'M', '2022-07-07', 0, 1, 237),
(1535, 'Clayton', 'Jeremy', 'jeremy.clayton@gmail.com', '0123456789861', 'M', '2020-07-22', 0, 2, 605),
(1536, 'Perkins', 'Christina', 'christina.perkins@gmail.com', '0123456789320', 'W', '2018-03-31', 1, 3, 774),
(1537, 'Benton', 'Sharon', 'sharon.benton@gmail.com', '0123456789317', 'W', '2023-06-10', 0, 4, 744),
(1538, 'Steele', 'Crystal', 'crystal.steele@gmail.com', '0123456789659', 'W', '2022-12-31', 0, 5, 200),
(1539, 'Smith', 'Tina', 'tina.smith@gmail.com', '0123456789681', 'W', '2022-07-31', 0, 6, 237),
(1540, 'Richard', 'Harold', 'harold.richard@gmail.com', '0123456789298', 'M', '2022-11-22', 0, 7, 866),
(1541, 'Reyes', 'Nicholas', 'nicholas.reyes@gmail.com', '0123456789875', 'M', '2021-07-09', 0, 8, 1043),
(1542, 'Young', 'Nicole', 'nicole.young@gmail.com', '0123456789551', 'W', '2023-03-22', 0, 9, 494),
(1543, 'Ward', 'Dylan', 'dylan.ward@gmail.com', '0123456789831', 'M', '2019-07-08', 1, 10, 642),
(1544, 'Hunt', 'Christina', 'christina.hunt@gmail.com', '0123456789418', 'W', '2022-06-29', 0, 11, 368),
(1545, 'Dean', 'Joshua', 'joshua.dean@gmail.com', '0123456789257', 'M', '2021-10-24', 0, 12, 592),
(1546, 'Sherman', 'Eric', 'eric.sherman@gmail.com', '0123456789114', 'M', '2020-10-28', 0, 13, 322),
(1547, 'Diaz', 'Cory', 'cory.diaz@gmail.com', '0123456789236', 'M', '2020-02-28', 1, 14, 645),
(1548, 'Davis', 'Douglas', 'douglas.davis@gmail.com', '0123456789250', 'M', '2023-01-26', 0, 15, 1070),
(1549, 'Bell', 'April', 'april.bell@gmail.com', '0123456789530', 'W', '2019-09-15', 1, 16, 1008),
(1550, 'Schmidt', 'Jason', 'jason.schmidt@gmail.com', '0123456789910', 'M', '2023-05-26', 0, 17, 149),
(1551, 'Cox', 'Corey', 'corey.cox@gmail.com', '0123456789680', 'M', '2019-03-22', 1, 18, 760),
(1552, 'Nicholson', 'Christopher', 'christopher.nicholson@gmail.com', '0123456789552', 'M', '2021-03-22', 0, 19, 373),
(1553, 'Jordan', 'Javier', 'javier.jordan@gmail.com', '0123456789884', 'M', '2019-11-01', 1, 20, 1000),
(1554, 'Williams', 'Stacey', 'stacey.williams@gmail.com', '0123456789379', 'W', '2023-05-01', 0, 21, 556),
(1555, 'Mosley', 'Mary', 'mary.mosley@gmail.com', '0123456789485', 'W', '2021-04-13', 0, 22, 817),
(1556, 'Bennett', 'James', 'james.bennett@gmail.com', '0123456789448', 'M', '2018-01-28', 1, 23, 620),
(1557, 'Dickson', 'Robert', 'robert.dickson@gmail.com', '0123456789883', 'M', '2021-11-20', 0, 24, 486),
(1558, 'Lindsey', 'Morgan', 'morgan.lindsey@gmail.com', '0123456789291', 'W', '2022-01-27', 0, 25, 772),
(1559, 'Sullivan', 'Jeffrey', 'jeffrey.sullivan@gmail.com', '0123456789712', 'M', '2021-02-07', 0, 26, 669),
(1560, 'Stephens', 'Kimberly', 'kimberly.stephens@gmail.com', '0123456789818', 'W', '2023-01-03', 0, 27, 732),
(1561, 'Brown', 'Amy', 'amy.brown@gmail.com', '0123456789431', 'W', '2019-05-10', 1, 28, 907),
(1562, 'Sanders', 'Jeffrey', 'jeffrey.sanders@gmail.com', '0123456789405', 'M', '2019-11-30', 1, 29, 1189),
(1563, 'Johnston', 'Michael', 'michael.johnston@gmail.com', '0123456789728', 'M', '2020-07-31', 0, 30, 1155),
(1564, 'Freeman', 'Jessica', 'jessica.freeman@gmail.com', '0123456789984', 'W', '2020-07-05', 0, 31, 810),
(1565, 'Perez', 'Christine', 'christine.perez@gmail.com', '0123456789158', 'W', '2019-04-17', 1, 32, 1139),
(1566, 'Little', 'Amber', 'amber.little@gmail.com', '0123456789227', 'W', '2018-04-15', 1, 33, 1152),
(1567, 'Hamilton', 'Brittany', 'brittany.hamilton@gmail.com', '0123456789882', 'W', '2019-03-24', 1, 34, 198),
(1568, 'Evans', 'Mark', 'mark.evans@gmail.com', '0123456789390', 'M', '2018-06-13', 1, 35, 717),
(1569, 'Davis', 'Kathleen', 'kathleen.davis@gmail.com', '0123456789629', 'W', '2021-02-25', 0, 36, 222),
(1570, 'Harper', 'Shawn', 'shawn.harper@gmail.com', '0123456789603', 'M', '2020-01-25', 1, 37, 306),
(1571, 'Walker', 'Kimberly', 'kimberly.walker@gmail.com', '0123456789259', 'W', '2023-06-26', 0, 38, 236),
(1572, 'Todd', 'Janet', 'janet.todd@gmail.com', '0123456789955', 'W', '2020-12-30', 0, 39, 1095),
(1573, 'Hicks', 'Michael', 'michael.hicks@gmail.com', '0123456789958', 'M', '2018-07-22', 1, 40, 706),
(1574, 'Blanchard', 'Kyle', 'kyle.blanchard@gmail.com', '0123456789289', 'M', '2020-04-01', 1, 41, 745),
(1575, 'Jackson', 'Edwin', 'edwin.jackson@gmail.com', '0123456789344', 'M', '2020-07-24', 0, 42, 517),
(1576, 'Ward', 'Jose', 'jose.ward@gmail.com', '0123456789396', 'M', '2019-11-27', 1, 43, 679),
(1577, 'Gonzalez', 'Suzanne', 'suzanne.gonzalez@gmail.com', '0123456789531', 'W', '2022-01-23', 0, 44, 21),
(1578, 'Wilson', 'Kristen', 'kristen.wilson@gmail.com', '0123456789612', 'W', '2019-05-30', 1, 45, 800),
(1579, 'Miranda', 'Susan', 'susan.miranda@gmail.com', '0123456789352', 'W', '2019-08-01', 1, 46, 868),
(1580, 'Kidd', 'Matthew', 'matthew.kidd@gmail.com', '0123456789385', 'M', '2021-02-16', 0, 47, 343),
(1581, 'Hamilton', 'Melissa', 'melissa.hamilton@gmail.com', '0123456789615', 'W', '2021-05-25', 0, 48, 931),
(1582, 'Gibson', 'Jerry', 'jerry.gibson@gmail.com', '0123456789184', 'M', '2019-04-14', 1, 49, 889),
(1583, 'Graham', 'Betty', 'betty.graham@gmail.com', '0123456789717', 'W', '2018-03-30', 1, 50, 682),
(1584, 'Jones', 'Audrey', 'audrey.jones@gmail.com', '0123456789138', 'W', '2018-09-21', 1, 51, 756),
(1585, 'Garza', 'Michael', 'michael.garza@gmail.com', '0123456789568', 'M', '2022-04-08', 0, 52, 903),
(1586, 'Butler', 'Jeremy', 'jeremy.butler@gmail.com', '0123456789205', 'M', '2018-01-27', 1, 53, 140),
(1587, 'Reyes', 'John', 'john.reyes@gmail.com', '0123456789338', 'M', '2019-01-13', 1, 54, 222),
(1588, 'Warren', 'Jeffery', 'jeffery.warren@gmail.com', '0123456789929', 'M', '2018-05-14', 1, 55, 583),
(1589, 'Whitney', 'Bradley', 'bradley.whitney@gmail.com', '0123456789102', 'M', '2018-01-21', 1, 56, 606),
(1590, 'Simmons', 'Paul', 'paul.simmons@gmail.com', '0123456789149', 'M', '2021-11-13', 0, 57, 852),
(1591, 'Gates', 'Stephanie', 'stephanie.gates@gmail.com', '0123456789692', 'W', '2020-11-27', 0, 58, 563),
(1592, 'Hahn', 'Anna', 'anna.hahn@gmail.com', '0123456789733', 'W', '2022-03-31', 0, 59, 898),
(1593, 'Hill', 'Margaret', 'margaret.hill@gmail.com', '0123456789979', 'W', '2018-06-22', 1, 60, 550),
(1594, 'Marshall', 'Lisa', 'lisa.marshall@gmail.com', '0123456789466', 'W', '2022-02-21', 0, 61, 904),
(1595, 'Gonzales', 'Brandon', 'brandon.gonzales@gmail.com', '0123456789275', 'M', '2019-04-18', 1, 62, 301),
(1596, 'Brown', 'Richard', 'richard.brown@gmail.com', '0123456789528', 'M', '2020-03-06', 1, 63, 713),
(1597, 'Parker', 'Robert', 'robert.parker@gmail.com', '0123456789545', 'M', '2020-11-13', 0, 64, 984),
(1598, 'Wall', 'Daniel', 'daniel.wall@gmail.com', '0123456789869', 'M', '2019-06-12', 1, 65, 484),
(1599, 'Velez', 'Jacob', 'jacob.velez@gmail.com', '0123456789626', 'M', '2019-07-07', 1, 66, 849),
(1600, 'Parker', 'Christopher', 'christopher.parker@gmail.com', '0123456789315', 'M', '2022-02-20', 0, 67, 64),
(1601, 'Ramos', 'Eric', 'eric.ramos@gmail.com', '0123456789790', 'M', '2022-07-16', 0, 68, 818),
(1602, 'Kelly', 'Michele', 'michele.kelly@gmail.com', '0123456789312', 'W', '2020-11-04', 0, 69, 744),
(1603, 'Harrison', 'Nicole', 'nicole.harrison@gmail.com', '0123456789917', 'W', '2021-08-09', 0, 70, 912),
(1604, 'Graham', 'Shawna', 'shawna.graham@gmail.com', '0123456789447', 'W', '2023-04-30', 0, 71, 864),
(1605, 'Rodgers', 'Lisa', 'lisa.rodgers@gmail.com', '0123456789653', 'W', '2023-04-08', 0, 72, 772),
(1606, 'Duran', 'Brenda', 'brenda.duran@gmail.com', '0123456789697', 'W', '2018-11-20', 1, 73, 992),
(1607, 'Silva', 'Mary', 'mary.silva@gmail.com', '0123456789478', 'W', '2021-11-08', 0, 74, 416),
(1608, 'Trevino', 'Mary', 'mary.trevino@gmail.com', '0123456789300', 'W', '2020-07-14', 0, 75, 509),
(1609, 'Bell', 'Joseph', 'joseph.bell@gmail.com', '0123456789822', 'M', '2018-08-08', 1, 76, 469),
(1610, 'Kidd', 'Jason', 'jason.kidd@gmail.com', '0123456789347', 'M', '2019-09-21', 1, 77, 1047),
(1611, 'Baldwin', 'Lori', 'lori.baldwin@gmail.com', '0123456789750', 'W', '2022-01-12', 0, 78, 964),
(1612, 'Everett', 'John', 'john.everett@gmail.com', '0123456789525', 'M', '2019-02-02', 1, 79, 729),
(1613, 'Allen', 'Kevin', 'kevin.allen@gmail.com', '0123456789649', 'M', '2019-09-07', 1, 80, 719),
(1614, 'Dudley', 'Gina', 'gina.dudley@gmail.com', '0123456789880', 'W', '2019-06-02', 1, 81, 574),
(1615, 'Tate', 'Christopher', 'christopher.tate@gmail.com', '0123456789691', 'M', '2019-07-31', 1, 82, 1013),
(1616, 'Black', 'Joseph', 'joseph.black@gmail.com', '0123456789780', 'M', '2018-12-24', 1, 83, 441),
(1617, 'Hubbard', 'Sarah', 'sarah.hubbard@gmail.com', '0123456789173', 'W', '2020-02-01', 1, 84, 856),
(1618, 'Ward', 'Steve', 'steve.ward@gmail.com', '0123456789331', 'M', '2019-08-31', 1, 85, 140),
(1619, 'Oneill', 'Andrew', 'andrew.oneill@gmail.com', '0123456789444', 'M', '2018-07-23', 1, 86, 754),
(1620, 'Miles', 'Jason', 'jason.miles@gmail.com', '0123456789345', 'M', '2019-02-20', 1, 87, 286),
(1621, 'Mcdonald', 'Matthew', 'matthew.mcdonald@gmail.com', '0123456789356', 'M', '2019-10-15', 1, 88, 150),
(1622, 'Shelton', 'Travis', 'travis.shelton@gmail.com', '0123456789821', 'M', '2019-12-09', 1, 89, 855),
(1623, 'Doyle', 'Jacob', 'jacob.doyle@gmail.com', '0123456789144', 'M', '2022-01-17', 0, 90, 548),
(1624, 'Arnold', 'Yolanda', 'yolanda.arnold@gmail.com', '0123456789826', 'W', '2018-10-02', 1, 91, 1217),
(1625, 'Phillips', 'Anna', 'anna.phillips@gmail.com', '0123456789350', 'W', '2020-04-21', 1, 92, 955),
(1626, 'Carrillo', 'Cathy', 'cathy.carrillo@gmail.com', '0123456789147', 'W', '2020-04-28', 1, 93, 655),
(1627, 'Jacobson', 'Christian', 'christian.jacobson@gmail.com', '0123456789916', 'M', '2018-12-30', 1, 94, 70),
(1628, 'Caldwell', 'Jane', 'jane.caldwell@gmail.com', '0123456789318', 'W', '2019-07-04', 1, 95, 1051),
(1629, 'Petty', 'Curtis', 'curtis.petty@gmail.com', '0123456789602', 'M', '2019-08-26', 1, 96, 771),
(1630, 'Rodriguez', 'Jonathan', 'jonathan.rodriguez@gmail.com', '0123456789623', 'M', '2020-09-10', 0, 97, 785),
(1631, 'Leon', 'Jesus', 'jesus.leon@gmail.com', '0123456789566', 'M', '2018-02-09', 1, 98, 603),
(1632, 'Mcclure', 'Randall', 'randall.mcclure@gmail.com', '0123456789878', 'M', '2023-04-29', 0, 99, 1204),
(1633, 'Wilson', 'Vicki', 'vicki.wilson@gmail.com', '0123456789282', 'W', '2021-04-14', 0, 100, 950),
(1634, 'Anderson', 'Craig', 'craig.anderson@gmail.com', '0123456789437', 'M', '2022-10-27', 0, 101, 214),
(1635, 'Patterson', 'Linda', 'linda.patterson@gmail.com', '0123456789641', 'W', '2020-01-26', 1, 102, 13),
(1636, 'Doyle', 'Ashley', 'ashley.doyle@gmail.com', '0123456789239', 'W', '2022-03-13', 0, 103, 1035),
(1637, 'Gonzalez', 'Shannon', 'shannon.gonzalez@gmail.com', '0123456789506', 'M', '2019-02-27', 1, 104, 935),
(1638, 'Davis', 'Jaclyn', 'jaclyn.davis@gmail.com', '0123456789906', 'W', '2018-04-06', 1, 105, 708),
(1639, 'Matthews', 'Jessica', 'jessica.matthews@gmail.com', '0123456789581', 'W', '2022-09-07', 0, 106, 1056),
(1640, 'Mathews', 'Patrick', 'patrick.mathews@gmail.com', '0123456789489', 'M', '2021-05-26', 0, 107, 1235),
(1641, 'Mason', 'Patrick', 'patrick.mason@gmail.com', '0123456789170', 'M', '2022-09-09', 0, 108, 1029),
(1642, 'Curtis', 'Michael', 'michael.curtis@gmail.com', '0123456789886', 'M', '2021-02-11', 0, 109, 885),
(1643, 'Pierce', 'Mark', 'mark.pierce@gmail.com', '0123456789246', 'M', '2019-02-05', 1, 110, 399),
(1644, 'Villegas', 'Julie', 'julie.villegas@gmail.com', '0123456789177', 'W', '2019-01-27', 1, 111, 182),
(1645, 'Reid', 'Thomas', 'thomas.reid@gmail.com', '0123456789107', 'M', '2020-12-21', 0, 112, 480),
(1646, 'George', 'Alexandria', 'alexandria.george@gmail.com', '0123456789986', 'W', '2022-02-09', 0, 113, 608),
(1647, 'Hill', 'Eileen', 'eileen.hill@gmail.com', '0123456789559', 'W', '2020-10-02', 0, 114, 717),
(1648, 'Cantrell', 'Julie', 'julie.cantrell@gmail.com', '0123456789838', 'W', '2020-12-18', 0, 115, 876),
(1649, 'Ritter', 'Aaron', 'aaron.ritter@gmail.com', '0123456789139', 'M', '2020-08-14', 0, 116, 1102),
(1650, 'Knight', 'Joseph', 'joseph.knight@gmail.com', '0123456789970', 'M', '2022-01-19', 0, 117, 762),
(1651, 'Smith', 'Brittany', 'brittany.smith@gmail.com', '0123456789493', 'W', '2022-06-28', 0, 118, 999),
(1652, 'Robinson', 'Christina', 'christina.robinson@gmail.com', '0123456789723', 'W', '2019-04-04', 1, 119, 1214),
(1653, 'Lawson', 'Victoria', 'victoria.lawson@gmail.com', '0123456789819', 'W', '2023-06-27', 0, 120, 794),
(1654, 'Cisneros', 'Gregory', 'gregory.cisneros@gmail.com', '0123456789849', 'M', '2019-01-15', 1, 121, 363),
(1655, 'Ray', 'Barbara', 'barbara.ray@gmail.com', '0123456789143', 'W', '2018-06-06', 1, 122, 1191),
(1656, 'Nguyen', 'Tammy', 'tammy.nguyen@gmail.com', '0123456789561', 'W', '2021-11-27', 0, 123, 821),
(1657, 'English', 'Mariah', 'mariah.english@gmail.com', '0123456789171', 'W', '2020-12-23', 0, 124, 436),
(1658, 'Pham', 'Justin', 'justin.pham@gmail.com', '0123456789265', 'M', '2021-06-18', 0, 125, 221),
(1659, 'Brown', 'Kurt', 'kurt.brown@gmail.com', '0123456789852', 'M', '2022-05-06', 0, 126, 698),
(1660, 'Goodman', 'Jason', 'jason.goodman@gmail.com', '0123456789355', 'M', '2019-06-12', 1, 127, 880),
(1661, 'Brock', 'Samantha', 'samantha.brock@gmail.com', '0123456789669', 'W', '2022-08-23', 0, 128, 695),
(1662, 'Parker', 'Andrew', 'andrew.parker@gmail.com', '0123456789460', 'M', '2019-01-07', 1, 129, 405),
(1663, 'Benjamin', 'Jeremy', 'jeremy.benjamin@gmail.com', '0123456789665', 'M', '2021-12-14', 0, 130, 1155),
(1664, 'Oconnor', 'Jose', 'jose.oconnor@gmail.com', '0123456789633', 'M', '2021-12-26', 0, 131, 432),
(1665, 'Martinez', 'Mason', 'mason.martinez@gmail.com', '0123456789455', 'M', '2021-02-19', 0, 132, 1177),
(1666, 'Lane', 'Brenda', 'brenda.lane@gmail.com', '0123456789527', 'W', '2020-08-05', 0, 133, 992),
(1667, 'Simpson', 'Mark', 'mark.simpson@gmail.com', '0123456789809', 'M', '2019-08-06', 1, 134, 537),
(1668, 'Miller', 'Laura', 'laura.miller@gmail.com', '0123456789749', 'W', '2019-10-10', 1, 135, 659),
(1669, 'Alvarado', 'Kenneth', 'kenneth.alvarado@gmail.com', '0123456789798', 'M', '2018-09-10', 1, 136, 592),
(1670, 'Hill', 'Jacob', 'jacob.hill@gmail.com', '0123456789499', 'M', '2022-07-21', 0, 137, 823),
(1671, 'Lin', 'Alexander', 'alexander.lin@gmail.com', '0123456789911', 'M', '2018-05-13', 1, 138, 1022),
(1672, 'Morris', 'Courtney', 'courtney.morris@gmail.com', '0123456789229', 'W', '2019-02-01', 1, 139, 392),
(1673, 'Sanchez', 'Cory', 'cory.sanchez@gmail.com', '0123456789134', 'M', '2023-02-17', 0, 140, 112),
(1674, 'Greene', 'Dustin', 'dustin.greene@gmail.com', '0123456789242', 'M', '2019-06-23', 1, 141, 531),
(1675, 'Taylor', 'James', 'james.taylor@gmail.com', '0123456789590', 'M', '2021-05-22', 0, 142, 192),
(1676, 'Harrell', 'Thomas', 'thomas.harrell@gmail.com', '0123456789688', 'M', '2020-09-06', 0, 143, 487),
(1677, 'Rowe', 'Alexandra', 'alexandra.rowe@gmail.com', '0123456789745', 'W', '2018-04-18', 1, 144, 1175),
(1678, 'Henderson', 'Patricia', 'patricia.henderson@gmail.com', '0123456789468', 'W', '2018-07-25', 1, 145, 946),
(1679, 'Bailey', 'Lisa', 'lisa.bailey@gmail.com', '0123456789786', 'W', '2021-03-30', 0, 146, 1196),
(1680, 'Roberts', 'Adam', 'adam.roberts@gmail.com', '0123456789828', 'M', '2022-01-21', 0, 147, 1223),
(1681, 'Ortiz', 'Alexander', 'alexander.ortiz@gmail.com', '0123456789270', 'M', '2018-06-17', 1, 148, 1043),
(1682, 'Everett', 'Robert', 'robert.everett@gmail.com', '0123456789230', 'M', '2019-03-14', 1, 149, 464),
(1683, 'Mejia', 'Laura', 'laura.mejia@gmail.com', '0123456789293', 'W', '2019-03-18', 1, 150, 657),
(1684, 'Davis', 'Michael', 'michael.davis@gmail.com', '0123456789567', 'M', '2018-04-30', 1, 151, 897),
(1685, 'Butler', 'Elizabeth', 'elizabeth.butler@gmail.com', '0123456789895', 'W', '2019-08-04', 1, 152, 859),
(1686, 'Stone', 'Michelle', 'michelle.stone@gmail.com', '0123456789442', 'W', '2018-10-14', 1, 153, 902),
(1687, 'Waters', 'Nathan', 'nathan.waters@gmail.com', '0123456789877', 'M', '2018-09-26', 1, 154, 587),
(1688, 'Jackson', 'David', 'david.jackson@gmail.com', '0123456789744', 'M', '2018-09-01', 1, 155, 960),
(1689, 'Hunter', 'Jenny', 'jenny.hunter@gmail.com', '0123456789684', 'W', '2019-09-23', 1, 156, 910),
(1690, 'Keller', 'Melissa', 'melissa.keller@gmail.com', '0123456789424', 'W', '2021-12-29', 0, 157, 769),
(1691, 'Dillon', 'Willie', 'willie.dillon@gmail.com', '0123456789256', 'M', '2018-09-13', 1, 158, 785),
(1692, 'Curry', 'Tiffany', 'tiffany.curry@gmail.com', '0123456789732', 'W', '2018-02-04', 1, 159, 944),
(1693, 'Young', 'Christina', 'christina.young@gmail.com', '0123456789824', 'W', '2023-06-19', 0, 160, 859),
(1694, 'Arroyo', 'Deborah', 'deborah.arroyo@gmail.com', '0123456789608', 'W', '2019-09-10', 1, 161, 1009),
(1695, 'Lewis', 'Kenneth', 'kenneth.lewis@gmail.com', '0123456789994', 'M', '2019-07-17', 1, 162, 946),
(1696, 'Drake', 'Angelica', 'angelica.drake@gmail.com', '0123456789562', 'W', '2021-07-22', 0, 163, 837),
(1697, 'Craig', 'Wesley', 'wesley.craig@gmail.com', '0123456789865', 'M', '2022-08-24', 0, 164, 1004),
(1698, 'Sanchez', 'Melissa', 'melissa.sanchez@gmail.com', '0123456789971', 'W', '2020-06-23', 1, 165, 868),
(1699, 'Gonzalez', 'Richard', 'richard.gonzalez@gmail.com', '0123456789647', 'M', '2021-08-13', 0, 166, 441),
(1700, 'Parker', 'Bryan', 'bryan.parker@gmail.com', '0123456789508', 'M', '2020-11-30', 0, 167, 245),
(1701, 'Morgan', 'Rachel', 'rachel.morgan@gmail.com', '0123456789384', 'W', '2021-09-11', 0, 168, 478),
(1702, 'Patterson', 'Crystal', 'crystal.patterson@gmail.com', '0123456789267', 'W', '2018-04-02', 1, 169, 417),
(1703, 'Pierce', 'Angela', 'angela.pierce@gmail.com', '0123456789991', 'W', '2021-08-01', 0, 170, 1049),
(1704, 'Morrison', 'Daniel', 'daniel.morrison@gmail.com', '0123456789872', 'M', '2023-06-08', 0, 171, 654),
(1705, 'Meyer', 'William', 'william.meyer@gmail.com', '0123456789656', 'M', '2019-05-17', 1, 172, 458),
(1706, 'Williams', 'Brianna', 'brianna.williams@gmail.com', '0123456789445', 'W', '2022-02-13', 0, 173, 806),
(1707, 'Wright', 'Laurie', 'laurie.wright@gmail.com', '0123456789375', 'W', '2020-07-24', 0, 174, 811),
(1708, 'Daniels', 'Steven', 'steven.daniels@gmail.com', '0123456789123', 'M', '2020-07-12', 0, 175, 521),
(1709, 'Baxter', 'Colton', 'colton.baxter@gmail.com', '0123456789679', 'M', '2020-09-10', 0, 176, 309),
(1710, 'Parker', 'Charles', 'charles.parker@gmail.com', '0123456789879', 'M', '2021-06-28', 0, 177, 487),
(1711, 'Simmons', 'Autumn', 'autumn.simmons@gmail.com', '0123456789938', 'W', '2019-10-08', 1, 178, 146),
(1712, 'Solis', 'Randall', 'randall.solis@gmail.com', '0123456789885', 'M', '2018-07-26', 1, 179, 984),
(1713, 'Watkins', 'Carlos', 'carlos.watkins@gmail.com', '0123456789237', 'M', '2018-10-12', 1, 180, 845),
(1714, 'Taylor', 'Alex', 'alex.taylor@gmail.com', '0123456789791', 'M', '2021-09-03', 0, 181, 1085),
(1715, 'Brown', 'Christopher', 'christopher.brown@gmail.com', '0123456789430', 'M', '2021-05-05', 0, 182, 1026),
(1716, 'Harris', 'Mark', 'mark.harris@gmail.com', '0123456789367', 'M', '2021-07-15', 0, 183, 1218),
(1717, 'Murray', 'Nancy', 'nancy.murray@gmail.com', '0123456789595', 'W', '2023-04-12', 0, 184, 468),
(1718, 'Grimes', 'Carlos', 'carlos.grimes@gmail.com', '0123456789475', 'M', '2019-01-31', 1, 185, 86),
(1719, 'Lee', 'Maxwell', 'maxwell.lee@gmail.com', '0123456789735', 'M', '2021-09-09', 0, 186, 541),
(1720, 'Potter', 'April', 'april.potter@gmail.com', '0123456789959', 'W', '2021-09-20', 0, 187, 983),
(1721, 'Pham', 'David', 'david.pham@gmail.com', '0123456789782', 'M', '2019-11-17', 1, 188, 538),
(1722, 'Johnson', 'Eric', 'eric.johnson@gmail.com', '0123456789646', 'M', '2022-09-02', 0, 189, 1062),
(1723, 'Hernandez', 'Francisco', 'francisco.hernandez@gmail.com', '0123456789391', 'M', '2021-02-11', 0, 190, 198),
(1724, 'Gilbert', 'Kevin', 'kevin.gilbert@gmail.com', '0123456789446', 'M', '2018-02-17', 1, 191, 982),
(1725, 'Burke', 'Ashley', 'ashley.burke@gmail.com', '0123456789689', 'W', '2022-07-11', 0, 192, 126),
(1726, 'Todd', 'Lori', 'lori.todd@gmail.com', '0123456789360', 'W', '2023-05-31', 0, 193, 368),
(1727, 'Travis', 'Anita', 'anita.travis@gmail.com', '0123456789816', 'W', '2020-07-12', 0, 194, 1198),
(1728, 'Garcia', 'Robert', 'robert.garcia@gmail.com', '0123456789401', 'M', '2022-02-14', 0, 195, 674),
(1729, 'Cervantes', 'Mark', 'mark.cervantes@gmail.com', '0123456789351', 'M', '2018-10-04', 1, 196, 215),
(1730, 'Thompson', 'Hannah', 'hannah.thompson@gmail.com', '0123456789414', 'W', '2019-08-04', 1, 197, 548),
(1731, 'Wood', 'Vanessa', 'vanessa.wood@gmail.com', '0123456789743', 'W', '2021-06-01', 0, 198, 1121),
(1732, 'Gray', 'Heidi', 'heidi.gray@gmail.com', '0123456789135', 'W', '2023-01-20', 0, 199, 470),
(1733, 'Gomez', 'Gerald', 'gerald.gomez@gmail.com', '0123456789873', 'M', '2023-01-03', 0, 200, 1043),
(1734, 'Diaz', 'Lisa', 'lisa.diaz@gmail.com', '0123456789550', 'W', '2020-05-01', 1, 201, 986),
(1735, 'Mcdonald', 'Brandon', 'brandon.mcdonald@gmail.com', '0123456789443', 'M', '2020-01-12', 1, 202, 26),
(1736, 'Jacobson', 'Dorothy', 'dorothy.jacobson@gmail.com', '0123456789117', 'W', '2022-09-20', 0, 203, 1149),
(1737, 'Kidd', 'Wendy', 'wendy.kidd@gmail.com', '0123456789261', 'W', '2022-01-14', 0, 204, 112),
(1738, 'Owens', 'John', 'john.owens@gmail.com', '0123456789774', 'M', '2021-08-29', 0, 205, 1173),
(1739, 'Chen', 'Joshua', 'joshua.chen@gmail.com', '0123456789859', 'M', '2019-04-15', 1, 206, 322),
(1740, 'Andrews', 'Robert', 'robert.andrews@gmail.com', '0123456789904', 'M', '2023-03-03', 0, 207, 343),
(1741, 'Hoffman', 'Savannah', 'savannah.hoffman@gmail.com', '0123456789253', 'W', '2018-05-14', 1, 208, 92),
(1742, 'Howard', 'Robert', 'robert.howard@gmail.com', '0123456789201', 'M', '2022-04-23', 0, 209, 1157),
(1743, 'Marshall', 'Robin', 'robin.marshall@gmail.com', '0123456789604', 'M', '2022-09-18', 0, 210, 284),
(1744, 'Morgan', 'Terri', 'terri.morgan@gmail.com', '0123456789235', 'W', '2019-07-02', 1, 211, 144),
(1745, 'Martin', 'Paula', 'paula.martin@gmail.com', '0123456789365', 'W', '2019-06-15', 1, 212, 1078),
(1746, 'Mitchell', 'Stefanie', 'stefanie.mitchell@gmail.com', '0123456789783', 'W', '2019-04-03', 1, 213, 219),
(1747, 'Cox', 'Michael', 'michael.cox@gmail.com', '0123456789898', 'M', '2021-12-05', 0, 214, 50),
(1748, 'Miranda', 'Morgan', 'morgan.miranda@gmail.com', '0123456789456', 'W', '2021-12-30', 0, 215, 943),
(1749, 'Lynch', 'Jessica', 'jessica.lynch@gmail.com', '0123456789670', 'W', '2019-02-05', 1, 216, 603),
(1750, 'Lam', 'Nicole', 'nicole.lam@gmail.com', '0123456789913', 'W', '2018-02-16', 1, 217, 1011),
(1751, 'Grimes', 'Crystal', 'crystal.grimes@gmail.com', '0123456789276', 'W', '2018-12-28', 1, 218, 478),
(1752, 'Holt', 'Mike', 'mike.holt@gmail.com', '0123456789742', 'M', '2018-09-08', 1, 219, 1195),
(1753, 'Sanders', 'Chelsea', 'chelsea.sanders@gmail.com', '0123456789319', 'W', '2020-07-05', 0, 220, 188),
(1754, 'Johnston', 'Johnathan', 'johnathan.johnston@gmail.com', '0123456789570', 'M', '2018-06-19', 1, 221, 638),
(1755, 'Griffith', 'Becky', 'becky.griffith@gmail.com', '0123456789993', 'W', '2020-04-11', 1, 222, 723),
(1756, 'Mora', 'Douglas', 'douglas.mora@gmail.com', '0123456789501', 'M', '2023-06-21', 0, 223, 98),
(1757, 'Walker', 'George', 'george.walker@gmail.com', '0123456789121', 'M', '2021-02-28', 0, 224, 1085),
(1758, 'Salazar', 'Jennifer', 'jennifer.salazar@gmail.com', '0123456789847', 'W', '2019-12-21', 1, 225, 731),
(1759, 'Baker', 'Tara', 'tara.baker@gmail.com', '0123456789739', 'W', '2018-03-05', 1, 226, 114),
(1760, 'Wright', 'Anthony', 'anthony.wright@gmail.com', '0123456789332', 'M', '2022-11-16', 0, 227, 668),
(1761, 'Reed', 'Victoria', 'victoria.reed@gmail.com', '0123456789225', 'W', '2019-07-27', 1, 228, 678),
(1762, 'Levine', 'John', 'john.levine@gmail.com', '0123456789966', 'M', '2018-06-08', 1, 229, 687),
(1763, 'Morse', 'Andrew', 'andrew.morse@gmail.com', '0123456789359', 'M', '2019-04-30', 1, 230, 96),
(1764, 'Garner', 'Carol', 'carol.garner@gmail.com', '0123456789232', 'W', '2020-11-07', 0, 231, 1171),
(1765, 'White', 'Brian', 'brian.white@gmail.com', '0123456789307', 'M', '2019-02-23', 1, 232, 969),
(1766, 'Green', 'Adam', 'adam.green@gmail.com', '0123456789369', 'M', '2020-07-04', 0, 233, 836),
(1767, 'Powell', 'Sabrina', 'sabrina.powell@gmail.com', '0123456789214', 'W', '2019-08-30', 1, 234, 133),
(1768, 'Griffin', 'Thomas', 'thomas.griffin@gmail.com', '0123456789676', 'M', '2022-09-28', 0, 235, 812),
(1769, 'Berry', 'Patricia', 'patricia.berry@gmail.com', '0123456789583', 'W', '2022-01-20', 0, 236, 811),
(1770, 'Smith', 'Laura', 'laura.smith@gmail.com', '0123456789492', 'W', '2018-08-30', 1, 237, 1185),
(1771, 'Blackwell', 'Anthony', 'anthony.blackwell@gmail.com', '0123456789209', 'M', '2021-12-11', 0, 238, 1148),
(1772, 'Boyd', 'Samantha', 'samantha.boyd@gmail.com', '0123456789941', 'W', '2021-01-10', 0, 239, 622),
(1773, 'Mcdonald', 'Eric', 'eric.mcdonald@gmail.com', '0123456789486', 'M', '2018-07-22', 1, 240, 971),
(1774, 'Cooley', 'Richard', 'richard.cooley@gmail.com', '0123456789297', 'M', '2021-05-23', 0, 241, 801),
(1775, 'Bailey', 'Deborah', 'deborah.bailey@gmail.com', '0123456789975', 'W', '2020-04-14', 1, 242, 903),
(1776, 'Stanley', 'Shane', 'shane.stanley@gmail.com', '0123456789477', 'M', '2022-03-28', 0, 243, 1027),
(1777, 'Rodriguez', 'Leah', 'leah.rodriguez@gmail.com', '0123456789522', 'W', '2022-11-14', 0, 244, 351),
(1778, 'Edwards', 'Jacob', 'jacob.edwards@gmail.com', '0123456789850', 'M', '2019-10-05', 1, 245, 1234),
(1779, 'Meza', 'Daniel', 'daniel.meza@gmail.com', '0123456789856', 'M', '2018-10-26', 1, 246, 322),
(1780, 'Harris', 'Michael', 'michael.harris@gmail.com', '0123456789326', 'M', '2023-05-20', 0, 247, 930),
(1781, 'Willis', 'Michael', 'michael.willis@gmail.com', '0123456789106', 'M', '2023-04-11', 0, 248, 356),
(1782, 'Walker', 'Kathleen', 'kathleen.walker@gmail.com', '0123456789399', 'W', '2023-03-19', 0, 249, 319),
(1783, 'Munoz', 'Tiffany', 'tiffany.munoz@gmail.com', '0123456789963', 'W', '2019-11-03', 1, 250, 244),
(1784, 'Allen', 'Aaron', 'aaron.allen@gmail.com', '0123456789599', 'M', '2023-02-08', 0, 251, 71),
(1785, 'Campbell', 'Ernest', 'ernest.campbell@gmail.com', '0123456789272', 'M', '2022-11-05', 0, 252, 626),
(1786, 'Arnold', 'Michael', 'michael.arnold@gmail.com', '0123456789614', 'M', '2023-02-22', 0, 253, 882),
(1787, 'Wallace', 'Nicole', 'nicole.wallace@gmail.com', '0123456789240', 'W', '2020-10-26', 0, 254, 282),
(1788, 'Brady', 'Christopher', 'christopher.brady@gmail.com', '0123456789103', 'M', '2021-09-08', 0, 255, 313),
(1789, 'Newton', 'Kayla', 'kayla.newton@gmail.com', '0123456789893', 'W', '2019-07-05', 1, 256, 749),
(1790, 'Anderson', 'Lisa', 'lisa.anderson@gmail.com', '0123456789388', 'W', '2021-09-24', 0, 257, 713),
(1791, 'Williams', 'Daniel', 'daniel.williams@gmail.com', '0123456789719', 'M', '2021-02-09', 0, 258, 1122),
(1792, 'Haris', 'Michael', 'michael.haris@gmail.com', '0123456789373', 'M', '2022-08-25', 0, 259, 1204),
(1793, 'Perez', 'Brandon', 'brandon.perez@gmail.com', '0123456789403', 'M', '2018-09-23', 1, 260, 1217),
(1794, 'Rivas', 'Tara', 'tara.rivas@gmail.com', '0123456789512', 'W', '2020-11-08', 0, 261, 223),
(1795, 'Hernandez', 'Ashley', 'ashley.hernandez@gmail.com', '0123456789419', 'W', '2021-09-21', 0, 262, 280),
(1796, 'Collins', 'David', 'david.collins@gmail.com', '0123456789950', 'M', '2021-03-22', 0, 263, 150),
(1797, 'Russell', 'William', 'william.russell@gmail.com', '0123456789372', 'M', '2022-04-08', 0, 264, 641),
(1798, 'Vega', 'Jessica', 'jessica.vega@gmail.com', '0123456789480', 'W', '2019-06-17', 1, 265, 789),
(1799, 'Mason', 'Teresa', 'teresa.mason@gmail.com', '0123456789393', 'W', '2023-06-06', 0, 266, 218),
(1800, 'Mcgee', 'Matthew', 'matthew.mcgee@gmail.com', '0123456789560', 'M', '2021-11-26', 0, 267, 655),
(1801, 'Cook', 'Cheryl', 'cheryl.cook@gmail.com', '0123456789494', 'W', '2020-08-07', 0, 268, 1081),
(1802, 'Weeks', 'Matthew', 'matthew.weeks@gmail.com', '0123456789722', 'M', '2019-06-15', 1, 269, 839),
(1803, 'Ellison', 'Samantha', 'samantha.ellison@gmail.com', '0123456789458', 'W', '2019-08-14', 1, 270, 1025),
(1804, 'Randall', 'Anna', 'anna.randall@gmail.com', '0123456789685', 'W', '2018-10-03', 1, 271, 92),
(1805, 'Ramirez', 'Kyle', 'kyle.ramirez@gmail.com', '0123456789383', 'M', '2023-03-23', 0, 272, 905),
(1806, 'Serrano', 'Albert', 'albert.serrano@gmail.com', '0123456789736', 'M', '2022-04-11', 0, 273, 478),
(1807, 'Chavez', 'Tracey', 'tracey.chavez@gmail.com', '0123456789703', 'W', '2022-10-25', 0, 274, 573),
(1808, 'Wilson', 'Trevor', 'trevor.wilson@gmail.com', '0123456789469', 'M', '2019-10-31', 1, 275, 644),
(1809, 'Woods', 'Kenneth', 'kenneth.woods@gmail.com', '0123456789533', 'M', '2020-01-18', 1, 276, 976),
(1810, 'Gonzalez', 'Samantha', 'samantha.gonzalez@gmail.com', '0123456789195', 'W', '2020-07-12', 0, 277, 774),
(1811, 'Martinez', 'Jacob', 'jacob.martinez@gmail.com', '0123456789907', 'M', '2018-10-15', 1, 278, 97),
(1812, 'Price', 'Jade', 'jade.price@gmail.com', '0123456789325', 'W', '2022-09-26', 0, 279, 636),
(1813, 'Perez', 'Victoria', 'victoria.perez@gmail.com', '0123456789337', 'W', '2022-05-05', 0, 280, 226),
(1814, 'Hernandez', 'Kimberly', 'kimberly.hernandez@gmail.com', '0123456789924', 'W', '2020-04-18', 1, 281, 366),
(1815, 'Brooks', 'Melissa', 'melissa.brooks@gmail.com', '0123456789578', 'W', '2020-06-12', 1, 282, 647),
(1816, 'Garrett', 'Eric', 'eric.garrett@gmail.com', '0123456789843', 'M', '2018-08-04', 1, 283, 446),
(1817, 'Reilly', 'Joe', 'joe.reilly@gmail.com', '0123456789792', 'M', '2021-12-17', 0, 284, 1069),
(1818, 'Branch', 'Nicole', 'nicole.branch@gmail.com', '0123456789524', 'W', '2021-06-30', 0, 285, 1137),
(1819, 'Wong', 'Richard', 'richard.wong@gmail.com', '0123456789199', 'M', '2022-09-02', 0, 286, 792),
(1820, 'Bauer', 'Janet', 'janet.bauer@gmail.com', '0123456789707', 'W', '2022-01-13', 0, 287, 899),
(1821, 'Rodgers', 'Tammy', 'tammy.rodgers@gmail.com', '0123456789988', 'W', '2020-12-05', 0, 288, 607),
(1822, 'Sullivan', 'Stephanie', 'stephanie.sullivan@gmail.com', '0123456789421', 'W', '2022-06-02', 0, 289, 77),
(1823, 'Patterson', 'Heather', 'heather.patterson@gmail.com', '0123456789500', 'W', '2019-11-02', 1, 290, 286),
(1824, 'Sanders', 'Nicole', 'nicole.sanders@gmail.com', '0123456789800', 'W', '2021-08-26', 0, 291, 173),
(1825, 'Miranda', 'Brianna', 'brianna.miranda@gmail.com', '0123456789939', 'W', '2023-01-11', 0, 292, 371),
(1826, 'Shaw', 'Angelica', 'angelica.shaw@gmail.com', '0123456789905', 'W', '2020-02-02', 1, 293, 596),
(1827, 'Holt', 'Richard', 'richard.holt@gmail.com', '0123456789890', 'M', '2022-11-10', 0, 294, 1197),
(1828, 'Atkinson', 'Arthur', 'arthur.atkinson@gmail.com', '0123456789116', 'M', '2020-08-01', 0, 295, 1136),
(1829, 'Hernandez', 'Joseph', 'joseph.hernandez@gmail.com', '0123456789484', 'M', '2023-02-28', 0, 296, 581),
(1830, 'Johnson', 'Henry', 'henry.johnson@gmail.com', '0123456789252', 'M', '2019-07-02', 1, 297, 381),
(1831, 'Flores', 'Bailey', 'bailey.flores@gmail.com', '0123456789796', 'W', '2018-02-07', 1, 298, 1063),
(1832, 'Howell', 'Stephanie', 'stephanie.howell@gmail.com', '0123456789285', 'W', '2018-08-02', 1, 299, 113),
(1833, 'Mills', 'Sara', 'sara.mills@gmail.com', '0123456789273', 'W', '2019-02-20', 1, 300, 542);

-- --------------------------------------------------------

--
-- Tabellenstruktur für Tabelle `kundenkonto`
--

DROP TABLE IF EXISTS `kundenkonto`;
CREATE TABLE `kundenkonto` (
  `KKontoID` int(11) NOT NULL,
  `Guthaben` decimal(5,2) NOT NULL,
  `LetzteZahlung` date DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

--
-- Daten für Tabelle `kundenkonto`
--

INSERT INTO `kundenkonto` (`KKontoID`, `Guthaben`, `LetzteZahlung`) VALUES
(1, '22.58', NULL),
(2, '188.98', NULL),
(3, '610.86', NULL),
(4, '436.80', NULL),
(5, '300.78', NULL),
(6, '950.29', NULL),
(7, '616.04', NULL),
(8, '611.53', NULL),
(9, '296.08', NULL),
(10, '613.52', NULL),
(11, '123.32', NULL),
(12, '79.36', NULL),
(13, '758.64', NULL),
(14, '476.87', NULL),
(15, '244.58', NULL),
(16, '298.39', NULL),
(17, '543.55', NULL),
(18, '211.85', NULL),
(19, '923.78', NULL),
(20, '608.94', NULL),
(21, '327.35', NULL),
(22, '878.37', NULL),
(23, '198.56', NULL),
(24, '104.50', NULL),
(25, '430.23', NULL),
(26, '295.87', NULL),
(27, '749.74', NULL),
(28, '48.03', NULL),
(29, '45.77', NULL),
(30, '842.26', NULL),
(31, '467.43', NULL),
(32, '407.53', NULL),
(33, '102.36', NULL),
(34, '754.96', NULL),
(35, '355.37', NULL),
(36, '446.26', NULL),
(37, '923.54', NULL),
(38, '302.18', NULL),
(39, '152.83', NULL),
(40, '767.51', NULL),
(41, '115.68', NULL),
(42, '570.47', NULL),
(43, '364.34', NULL),
(44, '729.66', NULL),
(45, '72.50', NULL),
(46, '350.42', NULL),
(47, '640.65', NULL),
(48, '217.04', NULL),
(49, '972.27', NULL),
(50, '120.08', NULL),
(51, '240.62', NULL),
(52, '492.96', NULL),
(53, '868.91', NULL),
(54, '801.68', NULL),
(55, '362.74', NULL),
(56, '384.33', NULL),
(57, '465.75', NULL),
(58, '242.14', NULL),
(59, '288.92', NULL),
(60, '440.59', NULL),
(61, '837.71', NULL),
(62, '978.43', NULL),
(63, '450.44', NULL),
(64, '452.84', NULL),
(65, '115.78', NULL),
(66, '863.04', NULL),
(67, '865.52', NULL),
(68, '824.78', NULL),
(69, '270.75', NULL),
(70, '70.83', NULL),
(71, '114.22', NULL),
(72, '978.19', NULL),
(73, '427.85', NULL),
(74, '913.40', NULL),
(75, '204.92', NULL),
(76, '570.02', NULL),
(77, '28.50', NULL),
(78, '118.76', NULL),
(79, '175.46', NULL),
(80, '196.97', NULL),
(81, '852.54', NULL),
(82, '922.47', NULL),
(83, '562.77', NULL),
(84, '995.24', NULL),
(85, '632.15', NULL),
(86, '279.61', NULL),
(87, '642.46', NULL),
(88, '427.62', NULL),
(89, '333.43', NULL),
(90, '190.11', NULL),
(91, '41.04', NULL),
(92, '902.30', NULL),
(93, '597.27', NULL),
(94, '625.15', NULL),
(95, '580.17', NULL),
(96, '68.38', NULL),
(97, '210.83', NULL),
(98, '285.35', NULL),
(99, '104.63', NULL),
(100, '143.21', NULL),
(101, '802.20', NULL),
(102, '141.03', NULL),
(103, '359.78', NULL),
(104, '442.41', NULL),
(105, '353.48', NULL),
(106, '286.71', NULL),
(107, '0.68', NULL),
(108, '87.37', NULL),
(109, '159.47', NULL),
(110, '967.64', NULL),
(111, '583.20', NULL),
(112, '698.13', NULL),
(113, '149.57', NULL),
(114, '764.55', NULL),
(115, '868.55', NULL),
(116, '865.61', NULL),
(117, '311.01', NULL),
(118, '491.08', NULL),
(119, '707.27', NULL),
(120, '872.30', NULL),
(121, '994.45', NULL),
(122, '146.09', NULL),
(123, '591.66', NULL),
(124, '420.00', NULL),
(125, '255.29', NULL),
(126, '281.87', NULL),
(127, '22.72', NULL),
(128, '451.32', NULL),
(129, '415.79', NULL),
(130, '549.73', NULL),
(131, '639.47', NULL),
(132, '486.43', NULL),
(133, '689.89', NULL),
(134, '731.79', NULL),
(135, '125.66', NULL),
(136, '743.10', NULL),
(137, '413.20', NULL),
(138, '271.70', NULL),
(139, '198.06', NULL),
(140, '38.79', NULL),
(141, '187.50', NULL),
(142, '336.94', NULL),
(143, '668.34', NULL),
(144, '646.78', NULL),
(145, '191.70', NULL),
(146, '305.84', NULL),
(147, '903.91', NULL),
(148, '466.23', NULL),
(149, '590.15', NULL),
(150, '340.81', NULL),
(151, '968.34', NULL),
(152, '151.42', NULL),
(153, '444.97', NULL),
(154, '824.45', NULL),
(155, '358.11', NULL),
(156, '423.58', NULL),
(157, '190.06', NULL),
(158, '910.54', NULL),
(159, '604.46', NULL),
(160, '281.36', NULL),
(161, '544.21', NULL),
(162, '969.95', NULL),
(163, '655.88', NULL),
(164, '233.63', NULL),
(165, '954.19', NULL),
(166, '546.18', NULL),
(167, '385.06', NULL),
(168, '949.40', NULL),
(169, '367.95', NULL),
(170, '829.81', NULL),
(171, '834.81', NULL),
(172, '375.19', NULL),
(173, '819.67', NULL),
(174, '627.04', NULL),
(175, '961.48', NULL),
(176, '74.24', NULL),
(177, '816.11', NULL),
(178, '539.35', NULL),
(179, '204.59', NULL),
(180, '657.31', NULL),
(181, '39.44', NULL),
(182, '653.89', NULL),
(183, '186.54', NULL),
(184, '674.20', NULL),
(185, '583.03', NULL),
(186, '119.95', NULL),
(187, '548.33', NULL),
(188, '45.87', NULL),
(189, '893.06', NULL),
(190, '454.43', NULL),
(191, '539.62', NULL),
(192, '822.50', NULL),
(193, '356.55', NULL),
(194, '735.83', NULL),
(195, '415.60', NULL),
(196, '394.69', NULL),
(197, '632.03', NULL),
(198, '630.00', NULL),
(199, '812.78', NULL),
(200, '446.22', NULL),
(201, '921.71', NULL),
(202, '966.24', NULL),
(203, '196.30', NULL),
(204, '996.18', NULL),
(205, '387.49', NULL),
(206, '247.35', NULL),
(207, '314.74', NULL),
(208, '178.73', NULL),
(209, '59.77', NULL),
(210, '912.90', NULL),
(211, '580.48', NULL),
(212, '145.94', NULL),
(213, '920.27', NULL),
(214, '792.90', NULL),
(215, '833.26', NULL),
(216, '185.29', NULL),
(217, '20.46', NULL),
(218, '773.42', NULL),
(219, '757.30', NULL),
(220, '249.20', NULL),
(221, '970.30', NULL),
(222, '132.74', NULL),
(223, '99.30', NULL),
(224, '331.02', NULL),
(225, '375.62', NULL),
(226, '127.08', NULL),
(227, '784.58', NULL),
(228, '250.73', NULL),
(229, '818.72', NULL),
(230, '845.76', NULL),
(231, '31.24', NULL),
(232, '491.94', NULL),
(233, '637.21', NULL),
(234, '929.69', NULL),
(235, '874.60', NULL),
(236, '66.13', NULL),
(237, '531.41', NULL),
(238, '309.17', NULL),
(239, '210.98', NULL),
(240, '155.46', NULL),
(241, '388.92', NULL),
(242, '392.91', NULL),
(243, '253.76', NULL),
(244, '968.04', NULL),
(245, '136.48', NULL),
(246, '940.79', NULL),
(247, '924.89', NULL),
(248, '38.73', NULL),
(249, '787.61', NULL),
(250, '954.91', NULL),
(251, '825.48', NULL),
(252, '78.35', NULL),
(253, '606.75', NULL),
(254, '972.64', NULL),
(255, '28.65', NULL),
(256, '268.75', NULL),
(257, '652.92', NULL),
(258, '244.50', NULL),
(259, '290.29', NULL),
(260, '277.93', NULL),
(261, '85.88', NULL),
(262, '989.98', NULL),
(263, '424.40', NULL),
(264, '66.29', NULL),
(265, '696.41', NULL),
(266, '605.30', NULL),
(267, '657.31', NULL),
(268, '985.03', NULL),
(269, '612.66', NULL),
(270, '843.92', NULL),
(271, '863.76', NULL),
(272, '736.64', NULL),
(273, '327.19', NULL),
(274, '601.01', NULL),
(275, '445.45', NULL),
(276, '612.15', NULL),
(277, '204.12', NULL),
(278, '653.23', NULL),
(279, '888.11', NULL),
(280, '621.15', NULL),
(281, '731.71', NULL),
(282, '79.50', NULL),
(283, '398.02', NULL),
(284, '765.77', NULL),
(285, '159.47', NULL),
(286, '16.13', NULL),
(287, '753.08', NULL),
(288, '20.67', NULL),
(289, '981.41', NULL),
(290, '292.51', NULL),
(291, '198.07', NULL),
(292, '885.81', NULL),
(293, '267.34', NULL),
(294, '424.87', NULL),
(295, '542.29', NULL),
(296, '55.23', NULL),
(297, '219.54', NULL),
(298, '884.93', NULL),
(299, '659.74', NULL),
(300, '878.33', NULL);

-- --------------------------------------------------------

--
-- Tabellenstruktur für Tabelle `lager`
--

DROP TABLE IF EXISTS `lager`;
CREATE TABLE `lager` (
  `LagerID` int(11) NOT NULL,
  `StandortID` int(11) NOT NULL,
  `RegionID` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

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

DROP TABLE IF EXISTS `lager_einzelteile`;
CREATE TABLE `lager_einzelteile` (
  `Lager_EteileID` int(11) NOT NULL,
  `MinBestand` int(11) NOT NULL,
  `MaxBestand` int(11) NOT NULL,
  `Bestand` int(11) NOT NULL,
  `LagerID` int(11) NOT NULL,
  `EinzelteileID` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- --------------------------------------------------------

--
-- Tabellenstruktur für Tabelle `lager_lieferant`
--

DROP TABLE IF EXISTS `lager_lieferant`;
CREATE TABLE `lager_lieferant` (
  `Lager_LieferID` int(11) NOT NULL,
  `LieferantID` int(11) NOT NULL,
  `LagerID` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- --------------------------------------------------------

--
-- Tabellenstruktur für Tabelle `lieferant`
--

DROP TABLE IF EXISTS `lieferant`;
CREATE TABLE `lieferant` (
  `LieferantID` int(11) NOT NULL,
  `LieferantName` varchar(50) NOT NULL,
  `LetzteLieferung` date NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- --------------------------------------------------------

--
-- Tabellenstruktur für Tabelle `lieferdetails`
--

DROP TABLE IF EXISTS `lieferdetails`;
CREATE TABLE `lieferdetails` (
  `LieferdetailsID` int(11) NOT NULL,
  `Anzahl` int(11) NOT NULL,
  `Stueckpreis` decimal(8,2) NOT NULL,
  `LieferantID` int(11) NOT NULL,
  `EinzelteileID` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- --------------------------------------------------------

--
-- Tabellenstruktur für Tabelle `lieferung`
--

DROP TABLE IF EXISTS `lieferung`;
CREATE TABLE `lieferung` (
  `LieferungID` int(11) NOT NULL,
  `BestellDatum` date NOT NULL,
  `GesamtPreis` decimal(8,2) NOT NULL,
  `LieferdetailsID` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- --------------------------------------------------------

--
-- Tabellenstruktur für Tabelle `mitarbeiter`
--

DROP TABLE IF EXISTS `mitarbeiter`;
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
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

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

DROP TABLE IF EXISTS `privatinfo`;
CREATE TABLE `privatinfo` (
  `PrivatInfoID` int(11) NOT NULL,
  `Nachname` varchar(30) NOT NULL,
  `Vorname` varchar(30) NOT NULL,
  `Mobilnummer` varchar(30) NOT NULL,
  `EmailPrivate` varchar(100) NOT NULL,
  `WohnortID` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

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

DROP TABLE IF EXISTS `region`;
CREATE TABLE `region` (
  `RegionID` int(11) NOT NULL,
  `Region_Name` varchar(30) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

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

DROP TABLE IF EXISTS `reparatur`;
CREATE TABLE `reparatur` (
  `ReparaturID` int(11) NOT NULL,
  `ReparaturDatum` date NOT NULL,
  `ReparaturDauer` int(11) DEFAULT NULL,
  `Abgeschlossen` tinyint(1) DEFAULT NULL,
  `DefektID` int(11) NOT NULL,
  `BearbeiterID` int(11) NOT NULL,
  `LagerID` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- --------------------------------------------------------

--
-- Tabellenstruktur für Tabelle `standort`
--

DROP TABLE IF EXISTS `standort`;
CREATE TABLE `standort` (
  `StandortID` int(11) NOT NULL,
  `PLZ` char(5) NOT NULL,
  `Stadt` varchar(30) NOT NULL,
  `Strasse` varchar(30) NOT NULL,
  `Sammelpunkt` tinyint(1) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

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

DROP TABLE IF EXISTS `warenausgabe`;
CREATE TABLE `warenausgabe` (
  `WarenausgabeID` int(11) NOT NULL,
  `AnzahlDerTeile` int(11) NOT NULL,
  `ReparaturID` int(11) NOT NULL,
  `EinzelteileID` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- --------------------------------------------------------

--
-- Tabellenstruktur für Tabelle `zahlung`
--

DROP TABLE IF EXISTS `zahlung`;
CREATE TABLE `zahlung` (
  `ZahlungID` int(11) NOT NULL,
  `GesamtPreis` decimal(6,2) NOT NULL,
  `BestellERID` int(11) NOT NULL,
  `ZMethodID` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- --------------------------------------------------------

--
-- Tabellenstruktur für Tabelle `zahlungsmethode`
--

DROP TABLE IF EXISTS `zahlungsmethode`;
CREATE TABLE `zahlungsmethode` (
  `ZMethodID` int(11) NOT NULL,
  `MinutenSatz` int(11) NOT NULL,
  `ZahlungsType` enum('K','A') NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

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
  ADD PRIMARY KEY (`BestellERID`);

--
-- Indizes für die Tabelle `defekt`
--
ALTER TABLE `defekt`
  ADD PRIMARY KEY (`DefektID`);

--
-- Indizes für die Tabelle `einzelteile`
--
ALTER TABLE `einzelteile`
  ADD PRIMARY KEY (`EinzelteileID`);

--
-- Indizes für die Tabelle `eroller`
--
ALTER TABLE `eroller`
  ADD PRIMARY KEY (`ERollerID`);

--
-- Indizes für die Tabelle `fahrtenbuch`
--
ALTER TABLE `fahrtenbuch`
  ADD PRIMARY KEY (`FahrtenbuchID`);

--
-- Indizes für die Tabelle `fuhrpark`
--
ALTER TABLE `fuhrpark`
  ADD PRIMARY KEY (`FirmenwagenID`);

--
-- Indizes für die Tabelle `haltepunkt`
--
ALTER TABLE `haltepunkt`
  ADD PRIMARY KEY (`HaltepunktID`);

--
-- Indizes für die Tabelle `kunde`
--
ALTER TABLE `kunde`
  ADD PRIMARY KEY (`KundeID`),
  ADD UNIQUE KEY `EmailAdress` (`EmailAdress`),
  ADD UNIQUE KEY `Mobilnummer` (`Mobilnummer`);

--
-- Indizes für die Tabelle `kundenkonto`
--
ALTER TABLE `kundenkonto`
  ADD PRIMARY KEY (`KKontoID`);

--
-- Indizes für die Tabelle `lager`
--
ALTER TABLE `lager`
  ADD PRIMARY KEY (`LagerID`);

--
-- Indizes für die Tabelle `lager_einzelteile`
--
ALTER TABLE `lager_einzelteile`
  ADD PRIMARY KEY (`Lager_EteileID`);

--
-- Indizes für die Tabelle `lager_lieferant`
--
ALTER TABLE `lager_lieferant`
  ADD PRIMARY KEY (`Lager_LieferID`);

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
  ADD PRIMARY KEY (`LieferdetailsID`);

--
-- Indizes für die Tabelle `lieferung`
--
ALTER TABLE `lieferung`
  ADD PRIMARY KEY (`LieferungID`);

--
-- Indizes für die Tabelle `mitarbeiter`
--
ALTER TABLE `mitarbeiter`
  ADD PRIMARY KEY (`MitarbeiterID`),
  ADD UNIQUE KEY `BusinessEmail` (`BusinessEmail`);

--
-- Indizes für die Tabelle `privatinfo`
--
ALTER TABLE `privatinfo`
  ADD PRIMARY KEY (`PrivatInfoID`),
  ADD UNIQUE KEY `Mobilnummer` (`Mobilnummer`),
  ADD UNIQUE KEY `EmailPrivate` (`EmailPrivate`);

--
-- Indizes für die Tabelle `region`
--
ALTER TABLE `region`
  ADD PRIMARY KEY (`RegionID`);

--
-- Indizes für die Tabelle `reparatur`
--
ALTER TABLE `reparatur`
  ADD PRIMARY KEY (`ReparaturID`);

--
-- Indizes für die Tabelle `standort`
--
ALTER TABLE `standort`
  ADD PRIMARY KEY (`StandortID`);

--
-- Indizes für die Tabelle `warenausgabe`
--
ALTER TABLE `warenausgabe`
  ADD PRIMARY KEY (`WarenausgabeID`);

--
-- Indizes für die Tabelle `zahlung`
--
ALTER TABLE `zahlung`
  ADD PRIMARY KEY (`ZahlungID`);

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
  MODIFY `BestellERID` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT für Tabelle `defekt`
--
ALTER TABLE `defekt`
  MODIFY `DefektID` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT für Tabelle `eroller`
--
ALTER TABLE `eroller`
  MODIFY `ERollerID` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT für Tabelle `fahrtenbuch`
--
ALTER TABLE `fahrtenbuch`
  MODIFY `FahrtenbuchID` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT für Tabelle `haltepunkt`
--
ALTER TABLE `haltepunkt`
  MODIFY `HaltepunktID` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT für Tabelle `kunde`
--
ALTER TABLE `kunde`
  MODIFY `KundeID` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=2045;

--
-- AUTO_INCREMENT für Tabelle `kundenkonto`
--
ALTER TABLE `kundenkonto`
  MODIFY `KKontoID` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=301;

--
-- AUTO_INCREMENT für Tabelle `lieferdetails`
--
ALTER TABLE `lieferdetails`
  MODIFY `LieferdetailsID` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT für Tabelle `lieferung`
--
ALTER TABLE `lieferung`
  MODIFY `LieferungID` int(11) NOT NULL AUTO_INCREMENT;

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
  MODIFY `ReparaturID` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT für Tabelle `standort`
--
ALTER TABLE `standort`
  MODIFY `StandortID` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=1251;

--
-- AUTO_INCREMENT für Tabelle `warenausgabe`
--
ALTER TABLE `warenausgabe`
  MODIFY `WarenausgabeID` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT für Tabelle `zahlung`
--
ALTER TABLE `zahlung`
  MODIFY `ZahlungID` int(11) NOT NULL AUTO_INCREMENT;
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
