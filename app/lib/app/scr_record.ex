defmodule App.ScrRecord do
  @moduledoc """
  Estrutura de dados que representa uma linha do arquivo SCR (Sistema de Informações de Créditos).
  """

  @type t :: %__MODULE__{
          data_base: Date.t() | nil,
          uf: String.t(),
          tcb: String.t(),
          sr: String.t(),
          cliente: String.t(),
          ocupacao: String.t(),
          cnae_secao: String.t(),
          cnae_subclasse: String.t(),
          porte: String.t(),
          modalidade: String.t(),
          origem: String.t(),
          indexador: String.t(),
          numero_de_operacoes: integer(),
          a_vencer_ate_90_dias: float(),
          a_vencer_de_91_ate_360_dias: float(),
          a_vencer_de_361_ate_1080_dias: float(),
          a_vencer_de_1081_ate_1800_dias: float(),
          a_vencer_de_1801_ate_5400_dias: float(),
          a_vencer_acima_de_5400_dias: float(),
          vencido_acima_de_15_dias: float(),
          carteira_ativa: float(),
          carteira_inadimplida_arrastada: float(),
          ativo_problematico: float()
        }

  defstruct [
    :data_base,
    :uf,
    :tcb,
    :sr,
    :cliente,
    :ocupacao,
    :cnae_secao,
    :cnae_subclasse,
    :porte,
    :modalidade,
    :origem,
    :indexador,
    :numero_de_operacoes,
    :a_vencer_ate_90_dias,
    :a_vencer_de_91_ate_360_dias,
    :a_vencer_de_361_ate_1080_dias,
    :a_vencer_de_1081_ate_1800_dias,
    :a_vencer_de_1801_ate_5400_dias,
    :a_vencer_acima_de_5400_dias,
    :vencido_acima_de_15_dias,
    :carteira_ativa,
    :carteira_inadimplida_arrastada,
    :ativo_problematico
  ]

  @doc """
  Converte uma linha CSV em uma struct ScrRecord.

  ## Parâmetros
  - line: String contendo uma linha do CSV separada por ponto e vírgula

  ## Retorno
  - {:ok, %ScrRecord{}} em caso de sucesso
  - {:error, reason} em caso de erro

  ## Exemplos

      iex> line = "2025-08-31;AC;Bancário;S1;PF;PF - Aposentado/pensionista;\\"-\\";\\"-\\";PF - Acima de 20 salários mínimos;PF - Cartão de crédito;Sem destinação específica;Prefixado;650;4747872,59;1283843,16;45522,24;25,11;60,16;14595,34;246746,80;6338665,40;202126,07;377748,91"
      iex> App.ScrRecord.from_csv_line(line)
      {:ok, %App.ScrRecord{uf: "AC", tcb: "Bancário", ...}}
  """
  def from_csv_line(line) when is_binary(line) do
    try do
      fields = String.split(String.trim(line), ";")

      if length(fields) < 23 do
        {:error, :insufficient_fields}
      else
        record = %__MODULE__{
          data_base: parse_date(Enum.at(fields, 0)),
          uf: clean_string(Enum.at(fields, 1)),
          tcb: clean_string(Enum.at(fields, 2)),
          sr: clean_string(Enum.at(fields, 3)),
          cliente: clean_string(Enum.at(fields, 4)),
          ocupacao: clean_string(Enum.at(fields, 5)),
          cnae_secao: clean_string(Enum.at(fields, 6)),
          cnae_subclasse: clean_string(Enum.at(fields, 7)),
          porte: clean_string(Enum.at(fields, 8)),
          modalidade: clean_string(Enum.at(fields, 9)),
          origem: clean_string(Enum.at(fields, 10)),
          indexador: clean_string(Enum.at(fields, 11)),
          numero_de_operacoes: parse_integer(Enum.at(fields, 12)),
          a_vencer_ate_90_dias: parse_float(Enum.at(fields, 13)),
          a_vencer_de_91_ate_360_dias: parse_float(Enum.at(fields, 14)),
          a_vencer_de_361_ate_1080_dias: parse_float(Enum.at(fields, 15)),
          a_vencer_de_1081_ate_1800_dias: parse_float(Enum.at(fields, 16)),
          a_vencer_de_1801_ate_5400_dias: parse_float(Enum.at(fields, 17)),
          a_vencer_acima_de_5400_dias: parse_float(Enum.at(fields, 18)),
          vencido_acima_de_15_dias: parse_float(Enum.at(fields, 19)),
          carteira_ativa: parse_float(Enum.at(fields, 20)),
          carteira_inadimplida_arrastada: parse_float(Enum.at(fields, 21)),
          ativo_problematico: parse_float(Enum.at(fields, 22))
        }

        {:ok, record}
      end
    rescue
      e -> {:error, {:parse_error, e}}
    end
  end

  # Funções auxiliares de parsing

  defp parse_date(nil), do: nil
  defp parse_date(""), do: nil

  defp parse_date(date_string) do
    case Date.from_iso8601(date_string) do
      {:ok, date} -> date
      {:error, _} -> nil
    end
  end

  defp parse_integer(nil), do: 0
  defp parse_integer(""), do: 0

  defp parse_integer(value) when is_binary(value) do
    value
    |> String.trim()
    |> String.replace(",", "")
    |> String.replace(".", "")
    |> Integer.parse()
    |> case do
      {num, _} -> num
      :error -> 0
    end
  end

  defp parse_float(nil), do: 0.0
  defp parse_float(""), do: 0.0

  defp parse_float(value) when is_binary(value) do
    value
    |> String.trim()
    |> String.replace(",", ".")
    |> Float.parse()
    |> case do
      {num, _} -> num
      :error -> 0.0
    end
  end

  defp clean_string(nil), do: ""
  defp clean_string(value) when is_binary(value) do
    value
    |> String.trim()
    |> String.replace(~r/^"|"$/, "")
  end
end
