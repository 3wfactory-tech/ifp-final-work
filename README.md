# ProcessPayments

A payment processing library that analyzes credit operations data from the Brazilian Central Bank's SCR (Sistema de Informações de Créditos) system.

## Dataset

This project utilizes the **SCR.data** dataset from the Banco Central do Brasil (Central Bank of Brazil), specifically from the Departamento de Monitoramento do Sistema Financeiro.

### Dataset Description
The SCR.data provides monthly aggregated information about credit operations received through the Sistema de Informações de Créditos (SCR). Reports are updated on the last business day of each month, making data available 60 days after the end of each period.

### Key Features
- **Coverage**: Active portfolio and delinquency aggregated data
- **Breakdowns available**:
  - Client type (Individual/PJ - Legal Entity)
  - Credit modality
  - Brazilian states (Unidade da Federação)
  - Economic activity classification (CNAE for PJ)
  - Occupation nature (for individuals)
  - Client size/income
  - Resource origin
  - Operation indexer
- **Time period**: Monthly data from June 2012 onwards
- **Geographic coverage**: Brazil (state-level granularity)
- **Update frequency**: Monthly
- **Format**: CSV files (approximately 700,000 monthly series available)

### Data Source
- **Organization**: Banco Central do Brasil / Departamento de Monitoramento do Sistema Financeiro
- **License**: Open Data Commons Open Database License (ODbL)
- **Contact**: scr.data@bcb.gov.br
- **Portal**: [https://dadosabertos.bcb.gov.br/it/dataset/scr_data](https://dadosabertos.bcb.gov.br/it/dataset/scr_data)

### Important Notes
- Data may differ from other Central Bank publications due to the detailed nature of SCR information
- Monthly CSV files are provided as a temporary solution and may be subject to changes
- For detailed methodology, refer to the official documentation available on the dataset page

## Usage

### Data Processing

The library includes a `ProcessPayments.DataProcessor` module for analyzing SCR data:

```elixir
# Process all CSV files in the datasets directory
result = ProcessPayments.DataProcessor.process_datasets()
# Returns: %{"1" => 4251.55, "2" => 2300.25, "3" => 4001.35}

# Process a specific file
result = ProcessPayments.DataProcessor.process_file("datasets/sample_data.csv")
```

The processor aggregates the `a_vencer_ate_90_dias` (amounts due within 90 days) field grouped by `ocupacao` (occupation).

### Data Format

CSV files should have the following structure:
- First column: `ocupacao` (occupation code)
- Second column: `a_vencer_ate_90_dias` (amount due within 90 days)
- Additional columns are ignored

Example CSV:
```csv
ocupacao,a_vencer_ate_90_dias,modalidade,uf
1,1000.50,1,SP
1,2500.75,2,RJ
2,1500.25,1,MG
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at <https://hexdocs.pm/proccess_payments>.

