-- SCRUM-1904: evolucao temporal das ocorrencias registradas.
-- Ajuste os valores da CTE filters ou aplique os filtros na ferramenta de BI.
WITH filters AS (
    SELECT
        NULL::uuid AS company_id,
        NULL::date AS start_date,
        NULL::date AS end_date
)
SELECT
    d.date_key,
    COUNT(DISTINCT d.incident_id)::bigint AS occurrence_count,
    COALESCE(SUM(d.estimated_quantity_kg), 0)::numeric AS estimated_quantity_kg
FROM bi.mart_occurrences_dashboard AS d
CROSS JOIN filters AS f
WHERE (f.company_id IS NULL OR d.company_id = f.company_id)
  AND (f.start_date IS NULL OR d.date_key >= f.start_date)
  AND (f.end_date IS NULL OR d.date_key < f.end_date)
GROUP BY d.date_key
ORDER BY d.date_key;
