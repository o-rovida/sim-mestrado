# Processador de Dados de Mortalidade

Este projeto baixa, processa e insere dados de mortalidade do Sistema de Informações sobre Mortalidade (SIM) do DATASUS em um banco de dados DuckDB. A principal característica deste sistema é a sua capacidade de se adaptar dinamicamente ao esquema dos dados, criando e alterando tabelas conforme necessário.

## Funcionalidades

- **Download Automatizado**: Baixa os arquivos de dados de mortalidade anuais diretamente do repositório oficial.
- **Processamento em Lotes**: Os dados são lidos e processados em lotes para otimizar o uso de memória.
- **Esquema Dinâmico**: O banco de dados e as tabelas são criados e modificados dinamicamente, adicionando novas colunas conforme novos campos surgem nos dados.

## Como Usar

1.  **Instalar dependências:**
    ```bash
    pip install -r requirements.txt
    ```

2.  **Executar o script:**

    Execute o script a partir do diretório raiz, passando o ano inicial e o ano final como argumentos de linha de comando.

    ```bash
    python src/seed.py <ano_inicial> <ano_final>
    ```

    Por exemplo, para processar os dados de 2020 a 2022:
    ```bash
    python src/seed.py 2020 2022
    ```

    Após a execução, um arquivo chamado `sim.duckdb` será criado, contendo os dados processados.

## Base de Dados Processada

A base de dados resultante de um processamento anterior pode ser encontrada no link abaixo:

[Link para a base de dados](https://drive.google.com/file/d/1mkiu8Ql95D-NCug45APhiTr1hE2eVis0/view?usp=drive_link)