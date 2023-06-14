
DROP DATABASE IF EXISTS EW_DB;
CREATE DATABASE IF NOT EXISTS EW_DB 
DEFAULT CHARACTER SET utf8mb4 
COLLATE utf8mb4_general_ci;
USE EW_DB;

------------------------------------------------------------------------------------------------

DROP TABLE IF EXISTS PAYMENTMETHOD;
CREATE TABLE IF NOT EXISTS PAYMENTMETHOD 
(
     PaymentMethodID    integer	        not null
    ,MinutenSatz	    integer	        not null
    ,PaymentType	    enum('K','A')	not null
    ,CONSTRAINT paymentmethod_pk PRIMARY KEY (PaymentMethodID)
);


DROP TABLE IF EXISTS PAYMENTACCOUNT;
CREATE TABLE IF NOT EXISTS PAYMENTACCOUNT
(
     PaymentAccountID	integer	        not null	AUTO_INCREMENT
    ,Balance	        decimal(8,2)	not null	
    ,LastPaymentDate	Date	            null	
    ,PaymentMethodID	integer	        not null
    ,CONSTRAINT paymentaccount_pk PRIMARY KEY (PaymentAccountID)
    ,CONSTRAINT paymentaccount_paymentmethod_fk FOREIGN KEY (PaymentMethodID) 
    REFERENCES PAYMENTMETHOD(PaymentMethodID)
);


DROP TABLE IF EXISTS CUSTOMER;
CREATE TABLE IF NOT EXISTS CUSTOMER 
(
     CustomerID	        integer	        not null	Primärschlüssel, Autoincrement
    ,LastName	        varchar(30)	    not null	
    ,FirstName	        varchar(30)	    not null	
    ,EmailAdress	    varchar(100)	not null	Unique
    ,Mobilnummer	    varchar(30) 	not null	
    ,Gender	            enum('M','W','D')	null	Werte:M (männlich),W (weiblich),D (divers)
    ,LetzteNutzung	    Date	        not null	
    ,Inaktiv	        boolean	        not null	
    .PaymentAccountID	integer	        not null	FK, Referenz auf PaymentAccount.PaymentAccountID
    ,WohnortID	i       integer	        not null	FK, Referenz auf Locations.LocationID
);


DROP TABLE IF EXISTS ARCHIV;
CREATE TABLE IF NOT EXISTS ARCHIV 
(
     ArchivCustomerID	integer	        not null	Primärschlüssel, FK, Referenz auf Customer.CustomerID
    ,LastName	        varchar(30)	    not null	
    ,FirstName	        varchar(30)	    not null	
    ,EmailAdress	    varchar(100)	not null	Unique
    ,Mobilnummer	    varchar(30)	    not null	
    ,Gender	            enum('M','W','D')	null	Werte:M (männlich),W (weiblich),D (divers)
);


DROP TABLE IF EXISTS LOCATIONS;
CREATE TABLE IF NOT EXISTS LOCATIONS
(
     LocationID	        integer	        not null	Primärschlüssel, Autoincrement
    ,PLZ	            char(5)	        not null	
    ,City	            varchar(30)	    not null	
    ,Street	            varchar(30)	    not null	
    ,Sammelpunkt	    boolean         	null	
);


DROP TABLE IF EXISTS ORDER_EROLLER;
CREATE TABLE IF NOT EXISTS ORDER_EROLLER 
(
     Order_ERollerID	integer	        not null	Primärschlüssel, Autoincrement
    ,Nutzdauer	        time	        not null	
    ,StartpunktID	    integer	        not null	FK, Referenz auf Locations.LocationID
    ,EndPunktID	        integer	        not null	FK, Referenz auf Locations.LocationID
    ,GesamtFahrstecke	integer	        not null	
    ,ZahlmethodeID	    integer	        not null	FK, Referenz auf PaymentMethod.PaymentID
    ,Preis	            decimal(6,2)	not null	berechnet: Nutzdauer * PaymentMethod.MinutenSatz
    ,CustomerID	        integer	        not null	FK, Referenz auf Customer.CustomerID
    ,ERollerID	        integer	        not null	FK, Referenz auf ERoller.ERollerID
);


