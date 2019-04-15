<!--Tomcat/webapps/jpivot/WEB-INF/queries/bon.jsp-->
<%@ page session="true" contentType="text/html; charset=ISO-8859-1" %> 
<%@ taglib uri="http://www.tonbeller.com/jpivot" prefix="jp" %> 
<%@ taglib prefix="c" uri="http://java.sun.com/jstl/core" %> 

<jp:mondrianQuery 
	id="query01" 
	jdbcDriver="oracle.jdbc.driver.OracleDriver"
	jdbcUrl="jdbc:oracle:thin:@ora14.informatik.haw-hamburg.de:1521:inf14" 
	jdbcUser= "ach018" 
	jdbcPassword= "P0k3mon.Master" 
	catalogUri="file:///Users/tripham/Tomcat/webapps/jpivot/WEB-INF/queries/BonDaten.xml"> 

	select {[Measures].[Preis], [Measures].[Absatz]} on columns, 	
	{([Datum].[Alle Tage], [Artikel].[Alle Artikel], [Filiale].[B])} on rows 
	from [BonDaten]	
</jp:mondrianQuery> 

<c:set var="title01" scope="session">Test it</c:set> 