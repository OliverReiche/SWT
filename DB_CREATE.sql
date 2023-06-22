
DROP DATABASE IF EXISTS EW_DB;
CREATE DATABASE IF NOT EXISTS EW_DB 
DEFAULT CHARACTER SET utf8mb4 
COLLATE utf8mb4_general_ci;
USE EW_DB;






DROP TABLE IF EXISTS PAYMENTMETHOD;
CREATE TABLE IF NOT EXISTS PAYMENTMETHOD 
(
     PMethodID          integer	        not null
    ,MinutenSatz	    integer	        not null
    ,PaymentType	    enum('K','A')	not null
    ,CONSTRAINT pmethod_pk PRIMARY KEY (PMethodID)
);

DROP TABLE IF EXISTS ZAHLUNG;
CREATE TABLE IF NOT EXISTS ZAHLUNG 
(
     ZahlungID	        integer	        not null	AUTO_INCREMENT
    ,GesamtPreis	    decimal(6,2)	not null	-- Berechnet: Order_ERoller.NutzungsZeit * PaymentMethod.MinutenSatz
    ,Order_ERollerID	integer	        not null	-- FK, Referenz auf Order_ERoller.Order_ERollerID
    ,PMethodID	        integer	        not null	-- FK, Referenz auf PaymentMethod.PMethodID
    ,CONSTRAINT zahlung_pk PRIMARY KEY (ZahlungID)
);


DROP TABLE IF EXISTS PAYMENTACCOUNT;
CREATE TABLE IF NOT EXISTS PAYMENTACCOUNT
(
     PaymentAccountID	integer	        not null	AUTO_INCREMENT
    ,Balance	        decimal(8,2)	not null	
    ,LastPaymentDate	Date	            null	
    ,CONSTRAINT paymentaccount_pk PRIMARY KEY (PaymentAccountID)
);


DROP TABLE IF EXISTS CUSTOMER;
CREATE TABLE IF NOT EXISTS CUSTOMER 
(
     CustomerID	        integer	        not null	AUTO_INCREMENT
    ,LastName	        varchar(30)	    not null	
    ,FirstName	        varchar(30)	    not null	
    ,EmailAdress	    varchar(100)	not null	Unique
    ,Mobilnummer	    varchar(30) 	not null	Unique
    ,Gender	            enum('M','W','D')	null	-- Werte:M (männlich),W (weiblich),D (divers)
    ,LetzteNutzung	    Date	        not null	
    ,Inaktiv	        boolean	        not null	
    ,PaymentAccountID	integer	        not null	-- FK, Referenz auf PaymentAccount.PaymentAccountID
    ,WohnortID	        integer	        not null	-- FK, Referenz auf Locations.LocationID
    ,CONSTRAINT customer_pk PRIMARY KEY (CustomerID)
);


DROP TABLE IF EXISTS LOCATIONS;
CREATE TABLE IF NOT EXISTS LOCATIONS
(	
	 LocationID	        integer	        not null	AUTO_INCREMENT
    ,PLZ	            char(5)	        not null	
    ,City	            varchar(30)	    not null	
    ,Street	            varchar(30)	    not null	
    ,Sammelpunkt	    boolean         	null
    ,CONSTRAINT location_pk PRIMARY KEY (LocationID)
);


DROP TABLE IF EXISTS ORDER_EROLLER;
CREATE TABLE IF NOT EXISTS ORDER_EROLLER 
(
     Order_ERollerID	integer	        not null	AUTO_INCREMENT
    ,Nutzdauer	        time	        not null	
    ,StartPunktID	    integer	        not null	-- FK, Referenz auf Locations.LocationID
    ,EndPunktID	        integer	        not null	-- FK, Referenz auf Locations.LocationID
    ,GesamtFahrstecke	integer	        not null	
    ,CustomerID	        integer	        not null	-- FK, Referenz auf Customer.CustomerID
    ,ERollerID	        integer	        not null	-- FK, Referenz auf ERoller.ERollerID
    ,CONSTRAINT order_eroller_pk PRIMARY KEY (Order_ERollerID)
);


DROP TABLE IF EXISTS EROLLER;
CREATE TABLE IF NOT EXISTS EROLLER 
(
     ERollerID	        integer	        not null	AUTO_INCREMENT
    ,LastMaintenance	Date	        not null	
    ,NextMaintenance	Date	        not null	-- Berechnet: LastMaintenance + 7 Tage
    ,IsDefect	        Boolean	        not null	-- True = Defekt, Flase = Nicht Defekt
    ,Battery	        integer	        not null	
    ,StandortID	        integer	        not null	-- FK, Referenz auf Locations.LocationID
    ,LagerID	        integer	        not null	-- FK, Referenz auf Lager.LagerID
    ,HaltepunktID	    integer	            null	-- FK, Referenz auf Haltepunkt.HaltepunktID
    ,CONSTRAINT eroller_pk PRIMARY KEY (ERollerID)
);


