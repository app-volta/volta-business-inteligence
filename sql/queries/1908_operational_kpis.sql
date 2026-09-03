-- SCRUM-1908: cards de KPIs operacionais.
-- O resultado tem uma linha para alimentar os seis cards do dashboard.
WITH occurrence_kpi AS (
    SELECT
        COUNT(DISTINCT incident_id) AS total_occurrences,
        COALESCE(SUM(estimated_quantity_kg), 0) AS total_estimated_quantity_kg
    FROM bi.mart_occurrences_dashboard
),
collection_kpi AS (
    SELECT
        COUNT(DISTINCT collection_id) AS total_collections,
        COUNT(DISTINCT CASE
            WHEN UPPER(current_status) IN (
                'COMPLETED',
                'DONE',
                'COLLECTED',
                'CONCLUIDA',
                'FINALIZADA',
                'COLETADA'
            )
            THEN collection_id
        END) AS completed_collections,
        AVG(CASE
            WHEN completed_at IS NOT NULL THEN resolution_time_hours
        END) AS avg_resolution_hours
    FROM bi.mart_collection_performance
)
SELECT
    o.total_occurrences,
    o.total_estimated_quantity_kg,
    c.total_collections,
    c.completed_collections,
    ROUND(
        100.0 * c.completed_collections / NULLIF(c.total_collections, 0),
        2
    ) AS completion_rate_pct,
    ROUND(c.avg_resolution_hours, 2) AS avg_resolution_hours
FROM occurrence_kpi AS o
CROSS JOIN collection_kpi AS c;
