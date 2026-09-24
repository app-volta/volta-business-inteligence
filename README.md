# VOLTA Business Intelligence

Repositório da camada de Business Intelligence do VOLTA, com dashboards,
indicadores ESG e análise operacional sobre dados originados no PostgreSQL.

## Escopo

Esta camada não substitui o backend transacional: o PostgreSQL continua sendo a
fonte oficial dos dados. O repositório mantém duas rotas analíticas distintas:
o Data Mart PostgreSQL no schema `bi` e a pipeline Lakeflow no Databricks,
necessária para a entrega de ETL Bronze–Silver–Gold. A pipeline não grava no
banco operacional.

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

Para o boxplot do SCRUM-1905, use a consulta em
`sql/queries/1905_resolution_time_boxplot.sql` sobre
`bi.mart_collection_performance`. O resultado tem uma linha por coleta
concluida e a coluna `resolution_hours` para o eixo numerico.

Para o histograma do SCRUM-1906, use a consulta em
`sql/queries/1906_occurrences_by_hour.sql` sobre
`bi.mart_occurrences_dashboard`. O horario e convertido para
`America/Sao_Paulo` antes da agregacao.

Para o mapa do SCRUM-1907, use a consulta em
`sql/queries/1907_occurrences_map.sql` sobre
`bi.mart_collection_performance`. Os marcadores representam as cooperativas
associadas as ocorrencias e usam `occurrence_count` para o tamanho do ponto.

Para os cards de KPI do SCRUM-1908, use a consulta em
`sql/queries/1908_operational_kpis.sql`. O resultado tem uma linha com os
totais de ocorrencias, volume estimado, coletas, conclusoes, taxa de conclusao
e tempo medio de resolucao. `completed_collections` conta o status atual de
conclusao; no Gold Databricks, `historically_completed_collections` é o
indicador separado para conclusoes que ocorreram em algum momento.

## Pipeline Databricks (SCRUM-1937)

Os notebooks ficam em
`databricks/pipeline/VOLTA - Pipeline BI/transformations/`:

- `01_bronze_volta.ipynb`: recortes das tabelas de origem;
- `02_silver_volta.ipynb`: tipagem, limpeza e datas locais;
- `03_gold_volta.ipynb`: dimensões enriquecidas e agregações para dashboard.

A origem é o catálogo `volta_postgres`, schema `public`. As saídas usam nomes
totalmente qualificados no catálogo `workspace`, schemas `bronze`, `silver` e
`gold`; portanto, os valores padrão de catálogo/esquema da configuração da
pipeline não substituem esses nomes. Em outro workspace, ajuste os nomes
qualificados antes de executar.

No Gold, `completed_collections` segue o contrato do SCRUM-1908 e conta coletas
cujo status atual indica conclusão. `historically_completed_collections` conta
coletas com ao menos um evento histórico de conclusão. O tempo de resolução
usa o primeiro evento histórico válido após a solicitação, filtrando eventos
anteriores antes de escolher o primeiro; durações negativas ou sem horário
válido ficam fora dos cálculos. A conclusão histórica não exige que o evento
seja posterior à solicitação; essa condição vale apenas para a duração.

`occurrences_over_time` inclui dias sem ocorrências como zero entre a primeira
e a última data observada por empresa, para cada combinação de dimensões
observada. Para filtros temporais além desse intervalo, o dashboard deve
completar o calendário no visual.

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
Os notebooks dependem do runtime do Databricks e devem ser validados executando
a pipeline no workspace.
