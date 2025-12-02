# lib/my_app/aggregator.ex
defmodule App.WorkerAggregator do
  use GenServer

  # --- API Pública ---
  # Inicia o GenServer (obrigatório para processos supervisionados)
  def start_link(_) do
    GenServer.start_link(__MODULE__, %{successful: [], failed: [], aggregated: %{}, max_value_risc: 100000}, name: __MODULE__)
  end

  @doc """
  Define o valor máximo de risco para análise.
  """
  # Define o valor máximo de risco (API pública)
  def set_max_value_risc(value) do
    GenServer.cast(__MODULE__, {:set_max_value_risc, value})
  end

  @doc """
  Recebe um resultado de processamento de linha e agrega imediatamente.
  Este é o método principal que será chamado pelo Stream.run().
  """
  # Agrega resultado processado (API pública)
  def tally(result) do
    GenServer.cast(__MODULE__, {:tally, result})
  end

  @doc """
  Retorna o resultado final com agregações e análise de risco.
  """
  # Retorna agregações e análise de risco (API pública)
  def get_result() do
    GenServer.call(__MODULE__, :get_result)
  end

  @doc """
  Retorna estatísticas do processamento.
  """
  # Retorna estatísticas do processamento (API pública)
  def get_stats() do
    GenServer.call(__MODULE__, :get_stats)
  end

  @doc """
  Reseta o estado do agregador.
  """
  # Reseta o estado do agregador (API pública)
  def reset() do
    GenServer.cast(__MODULE__, :reset)
  end

  # --- Callbacks do GenServer ---
  @impl true
  def init(initial_state) do # OBRIGATÓRIO: inicializa o estado do GenServer
    IO.puts("--- O Worker Aggregator iniciou! ---")
    {:ok, initial_state}
  end

  @impl true
  def handle_cast({:set_max_value_risc, value}, state) do # Callback para mensagens assíncronas
    {:noreply, %{state | max_value_risc: value}}
  end

  @impl true
  def handle_cast({:tally, {:ok, record}}, state) do # Callback para agregar sucesso
    new_successful = [record | state.successful]
    new_aggregated =
      Map.update(
        state.aggregated,
        record.ocupacao,
        record.numero_de_operacoes,
        &(&1 + record.numero_de_operacoes)
      )
    {:noreply, %{state | successful: new_successful, aggregated: new_aggregated}}
  end

  @impl true
  def handle_cast({:tally, {:error, reason}}, state) do # Callback para agregar erro
    new_failed = [reason | state.failed]
    {:noreply, %{state | failed: new_failed}}
  end

  @impl true
  def handle_cast(:reset, _state) do # Callback para resetar estado
    {:noreply, %{successful: [], failed: [], aggregated: %{}, max_value_risc: 5000000}}
  end

  @impl true
  def handle_call(:get_result, _from, state) do # OBRIGATÓRIO: callback para requisições síncronas
    aggregated_with_risk = analytics_risc_card_use(state.aggregated, state.max_value_risc)
    result = {:ok, aggregated_with_risk, state.failed}
    {:reply, result, state}
  end

  @impl true
  def handle_call(:get_stats, _from, state) do # Callback para requisições síncronas
    stats = %{
      successful_count: length(state.successful),
      failed_count: length(state.failed),
      occupations_count: map_size(state.aggregated),
      total_operations: Enum.sum(Map.values(state.aggregated))
    }
    {:reply, stats, state}
  end

  # --- Funções Privadas ---

  defp analytics_risc_card_use(aggregated_map, max_value_risc) do
    aggregated_map
    |> Enum.map(fn {occupation, operations_count} ->
      %{
        person: occupation,
        operations_count: operations_count,
        exist_risc: if(operations_count > max_value_risc, do: :high, else: :low)
      }
    end)
    |> Enum.sort_by(& &1.operations_count, :desc)
  end
end
