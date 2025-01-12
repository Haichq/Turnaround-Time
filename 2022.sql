with allSubset as(  
  SELECT OrderNumber  
      ,ActionType
      ,Comment
      ,Creation
  FROM [PASNet].[dbo].[STAT_PROTO]
  -- Anlage Creation betwwen Feb/Maerz/April 2022
  where creation between '2022-01-02' and '2022-01-05'
  -- nur für 01.Feb -> creation between '2022-01-02' and '2022-02-02'
  and OrderNumber like 'H/2022%'
  -- neu erstellt
  and ActionType = 17 
  
),

-- amount of queried events in 3 months
count_allsubset as(
select  count (*) as amount_allSubset
from allSubset
group by OrderNumber
),

-- Faelle with first 'mikroskopie abgeschlossen' and its creation time
query_allSubset_Mikro as(
 select tmp.OrderNumber, tmp.ActionType, tmp.Creation as first_mikros_creation
 from allSubset, [PASNet].[dbo].[STAT_PROTO] tmp

 inner join(
	select OrderNumber, ActionType,min(Creation) as theFirst
	from [PASNet].[dbo].[STAT_PROTO] 
	where ActionType = 71
	group by OrderNumber, ActionType
 )as t2 on tmp.OrderNumber = t2.OrderNumber
 where allSubset.OrderNumber = tmp.OrderNumber
 and tmp.Creation = t2.theFirst 
 group by tmp.Creation,tmp.OrderNumber,tmp.ActionType
),

-- amount of 'mikroskopie abgeschloosen' in queried Faelle 
count_mikros as(
select count (*) as amount_mikros
from query_allSubset_Mikro
group by OrderNumber
),
---------Left outer Join?------------------
-- find all subset with mikrokopie in [PASNet].[dbo].[STAT_PROTO]
query_allSubset as(
select tmp.OrderNumber, tmp.Creation,tmp.Comment,tmp.ActionType
from [PASNet].[dbo].[STAT_PROTO] tmp, query_allSubset_Mikro q
where tmp.OrderNumber = q.OrderNumber
),


-- erfassung creation time
mikro_erfassung as(
select OrderNumber, creation as erfassung_creation
from query_allSubset
where ActionType = 2
),

--anlage creation time
anlage as(
select OrderNumber,creation as anlage_creation
from query_allSubset
where ActionType =17
),

-- first 'Freigegeben' creation time
first_Frei as( 
select t1.OrderNumber ,t1.Creation as first_Frei_Creation
from query_allSubset t1    
 inner join(
	select OrderNumber, ActionType,min(Creation) as theFirst
	from query_allSubset
	where ActionType = 68
	group by OrderNumber, ActionType
 )as t2 on t1.OrderNumber = t2.OrderNumber
where t1.Creation = t2.theFirst and t1.ActionType = t2.ActionType

),

--------------------------------------1.Diktat bearbeite zwischen Freigegeben und Mikroskopie abgeschlossen-----------------------------------------------------------------------

-- all Faelle with 'Diktat bearbeiten' in quried Faellen
diktat as(
SELECT [OrderNumber]    
      ,[Creation]
  FROM query_allSubset
  where ActionType = 31
 
 ),


Makroskopie as(
 select tmp.OrderNumber, tmp.ActionType, tmp.Creation as first_makros_creation
 from allSubset, [PASNet].[dbo].[STAT_PROTO] tmp

 inner join(
	select OrderNumber, ActionType,min(Creation) as theFirst
	from [PASNet].[dbo].[STAT_PROTO] 
	where ActionType = 69
	group by OrderNumber, ActionType
 )as t2 on tmp.OrderNumber = t2.OrderNumber
 where allSubset.OrderNumber = tmp.OrderNumber
 and tmp.Creation = t2.theFirst 
 group by tmp.Creation,tmp.OrderNumber,tmp.ActionType

),

 -- all 'Diktat bearbeiten' Faelle in between 'Freigegeben' and 'Mikroskopie abgeschlossen'
 diktat_betweenAllSubset as(
SELECT   tmp.OrderNumber     
      ,tmp.Creation	
  FROM diktat tmp, first_Frei, query_allSubset_Mikro
  where first_Frei.OrderNumber = tmp.OrderNumber
  and query_allSubset_Mikro.OrderNumber = tmp.OrderNumber
  and (tmp.Creation) >= first_Frei_Creation
  and (tmp.Creation) <=  first_mikros_creation

),

