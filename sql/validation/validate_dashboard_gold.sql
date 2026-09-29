-- Recalcula os KPIs e a distribuicao horaria da Silver e compara com a Gold.
-- Executar no Databricks SQL Editor; somente leitura, sem filtros do dashboard.
WITH occurrence_detail AS (
    SELECT
        COUNT(DISTINCT incident_id) AS total_occurrences,
        COALESCE(SUM(estimated_quantity_kg), 0) AS estimated_quantity_kg
    FROM workspace.silver.occurrence_clean
),
collection_detail AS (
    SELECT
        COUNT(DISTINCT collection_id) AS total_collections,
        COUNT(DISTINCT CASE
            WHEN is_currently_completed THEN collection_id
        END) AS completed_collections,
        COUNT(DISTINCT CASE
            WHEN has_completion_event AND resolution_time_hours IS NOT NULL
            THEN collection_id
        END) AS resolved_collections_count,
        COALESCE(SUM(CASE
            WHEN has_completion_event AND resolution_time_hours IS NOT NULL
            THEN resolution_time_hours
            ELSE 0
        END), 0) AS resolution_hours_sum
    FROM workspace.silver.collection_clean
),
detail_kpis AS (
    SELECT
        CAST(o.total_occurrences AS DOUBLE) AS total_occurrences,
        CAST(o.estimated_quantity_kg AS DOUBLE) AS estimated_quantity_kg,
        CAST(c.total_collections AS DOUBLE) AS total_collections,
        CAST(c.completed_collections AS DOUBLE) AS completed_collections,
        CAST(100.0 * c.completed_collections
            / NULLIF(c.total_collections, 0) AS DOUBLE) AS completion_rate_pct,
        CAST(c.resolution_hours_sum
            / NULLIF(c.resolved_collections_count, 0) AS DOUBLE)
            AS avg_resolution_hours
    FROM occurrence_detail AS o
    CROSS JOIN collection_detail AS c
),
gold_kpis AS (
    SELECT
        CAST(SUM(total_occurrences) AS DOUBLE) AS total_occurrences,
        CAST(SUM(estimated_quantity_kg) AS DOUBLE) AS estimated_quantity_kg,
        CAST(SUM(total_collections) AS DOUBLE) AS total_collections,
        CAST(SUM(completed_collections) AS DOUBLE) AS completed_collections,
        CAST(100.0 * SUM(completed_collections)
            / NULLIF(SUM(total_collections), 0) AS DOUBLE) AS completion_rate_pct,
        CAST(SUM(resolution_hours_sum)
            / NULLIF(SUM(resolved_collections_count), 0) AS DOUBLE)
            AS avg_resolution_hours
    FROM workspace.gold.operational_kpis
),
kpi_comparison AS (
    SELECT 'total_occurrences' AS metric,
        d.total_occurrences AS detail_value, g.total_occurrences AS gold_value
    FROM detail_kpis AS d CROSS JOIN gold_kpis AS g
    UNION ALL
    SELECT 'estimated_quantity_kg', d.estimated_quantity_kg, g.estimated_quantity_kg
    FROM detail_kpis AS d CROSS JOIN gold_kpis AS g
    UNION ALL
    SELECT 'total_collections', d.total_collections, g.total_collections
    FROM detail_kpis AS d CROSS JOIN gold_kpis AS g
    UNION ALL
    SELECT 'completed_collections', d.completed_collections, g.completed_collections
    FROM detail_kpis AS d CROSS JOIN gold_kpis AS g
    UNION ALL
    SELECT 'completion_rate_pct', d.completion_rate_pct, g.completion_rate_pct
    FROM detail_kpis AS d CROSS JOIN gold_kpis AS g
    UNION ALL
    SELECT 'avg_resolution_hours', d.avg_resolution_hours, g.avg_resolution_hours
    FROM detail_kpis AS d CROSS JOIN gold_kpis AS g
),
hour_detail AS (
    SELECT hour_of_day, COUNT(DISTINCT incident_id) AS occurrence_count
    FROM workspace.silver.occurrence_clean
    GROUP BY hour_of_day
),
hour_gold AS (
    SELECT hour_of_day, SUM(occurrence_count) AS occurrence_count
    FROM workspace.gold.occurrences_by_hour
    GROUP BY hour_of_day
),
hour_comparison AS (
    SELECT
        CASE
            WHEN COALESCE(d.hour_of_day, g.hour_of_day) IS NULL THEN 'hour_null'
            ELSE CONCAT('hour_', CAST(COALESCE(d.hour_of_day, g.hour_of_day) AS STRING))
        END AS metric,
        CAST(COALESCE(d.occurrence_count, 0) AS DOUBLE) AS detail_value,
        CAST(COALESCE(g.occurrence_count, 0) AS DOUBLE) AS gold_value
    FROM hour_detail AS d
    FULL OUTER JOIN hour_gold AS g
        ON d.hour_of_day <=> g.hour_of_day
),
comparison AS (
    SELECT metric, detail_value, gold_value FROM kpi_comparison
    UNION ALL
    SELECT metric, detail_value, gold_value FROM hour_comparison
)
SELECT
    metric,
    detail_value,
    gold_value,
    detail_value - gold_value AS difference,
    CASE
        WHEN ABS(detail_value - gold_value) < 0.000001 THEN 'OK'
        ELSE 'DIVERGENCE'
    END AS validation_status
FROM comparison
ORDER BY metric;
