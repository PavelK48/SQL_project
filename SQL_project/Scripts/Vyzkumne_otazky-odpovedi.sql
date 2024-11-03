-- 1. Rostou v průběhu let mzdy ve všech odvětvích, nebo v některých klesají?
-- řešení:
WITH quest1_final AS (
		SELECT 
			tp2.year
			,tp2.category_name
			,tp2.value - tp1.value AS diff
		FROM t_pavel_kozak_project_sql_primary_final tp1
		JOIN t_pavel_kozak_project_sql_primary_final tp2
			ON tp1.year = tp2.year -1
			AND tp1.code = tp2.code
			AND tp2.description = 'payroll'
			AND tp2.category_name IS NOT null
		)
SELECT
	year
	,category_name AS industry_branch_name
	,ROUND (diff, 0) AS decrease_amount
FROM quest1_final
WHERE diff < 0
;

/*Výsledek nám dává roky a odvětví, v kterých mzda poklesla.
V případě zadání opačného znaménka ">" nám výsledek ukáže roky a odvětví,
ve kterých mzda rostla. */



-- 2. Kolik je možné si koupit litrů mléka a kilogramů chleba za první a poslední srovnatelné období v dostupných datech cen a mezd?
 
-- pomocný výpočet
/*
SELECT *
FROM t_pavel_kozak_project_sql_primary_final tpk
WHERE `year` IN (2006,2018)	
	AND category_name IS NULL
;

SELECT *
FROM t_pavel_kozak_project_sql_primary_final tpk
WHERE `year` IN (2006,2018)
	AND code IN ('114201', '111301')
	OR category_name IS NULL
	AND `year` IN (2006,2018)
;
*/

--  řešení:
SELECT 
	tpk.`year`
	, tpk.category_name
	, ROUND (tpk2.value/tpk.value, 2) AS result
FROM t_pavel_kozak_project_sql_primary_final tpk
JOIN t_pavel_kozak_project_sql_primary_final tpk2
ON tpk.`year`=tpk2.`year`
	AND tpk.`year` IN (2006,2018)
	AND tpk.code IN ('114201', '111301', 'NULL')
	AND tpk2.category_name IS NULL
;

-- Výsledné řešení ukazuje sloupeček "result", který nám říká kolik litrů mléka a kilogramů chleba si můžeme v letech 2006 a 2018 koupit.

-- Variantní řešení otázky č.2 za pomocí vnořeného selectu, ovšem není uplně přehledné. Mohlo by sloužit k případnému porovnání mezi těmito roky.
 SELECT `year`
	, category_name
	,value	
	,ROUND ((SELECT value
	  FROM t_pavel_kozak_project_sql_primary_final tpk
	  WHERE `year` = 2006	
			AND category_name IS NULL)/value, 2) AS avg_2006
	,ROUND ((SELECT value
	  FROM t_pavel_kozak_project_sql_primary_final tpk
	  WHERE `year` = 2018	
			AND category_name IS NULL)/value, 2) AS avg_2018
FROM t_pavel_kozak_project_sql_primary_final tpk
WHERE `year` IN (2006,2018)
	AND code IN ('114201', '111301')
;



-- 3. Která kategorie potravin zdražuje nejpomaleji (je u ní nejnižší percentuální meziroční nárůst)?

-- meziroční rozdíl cen:
SELECT 
	tpk2.`year`
	,tpk2.category_name
	,tpk2.value - tpk.value AS dif_in_CZK
	,ROUND(((tpk2.value/tpk.value)-1)*100,2) AS dif_in_perc
FROM t_pavel_kozak_project_sql_primary_final tpk
JOIN t_pavel_kozak_project_sql_primary_final tpk2
	ON tpk.`year`=tpk2.`year`-1
	AND tpk.code = tpk2.code
	AND tpk.description = 'price'
--	AND tpk2.`year` = 2007
--	AND tpk.category_name = 'Eidamská cihla'
GROUP BY tpk2.category_name, tpk2.`year`
-- ORDER BY tpk.category_name, tpk2.`year`
;
