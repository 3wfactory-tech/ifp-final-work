defmodule App.WorkerReadFile do
  use GenServer

  # API Pública
  def start_link(opts) do
    # Damos um nome ao processo para encontrá-lo facilmente
    GenServer.start_link(__MODULE__, opts, name: :my_worker)
  end

  # Callbacks do GenServer
  @impl true
  def init(_opts) do
    IO.puts("--- O Worker Read Files iniciou! ---")
    {:ok, %{}} # O estado inicial é um mapa vazio
  end
end
