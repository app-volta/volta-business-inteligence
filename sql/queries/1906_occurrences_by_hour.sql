-- SCRUM-1906: histograma de ocorrencias por hora no fuso de Sao Paulo.
-- Retorna uma linha por hora com ocorrencias registradas.
WITH filters AS (
    SELECT
        NULL::uuid AS company_id,
        NULL::date AS start_date,
        NULL::date AS end_date
), occurrences_by_hour AS (
    SELECT
        EXTRACT(
            HOUR FROM ((d.registered_at AT TIME ZONE 'UTC')
                       AT TIME ZONE 'America/Sao_Paulo')
        )::int AS hour_of_day,
        COUNT(DISTINCT d.incident_id)::bigint AS occurrence_count
    FROM bi.mart_occurrences_dashboard AS d
    CROSS JOIN filters AS f
    WHERE (f.company_id IS NULL OR d.company_id = f.company_id)
      AND (f.start_date IS NULL OR d.date_key >= f.start_date)
      AND (f.end_date IS NULL OR d.date_key < f.end_date)
    GROUP BY hour_of_day
)
SELECT
    hour_of_day,
    occurrence_count
FROM occurrences_by_hour
ORDER BY hour_of_day;