-- amount of 'Dikat bearbeiten' Faelle which between 'Freigegeben' and 'Mikroskopie abgeschlossen'
count_diktat as(
select count (*) as amount_diktat
from diktat_betweenAllSubset
),

---------------------------------------------------Basis----------------------------------------------------------------------------

-- table result from above requirements
Basis as(
select  distinct query_allSubset_Mikro.OrderNumber
-----------------turnaroud time between each process----
		,DATEDIFF(MINUTE, anlage_creation, erfassung_creation) as Diff_Erfassung_Anlage
		,DATEDIFF(MINUTE, erfassung_creation, first_makros_creation) as Diff_Makros_Erfassung
		,DATEDIFF(MINUTE,first_makros_creation, first_Frei_Creation) as Diff_Freigegeben_Makro
	
		,DATEDIFF(MINUTE,  first_Frei_Creation, first_mikros_creation) as Diff_Mikro_Freigegeben
		
		 -----------------------------------to anlage---------------------------------------------------------------------------------------------------
		 --Erfassung - Anlage
		 ,DATEDIFF(MINUTE, anlage_creation, erfassung_creation) as Erfassung_Anlage	
		 -- Diktat - Anlage
		 ,DATEDIFF(MINUTE, anlage_creation,first_makros_creation) as Makro_Anlage	
		 -- Freigegeben - Anlage
		 ,DATEDIFF(MINUTE, anlage_creation, first_Frei_Creation) as Freigegeben_Anlage
		 -- Mikroskopie - Anlage
		 ,DATEDIFF(MINUTE, anlage_creation, first_mikros_creation) as Mikro_Anlage	

		 -----------------------------------------each creation ----------------------------------------------------------------------------------------------
		 ,anlage_creation
		 ,erfassung_creation
		 ,first_makros_creation
		 ,first_Frei_Creation
		 ,query_allSubset_Mikro.first_mikros_creation 

from 
mikro_erfassung, anlage, first_Frei, query_allSubset_Mikro
	, Makroskopie

where query_allSubset_Mikro.OrderNumber = mikro_erfassung.OrderNumber
and anlage.OrderNumber = query_allSubset_Mikro.OrderNumber
and first_Frei.OrderNumber = query_allSubset_Mikro.OrderNumber
and first_Frei.OrderNumber = Makroskopie.OrderNumber
and first_mikros_creation > first_Frei_Creation 
and first_makros_creation > erfassung_creation
),



count_basis as(
select count(*) as final_result
from Basis 
),


-- average turnaround time in 2023 in MINUTES
totalTime_2023 as(
select avg(Diff_Erfassung_Anlage +Diff_Makros_Erfassung + Diff_Freigegeben_Makro+ Diff_Mikro_Freigegeben) as totalTime
from Basis 

),

--average turnaround time in 2023 in Day(s)/Minutes
show_totalTime_2023 as(
select totalTime
		,FLOOR(totalTime / 1440) as Days_2023
		,FLOOR((totalTime % 1440) / 60) as Hours
		,totalTime % 60 as Minutes
from totalTime_2023

),

slower as(
select *
from Basis , show_totalTime_2023

group by totalTime,OrderNumber,Diff_Erfassung_Anlage,Diff_Freigegeben_Makro ,Diff_Mikro_Freigegeben
,anlage_creation,erfassung_creation,first_Frei_Creation,first_mikros_creation, first_makros_creation,
Diff_Makros_Erfassung,Erfassung_Anlage,Makro_Anlage,Freigegeben_Anlage,Mikro_Anlage, Days_2023,show_totalTime_2023.Hours,
show_totalTime_2023.Minutes

having sum(Diff_Erfassung_Anlage + Diff_Makros_Erfassung + Diff_Freigegeben_Makro + Diff_Mikro_Freigegeben) > totalTime
),

count_slower as(
select COUNT(OrderNumber) as amount_slower
from slower
),

