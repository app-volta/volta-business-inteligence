-- SCRUM-1903: dados do grafico de barras de ocorrencias por setor.
-- Ajuste os valores da CTE filters ou aplique os filtros na ferramenta de BI.
WITH filters AS (
    SELECT
        NULL::uuid AS company_id,
        NULL::date AS start_date,
        NULL::date AS end_date
)
SELECT
    d.company_id,
    d.company_name,
    d.area_id,
    d.sector_name,
    COUNT(DISTINCT d.incident_id)::bigint AS occurrence_count,
    COALESCE(SUM(d.estimated_quantity_kg), 0)::numeric AS estimated_quantity_kg
FROM bi.mart_occurrences_dashboard AS d
CROSS JOIN filters AS f
WHERE (f.company_id IS NULL OR d.company_id = f.company_id)
  AND (f.start_date IS NULL OR d.date_key >= f.start_date)
  AND (f.end_date IS NULL OR d.date_key < f.end_date)
GROUP BY
    d.company_id,
    d.company_name,
    d.area_id,
    d.sector_name
ORDER BY occurrence_count DESC, d.sector_name;
