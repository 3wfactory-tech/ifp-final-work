#!/usr/bin/env elixir

# Exemplo de uso do App.Processor com WorkerAggregator

IO.puts("\n=== Exemplo de Uso: Processor com Aggregator ===\n")

# Processando um arquivo CSV


# Processa todos os arquivos CSV na pasta datasets
dataset_dir = Path.expand("../datasets")
csv_files =
  dataset_dir
  |> File.ls!()
  |> Enum.filter(&String.ends_with?(&1, ".csv"))
  |> Enum.map(&Path.join(dataset_dir, &1))


if csv_files == [] do
  IO.puts("Nenhum arquivo CSV encontrado na pasta datasets.")
else
  total_start = :erlang.monotonic_time(:millisecond)

  # Processamento funcional dos arquivos e acumulação dos totais
  {totals, _} =
    Enum.reduce(csv_files, {%{operations: 0, high_risk: 0, low_risk: 0, errors: 0, lines: 0}, total_start}, fn file_path, {acc, _start_time} ->
      IO.puts("\n📁 Processando arquivo: #{file_path}\n")
      {:ok, aggregated, stats, errors} = App.Processor.run(file_path)

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
      total_errors = length(errors)

      IO.puts("Total de operações: #{total_operations}")
      IO.puts("Ocupações com alto risco: #{high_risk_count}")
      IO.puts("Ocupações com baixo risco: #{low_risk_count}")
      IO.puts("Total de erros: #{total_errors}")
      IO.puts("\n=== Fim do processamento do arquivo ===\n")

      lines_processed = stats[:successful_count] + stats[:failed_count]
      new_acc = %{
        operations: acc.operations + total_operations,
        high_risk: acc.high_risk + high_risk_count,
        low_risk: acc.low_risk + low_risk_count,
        errors: acc.errors + total_errors,
        lines: acc.lines + lines_processed
      }
      {new_acc}
    end)

  total_end = :erlang.monotonic_time(:millisecond)
  total_time = total_end - total_start

  IO.puts("\n=== Resultado Final de Todos os Arquivos ===")
  IO.puts("Total de operações: #{totals.operations}")
  IO.puts("Ocupações com alto risco: #{totals.high_risk}")
  IO.puts("Ocupações com baixo risco: #{totals.low_risk}")
  IO.puts("Total de erros: #{totals.errors}")
  IO.puts("Total de linhas processadas: #{totals.lines}")
  IO.puts("⏱️ Tempo total de processamento de todos os arquivos: #{total_time} ms\n")
end
    # ...existing code...
