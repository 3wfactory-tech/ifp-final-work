defmodule ProcessPayments.DataProcessor do
  @moduledoc """
  Module for processing SCR (Sistema de Informações de Créditos) data files.

  This module reads CSV files from the datasets directory and performs
  aggregations on credit operation data, specifically summing values
  due within 90 days grouped by occupation.
  """

  @datasets_path "../datasets"

  @doc """
  Processes all CSV files in the datasets directory and returns the sum of
  "a_vencer_ate_90_dias" values grouped by "ocupacao" (occupation).

  ## Returns
  A map where keys are occupation codes and values are the total sum
  of amounts due within 90 days for that occupation.
  """
  def process_datasets do
    IO.inspect("Starting dataset processing", label: "ProcessPayments.DataProcessor")
    @datasets_path
    |> list_csv_files()
    |> Enum.reduce(%{}, fn file_path, acc ->
      IO.inspect(file_path, label: "Processing file")
      process_file(file_path, acc)
    end)
    |> tap(&IO.inspect(&1, label: "Final aggregated result"))
  end

  @doc """
  Processes only the specific dataset file: planilha_202508.csv

  ## Returns
  A map with aggregated data from the August 2025 dataset
  """
  def process_single_dataset do
    file_path = Path.join(@datasets_path, "planilha_202508.csv")
    IO.inspect(file_path, label: "Processing single dataset file")

    # Medir recursos antes do processamento
    {cpu_before, memory_before, schedulers_before} = measure_system_resources()

    {time_us, result} = :timer.tc(fn -> process_file(file_path) end)

    # Medir recursos depois do processamento
    {cpu_after, memory_after, schedulers_after} = measure_system_resources()

    # Calcular diferenças
    cpu_used = cpu_after - cpu_before
    memory_used = memory_after - memory_before
    schedulers_used = schedulers_after - schedulers_before

    time_ms = time_us / 1000
    time_s = time_ms / 1000

    IO.inspect("Processing completed in #{time_us} microseconds (#{time_ms} ms / #{time_s} seconds)", label: "Performance")
    IO.inspect("CPU time used: #{cpu_used} microseconds", label: "System Resources")
    IO.inspect("Memory used: #{memory_used} bytes (#{memory_used / 1024 / 1024} MB)", label: "System Resources")
    IO.inspect("Schedulers used: #{schedulers_used}", label: "System Resources")



    result
  end

  @doc """
  Processes a single CSV file and aggregates the data.

  ## Parameters
  - file_path: Path to the CSV file to process
  - accumulator: Current aggregation map

  ## Returns
  Updated aggregation map with data from the file
  """
  def process_file(file_path, accumulator \\ %{}) do
    IO.inspect(file_path, label: "Starting to process file")
    try do
      stream = File.stream!(file_path)

      {first_line, rest_stream} = case Stream.take(stream, 1) |> Enum.to_list() do
        [line] -> {line, Stream.drop(stream, 1)}
        [] -> {nil, stream}
      end

      case first_line do
        nil ->
          IO.inspect("File is empty", label: "ProcessPayments.DataProcessor")
          accumulator
        _ ->
          # Check if first line is header
          is_header = case String.split(first_line, ";") do
            [first_col | _] ->
              case Float.parse(String.trim(first_col)) do
                {_num, _} ->
                  IO.inspect("First line appears to be data (numeric)", label: "Header detection")
                  false  # Numeric, no header
                :error ->
                  IO.inspect("First line appears to be header (text)", label: "Header detection")
                  true      # Text, likely header
              end
            _ ->
              IO.inspect("Unable to determine header, assuming no header", label: "Header detection")
              false
          end

          data_stream = if is_header do
            rest_stream
          else
            Stream.concat([first_line], rest_stream)
          end

          {result, line_count} = Enum.reduce(data_stream, {accumulator, 0}, fn line, {acc, count} ->
            case String.split(String.trim(line), ",") do
              [ocupacao, a_vencer | _rest] ->
                ocupacao_str = String.trim(ocupacao)
                amount = parse_amount(String.trim(a_vencer))

                if ocupacao_str != "" && amount > 0 do
                  new_acc = Map.update(acc, ocupacao_str, amount, &(&1 + amount))
                  {new_acc, count + 1}
                else
                  {acc, count + 1}
                end
              _ ->
                {acc, count + 1}
            end
          end)

          IO.inspect(line_count, label: "Lines processed in file")
          IO.inspect(result, label: "Aggregation result for file")
          result
      end
    rescue
      File.Error ->
        IO.inspect("File not found or cannot be read", label: "File error")
        accumulator
    end
  end

  @doc """
  Lists all CSV files in the datasets directory.

  ## Returns
  List of file paths for CSV files
  """
  def list_csv_files(directory \\ @datasets_path) do
    Path.join(directory, "*.csv")
    |> Path.wildcard()
  end

  # Private functions

  defp parse_amount(nil), do: 0.0
  defp parse_amount(""), do: 0.0
  defp parse_amount(value) when is_binary(value) do
    value
    |> String.replace(",", ".")
    |> String.replace(~r/[^\d.-]/, "")
    |> Float.parse()
    |> case do
      {num, _} -> num
      :error -> 0.0
    end
  end
  defp parse_amount(value) when is_number(value), do: value / 1.0
  defp parse_amount(_), do: 0.0

  @doc """
  Measures system resources: CPU time, memory usage, and scheduler utilization.

  ## Returns
  Tuple with {cpu_time_microseconds, memory_bytes, schedulers_online}
  """
  def measure_system_resources do
    # CPU time in microseconds (runtime + wall clock)
    {total_run_time, _} = :erlang.statistics(:runtime)
    {_, _} = :erlang.statistics(:wall_clock)

    # Memory usage in bytes
    memory_info = :erlang.memory()
    total_memory = memory_info[:total]

    # Number of schedulers online (CPU cores being used)
    schedulers_online = :erlang.system_info(:schedulers_online)

    {total_run_time, total_memory, schedulers_online}
  end
end
