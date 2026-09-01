-- SCRUM-1905: distribuicao do tempo de resolucao das coletas.
-- Retorna uma linha por coleta concluida para uso em boxplot.
WITH filters AS (
    SELECT
        NULL::uuid AS company_id,
        NULL::date AS start_date,
        NULL::date AS end_date
)
SELECT
    m.collection_id,
    m.company_id,
    m.company_name,
    m.sector_name,
    m.waste_category,
    m.cooperative_name,
    m.requested_date_key,
    m.requested_at,
    m.completed_at,
    ROUND(m.resolution_time_hours, 2) AS resolution_hours
FROM bi.mart_collection_performance AS m
CROSS JOIN filters AS f
WHERE m.completed_at IS NOT NULL
  AND m.resolution_time_hours IS NOT NULL
  AND (f.company_id IS NULL OR m.company_id = f.company_id)
  AND (f.start_date IS NULL OR m.requested_date_key >= f.start_date)
  AND (f.end_date IS NULL OR m.requested_date_key < f.end_date)
ORDER BY resolution_hours;
