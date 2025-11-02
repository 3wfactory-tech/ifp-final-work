#!/usr/bin/env elixir

# Exemplo de uso do App.Processor com WorkerAggregator

IO.puts("\n=== Exemplo de Uso: Processor com Aggregator ===\n")

# Processando um arquivo CSV
file_path = "../datasets/planilha_202508.csv"

IO.puts("📁 Processando arquivo: #{file_path}\n")

{:ok, aggregated, errors} = App.Processor.run(file_path)

IO.puts("\n📊 Resultados da Agregação:\n")

aggregated
|> Enum.sort_by(fn %{operations_count: count} -> count end, :desc)
|> Enum.each(fn result ->
  risk_emoji = if result.exist_risc == :high, do: "🔴", else: "🟢"
  IO.puts("#{risk_emoji} #{result.person}")
  IO.puts("   Operações: #{result.operations_count}")
  IO.puts("   Risco: #{result.exist_risc}")
  IO.puts("")
end)

IO.puts("\n📈 Estatísticas:\n")

total_operations = Enum.reduce(aggregated, 0, fn %{operations_count: count}, acc -> acc + count end)
high_risk_count = Enum.count(aggregated, fn %{exist_risc: risk} -> risk == :high end)
low_risk_count = Enum.count(aggregated, fn %{exist_risc: risk} -> risk == :low end)

IO.puts("Total de operações: #{total_operations}")
IO.puts("Ocupações com alto risco: #{high_risk_count}")
IO.puts("Ocupações com baixo risco: #{low_risk_count}")
IO.puts("Total de erros: #{length(errors)}")

IO.puts("\n=== Fim do Exemplo ===\n")
