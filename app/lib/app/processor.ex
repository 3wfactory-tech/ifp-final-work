defmodule App.Processor do
  alias App.ScrRecord
  alias App.WorkerAggregator

  @doc """
  Processa um arquivo CSV do SCR de forma concorrente usando o padrão Stream-Task-Aggregator.

  Os resultados são enviados para o WorkerAggregator à medida que ficam prontos,
  sem precisar carregar tudo na memória.

  ## Parâmetros
  - file_path: Caminho para o arquivo CSV
  - options: Opções opcionais
    - :max_value_risc - Valor máximo para análise de risco (padrão: 100000)
    - :max_concurrency - Máximo de tarefas concorrentes (padrão: System.schedulers_online() * 2)

  ## Retorno
  Tupla com {:ok, agregações, erros}
  """
  def run(file_path, options \\ []) do
    max_value_risc_card_use = Keyword.get(options, :max_value_risc, 1000000)
    max_concurrency = Keyword.get(options, :max_concurrency, System.schedulers_online() * 3)

    start_time = :erlang.monotonic_time(:millisecond)

    # Reseta e configura o agregador antes de começar
    WorkerAggregator.reset()
    WorkerAggregator.set_max_value_risc(max_value_risc_card_use)

    # Processa o arquivo usando Stream.each para enviar resultados imediatamente ao agregador
    file_path
    |> File.stream!() # 1. O LEITOR (Lazy Stream)
    |> Stream.drop(1) # Pula o cabeçalho
    |> Task.async_stream(&process_line(&1), max_concurrency: max_concurrency) # 2. OS WORKERS (Paralelos)
    |> Stream.each(fn result -> # permite executar uma ação para cada elemento de uma stream, sem modificar os elementos.
      # 3. O AGREGADOR (GenServer) recebe cada resultado assim que fica pronto
      case result do
        {:ok, {:ok, record}} ->
          WorkerAggregator.tally({:ok, record})
        {:ok, {:error, reason}} ->
          WorkerAggregator.tally({:error, reason})
        {:exit, reason} ->
          WorkerAggregator.tally({:error, {:exit, reason}})
      end
    end)
    |> Stream.run()

    end_time = :erlang.monotonic_time(:millisecond)

    # Obtém o resultado final do agregador
    {:ok, aggregated, failed} = WorkerAggregator.get_result()
    stats = WorkerAggregator.get_stats()

    IO.puts("\n=== Resumo do Processamento (Stream-Task-Aggregator) ===")
    IO.puts("Tempo: #{end_time - start_time} ms")
    IO.puts("Tarefas concorrentes: #{max_concurrency}")
    IO.puts("Registros processados: #{stats.successful_count}")
    IO.puts("Registros com erro: #{stats.failed_count}")
    IO.puts("Ocupações únicas: #{stats.occupations_count}")
    IO.puts("Total de operações: #{stats.total_operations}")
    IO.puts("========================================================\n")

    {:ok, aggregated, stats, failed}
  end

  # Processa uma linha CSV e retorna um ScrRecord.
  defp process_line(line) do
    ScrRecord.from_csv_line(line)
  end
end
