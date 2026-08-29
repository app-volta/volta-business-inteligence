$ErrorActionPreference = "Stop"

$sqlPath = Join-Path $PSScriptRoot "..\sql\datamart\001_create_bi_star_schema.sql"
$sql = Get-Content -Raw $sqlPath

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

Write-Host "OK: Data Mart SQL validado."
