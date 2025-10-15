# Visão Geral do Projeto de Análise de Mortalidade Infantil

Este projeto extrai e analisa dados de mortalidade infantil do DATASUS, dividido em três etapas principais.

---

## 📂 Estrutura do Projeto

```
projeto/
│
├── seed/                          # Python - Download e processamento
│   └── download_datasus.py        # Script para criar sim.duckdb
│
└── r_analysis/                    # R - Análise e modelagem
    ├── 1_preparar_dados.R         # Cria mortalidade_infantil.RData
    ├── 2_regressao_linear.R       # Gera análise e gráfico
    └── mortalidade_infantil.RData # Fonte para dataframe usado em análise

---

## 🔄 Fluxo de Trabalho

### **Etapa 1: Criação do Banco de Dados (`sim.duckdb`)**

**Linguagem:** Python  
**Script:** `seed/download_datasus.py`

#### Objetivo
Baixar e processar dados brutos de mortalidade do DATASUS.

#### Processo
1. Baixa arquivos anuais do DATASUS (Sistema de Informações sobre Mortalidade)
2. Processa os dados em lotes para otimizar o uso de memória
3. Insere os dados em um banco de dados `DuckDB`, ajustando a estrutura da tabela dinamicamente para acomodar novos campos

#### Resultado
- **Arquivo gerado:** `sim.duckdb` contendo os dados consolidados de mortalidade

#### Como executar
```bash
cd seed
python download_datasus.py
```

---

### **Etapa 2: Preparação dos Dados de Mortalidade Infantil**

**Linguagem:** R  
**Script:** `r_analysis/1_preparar_dados.R`

#### Objetivo
Extrair e limpar um subconjunto específico de dados focado em mortalidade infantil.

#### Processo
1. Conecta ao banco de dados `sim.duckdb`
2. Filtra registros de mortalidade infantil (menores de 1 ano)
3. Seleciona e transforma variáveis relevantes:
   - `DTOBITO`: Data do óbito
   - `PESO`: Peso ao nascer
   - `SEXO`: Sexo da criança
   - `RACACOR`: Raça/cor
   - `ESCMAE`: Escolaridade da mãe
   - `SEMAGESTAC`: Semanas de gestação
   - `CAUSA_BLOCO`: Causa do óbito agrupada
   - `RAZAOVIVMORT`: Razão de filhos vivos/mortos
   - `IDADE`: Idade no momento do óbito
4. Remove valores inconsistentes e realiza limpeza dos dados
5. Salva o objeto `mortalidade_infantil_limpo`

#### Resultado
- **Arquivo gerado:** `mortalidade_infantil.RData` contendo o objeto `mortalidade_infantil_limpo`

#### Como executar
```r
# IMPORTANTE: Os arquivos devem estar na mesma pasta
setwd("caminho/para/r_analysis")  # Ajuste o caminho conforme necessário
source("1_preparar_dados.R")
```

**Pré-requisito:** O arquivo `sim.duckdb` deve estar na mesma pasta.

---

### **Etapa 3: Análise de Regressão Linear**

**Linguagem:** R  
**Script:** `r_analysis/2_regressao_linear.R`

#### Objetivo
Analisar a mortalidade infantil e criar um modelo preditivo para dias de sobrevivência.

#### Processo
1. Carrega os dados limpos de `mortalidade_infantil.RData`
2. Converte a variável `IDADE` para dias contínuos (`IDADE_DIAS_CONTINUO`)
3. Realiza análise exploratória:
   - Estatísticas descritivas da idade em dias
   - Correlações entre variáveis (PESO, SEMAGESTAC, RAZAOVIVMORT)
4. Divide os dados em conjuntos de treino (80%) e teste (20%)
5. Cria modelo de regressão linear:
   ```
   IDADE_DIAS ~ PESO + SEMAGESTAC + RAZAOVIVMORT + CAUSA_BLOCO + SEXO + RACACOR
   ```
6. Avalia o desempenho do modelo:
   - Coeficientes e p-valores
   - RMSE (erro médio)
   - R² (poder explicativo)
7. Gera gráfico de diagnóstico no RStudio

#### Resultado
- **Output no console:** Tabela de coeficientes, métricas de desempenho
- **Gráfico no RStudio:** Valores reais vs previstos

#### Como executar
```r
# IMPORTANTE: Os arquivos devem estar na mesma pasta
setwd("caminho/para/r_analysis")  # Ajuste o caminho conforme necessário
source("2_regressao_linear.R")
```

**Pré-requisito:** O arquivo `mortalidade_infantil.RData` deve estar na mesma pasta.