DROP TABLE IF EXISTS DEFECT;
CREATE TABLE IF NOT EXISTS DEFECT 
(
     DefectID	        integer	        not null	AUTO_INCREMENT
    ,Defects	        varchar(250)    not null	
    ,Battery	        integer         not null	
    ,ERollerID	        integer	        not null	-- FK, Referenz auf ERoller.ERollerID
    ,CONSTRAINT defect_pk PRIMARY KEY (DefectID)
);


DROP TABLE IF EXISTS REPERATUR;
CREATE TABLE IF NOT EXISTS REPERATUR 
(
     ReperaturID	    integer	        not null	AUTO_INCREMENT
    ,ReperaturDatum	    Date	        not null	
    ,ReperaturDauer	    integer	            null	
    ,Abgeschlossen	    Boolean	            null    -- True = Abgeschlossen, False = noch in Bearbeitung
    ,DefectID	        integer	        not null	-- FK, Referent auf Defect.DefectID
    ,BearbeiterID	    integer	        not null	-- FK, Referenz auf Employee.EmployeeID
    ,LagerID	        integer	        not null	-- FK, Referenz auf Lager.LagerID
    ,CONSTRAINT reperatur_pk PRIMARY KEY (ReperaturID)
);


DROP TABLE IF EXISTS LAGER;
CREATE TABLE IF NOT EXISTS LAGER 
(
     LagerID	        integer	        not null
    ,MinAmount	        integer	        not null	
    ,MaxAmount	        integer	        not null	
    ,AmountInStock	    integer	        not null	
    ,RegionID	        integer		    not null	-- FK, Referenz auf Region.RegionID
    ,CONSTRAINT lager_pk PRIMARY KEY (LagerID)
);


DROP TABLE IF EXISTS LIEFERANT;
CREATE TABLE IF NOT EXISTS LIEFERANT 
(
     LieferantID	    integer	        not null	
    ,LieferantName	    varchar(50)	    not null	Unique
    ,LetzteLieferung	date	        not null	
    ,LagerID	        integer	        not null	-- FK, Referenz auf Lager.LagerID
    ,CONSTRAINT liefernat_pk PRIMARY KEY (LieferantID)
);


DROP TABLE IF EXISTS LAGER_EINZELTEILE;
CREATE TABLE IF NOT EXISTS LAGER_EINZELTEILE
(
     Lager_EteileID	    integer	        not null
    ,LagerID	        integer	        not null	-- FK, Referenz auf Lager.LagerID
    ,EinzelteileID	    integer	        not null	-- FK, Referenz auf Einzelteile.EinzelteileID
    ,CONSTRAINT lager_eteile_pk PRIMARY KEY (Lager_EteileID)
);


DROP TABLE IF EXISTS EINZELTEILE;
CREATE TABLE IF NOT EXISTS EINZELTEILE 
(   
     EinzelteileID	    integer     	not null
    ,EType	            varchar(50)     not null	
    ,EName	            integer	        not null	
    ,Gewicht	        decimal(8,2)	not null	
    ,CONSTRAINT einzelteile_pk PRIMARY KEY (EinzelteileID)
);


DROP TABLE IF EXISTS BESTELLDETAILS;
CREATE TABLE IF NOT EXISTS BESTELLDETAILS 
(
     BestelldetailsID	integer	        not null	AUTO_INCREMENT
    ,Quanitiy	        integer	        not null	
    ,PricePerUnit	    decimal(8,2)	not null	
    ,LieferantID	    integer	        not null	-- FK, Referenz auf Lieferant.LieferantID
    ,EinzelteileID	    integer     	not null	-- FK, Referenz auf Einzelteile.EinzelteileID
    ,CONSTRAINT bestelldetails_pk PRIMARY KEY (BestelldetailsID)
);


DROP TABLE IF EXISTS WARENAUSGABE;
CREATE TABLE IF NOT EXISTS WARENAUSGABE 
(
     WarenausgabeID	    integer	        not null	AUTO_INCREMENT
    ,AnzahlDerTeile     integer         not null
    ,ReperaturID	    integer	        not null	-- FK, Referenz auf Reperatur.ReperaturID
    ,EinzelteileID	    integer	        not null	-- FK, Referenz auf Einzelteile.EinzelteileID
    ,CONSTRAINT warenausgabe_pk PRIMARY KEY (WarenausgabeID)
);