DROP TABLE IF EXISTS EROLLER;
CREATE TABLE IF NOT EXISTS EROLLER 
(
     ERollerID	        integer	        not null	Primärschlüssel, Autoincrement
    ,StatusID	        integer	        not null	FK, Referenz auf Status_ERoller.StatusID
    ,ModellID	        integer	        not null	FK, Referenz auf Modell.ModellID
);


DROP TABLE IF EXISTS STATUS_EROLLER;
CREATE TABLE IF NOT EXISTS STATUS_EROLLER 
(
     StatusID	        integer	        not null	Primärschlüssel, Autoincrement
    ,Defects	        varchar(250)	    null	
    ,Battery	        integer	        not null	
    ,LastMaintenance	Date	        not null	
    ,NextMaintenance	Date	        not null	Berechnet: LastMaintenance + 7 Tage
    ,EmployeeID	        integer	            null	FK, Referenz auf Employee.EmployeeID
    ,LagerID	        integer	            null	FK, Referenz auf Lager.LagerID
);


DROP TABLE IF EXISTS MODELL;
CREATE TABLE IF NOT EXISTS MODELL 
(
     ModellID	        integer	        not null	Primärschlüssel
    ,Type	            varchar(50)	    not null	
    ,Name	            varchar(50) 	not null	
);


DROP TABLE IF EXISTS EINZELNE_TEILE;
CREATE TABLE IF NOT EXISTS EINZELNE_TEILE 
(
     EinzelteileID	    integer	        not null	Primärschlüssel, Autoincrement
    ,ModellID	        integer	        not null	FK, Referenz auf Modell.ModellID
    ,LagerID	        integer	        not null	FK, Referenz auf Lager.LagerID
);


DROP TABLE IF EXISTS LAGER;
CREATE TABLE IF NOT EXISTS LAGER 
(
     LagerID	        integer	        not null	Primärschlüssel
    ,MinAmount	        integer	        not null	
    ,MaxAmount	        integer	        not null	
    ,AmountInStock	    integer	        not null	
    ,RegionID	        varchar(30)	    not null	FK, Referenz auf Region.RegionID
);


DROP TABLE IF EXISTS LIEFERANT;
CREATE TABLE IF NOT EXISTS LIEFERANT 
(
     LieferantID	    integer	        not null	Primärschlüssel
    ,LieferantName	    varchar(50)	    not null	
    ,LetzteLieferung	date	        not null	
    ,LagerID	        integer	        not null	FK, Referenz auf Lager.LagerID
    ,BestellungenID	    integer	        not null	FK, Referenz auf Bestellungen.BestellungenID
);


DROP TABLE IF EXISTS BESTELLUNGEN;
CREATE TABLE IF NOT EXISTS BESTELLUNGEN 
(
     BestellungenID	    integer	        not null	Primärschlüssel, Autoincrement
    ,OrderStart	        date	        not null	
    ,DeliveryDate	    date	        not null	
    ,Price	            integer	        not null	
    ,Quantity	        integer	        not null	
);


DROP TABLE IF EXISTS EMPLOYEE;
CREATE TABLE IF NOT EXISTS EMPLOYEE
(
     EmployeeID	        integer	        not null	Primärschlüssel, Autoincrement
    ,BusinessPhone	    varchar(30)	        null	
    ,BusinessEmail	    varchar(100)	not null	Unique, Format:LastName.FirstName@ecowheels.com
    ,JobTitle	        varchar(30)	    not null	
    ,HireDate	        date	        not null	
    ,ManagerID	        integer	            null	FK, Referenz auf Employee.EmployeeID
    ,PrivatinfoID	    integer	        not null	FK, Referenz auf Privatinfo.PrivatinfoID
    ,SalaryID	        integer	        not null	FK, Referenz auf Salary.SalaryID
    ,ArbeitsortID	    integer	        not null	FK, Referenz auf Locations.LocationID
    ,DepartmentID	    integer	        not null	FK, Referenz auf Department.DepartmentID
);


