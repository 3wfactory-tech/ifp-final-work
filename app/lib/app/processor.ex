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
    |> Stream.each(fn result ->
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
    # data_base;uf;tcb;sr;cliente;ocupacao;cnae_secao;cnae_subclasse;porte;modalidade;origem;indexador;numero_de_operacoes;a_vencer_ate_90_dias;a_vencer_de_91_ate_360_dias;a_vencer_de_361_ate_1080_dias;a_vencer_de_1081_ate_1800_dias;a_vencer_de_1801_ate_5400_dias;a_vencer_acima_de_5400_dias;vencido_acima_de_15_dias;carteira_ativa;carteira_inadimplida_arrastada;ativo_problematico
    # 2025-08-31;AC;Bancário;S1;PF;PF - Aposentado/pensionista;"-";"-";PF - Acima de 20 salários mínimos            ;PF - Cartão de crédito;Sem destinação específica;Prefixado;650;4747872,59;1283843,16;45522,24;25,11;60,16;14595,34;246746,80;6338665,40;202126,07;377748,91

    ScrRecord.from_csv_line(line)
  end

  @doc """
  Exemplo de como agregar dados por ocupação.

  ## Parâmetros
  - records: Lista de %ScrRecord{}

  ## Retorno
  Mapa com totais agregados por ocupação
  """
  def aggregate_by_occupation(records) do
    records
    |> Enum.group_by(& &1.ocupacao)
    |> Enum.map(fn {ocupacao, records_list} ->
      total_90_dias =
        records_list
        |> Enum.map(& &1.a_vencer_ate_90_dias)
        |> Enum.sum()

      {ocupacao, %{
        count: length(records_list),
        total_a_vencer_ate_90_dias: total_90_dias
      }}
    end)
    |> Enum.into(%{})
  end
end