DROP TABLE IF EXISTS ORDER_LAGER;
CREATE TABLE IF NOT EXISTS ORDER_LAGER 
(   
     Order_LagerID	    integer	        not null	AUTO_INCREMENT
    ,BestellDatum	    date	        not null	
    ,TotalPrice	        decimal(8,2)	not null	
    ,BestelldetailsID	integer	        not null	-- FK, Referenz auf Bestelldetails.BestelldetailsID
    ,CONSTRAINT order_lager_pk PRIMARY KEY (Order_LagerID)
);


DROP TABLE IF EXISTS EMPLOYEE;
CREATE TABLE IF NOT EXISTS EMPLOYEE
(
     EmployeeID	        integer	        not null    AUTO_INCREMENT
    ,BusinessPhone	    varchar(30)	        null	
    ,BusinessEmail	    varchar(100)	not null	Unique  -- Format:LastName.FirstName@ecowheels.com
    ,JobTitle	        varchar(30)	    not null	
    ,HireDate	        date	        not null	
    ,ManagerID	        integer	            null	-- FK, Referenz auf Employee.EmployeeID
    ,PrivateinfoID	    integer	        not null	-- FK, Referenz auf Privateinfo.PrivatinfoID
    ,Salary  	        integer	        not null	
    ,Vacation           integer         not null
    ,ArbeitsortID	    integer	        not null	-- FK, Referenz auf Locations.LocationID
    ,DepartmentID	    integer	        not null	-- FK, Referenz auf Department.DepartmentID
    ,CONSTRAINT employee_pk PRIMARY KEY (EmployeeID)
);


DROP TABLE IF EXISTS DEPARTMENT;
CREATE TABLE IF NOT EXISTS DEPARTMENT
(
     DepartmentID	    integer	        not null
    ,DepartmentName	    varchar(30)	    not null	Unique
    ,CONSTRAINT department_pk PRIMARY KEY (DepartmentID)
);


DROP TABLE IF EXISTS REGION;
CREATE TABLE IF NOT EXISTS REGION
(
     RegionID	        integer	        not null
    ,Region_Name	    varchar(30)	    not null
    ,CONSTRAINT region_pk PRIMARY KEY (RegionID)
);


DROP TABLE IF EXISTS PRIVATEINFO;
CREATE TABLE IF NOT EXISTS PRIVATEINFO
(
     PrivateInfoID	    integer	        not null	AUTO_INCREMENT
    ,LastName	        varchar(30)	    not null	
    ,FirstName	        varchar(30)	    not null	
    ,Mobilnummer	    varchar(30)	    not null	Unique
    ,EmailPrivate	    varchar(100)	not null	Unique
    ,WohnortID	        integer	        not null	-- FK, Referenz auf Locations.LocationID
    ,CONSTRAINT privateinfo_pk PRIMARY KEY (PrivateInfoID)
);


DROP TABLE IF EXISTS FUHRPARK;
CREATE TABLE IF NOT EXISTS FUHRPARK
(
     FirmenwagenID	    integer	        not null
    ,AutoType	        varchar(50)	    not null	
    ,NächsteWartung	    date	        not null	
    ,LagerID	        integer	        not null	-- FK, Referenz auf Lager.LagerID
    ,CONSTRAINT firmenwagen_pk PRIMARY KEY (FirmenwagenID)
);


DROP TABLE IF EXISTS FAHRTENBUCH;
CREATE TABLE IF NOT EXISTS FAHRTENBUCH
(
     FahrtenbuchID	    integer	        not null	AUTO_INCREMENT
    ,Fahrtstart	        timestamp	    not null	
    ,Fahrtende	        timestamp	    not null	
    ,Fahrtdauer	        timestamp	    not null	-- Berechnet: |Fahrtstart - Fahrtende|
    ,FirmenwagenID	    integer	        not null	-- FK, Referenz auf Fuhrpark.FirmenwagenID
    ,EmployeeID	        integer	        not null	-- FK, Referenz auf Employee.EmployeeID
    ,RollerEingesamelt	integer	        not null
    ,CONSTRAINT fahrtenbuch_pk PRIMARY KEY (FahrtenbuchID)
);


DROP TABLE IF EXISTS HALTEPUNKT;
CREATE TABLE IF NOT EXISTS HALTEPUNKT
(
     HaltepunktID	    integer         not null	AUTO_INCREMENT
    ,Zeitpunkt	        timestamp	    not null	
    ,FahrtenbuchID	    integer	        not null	-- FK, Referenz auf Fahrtenbuch.FahrtenbuchID
    ,LocationID	        integer	        not null	-- FK, Referenz auf Locations.LocationID
    ,CONSTRAINT haltepunkt_pk PRIMARY KEY (HaltepunktID)
);
