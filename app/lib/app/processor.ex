defmodule App.Processor do
  alias App.ScrRecord
  alias App.WorkerAggregator

  @doc """
  Processa um arquivo CSV do SCR de forma concorrente.

  ## Parâmetros
  - file_path: Caminho para o arquivo CSV

  ## Retorno
  Tupla com {:ok, agregações, erros}
  """
  def run(file_path) do
    max_value_risc_card_use = 100000
    max_concurrency = System.schedulers_online() * 2
    start_time = :erlang.monotonic_time(:millisecond)

    # Reseta o agregador antes de começar
    WorkerAggregator.reset()

    results =
      file_path
      |> File.stream!() # 1. O LEITOR (Lazy Stream)
      |> Stream.drop(1) # Pula o cabeçalho
      |> Task.async_stream(&process_line(&1), max_concurrency: max_concurrency) # 2. OS WORKERS (Paralelos)
      |> Enum.to_list()

    end_time = :erlang.monotonic_time(:millisecond)

    # O Aggregator processa os resultados
    {:ok, aggregated, failed} = WorkerAggregator.process_results(results, max_value_risc_card_use)

    # Obtém o estado completo para estatísticas
    state = WorkerAggregator.get_result()

    IO.puts("\n=== Resumo do Processamento ===")
    IO.puts("Tempo: #{end_time - start_time} ms")
    IO.puts("Foi utilizado um total de #{max_concurrency} tarefas concorrentes.")
    IO.puts("Registros processados com sucesso: #{length(state.successful)}")
    IO.puts("Registros com erro: #{length(failed)}")
    IO.puts("================================\n")

    {:ok, aggregated, failed}
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
