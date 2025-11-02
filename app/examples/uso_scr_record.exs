# Exemplo de uso do App.Processor com ScrRecord

# 1. Processando um arquivo CSV
# {:ok, records, errors} = App.Processor.run("../datasets/planilha_202508.csv")

# 2. Acessando dados de um registro
# record = List.first(records)
# IO.inspect(record.ocupacao)
# IO.inspect(record.a_vencer_ate_90_dias)
# IO.inspect(record.data_base)

# 3. Filtrando registros por UF
# records_ac = Enum.filter(records, fn r -> r.uf == "AC" end)

# 4. Agregando por ocupação
# agregados = App.Processor.aggregate_by_occupation(records)
# IO.inspect(agregados)

# 5. Calculando estatísticas
# total_carteira_ativa = Enum.reduce(records, 0.0, fn r, acc -> acc + r.carteira_ativa end)
# IO.puts("Total da carteira ativa: R$ #{:erlang.float_to_binary(total_carteira_ativa, decimals: 2)}")

# 6. Agrupando por modalidade
# por_modalidade = Enum.group_by(records, & &1.modalidade)
# Enum.each(por_modalidade, fn {modalidade, lista} ->
#   IO.puts("#{modalidade}: #{length(lista)} registros")
# end)

# 7. Exemplo de processamento de uma linha única
line = "2025-08-31;AC;Bancário;S1;PF;PF - Aposentado/pensionista;\"-\";\"-\";PF - Acima de 20 salários mínimos;PF - Cartão de crédito;Sem destinação específica;Prefixado;650;4747872,59;1283843,16;45522,24;25,11;60,16;14595,34;246746,80;6338665,40;202126,07;377748,91"

case App.ScrRecord.from_csv_line(line) do
  {:ok, record} ->
    IO.puts("\n=== Registro SCR ===")
    IO.puts("UF: #{record.uf}")
    IO.puts("TCB: #{record.tcb}")
    IO.puts("Cliente: #{record.cliente}")
    IO.puts("Ocupação: #{record.ocupacao}")
    IO.puts("Modalidade: #{record.modalidade}")
    IO.puts("Número de operações: #{record.numero_de_operacoes}")
    IO.puts("A vencer até 90 dias: R$ #{:erlang.float_to_binary(record.a_vencer_ate_90_dias, decimals: 2)}")
    IO.puts("Carteira ativa: R$ #{:erlang.float_to_binary(record.carteira_ativa, decimals: 2)}")
    IO.puts("Data base: #{record.data_base}")
    IO.puts("===================\n")

  {:error, reason} ->
    IO.puts("Erro ao processar linha: #{inspect(reason)}")
end
