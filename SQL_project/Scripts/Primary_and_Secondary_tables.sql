-- vytvoření tabulky SQL_primary:


-- tímto vytvářím view pro ceny:
CREATE OR REPLACE VIEW v_prices_draft AS
	SELECT 
		YEAR(date_from) AS `year`
		,cpc.code AS code
		,cpc.name AS category_name
		,ROUND (AVG(cp.value), 2) AS value
		,'price' AS description
	FROM czechia_price cp
	JOIN czechia_price_category cpc
		ON cp.category_code = cpc.code
		AND cp.region_code IS NULL
		AND cpc.name <> 'Jakostní víno bílé'
	GROUP BY `year`, cpc.name
;

-- tímto tvořím view pro mzdy:
CREATE OR REPLACE VIEW v_payrolls_draft AS
	SELECT 
		payroll_year AS `year`
		,COALESCE (cpib.code, 'AVG') AS code  -- pro snadnější použití vyplním NULL ve sloupci code
		,cpib.name AS category_name
		,ROUND(AVG(cp.value), 2) AS value
		,'payroll' AS description
	FROM czechia_payroll cp
	LEFT JOIN czechia_payroll_industry_branch cpib
		ON cp.industry_branch_code = cpib.code
	WHERE value_type_code = 5958
	GROUP BY industry_branch_code, payroll_year
;

CREATE OR REPLACE TABLE t_pavel_kozak_project_SQL_primary_final AS
	SELECT *
	FROM v_payrolls_draft vpd
UNION
	SELECT *
	FROM v_prices_draft vpd2
	WHERE `year` >= 2006
		AND `year` <= 2018	-- sjednocení na stejné roky
;

-- rychlý náhled do tabulky primary_final:
SELECT *
FROM t_pavel_kozak_project_sql_primary_final tpk;

-- následují pomocné a kontrolní výpočty k vytvoření tabulky primary final:
-- příprava dat czechia price
SELECT 
	ROUND (AVG(cp.value), 2) AS price
	,category_code
	,cpc.name AS category_name
	,YEAR(date_from) AS YEAR
	,cp.region_code
FROM czechia_price cp
JOIN czechia_price_category cpc
	ON cp.category_code = cpc.code
	AND cp.region_code IS NULL
GROUP BY year, category_code
;

-- kontrola správnosti a kontrolní výpočty:
SELECT 
	cpc.name AS category_name
	,COUNT (*)
FROM czechia_price cp
JOIN czechia_price_category cpc
	ON cp.category_code = cpc.code
WHERE region_code IS NULL
GROUP BY category_code
;

-- jakostní víno bíle - záznamy pouze v letech 2016-2018!!! (nezahrnuji do tabulky,
-- tento produkt není sledován po celé období, ovlivnil by tak negativně výsledky)
SELECT 
	ROUND (AVG(cp.value), 2) AS price
	,category_code
	,cpc.name AS category_name
	,YEAR(date_from) AS year
FROM czechia_price cp
JOIN czechia_price_category cpc
	ON cp.category_code = cpc.code
WHERE region_code IS NULL
AND category_code = 212101
GROUP BY YEAR
;


-- kapr živý - každoročně sezonní prodej, 19 záznamů, (dle mého názoru se jedná o relevantní údaj,
-- proto jej zahrnuji do finální tabulky)
SELECT 
	ROUND (AVG(cp.value), 2) AS price
	,category_code
	,cpc.name AS category_name
	,YEAR(date_from) AS YEAR
	,MONTH(date_from) AS month
FROM czechia_price cp
JOIN czechia_price_category cpc
	ON cp.category_code = cpc.code
WHERE region_code IS NULL
AND category_code = 2000001
GROUP BY YEAR, MONTH
;

-- očištěná tabulka czechia price (bez jakostního vína), bez regionu, bez kódu kategorie, pozn.: v datech roky 2006-2018
SELECT 
	ROUND (AVG(cp.value), 2) AS value
	,cpc.code AS code
	,cpc.name AS category_name
	,YEAR(date_from) AS `year`
FROM czechia_price cp
JOIN czechia_price_category cpc
	ON cp.category_code = cpc.code
	AND cp.region_code IS NULL
	AND cpc.name <> 'Jakostní víno bílé'
GROUP BY `year`, cpc.name
;

-- ověření správnosti dat czechia payroll - počet řádků odpovídá, v roce 2021 
-- pouze 4 záznamy, ovšem ty se ve tab. primary final nevyskytují
SELECT 
	cpib.name AS branch
	,COUNT (*)
	,payroll_year
	,cp.value_type_code
FROM czechia_payroll cp
LEFT JOIN czechia_payroll_industry_branch cpib
ON cp.industry_branch_code = cpib.code
WHERE cp.value_type_code = 5958
GROUP BY industry_branch_code /*, payroll_year*/
;

-- ověření průměru mezd NULL vs odvětví - hodnoty se nerovnají. Předpokládám, že je chyba již ve zdrojových datech.
WITH average_payroll AS 
			(SELECT 
				ROUND (AVG (value),2) AS payroll
				,payroll_year
			FROM czechia_payroll cp
			WHERE value_type_code = 5958
			AND industry_branch_code IS NOT NULL
			GROUP BY payroll_year),
	AVG_null AS
			(SELECT
				ROUND (AVG (value),2) AS payroll
				,payroll_year
			FROM czechia_payroll cp
			WHERE value_type_code = 5958
			AND industry_branch_code IS NULL
			GROUP BY payroll_year)
SELECT
	ap.payroll_year
	,ap.payroll-an.payroll AS diff
FROM average_payroll ap
JOIN AVG_null an
ON ap.payroll_year = an.payroll_year
;

-- vytvoření tabulky SQL_secondary_final:

-- zjisťuji jaké oblasti zemí se vyskytují ve zdrojové tabulce, které by mne mohly zajímat? 
-- (mimo evropské země bych vybral Central Europe and the Baltics?, European Union, World?)
SELECT DISTINCT
country
FROM economies e
;

-- vytvořím si seznam evropských zemí, abych tyto země mohl vyfiltrovat z economies:
SELECT DISTINCT
	country
	,continent
FROM countries c
WHERE continent = 'Europe'
;

-- vyberu data pomocí JOIN (data na continent Europe) a přes UNION sjednotím s vybranými daty jako je svět, EU, apod. 
-- Pro vytvoření tabulky omezím na společné roky 2006-2018 (stejně jako v tabulky primary_final).

CREATE OR REPLACE TABLE t_pavel_kozak_project_SQL_secondary_final AS
	SELECT
		e.country
		, e.`year`
		, ROUND (e.GDP, 0) AS GDP
	FROM economies e
	JOIN countries c
	ON e.country = c.country
		AND c.continent = 'Europe'
		AND e.`year` >= 2006
		AND e.`year` <= 2018
	UNION
	SELECT
		e2.country
		, e2.`year`
		, ROUND (e2.GDP, 0) AS GDP
	FROM economies e2
	WHERE e2.country IN ('European Union', 'Central Europe and the Baltics', 'World')
		AND e2.`year` >= 2006
		AND e2.`year` <= 2018
;

SELECT *
FROM t_pavel_kozak_project_sql_secondary_final tpk2
;