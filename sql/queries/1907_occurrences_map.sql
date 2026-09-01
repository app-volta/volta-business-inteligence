-- SCRUM-1907: mapa das ocorrencias por localizacao da cooperativa.
-- A localizacao representa a cooperativa associada a cada coleta.
WITH filters AS (
    SELECT
        NULL::uuid AS company_id,
        NULL::date AS start_date,
        NULL::date AS end_date
)
SELECT
    m.cooperative_id,
    m.cooperative_name,
    m.latitude,
    m.longitude,
    COUNT(DISTINCT m.incident_id)::bigint AS occurrence_count
FROM bi.mart_collection_performance AS m
CROSS JOIN filters AS f
WHERE (f.company_id IS NULL OR m.company_id = f.company_id)
  AND (f.start_date IS NULL OR m.requested_date_key >= f.start_date)
  AND (f.end_date IS NULL OR m.requested_date_key < f.end_date)
GROUP BY
    m.cooperative_id,
    m.cooperative_name,
    m.latitude,
    m.longitude
ORDER BY occurrence_count DESC, m.cooperative_name;
