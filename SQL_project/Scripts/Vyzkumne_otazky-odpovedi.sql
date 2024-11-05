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

--  řešení úkolu 2:
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

-- pomocný krok, ve kterém vidím meziroční rozdíl cen v CZK a v procentech:
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

-- řešení č.1 (za pomocí vytvořením VIEW): Rozdíl mezi zdražováním v první a posledním období zjistitím funkcí SUM na sečtení abs.hodnot (růst/pokles v CZK)

CREATE OR REPLACE VIEW v_ukol_3 AS
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
	GROUP BY tpk2.category_name, tpk2.`year`
;

SELECT 
	vu.category_name
--	,tp.value																-- ukazuje nám výchozí hodnotu (cena z roku 2006)
	,SUM (vu.dif_in_CZK) AS dif_sum_in_CZK									-- ukazuje nám rozdíl v ceně (mezi rokem 2006 a 2018)
	,ROUND ((SUM (vu.dif_in_CZK)/tp.value)*100, 2) AS dif_in_percent		-- ukazuje nám rozdíl v ceně v %
FROM v_ukol_3 vu
LEFT JOIN t_pavel_kozak_project_sql_primary_final tp
	ON vu.category_name = tp.category_name
	AND tp.`year`= 2006
	AND description = 'price'
GROUP BY category_name
ORDER BY dif_in_percent
;

/* viz výsledek s využitím view (suma meziročních cenových rozdílů); 
u cukru a rajčat se cena mezi léty 2006 a 2018 dokonce snížila, nejmenší zdražení nastalo u banánů (7,4%),
největší zdražení u másla.
*/

-- řešení č.2 (bez VIEW):
SELECT 
	tpk2.category_name
	,tpk2.value - tpk.value AS dif_in_CZK									-- ukazuje nám rozdíl v ceně (mezi rokem 2006 a 2018)
	,ROUND(((tpk2.value/tpk.value)-1)*100,2) AS dif_in_percent				-- ukazuje nám rozdíl v ceně v %
FROM t_pavel_kozak_project_sql_primary_final tpk
JOIN t_pavel_kozak_project_sql_primary_final tpk2
	ON tpk.`year`=tpk2.`year`-12
	AND tpk.code = tpk2.code
	AND tpk.description = 'price'
GROUP BY tpk2.category_name 
ORDER BY dif_in_percent
;

-- 4. Existuje rok, ve kterém byl meziroční nárůst cen potravin výrazně vyšší než růst mezd (větší než 10 %)?

-- pomocný/kontrolní výpočty pro rozdíl cen mezi lety 2006 a 2007:
SELECT 
	(SELECT SUM (value)
	 FROM t_pavel_kozak_project_sql_primary_final tpk
	 WHERE description = 'price'
	 AND `year` = 2006) AS value_2006
	,(SELECT SUM (value)
	  FROM t_pavel_kozak_project_sql_primary_final tpk
	  WHERE description = 'price'
	  AND `year` = 2007) AS value_2007
	,(1263.43-1183.44) as difference
;

-- vytvoření VIEW pro hodnoty ceny:
CREATE OR REPLACE VIEW v_ukol4_prices AS
	SELECT 
		tpk2.`year`
		,SUM(tpk2.value) - SUM(tpk.value) AS price_dif_in_CZK
		,ROUND(((SUM(tpk2.value)/SUM(tpk.value))-1)*100,2) AS price_dif_in_perc
	FROM t_pavel_kozak_project_sql_primary_final tpk
	JOIN t_pavel_kozak_project_sql_primary_final tpk2
		ON tpk.`year`=tpk2.`year`-1
		AND tpk.code = tpk2.code
		AND tpk.description = 'price'
	GROUP BY tpk2.`year`
;


-- pomocný výpočet pro průměrné mzdy:
SELECT 
	tpk.`year`
	,ROUND(AVG (tpk.value),2) AS AVG_payroll
FROM t_pavel_kozak_project_sql_primary_final tpk
WHERE tpk.description = 'payroll'
	AND tpk.category_name IS NOT NULL
GROUP BY tpk.`year`
; 


-- vytvoření VIEW pro mzdy:
CREATE OR REPLACE VIEW v_ukol4_payrolls AS
	SELECT
		tpk2.`year`
		,ROUND(AVG (tpk2.value) - AVG (tpk.value),2) AS payroll_dif_in_CZK
		,ROUND(((AVG(tpk2.value)/AVG(tpk.value))-1)*100,2) AS payroll_dif_in_perc
	FROM t_pavel_kozak_project_sql_primary_final tpk
	JOIN t_pavel_kozak_project_sql_primary_final tpk2
		ON tpk.`year` = tpk2.`year`-1
		AND tpk.code = tpk2.code
		AND tpk2.category_name IS NOT NULL
	WHERE tpk2.description = 'payroll'
	GROUP BY tpk2.`year`
;

