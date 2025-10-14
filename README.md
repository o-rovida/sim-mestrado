# Visão Geral do Projeto de Análise de Mortalidade

Este projeto extrai e analisa dados de mortalidade do DATASUS.

### `seed` (Python)

- **Objetivo**: Baixar e processar dados brutos de mortalidade.
- **Processo**:
    1.  Baixa arquivos anuais do DATASUS.
    2.  Processa os dados em lotes para otimizar o uso de memória.
    3.  Insere os dados em um banco de dados `DuckDB`, ajustando a estrutura da tabela dinamicamente para acomodar novos campos.
- **Resultado**: Um arquivo `sim.duckdb` contendo os dados consolidados.

### `r_analysis` (R)

- **Objetivo**: Analisar a mortalidade infantil a partir dos dados processados.
- **Processo**:
    1.  Carrega e limpa um subconjunto de dados focado em mortalidade infantil.
    2.  Realiza uma análise de correlação entre variáveis como peso, idade gestacional e dias de vida.
    3.  Cria um modelo de regressão linear para prever a idade do óbito (em dias).
    4.  Avalia o modelo e analisa a distribuição dos resíduos.
    5.  Compara as médias de dias de vida entre diferentes grupos (causa do óbito, sexo, raça/cor) com testes de significância.