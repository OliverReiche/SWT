-- 
-- Datenbank: ew_db 
-- erstellt am 02.07.2023
-- durch Projektgruppe C5
-- Datenbank mit Tabellen für EcoWheels Verwaltungssystem

-- --------------------------------------------------------

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
