--drop
drop table fact_bestellung;
drop table dim_kunde; 
drop table dim_verkaeufer;
drop table dim_artikel; 
drop table dim_artgrp;
drop table dim_date;


--create
create table dim_kunde (
    dim_kunde_key integer generated always as identity, 
    kundennummer integer,
    vorname varchar2(50 char), 
    nachname varchar2(50 char), 
    adresse varchar2(50 char), 
    plz varchar2(5 char), 
    ort varchar2(50 char), 
    
    constraint dim_kunde_pk primary key(dim_kunde_key)
) 

create table dim_verkaeufer (
    dim_verkaeufer_key integer generated always as identity, 
    verkaeufer_vorname varchar2(50 char),
    filiale_name varchar2 (50 char),
    geburtstag date,
    wohnort varchar2(50 char),
    
    constraint dim_verkaeufer_pk primary key(dim_verkaeufer_key)
)

create table dim_artikel (
    dim_artikel_key integer generated always as identity, 
    artnr integer, 
    artname varchar2 (100 char), 
    artgrp varchar2 (10 char),
    
    constraint dim_artikel_pk primary key(dim_artikel_key)
)

create table dim_artgrp (
    dim_artgrp_key integer generated always as identity, 
    artgrp varchar2(10 char), 
    grpname varchar2(50 char),
    
    constraint dim_artgrp_pk primary key(dim_artgrp_key)
) 

--time dimension 
CREATE TABLE dim_date (
    dim_date_key integer generated always as identity,
    
    datum date,
    zeit timestamp,
    
    constraint dim_date_pk primary key(dim_date_key)
)

--insert
insert into dim_artikel (artnr, artname, artgrp) 
select artnr, artname, artgrp from gerken.artikel;

insert into dim_artgrp (artgrp, grpname)
select distinct artgrp, grpname from gerken.artikel;

--fact table 
create table fact_bestellung (
    anzahl integer, 
    preis number(10, 2), 
    
    dim_kunde_key integer, 
    dim_verkaeufer_key integer not null, 
    dim_artikel_key integer not null, 
    dim_artgrp_key integer not null, 
    dim_date_key integer not null,
    
    constraint dim_kunde_fk foreign key(dim_kunde_key) references dim_kunde(dim_kunde_key),
    constraint dim_verkaeufer_fk foreign key(dim_verkaeufer_key) references dim_verkaeufer(dim_verkaeufer_key),
    constraint dim_artikel_fk foreign key(dim_artikel_key) references dim_artikel(dim_artikel_key),
    constraint dim_artgrp_fk foreign key(dim_artgrp_key) references dim_artgrp(dim_artgrp_key), 
    constraint dim_date_fk foreign key(dim_date_key) references dim_date(dim_date_key)
)











