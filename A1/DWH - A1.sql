drop table dim_kunde; 
drop table dim_verkaeufer;
drop table dim_artikel; 
drop table dim_artgrp;

create table dim_kunde (
    dim_kunde_id number generated always as identity, 
    kundennummer number,
    vorname varchar2(50 char), 
    nachname varchar2(50 char), 
    adresse varchar2(50 char), 
    plz varchar2(5 char), 
    ort varchar2(50 char), 
    
    constraint dim_kunde_pk primary key(dim_kunde_id)
) 

create table dim_verkaeufer (
    dim_verkaeufer_id number generated always as identity, 
    verkaeufer_vorname varchar2(50 char),
    filiale_name varchar2 (50 char),
    geburtstag date,
    wohnort varchar2(50 char),
    
    constraint dim_verkaeufer_pk primary key(dim_verkaeufer_id)
)

create table dim_artikel (
    dim_artikel_id number generated always as identity, 
    artnr number, 
    artname varchar2 (100 char), 
    artgrp varchar2 (10 char),
    
    constraint dim_artikel_pk primary key(dim_artikel_id)
)

create table dim_artgrp (
    dim_artgrp_id number generated always as identity, 
    artgrp varchar2(10 char), 
    grpname varchar2(50 char),
    
    constraint dim_artgrp_pk primary key(dim_artgrp_id)
) 

insert into dim_artikel (artnr, artname, artgrp) 
select artnr, artname, artgrp from gerken.artikel;

insert into dim_artgrp (artgrp, grpname)
select distinct artgrp, grpname from gerken.artikel;




