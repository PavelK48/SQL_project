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
