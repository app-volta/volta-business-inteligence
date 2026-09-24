# Data Mart VOLTA

## Decisao tecnica

O PostgreSQL continua como fonte oficial dos dados operacionais. O projeto
mantém duas rotas analíticas com finalidades diferentes:

1. O Data Mart PostgreSQL no schema `bi`, composto por views para consultas e
   dashboards SQL.
2. A pipeline Lakeflow no Databricks, adicionada para a entrega de ETL
   Bronze–Silver–Gold do SCRUM-1937.

Ambas leem dados derivados do PostgreSQL; a pipeline não grava no banco
transacional. Não trate as duas saídas como uma única tabela física: o
consumidor do dashboard deve escolher uma rota e validar seus indicadores.

## Pipeline Databricks SCRUM-1937

Os notebooks versionados em
`databricks/pipeline/VOLTA - Pipeline BI/transformations/` implementam:

| Camada | Conteúdo |
| --- | --- |
| Bronze | Recortes das tabelas `public` necessárias aos indicadores |
| Silver | Chaves tipadas, texto normalizado, datas locais e status de coleta |
| Gold | Agregações de ocorrências, coletas, cooperativas e KPIs operacionais |

A origem configurada é `volta_postgres.public`. As saídas são explicitamente
qualificadas como `workspace.bronze.*`, `workspace.silver.*` e
`workspace.gold.*`. Alterar o catálogo padrão na UI da pipeline não redireciona
essas tabelas; ao promover os notebooks para outro catálogo/workspace, atualize
os identificadores qualificados.

### Contrato dos KPIs

- `completed_collections`: coletas cujo **status atual** indica conclusão,
  mantendo o significado da query `sql/queries/1908_operational_kpis.sql`.
- `historically_completed_collections`: coletas com ao menos um status de
  conclusão no histórico, mesmo se o status atual tiver sido reaberto; não
  exige que esse evento seja posterior à solicitação.
- `resolution_hours_sum` e `resolved_collections_count`: consideram o primeiro
  evento histórico de conclusão válido após a solicitação, filtrando eventos
  anteriores antes de escolher o primeiro; duração nula ou negativa não entra
  na soma nem no denominador.

Os status reconhecidos para conclusão histórica incluem `COMPLETED`, `DONE`,
`COLLECTED`, `CONCLUIDA`, `FINALIZADA` e `COLETADA`.

Os joins de área preservam `company_id` além de `area_id`, evitando associar
um setor de outra empresa em caso de inconsistência na origem; uma divergência
na origem mantém a ocorrência, mas deixa o setor sem correspondência. A série
`occurrences_over_time` preenche dias zerados no intervalo observado por
empresa e combinação de dimensões; um dashboard que mostre datas fora desse
intervalo deve completar o calendário no visual.

Para validar a pipeline, execute-a no Databricks e confirme as saídas nas três
camadas. O runtime Lakeflow não é validado pelo script local de SQL.

## Grao das facts

| View | Grao |
| --- | --- |
| `bi.fact_incident` | uma linha por ocorrencia registrada |
| `bi.fact_collection` | uma linha por solicitacao de coleta |
| `bi.fact_esg_metric` | uma linha por metrica ESG calculada por periodo |
| `bi.fact_cooperative_review` | uma linha por avaliacao de cooperativa |

## Dimensoes

| View | Uso principal |
| --- | --- |
| `bi.dim_company` | filtro por empresa/tenant |
| `bi.dim_area` | setor, unidade operacional e localizacao textual |
| `bi.dim_waste_type` | categoria de residuo e risco padrao |
| `bi.dim_cooperative` | cooperativas, nota media e coordenadas para mapa |
| `bi.dim_date` | calendario derivado das datas existentes no banco |

## Marts prontos para dashboard

| View | Indicadores suportados |
| --- | --- |
| `bi.mart_occurrences_dashboard` | ocorrencias por setor, categoria, hora, prioridade, status e volume estimado |
| `bi.mart_collection_performance` | tempo de agendamento, tempo de resolucao, urgencia, status de coleta e desempenho por cooperativa |
| `bi.mart_esg_monthly` | residuos totais, reciclados, taxa de reciclagem e variacao mensal |

## Limite conhecido

O schema operacional atual nao possui latitude e longitude da ocorrencia ou da
area industrial. Por isso, o mapa geografico consegue usar coordenadas das
cooperativas e enderecos textuais da empresa/area. Para um mapa exato de
ocorrencias, o backend precisa registrar coordenadas ou uma chave geografica da
planta/setor.

## Evolucao prevista

O próximo passo é definir qual das duas rotas será consumida por cada
dashboard. Se a camada Gold for adotada, mantenha os consumidores alinhados ao
contrato documentado acima e evite recalcular o mesmo KPI com uma definição
diferente na consulta PostgreSQL.

## SCRUM-1903: grafico de barras por setor

Use `bi.mart_occurrences_dashboard` como fonte do visual ou execute a consulta
em `sql/queries/1903_occurrences_by_sector.sql`:

- eixo: `sector_name`;
- valor: contagem de `incident_id`;
- filtros: `company_id`, `date_key`, `status`, `priority` ou `waste_category`;
- tooltip opcional: soma de `estimated_quantity_kg`.

O agrupamento sempre preserva `company_id` e `area_id`, pois o nome do setor
nao e necessariamente unico entre empresas.

## SCRUM-1904: evolucao temporal

Use `sql/queries/1904_occurrences_over_time.sql` para exibir a contagem de
ocorrencias e o volume estimado por `date_key`, mantendo filtros opcionais por
empresa e intervalo de datas.

## SCRUM-1905: boxplot do tempo de resolucao

Use `sql/queries/1905_resolution_time_boxplot.sql` sobre
`bi.mart_collection_performance`. Cada linha representa uma coleta concluida;
use `resolution_hours` como medida do boxplot e `company_name`, `sector_name`
ou `cooperative_name` como agrupamento opcional.

## SCRUM-1906: histograma por hora

Use `sql/queries/1906_occurrences_by_hour.sql` sobre
`bi.mart_occurrences_dashboard`. O campo `registered_at` e convertido de UTC
para `America/Sao_Paulo`; use `hour_of_day` no eixo X e
`occurrence_count` no eixo Y.

## SCRUM-1907: mapa geografico

Use `sql/queries/1907_occurrences_map.sql` sobre
`bi.mart_collection_performance`. Configure `longitude` e `latitude` como o
par de coordenadas, `occurrence_count` como tamanho do marcador e
`cooperative_name` como agrupamento ou tooltip. Como o modelo atual nao possui
coordenadas da ocorrencia ou da area, o ponto representa a cooperativa da
coleta associada.
