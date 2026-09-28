# Reconciliação do dashboard com a camada Gold

## Execução

- Data: 28/09/2026
- Ambiente: workspace de desenvolvimento, catálogo `workspace`
- Método: consulta somente de leitura que recalcula indicadores a partir das
  tabelas de detalhe Silver e compara o resultado com as agregações Gold.
- Escopo: sem filtros de dashboard; não houve execução do Job nem refresh da
  pipeline durante a conferência.
- Consulta reproduzível:
  [`sql/validation/validate_dashboard_gold.sql`](../sql/validation/validate_dashboard_gold.sql)

## Resultado

As seis métricas dos cards tiveram diferença zero entre o cálculo sobre Silver
e o agregado Gold:

| Métrica | Silver | Gold | Diferença |
| --- | ---: | ---: | ---: |
| Ocorrências | 100 | 100 | 0 |
| Volume estimado (kg) | 48.419,72 | 48.419,72 | 0 |
| Coletas | 80 | 80 | 0 |
| Coletas concluídas | 38 | 38 | 0 |
| Taxa de conclusão (%) | 47,5 | 47,5 | 0 |
| Tempo médio de resolução (h) | 34,7 | 34,7 | 0 |

As 24 faixas de `hour_of_day` também tiveram diferença zero. As horas 0 e
21–23 registraram 5 ocorrências cada; as horas 1–20 registraram 4 cada. A soma
das faixas é 100 ocorrências.

## Limites

Esta conferência valida a agregação de Silver para Gold no estado observado em
28/09/2026. Não reconcilia a Silver com o PostgreSQL operacional e não comprova
que os dados permanecerão iguais após novas cargas. A consulta retorna as
comparações para conferência manual; o CI valida estaticamente os artefatos e
não acessa o workspace Databricks.