-- řešení úkolu 4:
SELECT 
	vupr.`year`
	,vupr.price_dif_in_perc AS price
	,vupa.payroll_dif_in_perc AS payroll
	,vupr.price_dif_in_perc - vupa.payroll_dif_in_perc AS difference
	,CASE
		WHEN (vupr.price_dif_in_perc - vupa.payroll_dif_in_perc) < -10 THEN 'růst mezd nad 10%'
		WHEN (vupr.price_dif_in_perc - vupa.payroll_dif_in_perc) < -5 THEN 'růst mezd do 10%'
		WHEN (vupr.price_dif_in_perc - vupa.payroll_dif_in_perc) < 0 THEN 'růst mezd do 5%'
		WHEN (vupr.price_dif_in_perc - vupa.payroll_dif_in_perc) > 10 THEN 'růst cen nad 10%'
		WHEN (vupr.price_dif_in_perc - vupa.payroll_dif_in_perc) > 5 THEN 'růst cen do 10%'
		WHEN (vupr.price_dif_in_perc - vupa.payroll_dif_in_perc) > 0 THEN 'růst cen do 5%'
		ELSE 'růst 0%'
	 END AS marking
FROM v_ukol4_prices vupr
JOIN v_ukol4_payrolls vupa
	ON vupr.`year` = vupa.`year`
ORDER BY difference
;

/* Dle výsledku neexistuje výrazně vyšší (větší než 10%) nárůst cen potravin než růst mezd. 
 * Zajímavý z hlediska rozdílu je rok 2009, kdy mzdy rostly výrazněji než ceny potravin (ty v tom roce klesly).
 */

-- 5. Má výška HDP vliv na změny ve mzdách a cenách potravin? Neboli, pokud HDP vzroste výrazněji v jednom roce, 
-- projeví se to na cenách potravin či mzdách ve stejném nebo násdujícím roce výraznějším růstem?

-- řešení úkolu 5:
WITH quest_5 AS (
	SELECT 
		tsf2.country
		,tsf2.`year`
		,ROUND((tsf2.GDP-tsf.GDP)/1000000, 0) AS diffrence_in_mln_USD	-- spíše pro zajímavost o kolik meziročně stoupl/klesl HDP
		,ROUND(((tsf2.GDP/tsf.GDP)-1)*100, 2) AS GDP
		,vupa.payroll_dif_in_CZK
		,vupa.payroll_dif_in_perc AS payroll
		,vupr.price_dif_in_CZK
		,vupr.price_dif_in_perc AS price
	FROM t_pavel_kozak_project_sql_secondary_final tsf
	JOIN t_pavel_kozak_project_sql_secondary_final tsf2
		ON tsf.`year` = tsf2.`year` -1
		AND tsf.country = tsf2.country
		AND tsf.country = 'Czech Republic'	-- volitelné možnosti: 'Czech Republic', 'World', 'European Union', 'Central Europe and the Baltics', 'Germany'
	JOIN v_ukol4_payrolls vupa
		ON tsf2.`year` = vupa.`year`
	JOIN v_ukol4_prices vupr
		ON tsf2.`year` = vupr.`year`
	)
SELECT 
	q5.`year`
	,q5.GDP
	,q5.payroll
	,q5.price
	,CASE								-- pomůžu si přehlednějším znázorněním růstu/poklesu 
		WHEN q5.GDP < -4 THEN '---'
		WHEN q5.GDP < -2 THEN '--'
		WHEN q5.GDP < 0 THEN '-'
		WHEN q5.GDP < 2 THEN '+'
		WHEN q5.GDP < 4 THEN '++'
		WHEN q5.GDP >= 4 THEN '+++'
		ELSE '0'
	END AS GDP_mark
	,CASE								
		WHEN q5.payroll < -4 THEN '---'
		WHEN q5.payroll < -2 THEN '--'
		WHEN q5.payroll < 0 THEN '-'
		WHEN q5.payroll < 2 THEN '+'
		WHEN q5.payroll < 4 THEN '++'
		WHEN q5.payroll >= 4 THEN '+++'
		ELSE '0'
	END AS payroll_mark
	,CASE								
		WHEN q5.price < -4 THEN '---'
		WHEN q5.price < -2 THEN '--'
		WHEN q5.price < 0 THEN '-'
		WHEN q5.price < 2 THEN '+'
		WHEN q5.price < 4 THEN '++'
		WHEN q5.price >= 4 THEN '+++'
		ELSE '0'
	END AS price_mark
FROM quest_5 q5
ORDER BY `year`
;

/* HDP vs. mzdy - Z výše uvedeného vyplývá, že vzrůst HDP na růst mezd má vliv (korelace dle mého názoru existuje). 
				Výjimkou je rok 2009, který byl rokem ekon.krize = možná až překvapivě nedošlo k poklesu mezd, 
				spíše růst mezd pouze zpomalil (znatelné především u mezd v roce 2010) - domnívám se, že na trhu práce 
				došlo spíše ke zvýšení nezaměstnanosti, a díky tomu se udržela úroveň růstu mezd.
 				Poklesu HDP v roce 2012 a 2013 poklesla i mzda ale až v roce 2013. 
 				Dle výše popsaného to vypadá, že vývoj HDP má vliv na mzdy, většinou se tento vliv projeví ve mzdách až
 				v následujícím roce a vývoj mezd není tak výrazný jako u vývoje HDP.
 HDP vs ceny potravin - Výrazný pokles HDP měl vliv na cenu v roce 2009 (ekon.krize, možná pokles poptávky vedl 
 						ke snížení cen potravin), v jiných letech podobné ovlivnění není zřejmé. Na ceny potravin má 
 						spíše větší vliv řada faktorů, např.: úroda/neúroda. vývoj ceny PHM, ceny hnojiv apod.
 						Dle mého názoru vývoj HDP přímo nekoreluje s vývojem cen potravin.

*/
