# App.ScrRecord - Processamento de Dados SCR

## Estrutura de Dados

A `App.ScrRecord` é uma struct Elixir que representa uma linha do arquivo CSV do Sistema de Informações de Créditos (SCR) do Banco Central do Brasil.

### Campos da Struct

```elixir
%App.ScrRecord{
  data_base: Date.t() | nil,              # Data base dos dados
  uf: String.t(),                          # Unidade Federativa
  tcb: String.t(),                         # Tipo de Controle Bancário
  sr: String.t(),                          # Segmento de Risco
  cliente: String.t(),                     # Tipo de Cliente (PF/PJ)
  ocupacao: String.t(),                    # Ocupação do cliente
  cnae_secao: String.t(),                  # Seção CNAE
  cnae_subclasse: String.t(),              # Subclasse CNAE
  porte: String.t(),                       # Porte da empresa/renda
  modalidade: String.t(),                  # Modalidade de crédito
  origem: String.t(),                      # Origem do recurso
  indexador: String.t(),                   # Indexador da operação
  numero_de_operacoes: integer(),          # Quantidade de operações
  a_vencer_ate_90_dias: float(),           # Valor a vencer até 90 dias
  a_vencer_de_91_ate_360_dias: float(),    # Valor a vencer de 91 a 360 dias
  a_vencer_de_361_ate_1080_dias: float(),  # Valor a vencer de 361 a 1080 dias
  a_vencer_de_1081_ate_1800_dias: float(), # Valor a vencer de 1081 a 1800 dias
  a_vencer_de_1801_ate_5400_dias: float(), # Valor a vencer de 1801 a 5400 dias
  a_vencer_acima_de_5400_dias: float(),    # Valor a vencer acima de 5400 dias
  vencido_acima_de_15_dias: float(),       # Valor vencido há mais de 15 dias
  carteira_ativa: float(),                 # Total da carteira ativa
  carteira_inadimplida_arrastada: float(), # Carteira inadimplida arrastada
  ativo_problematico: float()              # Valor de ativos problemáticos
}
```

## Uso Básico

### 1. Converter uma linha CSV em struct

```elixir
line = "2025-08-31;AC;Bancário;S1;PF;PF - Aposentado/pensionista;\"-\";\"-\";PF - Acima de 20 salários mínimos;PF - Cartão de crédito;Sem destinação específica;Prefixado;650;4747872,59;1283843,16;45522,24;25,11;60,16;14595,34;246746,80;6338665,40;202126,07;377748,91"

{:ok, record} = App.ScrRecord.from_csv_line(line)
```

### 2. Processar um arquivo inteiro

```elixir
{:ok, records, errors} = App.Processor.run("caminho/para/arquivo.csv")

IO.puts("Registros processados: #{length(records)}")
IO.puts("Erros encontrados: #{length(errors)}")
```

### 3. Acessar campos do registro

```elixir
IO.puts("UF: #{record.uf}")
IO.puts("Ocupação: #{record.ocupacao}")
IO.puts("Carteira ativa: R$ #{record.carteira_ativa}")
```

## Exemplos de Análise

### Agregar por Ocupação

```elixir
agregados = App.Processor.aggregate_by_occupation(records)

# Exibe as ocupações com maior volume
agregados
|> Enum.sort_by(fn {_ocupacao, data} -> data.total_a_vencer_ate_90_dias end, :desc)
|> Enum.take(10)
|> Enum.each(fn {ocupacao, data} ->
  IO.puts("#{ocupacao}: R$ #{data.total_a_vencer_ate_90_dias}")
end)
```

### Filtrar por UF

```elixir
records_sp = Enum.filter(records, fn r -> r.uf == "SP" end)
IO.puts("Registros de São Paulo: #{length(records_sp)}")
```

### Calcular Total da Carteira Ativa

```elixir
total = Enum.reduce(records, 0.0, fn r, acc -> acc + r.carteira_ativa end)
IO.puts("Total da carteira ativa: R$ #{:erlang.float_to_binary(total, decimals: 2)}")
```

### Agrupar por Modalidade

```elixir
por_modalidade = 
  records
  |> Enum.group_by(& &1.modalidade)
  |> Enum.map(fn {modalidade, lista} ->
    {modalidade, %{
      count: length(lista),
      total: Enum.reduce(lista, 0.0, fn r, acc -> acc + r.carteira_ativa end)
    }}
  end)
  |> Enum.into(%{})
```

### Encontrar Registros com Inadimplência

```elixir
inadimplentes = 
  records
  |> Enum.filter(fn r -> r.vencido_acima_de_15_dias > 0 end)
  |> Enum.sort_by(& &1.vencido_acima_de_15_dias, :desc)
```

## Vantagens da Abordagem

1. **Type Safety**: Uso de structs tipadas garante segurança de tipos
2. **Documentação Clara**: Cada campo tem documentação com @type
3. **Parsing Robusto**: Tratamento de erros e valores vazios
4. **Facilidade de Uso**: API simples e intuitiva
5. **Performance**: Processamento concorrente com Task.async_stream

## Testes

Execute os testes com:

```bash
mix test test/app/scr_record_test.exs
```

## Exemplo Completo

Veja o arquivo `examples/uso_scr_record.exs` para um exemplo completo de uso.
