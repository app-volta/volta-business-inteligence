-- SCRUM-1904: evolucao temporal das ocorrencias registradas.
-- Ajuste os valores da CTE filters ou aplique os filtros na ferramenta de BI.
WITH filters AS (
    SELECT
        NULL::uuid AS company_id,
        NULL::date AS start_date,
        NULL::date AS end_date
)
SELECT
    dd.date_key,
    COUNT(DISTINCT d.incident_id)::bigint AS occurrence_count,
    COALESCE(SUM(d.estimated_quantity_kg), 0)::numeric AS estimated_quantity_kg
FROM bi.dim_date AS dd
CROSS JOIN filters AS f
LEFT JOIN bi.mart_occurrences_dashboard AS d
    ON d.date_key = dd.date_key
   AND (f.company_id IS NULL OR d.company_id = f.company_id)
WHERE (f.start_date IS NULL OR dd.date_key >= f.start_date)
  AND (f.end_date IS NULL OR dd.date_key < f.end_date)
GROUP BY dd.date_key
ORDER BY dd.date_key;
