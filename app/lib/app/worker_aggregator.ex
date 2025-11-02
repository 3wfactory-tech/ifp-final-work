# lib/my_app/aggregator.ex
defmodule App.WorkerAggregator do
  use GenServer

  # --- API Pública ---
  def start_link(_) do
    GenServer.start_link(__MODULE__, %{successful: [], failed: [], aggregated: %{}}, name: __MODULE__)
  end

  @doc """
  Processa os resultados do Task.async_stream, separando sucessos e erros.
  """
  def process_results(results, max_value_risc_card_use) do
    GenServer.call(__MODULE__, {:process_results, results, max_value_risc_card_use}, :infinity)
  end

  @doc """
  Adiciona um registro bem-sucedido ao estado.
  """
  def add_success(record) do
    GenServer.cast(__MODULE__, {:add_success, record})
  end

  @doc """
  Adiciona um erro ao estado.
  """
  def add_error(error) do
    GenServer.cast(__MODULE__, {:add_error, error})
  end

  @doc """
  Retorna o resultado final com agregações.
  """
  def get_result() do
    GenServer.call(__MODULE__, :get_result)
  end

  @doc """
  Reseta o estado do agregador.
  """
  def reset() do
    GenServer.cast(__MODULE__, :reset)
  end

  # --- Callbacks do GenServer ---
  @impl true
  def init(initial_state) do
    IO.puts("--- O Worker Aggregator iniciou! ---")
    {:ok, initial_state}
  end

  @impl true
  def handle_call({:process_results, results, max_value_risc_card_use}, _from, _state) do
    # Separa sucessos e erros
    {successful, failed} =
      results
      |> Enum.reduce({[], []}, fn
        {:ok, {:ok, record}}, {succ, fail} -> {[record | succ], fail}
        {:ok, {:error, reason}}, {succ, fail} -> {succ, [reason | fail]}
        {:exit, reason}, {succ, fail} -> {succ, [reason | fail]}
      end)

    # Agrega por ocupação
    aggregated =
      successful
      |> Enum.reduce(%{}, fn record, acc ->
        Map.update(acc, record.ocupacao, record.numero_de_operacoes, &(&1 + record.numero_de_operacoes))
      end)
      |> analytics_risc_card_use(max_value_risc_card_use)

    new_state = %{
      successful: successful,
      failed: failed,
      aggregated: aggregated
    }

    result = {:ok, aggregated, failed}
    {:reply, result, new_state}
  end

  @impl true
  def handle_call(:get_result, _from, state) do
    {:reply, state, state}
  end

  @impl true
  def handle_cast({:add_success, record}, state) do
    new_successful = [record | state.successful]
    {:noreply, %{state | successful: new_successful}}
  end

  @impl true
  def handle_cast({:add_error, error}, state) do
    new_failed = [error | state.failed]
    {:noreply, %{state | failed: new_failed}}
  end

  @impl true
  def handle_cast(:reset, _state) do
    {:noreply, %{successful: [], failed: [], aggregated: %{}}}
  end

  # --- Funções Privadas ---

  defp analytics_risc_card_use(results, max_value_risc_card_use) do
    Enum.map(results, fn {item, value} ->
      %{
        person: item,
        operations_count: value,
        exist_risc: if(value > max_value_risc_card_use, do: :high, else: :low)
      }
    end)
  end
end
