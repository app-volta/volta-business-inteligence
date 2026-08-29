# Data Mart VOLTA

## Decisao tecnica

O Data Mart do BI e implementado como views PostgreSQL no schema `bi`.

Essa escolha reduz custo e complexidade neste momento do projeto:

- nao duplica dados do banco transacional;
- nao exige pipeline Databricks antes do dashboard existir;
- mantem uma camada semantica estavel para Power BI, Metabase, Looker Studio ou
  outra ferramenta escolhida pelo time;
- permite evoluir para tabelas materializadas ou Delta Lake depois, se houver
  volume real que justifique.

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

O proximo passo natural e conectar o dashboard ao schema `bi` e criar os visuais
dos tickets de BI. Databricks so deve entrar se a banca exigir demonstracao de
lakehouse ou se o volume de dados passar a justificar uma camada analitica fora
do PostgreSQL.
