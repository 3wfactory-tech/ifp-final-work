defmodule ProcessPaymentsHandler do
  @moduledoc """
  Documentation for `ProcessPayments`.
  """

  @doc """
  Hello world.

  ## Examples

      iex> ProcessPayments.hello()
      :world

  """
  def handler do

    IO.inspect("Handler called", label: "ProcessPayments.Handler")
    ProcessPayments.DataProcessor.list_csv_files("datasets")
    |> Enum.reduce(%{}, fn file_path, acc ->
      IO.inspect(file_path, label: "Processing file")
      ProcessPayments.DataProcessor.process_file(file_path, acc)
    end)
    |> tap(&IO.inspect(&1, label: "Final aggregated result"))
  end
end