DROP TABLE IF EXISTS DEPARTMENT;
CREATE TABLE IF NOT EXISTS DEPARTMENT
(
     DepartmentID	    integer	        not null	Primärschlüssel
    ,DepartmentName	    varchar(30)	    not null	Unique
    ,DepartmentRegion	varchar(30)	    not null	FK, Referenz auf Region.RegionID
);


DROP TABLE IF EXISTS REGION;
CREATE TABLE IF NOT EXISTS REGION
(
     RegionID	        integer	        not null	Primärschlüssel
    ,Region_Name	    archar(30)	    not null	
);


DROP TABLE IF EXISTS SALARY;
CREATE TABLE IF NOT EXISTS SALARY
(
     SalaryID	        integer 	    not null	Primärschlüssel
    ,Salary	            integer	        not null
);


DROP TABLE IF EXISTS VACATION;
CREATE TABLE IF NOT EXISTS VACATION 
(
     VacationID	        integer	        not null	Primärschlüssel
    ,StartDate	        date	        not null	
    ,EndDate	        date	        not null	
    ,EmployeeID	        integer	        not null	FK, Referenz auf Employee.EmployeeID
);


DROP TABLE IF EXISTS PRIVATEINFO;
CREATE TABLE IF NOT EXISTS PRIVATEINFO
(
     PrivateinfoID	    integer	        not null	Primärschlüssel, Autoincrement
    ,LastName	        varchar(30)	    not null	
    ,FirstName	        varchar(30)	    not null	
    ,Mobilnummer	    varchar(30)	    not null	
    ,EmailPrivate	    varchar(100)	not null	Unique
    ,WohnortID	        integer	        not null	FK, Referenz auf Locations.LocationID
);


DROP TABLE IF EXISTS FUHRPARK;
CREATE TABLE IF NOT EXISTS FUHRPARK
(
     FirmenwagenID	    integer	        not null	Primärschlüssel
    ,Auto_Type	        varchar(50)	    not null	
    ,NächsteWartung	    date	        not null	
    ,LagerID	        integer	        not null	FK, Referenz auf Lager.LagerID
);


DROP TABLE IF EXISTS FAHRTENBUCH;
CREATE TABLE IF NOT EXISTS FAHRTENBUCH
(
     FahrtenbuchID	    integer	        not null	Primärschlüssel, Autoincrement
    ,Fahrtstart	        timestamp	    not null	
    ,Fahrtende	        timestamp	    not null	
    ,Fahrtdauer	        timestamp	    not null	Berechnet: |Fahrtstart - Fahrtender|
    ,FirmenwagenID	    integer	        not null	FK, Referenz auf Fuhrpark.FirmenwagenID
    ,EmployeeID	        integer	        not null	FK, Referenz auf Employee.EmployeeID
    ,HaltepunktID	    integer	        not null	FK, Referenz auf Haltepunkt.HaltepunktID
    ,RollerEingesamelt	integer	        not null	
);


DROP TABLE IF EXISTS HALTEPUNKT;
CREATE TABLE IF NOT EXISTS HALTEPUNKT
(
     HaltepunktID	    integer         not null	Primärschlüssel, Autoincrement
    ,ERollerID	        integer	        not null	FK, Referenz auf ERoller.ERollerID
    ,LocationID	        integer	        not null	FK, Referenz auf Locations.LocationID
);


DROP TABLE IF EXISTS APPLICANT;
CREATE TABLE IF NOT EXISTS APPLICANT
(
     ApplicantID	    integer	        not null	Primärschlüssel
    ,JobTitle	        varchar(50)	    not null	
    ,LastName	        varchar(30)	    not null	
    ,FirstName	        varchar(30)	    not null	
    ,Email	            varchar(100)    not null	Unique
    ,Telefonnummer	    varchar(30)	    not null	
    ,LocationID	        integer	        not null	FK, Referenz auf Locations.LocationID
);
 