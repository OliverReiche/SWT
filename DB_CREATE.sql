
DROP DATABASE IF EXISTS EW_DB;
CREATE DATABASE IF NOT EXISTS EW_DB 
DEFAULT CHARACTER SET utf8mb4 
COLLATE utf8mb4_general_ci;
USE EW_DB;

------------------------------------------------------------------------------------------------

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


DROP TABLE IF EXISTS ARCHIV;
CREATE TABLE IF NOT EXISTS ARCHIV 
(
     ArchivCustomerID	integer	        not null	-- FK, Referenz auf Customer.CustomerID
    ,LastName	        varchar(30)	    not null	
    ,FirstName	        varchar(30)	    not null	
    ,EmailAdress	    varchar(100)	not null	Unique
    ,Mobilnummer	    varchar(30)	    not null	Unique
    ,Gender	            enum('M','W','D')	null	-- Werte:M (männlich),W (weiblich),D (divers)
    ,CONSTRAINT archivcustomer_pk PRIMARY KEY (ArchivCustomerID)
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
    ,StartpunktID	    integer	        not null	-- FK, Referenz auf Locations.LocationID
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
    ,ModellID	        integer	        not null	-- FK, Referenz auf Modell.ModellID
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
     Reperatur	        integer	        not null	AUTO_INCREMENT
    ,ReperaturDatum	    Date	        not null	
    ,ReperaturDauer	    integer	            null	
    ,Abgeschlossen	    Boolean	            null    -- True = Abgeschlossen, False = noch in Bearbeitung
    ,BearbeiterID	    integer	        not null	-- FK, Referenz auf Employee.EmployeeID
    ,LagerID	        integer	        not null	-- FK, Referenz auf Lager.LagerID
    ,CONSTRAINT reperatur_pk PRIMARY KEY (Reperatur)
);


DROP TABLE IF EXISTS MODELL;
CREATE TABLE IF NOT EXISTS MODELL 
(
     ModellID	        integer	        not null
    ,Type	            varchar(50)	    not null	
    ,Name	            varchar(50) 	not null
    ,CONSTRAINT modell_pk PRIMARY KEY (ModellID)	
);


DROP TABLE IF EXISTS VERKNÜPFUNGSRELATION_LAGER_MODELL;
CREATE TABLE IF NOT EXISTS VERKNÜPFUNGSRELATION_LAGER_MODELL 
(
     Lager_ModellID	    integer	        not null	AUTO_INCREMENT
    ,ModellID	        integer	        not null	-- FK, Referenz auf Modell.ModellID
    ,LagerID	        integer	        not null	-- FK, Referenz auf Lager.LagerID
    ,CONSTRAINT lager_modell_pk PRIMARY KEY (Lager_ModellID)
);


DROP TABLE IF EXISTS LAGER;
CREATE TABLE IF NOT EXISTS LAGER 
(
     LagerID	        integer	        not null
    ,MinAmount	        integer	        not null	
    ,MaxAmount	        integer	        not null	
    ,AmountInStock	    integer	        not null	
    ,RegionID	        varchar(30)	    not null	-- FK, Referenz auf Region.RegionID
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


DROP TABLE IF EXISTS BESTELLUNGEN;
CREATE TABLE IF NOT EXISTS BESTELLUNGEN 
(
     BestellungenID	    integer	        not null	AUTO_INCREMENT
    ,OrderStart	        date	        not null	
    ,DeliveryDate	    date	        not null	
    ,Price	            integer	        not null	
    ,Quantity	        integer	        not null
    ,LieferantID	    integer	        not null	-- FK, Referenz auf Lieferant.LieferantID
    ,CONSTRAINT bestellungen_pk PRIMARY KEY (BestellungenID)

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
    ,PrivatinfoID	    integer	        not null	-- FK, Referenz auf Privatinfo.PrivatinfoID
    ,SalaryID	        integer	        not null	-- FK, Referenz auf Salary.SalaryID
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


DROP TABLE IF EXISTS SALARY;
CREATE TABLE IF NOT EXISTS SALARY
(
     SalaryID	        integer 	    not null
    ,Salary	            integer	        not null
    ,CONSTRAINT salary_pk PRIMARY KEY (SalaryID)
);


DROP TABLE IF EXISTS VACATION;
CREATE TABLE IF NOT EXISTS VACATION 
(
     VacationID	        integer	        not null
    ,StartDate	        date	        not null	
    ,EndDate	        date	        not null	
    ,EmployeeID	        integer	        not null	-- FK, Referenz auf Employee.EmployeeID
    ,CONSTRAINT vacation_pk PRIMARY KEY (VacationID)
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


DROP TABLE IF EXISTS APPLICANT;
CREATE TABLE IF NOT EXISTS APPLICANT
(
     ApplicantID	    integer	        not null
    ,JobTitle	        varchar(50)	    not null	
    ,LastName	        varchar(30)	    not null	
    ,FirstName	        varchar(30)	    not null	
    ,Email	            varchar(100)    not null	Unique
    ,Telefonnummer	    varchar(30)	    not null	
    ,LocationID	        integer	        not null	-- FK, Referenz auf Locations.LocationID
    ,CONSTRAINT applicant_pk PRIMARY KEY (ApplicantID)
);
 
