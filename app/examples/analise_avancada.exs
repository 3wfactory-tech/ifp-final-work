#!/usr/bin/env elixir

# Exemplo avançado de análise de dados SCR usando App.ScrRecord

defmodule ScrAnalysis do
  @moduledoc """
  Exemplos avançados de análise de dados SCR.
  """

  @doc """
  Analisa a distribuição de crédito por UF.
  """
  def analyze_by_uf(records) do
    records
    |> Enum.group_by(& &1.uf)
    |> Enum.map(fn {uf, records_list} ->
      {uf, %{
        total_operations: Enum.sum(Enum.map(records_list, & &1.numero_de_operacoes)),
        total_active: Enum.sum(Enum.map(records_list, & &1.carteira_ativa)),
        total_overdue: Enum.sum(Enum.map(records_list, & &1.vencido_acima_de_15_dias)),
        overdue_ratio: calculate_overdue_ratio(records_list)
      }}
    end)
    |> Enum.sort_by(fn {_uf, data} -> data.total_active end, :desc)
  end

  @doc """
  Analisa a distribuição de crédito por modalidade.
  """
  def analyze_by_modality(records) do
    records
    |> Enum.group_by(& &1.modalidade)
    |> Enum.map(fn {modalidade, records_list} ->
      {modalidade, %{
        count: length(records_list),
        total_90_days: Enum.sum(Enum.map(records_list, & &1.a_vencer_ate_90_dias)),
        total_91_360_days: Enum.sum(Enum.map(records_list, & &1.a_vencer_de_91_ate_360_dias)),
        total_active: Enum.sum(Enum.map(records_list, & &1.carteira_ativa))
      }}
    end)
    |> Enum.sort_by(fn {_mod, data} -> data.total_active end, :desc)
  end

  @doc """
  Identifica setores com maior inadimplência.
  """
  def high_default_sectors(records, limit \\ 10) do
    records
    |> Enum.group_by(& &1.cnae_secao)
    |> Enum.map(fn {cnae, records_list} ->
      total_active = Enum.sum(Enum.map(records_list, & &1.carteira_ativa))
      total_overdue = Enum.sum(Enum.map(records_list, & &1.vencido_acima_de_15_dias))

      overdue_ratio = if total_active > 0 do
        (total_overdue / total_active) * 100
      else
        0
      end

      {cnae, %{
        total_active: total_active,
        total_overdue: total_overdue,
        overdue_ratio: overdue_ratio,
        count: length(records_list)
      }}
    end)
    |> Enum.filter(fn {_cnae, data} -> data.total_active > 0 end)
    |> Enum.sort_by(fn {_cnae, data} -> data.overdue_ratio end, :desc)
    |> Enum.take(limit)
  end

  @doc """
  Analisa concentração de risco por cliente e porte.
  """
  def risk_concentration(records) do
    records
    |> Enum.group_by(fn r -> {r.cliente, r.porte} end)
    |> Enum.map(fn {{cliente, porte}, records_list} ->
      {{cliente, porte}, %{
        total_active: Enum.sum(Enum.map(records_list, & &1.carteira_ativa)),
        total_problematic: Enum.sum(Enum.map(records_list, & &1.ativo_problematico)),
        count: length(records_list)
      }}
    end)
    |> Enum.sort_by(fn {_key, data} -> data.total_active end, :desc)
  end

  @doc """
  Estatísticas gerais do portfolio.
  """
  def portfolio_stats(records) do
    total_active = Enum.sum(Enum.map(records, & &1.carteira_ativa))
    total_overdue = Enum.sum(Enum.map(records, & &1.vencido_acima_de_15_dias))
    total_problematic = Enum.sum(Enum.map(records, & &1.ativo_problematico))
    total_operations = Enum.sum(Enum.map(records, & &1.numero_de_operacoes))

    %{
      total_records: length(records),
      total_operations: total_operations,
      total_active_portfolio: total_active,
      total_overdue: total_overdue,
      total_problematic_assets: total_problematic,
      overdue_ratio: if(total_active > 0, do: (total_overdue / total_active) * 100, else: 0),
      problematic_ratio: if(total_active > 0, do: (total_problematic / total_active) * 100, else: 0),
      avg_operation_size: if(total_operations > 0, do: total_active / total_operations, else: 0)
    }
  end

  @doc """
  Analisa maturidade da carteira (distribuição por prazo).
  """
  def maturity_analysis(records) do
    total_90 = Enum.sum(Enum.map(records, & &1.a_vencer_ate_90_dias))
    total_91_360 = Enum.sum(Enum.map(records, & &1.a_vencer_de_91_ate_360_dias))
    total_361_1080 = Enum.sum(Enum.map(records, & &1.a_vencer_de_361_ate_1080_dias))
    total_1081_1800 = Enum.sum(Enum.map(records, & &1.a_vencer_de_1081_ate_1800_dias))
    total_1801_5400 = Enum.sum(Enum.map(records, & &1.a_vencer_de_1801_ate_5400_dias))
    total_above_5400 = Enum.sum(Enum.map(records, & &1.a_vencer_acima_de_5400_dias))

    total = total_90 + total_91_360 + total_361_1080 + total_1081_1800 + total_1801_5400 + total_above_5400

    %{
      up_to_90_days: %{amount: total_90, percentage: percentage(total_90, total)},
      from_91_to_360_days: %{amount: total_91_360, percentage: percentage(total_91_360, total)},
      from_361_to_1080_days: %{amount: total_361_1080, percentage: percentage(total_361_1080, total)},
      from_1081_to_1800_days: %{amount: total_1081_1800, percentage: percentage(total_1081_1800, total)},
      from_1801_to_5400_days: %{amount: total_1801_5400, percentage: percentage(total_1801_5400, total)},
      above_5400_days: %{amount: total_above_5400, percentage: percentage(total_above_5400, total)},
      total: total
    }
  end

  # Funções auxiliares privadas

  defp calculate_overdue_ratio(records) do
    total_active = Enum.sum(Enum.map(records, & &1.carteira_ativa))
    total_overdue = Enum.sum(Enum.map(records, & &1.vencido_acima_de_15_dias))

    if total_active > 0 do
      (total_overdue / total_active) * 100
    else
      0
    end
  end

  defp percentage(value, total) do
    if total > 0, do: (value / total) * 100, else: 0
  end

  # Funções de formatação

  def format_currency(value) do
    "R$ #{:erlang.float_to_binary(value, decimals: 2)}"
  end

  def format_percentage(value) do
    "#{:erlang.float_to_binary(value, decimals: 2)}%"
  end

  # Função de exemplo para demonstração
  def demo do
    IO.puts("\n=== Demonstração de Análise SCR ===\n")

    # Criar alguns registros de exemplo
    line1 = "2025-08-31;SP;Bancário;S1;PJ;PJ - Comércio;\"-\";\"-\";PJ - Médio;PJ - Capital de giro;Sem destinação específica;Prefixado;100;1000000,00;500000,00;200000,00;100000,00;50000,00;0,00;50000,00;1900000,00;30000,00;20000,00"
    line2 = "2025-08-31;RJ;Bancário;S2;PF;PF - Empregado;\"-\";\"-\";PF - Acima de 10 salários;PF - Empréstimo pessoal;Sem destinação específica;Pós-fixado;50;200000,00;100000,00;50000,00;0,00;0,00;0,00;10000,00;360000,00;8000,00;5000,00"

    {:ok, record1} = App.ScrRecord.from_csv_line(line1)
    {:ok, record2} = App.ScrRecord.from_csv_line(line2)

    records = [record1, record2]

    # Análise geral
    stats = portfolio_stats(records)
    IO.puts("=== Estatísticas Gerais ===")
    IO.puts("Total de registros: #{stats.total_records}")
    IO.puts("Total de operações: #{stats.total_operations}")
    IO.puts("Carteira ativa: #{format_currency(stats.total_active_portfolio)}")
    IO.puts("Total vencido: #{format_currency(stats.total_overdue)}")
    IO.puts("Taxa de inadimplência: #{format_percentage(stats.overdue_ratio)}")
    IO.puts("Tamanho médio da operação: #{format_currency(stats.avg_operation_size)}")

    # Análise de maturidade
    IO.puts("\n=== Análise de Maturidade ===")
    maturity = maturity_analysis(records)
    IO.puts("Até 90 dias: #{format_currency(maturity.up_to_90_days.amount)} (#{format_percentage(maturity.up_to_90_days.percentage)})")
    IO.puts("91-360 dias: #{format_currency(maturity.from_91_to_360_days.amount)} (#{format_percentage(maturity.from_91_to_360_days.percentage)})")

    # Análise por UF
    IO.puts("\n=== Análise por UF ===")
    by_uf = analyze_by_uf(records)
    Enum.each(by_uf, fn {uf, data} ->
      IO.puts("#{uf}: #{format_currency(data.total_active)} (#{data.total_operations} operações)")
    end)

    IO.puts("\n=== Fim da Demonstração ===\n")
  end
end

# Executar demonstração
ScrAnalysis.demo()
