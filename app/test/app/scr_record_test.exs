defmodule App.ScrRecordTest do
  use ExUnit.Case
  alias App.ScrRecord

  describe "from_csv_line/1" do
    test "converte uma linha CSV válida em ScrRecord" do
      line = "2025-08-31;AC;Bancário;S1;PF;PF - Aposentado/pensionista;\"-\";\"-\";PF - Acima de 20 salários mínimos;PF - Cartão de crédito;Sem destinação específica;Prefixado;650;4747872,59;1283843,16;45522,24;25,11;60,16;14595,34;246746,80;6338665,40;202126,07;377748,91"

      assert {:ok, record} = ScrRecord.from_csv_line(line)
      assert record.uf == "AC"
      assert record.tcb == "Bancário"
      assert record.sr == "S1"
      assert record.cliente == "PF"
      assert record.ocupacao == "PF - Aposentado/pensionista"
      assert record.numero_de_operacoes == 650
      assert_in_delta record.a_vencer_ate_90_dias, 4_747_872.59, 0.01
      assert_in_delta record.carteira_ativa, 6_338_665.40, 0.01
    end

    test "retorna erro para linha com campos insuficientes" do
      line = "2025-08-31;AC;Bancário"

      assert {:error, :insufficient_fields} = ScrRecord.from_csv_line(line)
    end

    test "trata valores vazios corretamente" do
      line = "2025-08-31;AC;Bancário;S1;PF;PF - Aposentado/pensionista;\"-\";\"-\";PF - Acima de 20 salários mínimos;PF - Cartão de crédito;Sem destinação específica;Prefixado;;;;;;;;;;;"

      assert {:ok, record} = ScrRecord.from_csv_line(line)
      assert record.numero_de_operacoes == 0
      assert record.a_vencer_ate_90_dias == 0.0
    end

    test "limpa strings com aspas" do
      line = "2025-08-31;AC;\"Bancário\";S1;PF;PF - Aposentado/pensionista;\"-\";\"-\";PF - Acima de 20 salários mínimos;PF - Cartão de crédito;Sem destinação específica;Prefixado;650;4747872,59;1283843,16;45522,24;25,11;60,16;14595,34;246746,80;6338665,40;202126,07;377748,91"

      assert {:ok, record} = ScrRecord.from_csv_line(line)
      assert record.tcb == "Bancário"
    end

    test "converte data corretamente" do
      line = "2025-08-31;AC;Bancário;S1;PF;PF - Aposentado/pensionista;\"-\";\"-\";PF - Acima de 20 salários mínimos;PF - Cartão de crédito;Sem destinação específica;Prefixado;650;4747872,59;1283843,16;45522,24;25,11;60,16;14595,34;246746,80;6338665,40;202126,07;377748,91"

      assert {:ok, record} = ScrRecord.from_csv_line(line)
      assert record.data_base == ~D[2025-08-31]
    end
  end
end
