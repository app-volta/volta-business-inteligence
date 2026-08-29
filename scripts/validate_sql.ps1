$ErrorActionPreference = "Stop"

$sqlPath = Join-Path $PSScriptRoot "..\sql\datamart\001_create_bi_star_schema.sql"
$sql = Get-Content -Raw $sqlPath
$queryPath = Join-Path $PSScriptRoot "..\sql\queries\1903_occurrences_by_sector.sql"
$query = Get-Content -Raw $queryPath

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

Write-Host "OK: Data Mart SQL validado."