faster as (
select *
from Basis , show_totalTime_2023

group by totalTime,OrderNumber,Diff_Erfassung_Anlage,Diff_Freigegeben_Makro ,Diff_Mikro_Freigegeben
,anlage_creation,erfassung_creation,first_Frei_Creation,first_mikros_creation, first_makros_creation,
Diff_Makros_Erfassung,Erfassung_Anlage,Makro_Anlage,Freigegeben_Anlage,Mikro_Anlage, Days_2023, show_totalTime_2023.Hours,
show_totalTime_2023.Minutes

having sum(Diff_Erfassung_Anlage + Diff_Makros_Erfassung + Diff_Freigegeben_Makro + Diff_Mikro_Freigegeben) <= totalTime
),

count_faster as (
select COUNT(OrderNumber) as amount_faster
from faster
)


--------------------------------------------------------------Qurey----------------------------------------------------------------------------

--avg. time: 2days 19h 58m 
-- latest: 3 days 0h 12m (1m09s) 
/*
select Days_2023,Hours,Minutes
from show_totalTime_2023
*/

--------------------------------------------------------------Qurey----------------------------------------------------------------------------

-- langsame Faelle: 1222
-- latest: 1198 (1m 37s)
-- 1133 (1m 09s)
-- 800(2m16s)
-- which slower than avg. time
/*
select sum(amount_slower) as amount
from count_slower
*/

--------------------------------------------------------------Qurey----------------------------------------------------------------------------

-- schnelle Faelle: 1794 Faelle (1m 32s) 
-- latest: 1821 
-- 1735 (1m32s)
-- which faster than avg. time
-- 1037(2m16s)
/*
select sum(amount_faster) as amount
from count_faster
*/


--------------------------------------------------------------Qurey----------------------------------------------------------------------------
-- final table results : 
-- 2868 Faelle in H/2023 (8s)  -- 1837 (1m11s)
-- 331 Faelle in N/2023 (2m 4s)
-- 263 Faelle in W/2023 (2s)


select *
from Basis



-- 1837 (1m10s)
/*
select sum(final_result) as final_result_2023
from count_basis

*/

--------------------------------------------------------------Qurey----------------------------------------------------------------------------
-- amount of all Faelle in 3 months which also contain the events dont meet the conditions above
-- 4933 Faelle
/*
select sum(amount_allSubset) as amount_allSubset
from count_allsubset 
*/
--------------------------------------------------------------Qurey----------------------------------------------------------------------------

-- amount of mikroskopie
-- 4002 Faelle
-- 19s
/*
select distinct sum(amount_mikros) as amount_mikros
from count_mikros
*/


--------------------------------------------------------------Qurey:Anlage-Erfassung----------------------------------------------------------------------------

-- 1837( 1m09s)
-- avg-H:26 N:35 W:27
/*
select avg(Diff_Erfassung_Anlage) as Minutes
from Basis b,negative n
where n.TEST = 'Positiv'
and b.OrderNumber = n.OrderNumber
*/
--------------------------------------------------------------Qurey:Erfassung-firstDiktat----------------------------------------------------------------------------
-- 1837(1m09s)
/*
select (Diff_firstDiktat_Erfassung) as Minutes
from Basis b
*/
--------------------------------------------------------------Qurey:firstDiktat-Freigegeben----------------------------------------------------------------------------
-- 1837 (1m09s)
/*
select Diff_Freigegeben_firstDiktat as Minutes
from Basis b

*/
--------------------------------------------------------------Qurey:Freigegeben-secondDiktat----------------------------------------------------------------------------
-- 1837(1m09s)
/*
select (Diff_Dik_Freigegeben) as Minutes
from Basis b
*/
--------------------------------------------------------------Qurey:secondDiktat-Mikroskopie----------------------------------------------------------------------------
-- 1837(1m09s)
/*
select (Diff_Mikro_Dik) as Minutes
from Basis b

*/


-----------------------------------Query:to anlage---------------------------------------------------------------------------------------------------
		 
		/* 
select avg(Erfassung_Anlage) as Erfassung_Anlage 
,avg(Diktat_Anlage) as Diktat_Anlage
,avg(Freigegeben_Anlage) as Freigegeben_Anlage
,avg(SecondDiktat_Anlage) as SecondDiktat_Anlage
,avg(Mikro_Anlage) as Mikro_Anlage	
from Basis 
	*/	 
		 