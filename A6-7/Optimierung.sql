-- drop bitmap indices of each foreign keys of fact table
drop index idx_dim_verkaeufer_key;
drop index idx_dim_artikel_key;
drop index idx_dim_kunde_key;
drop index idx_dim_artgrp_key;
drop index idx_dim_datum_key;

-- drop foreign keys constraint from fact table
alter table fact_bestellung drop constraint dim_verkaeufer_fk;
alter table fact_bestellung drop constraint dim_artikel_fk;
alter table fact_bestellung drop constraint dim_kunde_fk;
alter table fact_bestellung drop constraint dim_artgrp_fk;
alter table fact_bestellung drop constraint dim_datum_fk;

-- create bitmap indices on each foreign key of fact table
create bitmap index idx_dim_verkaeufer_key on fact_bestellung(dim_verkaeufer_key);
create bitmap index idx_dim_artikel_key on fact_bestellung(dim_artikel_key); 
create bitmap index idx_dim_kunde_key on fact_bestellung(dim_kunde_key); 
create bitmap index idx_dim_artgrp_key on fact_bestellung(dim_artgrp_key); 
create bitmap index idx_dim_datum_key on fact_bestellung(dim_datum_key); 

-- add foreign keys constraint to fact table
alter table fact_bestellung add constraint dim_verkaeufer_fk foreign key(dim_verkaeufer_key) references dim_verkaeufer(dim_verkaeufer_key);
alter table fact_bestellung add constraint dim_artikel_fk foreign key(dim_artikel_key) references dim_artikel(dim_artikel_key);
alter table fact_bestellung add constraint dim_kunde_fk foreign key(dim_kunde_key) references dim_kunde(dim_kunde_key);
alter table fact_bestellung add constraint dim_artgrp_fk foreign key(dim_artgrp_key) references dim_artgrp(dim_artgrp_key);
alter table fact_bestellung add constraint dim_datum_fk foreign key(dim_datum_key) references dim_datum(dim_datum_key);

alter table fact_bestellung add constraint dim_verkaeufer_fk foreign key(idx_dim_verkaeufer_key) references dim_verkaeufer(dim_verkaeufer_key);
alter table fact_bestellung add constraint dim_artikel_fk foreign key(idx_dim_artikel_key) references dim_artikel(dim_artikel_key);
alter table fact_bestellung add constraint dim_kunde_fk foreign key(idx_dim_kunde_key) references dim_kunde(dim_kunde_key);
alter table fact_bestellung add constraint dim_artgrp_fk foreign key(idx_dim_artgrp_key) references dim_artgrp(dim_artgrp_key);
alter table fact_bestellung add constraint dim_datum_fk foreign key(idx_dim_datum_key) references dim_datum(dim_datum_key);

-- view current username and schema 
select 
sys_context('USERENV','SESSION_USER') as "USER NAME", 
sys_context('USERENV', 'CURRENT_SCHEMA') as "CURRENT SCHEMA" 
from dual;

-- grant select access to current user
grant select any dictionary to ach016;
grant select on v_$sql to ach016;
grant select on v_$sql_plan to ach016;
grant select on v_$sql_plan_statistics_all to ach016;
grant select on v_$session to ach016;

-- examine execution plan
select kundennummer from fact_bestellung left join dim_kunde using(dim_kunde_key);
select * from table(dbms_xplan.display_cursor());

-- use autotrace
select kundennummer from fact_bestellung left join dim_kunde using(dim_kunde_key);

-- compare queries' performance 
-- Umsatz pro Filiale und Monat (group by)
select filiale_name, datum_monat, sum(anzahl * preis) as umsatz from fact_bestellung
right join dim_verkaeufer using(dim_verkaeufer_key)
right join dim_datum using(dim_datum_key)
group by filiale_name, datum_monat
order by filiale_name, datum_monat;

-- Umsatz pro Filiale und Monat (group by cube)
select nvl(filiale_name,' '), datum_monat, sum(anzahl * preis) as umsatz from fact_bestellung
right join dim_verkaeufer using(dim_verkaeufer_key)
right join dim_datum using(dim_datum_key)
group by cube(filiale_name, datum_monat)
order by filiale_name, datum_monat;

