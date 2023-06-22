
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
 ,ADD CONSTRAINT eroller_haltepunkr_fk FOREIGN KEY (HaltepunktID)
 REFERENCES HALTEPUNKT(HaltepunktID)
;
