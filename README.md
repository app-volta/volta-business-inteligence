# VOLTA Business Intelligence

Repositório da camada de Business Intelligence do VOLTA, focada em dashboards,
indicadores ESG e análise operacional sobre o banco PostgreSQL do projeto.

## Escopo

Esta camada não substitui o backend transacional. O banco relacional continua
sendo a fonte oficial dos dados. O BI consome esses dados por meio de um Data
Mart em Star Schema exposto no schema `bi`, com views próprias para dashboards.

## Data Mart

O arquivo principal é:

- `sql/datamart/001_create_bi_star_schema.sql`

Ele cria o schema `bi` e as views:

- `bi.dim_company`
- `bi.dim_area`
- `bi.dim_waste_type`
- `bi.dim_cooperative`
- `bi.dim_date`
- `bi.fact_incident`
- `bi.fact_collection`
- `bi.fact_esg_metric`
- `bi.fact_cooperative_review`
- `bi.mart_occurrences_dashboard`
- `bi.mart_collection_performance`
- `bi.mart_esg_monthly`

Essas views atendem a base dos tickets de BI: ocorrencias por setor, evolucao
temporal, tempo de resolucao, histograma por hora, mapa geografico, cards de
KPI, filtros e drill-down.

Para o grafico de barras do SCRUM-1903, use a consulta em
`sql/queries/1903_occurrences_by_sector.sql` sobre
`bi.mart_occurrences_dashboard`.

## Como aplicar

1. Configure a string do PostgreSQL remoto:

   ```powershell
   Copy-Item .env.example .env
   ```

2. Preencha `DATABASE_URL` no `.env`.

3. Execute o script no banco do projeto:

   ```powershell
   psql "$env:DATABASE_URL" -f sql/datamart/001_create_bi_star_schema.sql
   ```

4. Conecte a ferramenta de BI no PostgreSQL e selecione as views do schema
   `bi`.

## Validacao local

Sem precisar acessar o banco, rode:

```powershell
powershell -ExecutionPolicy Bypass -File scripts/validate_sql.ps1
```

Essa validacao confere propriedades basicas do SQL versionado antes de abrir PR.