-- Welche Filiale hat vom 1.9-3.9.2012 die hÃ¶chste Anzahl von Handcremes verkauft?
select filiale_name, sum(anzahl) as anzahl from fact_bestellung
right join dim_verkaeufer using(dim_verkaeufer_key)
right join dim_datum using(dim_datum_key)
right join dim_artikel using(dim_artikel_key)
where artname = 'Handcreme'
and datum between to_date('01.09.2012', 'DD.MM.YYYY') and to_date('03.09.2012', 'DD.MM.YYYY')
group by filiale_name 
order by filiale_name
fetch first row only;   -- A instead of A and B

-- Umsatz pro Artikelgruppe
select artgrp, sum(anzahl * preis) as umsatz from fact_bestellung
right join dim_artgrp using(dim_artgrp_key)
group by artgrp
order by umsatz;

-- Prozentualler Absatz der Artikelgruppe KÃ¶rperpflege in den einzelnen Filialen
select filiale_name, artgrp, 
round(sum(anzahl)/ cast(sum(sum(anzahl)) over (partition by filiale_name) as float), 3) as prozentualer_absatz 
from fact_bestellung
right join dim_verkaeufer using(dim_verkaeufer_key) 
right join dim_artgrp using(dim_artgrp_key)
group by filiale_name, artgrp
order by filiale_name, artgrp;

-- Umsatz pro Kunden
select kundennummer, sum(anzahl * preis) umsatz from fact_bestellung
full outer join dim_kunde using(dim_kunde_key) 
group by kundennummer
order by kundennummer;

-- Buchungen pro VerkÃ¤ufer und Tag
select kundennummer, datum, sum(anzahl * preis) as beitrag from fact_bestellung
left join dim_kunde using(dim_kunde_key)
right join dim_datum using(dim_datum_key)
group by kundennummer, datum
order by kundennummer, datum;

-- Einzigartige Kundennummer in Bondaten
select kundennummer from fact_bestellung left join dim_kunde using(dim_kunde_key); 

-- create Verkaufsdaten-View
create view Verkaufsdaten as 
select artname, kundennummer, anzahl, preis, anzahl * preis gesamtpreis from fact_bestellung 
left join dim_artikel using (dim_artikel_key)
left join dim_kunde using (dim_kunde_key)
order by artname, kundennummer;

select * from Verkaufsdaten;

-- create Verkaufsdaten-View
create view Verkaufsdaten as 
select artname, kundennummer, anzahl, preis, anzahl * preis gesamtpreis from fact_bestellung 
left join dim_artikel using (dim_artikel_key)
left join dim_kunde using (dim_kunde_key)
order by artname, kundennummer;

select * from Verkaufsdaten;

-- create Verkaufsdaten-Materialized-View
create materialized view Verkaufsdaten_Materialized as 
select artname, kundennummer, anzahl, preis, anzahl * preis gesamtpreis from fact_bestellung 
left join dim_artikel using (dim_artikel_key)
left join dim_kunde using (dim_kunde_key)
order by artname, kundennummer;

select * from Verkaufsdaten_Materialized;

-- Mehr SQL-Anfragen
-- Rangfolge der Umsätze der einzelnen Kunden in den einzelnen Monaten, Umsatz ud Prozentsatz am gesamten Monatumsatz
select rank() over (order by sum(anzahl * preis) desc) rank, 
to_char(datum, 'MM-YYYY') as monat_jahr, 
kundennummer, sum(anzahl * preis) umsatz, 
round(sum(anzahl * preis)/ cast(sum(sum(anzahl * preis)) over (partition by to_char(datum, 'MM-YYYY')) as float), 3) prozentsatz_monat
from fact_bestellung 
full outer join dim_datum using(dim_datum_key)
left join dim_kunde using(dim_kunde_key)
group by kundennummer, to_char(datum, 'MM-YYYY');

-- Umsatzsumme pro Monat, Artikelgruppe 
select to_char(datum, 'MM-YYYY') as monat_jahr, grpname, sum(anzahl * preis) umsatz
from fact_bestellung 
full outer join dim_datum using(dim_datum_key)
left join dim_artgrp using(dim_artgrp_key)
group by to_char(datum, 'MM-YYYY'), grpname
order by to_char(datum, 'MM-YYYY'), grpname;

-- Umsatzsumme pro Artikelgruppe, Monat
select grpname, to_char(datum, 'MM-YYYY') as monat_jahr, sum(anzahl * preis) umsatz
from fact_bestellung 
full outer join dim_datum using(dim_datum_key)
left join dim_artgrp using(dim_artgrp_key)
group by to_char(datum, 'MM-YYYY'), grpname
order by grpname, to_char(datum, 'MM-YYYY');





