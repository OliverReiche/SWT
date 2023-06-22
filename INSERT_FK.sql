
-----------------------------------------------------------
            --- Insert Skript für alle FKs  ---
-----------------------------------------------------------


ALTER TABLE ZAHLUNG
 ADD CONSTRAINT zahlung_order_eroller_fk FOREIGN KEY (Order_ERollerID)
 REFERENCES ORDER_EROLLER(Order_ERollerID)
 ,ADD CONSTRAINT zahlung_pmethod_fk FOREIGN KEY (PMethodID)
 REFERENCES PAYMENTMETHOD(PMethodID)
;


ALTER TABLE CUSTOMER
 ADD CONSTRAINT customer_paymentaccount_fk FOREIGN KEY (PaymentAccountID)
 REFERENCES PAYMENTACCOUNT(PaymentAccountID)
 ,ADD CONSTRAINT customer_locations_fk FOREIGN KEY (WohnortID)
 REFERENCES LOCATIONS(LocationID)
;


ALTER TABLE ORDER_EROLLER
 ADD CONSTRAINT order_eroller_customer_fk FOREIGN KEY (CustomerID)
 REFERENCES CUSTOMER(CustomerID)
 ,ADD CONSTRAINT order_eroller_eroller_fk FOREIGN KEY (ERollerID)
 REFERENCES EROLLER(ERollerID)
 ,ADD CONSTRAINT order_eroller_locations_fk1 FOREIGN KEY (StartPunktID)
 REFERENCES LOCATIONS(LocationID)
 ,ADD CONSTRAINT order_eroller_locations_fk2 FOREIGN KEY (EndPunktID)
 REFERENCES LOCATIONS(LocationID)
;


ALTER TABLE EROLLER
 ADD CONSTRAINT eroller_locations_fk FOREIGN KEY (StandortID)
 REFERENCES LOCATIONS(LocationID)
 ,ADD CONSTRAINT eroller_lager_fk FOREIGN KEY (LagerID)
 REFERENCES LAGER(LagerID)
 ,ADD CONSTRAINT eroller_haltepunkt_fk FOREIGN KEY (HaltepunktID)
 REFERENCES HALTEPUNKT(HaltepunktID)
;


ALTER TABLE DEFECT
 ADD CONSTRAINT defect_eroller_fk FOREIGN KEY (ERollerID)
 REFERENCES EROLLER(ERollerID)
;


ALTER TABLE REPERATUR
 ADD CONSTRAINT reperatur_defect_fk FOREIGN KEY (DefectID)
 REFERENCES DEFECT(DefectID)
 ,ADD CONSTRAINT reperatur_employee_fk FOREIGN KEY (BearbeiterID)
 REFERENCES EMPLOYEE(EmployeeID)
 ,ADD CONSTRAINT reperatur_lager_fk FOREIGN KEY (LagerID)
 REFERENCES LAGER(LagerID)
;


ALTER TABLE LAGER
 ADD CONSTRAINT lager_region_fk FOREIGN KEY (RegionID)
 REFERENCES REGION(RegionID)
;


ALTER TABLE LIEFERANT
 ADD CONSTRAINT lieferant_lager_fk FOREIGN KEY (LagerID)
 REFERENCES LAGER(LagerID)
;


ALTER TABLE LAGER_EINZELTEILE
 ADD CONSTRAINT lager_einzelteile_lager_fk FOREIGN KEY (LagerID)
 REFERENCES LAGER(LagerID)
 ,ADD CONSTRAINT lager_einzelteile_fk FOREIGN KEY (EinzelteileID)
 REFERENCES EINZELTEILE(EinzelteileID)
;


ALTER TABLE BESTELLDETAILS
 ADD CONSTRAINT bestelldetails_lieferant_fk FOREIGN KEY (LieferantID)
 REFERENCES LIEFERANT(LieferantID)
 ,ADD CONSTRAINT bestelldetails_einzelteile_fk FOREIGN KEY (EinzelteileID)
 REFERENCES EINZELTEILE(EinzelteileID)
;


ALTER TABLE WARENAUSGABE
 ADD CONSTRAINT warenausgabe_reperatur_fk FOREIGN KEY (ReperaturID)
 REFERENCES REPERATUR(ReperaturID)
 ,ADD CONSTRAINT warenausgabe_einzelteile_fk FOREIGN KEY (EinzelteileID)
 REFERENCES EINZELTEILE(EinzelteileID)
;


ALTER TABLE ORDER_LAGER
 ADD CONSTRAINT order_lager_bestelldetails_fk FOREIGN KEY (BestelldetailsID)
 REFERENCES BESTELLDETAILS(BestelldetailsID)
;


ALTER TABLE EMPLOYEE
 ADD CONSTRAINT employee_manager_fk FOREIGN KEY (ManagerID)
 REFERENCES EMPLOYEE(EmployeeID)
 ,ADD CONSTRAINT employee_privatinfo_fk FOREIGN KEY (PrivatinfoID)
 REFERENCES PRIVATEINFO(PrivatinfoID)
 ,ADD CONSTRAINT employee_locations_fk FOREIGN KEY (ArbeitsortID)
 REFERENCES LOCATIONS(LocationID)
 ,ADD CONSTRAINT employee_department_fk FOREIGN KEY (DepartmentID)
 REFERENCES DEPARTMENT(DepartmentID)
;


ALTER TABLE PRIVATEINFO
 ADD CONSTRAINT privateinfo_locations_fk FOREIGN KEY (WohnortID)
 REFERENCES LOCATIONS(LocationID)
;


ALTER TABLE FUHRPARK
 ADD CONSTRAINT fuhrpark_lager_fk FOREIGN KEY (LagerID)
 REFERENCES LAGER(LagerID)
;


ALTER TABLE FAHRTENBUCH
 ADD CONSTRAINT fahrtenbuch_fuhrpark_fk FOREIGN KEY (FirmenwagenID)
 REFERENCES FUHRPARK(FirmenwagenID)
 ,ADD CONSTRAINT fahrtenbuch_employee_fk FOREIGN KEY (EmployeeID)
 REFERENCES EMPLOYEE(EmployeeID)
;


ALTER TABLE HALTEPUNKT
 ADD CONSTRAINT haltepunkt_fahrtenbuch_fk FOREIGN KEY (FahrtenbuchID)
 REFERENCES FAHRTENBUCH(FahrtenbuchID)
 ,ADD CONSTRAINT haltepunkt_locations_fk FOREIGN KEY (LocationID)
 REFERENCES LOCATIONS(LocationID)
;