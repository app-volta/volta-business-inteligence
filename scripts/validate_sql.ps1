$ErrorActionPreference = "Stop"

$sqlPath = Join-Path $PSScriptRoot "..\sql\datamart\001_create_bi_star_schema.sql"
$sql = Get-Content -Raw $sqlPath
$queryPath = Join-Path $PSScriptRoot "..\sql\queries\1903_occurrences_by_sector.sql"
$query = Get-Content -Raw $queryPath
$query1904Path = Join-Path $PSScriptRoot "..\sql\queries\1904_occurrences_over_time.sql"
$query1904 = Get-Content -Raw $query1904Path
$query1905Path = Join-Path $PSScriptRoot "..\sql\queries\1905_resolution_time_boxplot.sql"
$query1905 = Get-Content -Raw $query1905Path
$query1906Path = Join-Path $PSScriptRoot "..\sql\queries\1906_occurrences_by_hour.sql"
$query1906 = Get-Content -Raw $query1906Path
$query1907Path = Join-Path $PSScriptRoot "..\sql\queries\1907_occurrences_map.sql"
$query1907 = Get-Content -Raw $query1907Path
$query1908Path = Join-Path $PSScriptRoot "..\sql\queries\1908_operational_kpis.sql"
$query1908 = Get-Content -Raw $query1908Path

$required = @(
    "CREATE SCHEMA IF NOT EXISTS bi",
    "CREATE OR REPLACE VIEW bi.dim_company",
    "CREATE OR REPLACE VIEW bi.dim_area",
    "CREATE OR REPLACE VIEW bi.dim_waste_type",
    "CREATE OR REPLACE VIEW bi.dim_cooperative",
    "CREATE OR REPLACE VIEW bi.dim_date",
    "CREATE OR REPLACE VIEW bi.fact_incident",
    "CREATE OR REPLACE VIEW bi.fact_collection",
    "CREATE OR REPLACE VIEW bi.fact_esg_metric",
    "CREATE OR REPLACE VIEW bi.fact_cooperative_review",
    "CREATE OR REPLACE VIEW bi.mart_occurrences_dashboard",
    "CREATE OR REPLACE VIEW bi.mart_collection_performance",
    "CREATE OR REPLACE VIEW bi.mart_esg_monthly"
)

foreach ($needle in $required) {
    if (-not $sql.Contains($needle)) {
        throw "SQL obrigatorio nao encontrado: $needle"
    }
}

$openParens = ([regex]::Matches($sql, "\(")).Count
$closeParens = ([regex]::Matches($sql, "\)")).Count

if ($openParens -ne $closeParens) {
    throw "Parenteses desbalanceados no SQL: $openParens abertos, $closeParens fechados"
}

foreach ($needle in @(
    "FROM bi.mart_occurrences_dashboard AS d",
    "COUNT(DISTINCT d.incident_id)",
    "GROUP BY"
)) {
    if (-not $query.Contains($needle)) {
        throw "Consulta do SCRUM-1903 invalida: $needle"
    }
}

foreach ($needle in @(
    "FROM bi.dim_date AS dd",
    "LEFT JOIN bi.mart_occurrences_dashboard AS d",
    "COUNT(DISTINCT d.incident_id)",
    "dd.date_key",
    "GROUP BY dd.date_key",
    "ORDER BY dd.date_key"
)) {
    if (-not $query1904.Contains($needle)) {
        throw "Consulta do SCRUM-1904 invalida: $needle"
    }
}

foreach ($needle in @(
    "FROM bi.mart_collection_performance AS m",
    "m.completed_at IS NOT NULL",
    "m.resolution_time_hours IS NOT NULL",
    "resolution_hours",
    "ORDER BY resolution_hours"
)) {
    if (-not $query1905.Contains($needle)) {
        throw "Consulta do SCRUM-1905 invalida: $needle"
    }
}

foreach ($needle in @(
    "FROM bi.mart_occurrences_dashboard AS d",
    "America/Sao_Paulo",
    "hour_of_day",
    "occurrence_count",
    "ORDER BY hour_of_day"
)) {
    if (-not $query1906.Contains($needle)) {
        throw "Consulta do SCRUM-1906 invalida: $needle"
    }
}

foreach ($needle in @(
    "FROM bi.mart_collection_performance AS m",
    "m.latitude",
    "m.longitude",
    "occurrence_count",
    "GROUP BY",
    "ORDER BY occurrence_count"
)) {
    if (-not $query1907.Contains($needle)) {
        throw "Consulta do SCRUM-1907 invalida: $needle"
    }
}

foreach ($needle in @(
    "FROM bi.mart_occurrences_dashboard",
    "FROM bi.mart_collection_performance",
    "total_occurrences",
    "total_collections",
    "completion_rate_pct",
    "avg_resolution_hours"
)) {
    if (-not $query1908.Contains($needle)) {
        throw "Consulta do SCRUM-1908 invalida: $needle"
    }
}

Write-Host "OK: Data Mart SQL validado."
