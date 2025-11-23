Projeto final da disciplina de introdução a programação funcional do PPGCA - UTFPR

Universidade: UTFPR
Programa: PPGCA
Aluno: Wilton Ribeiro Silva
Prof: Dr. Adolfo Neto
Ano: 2025
Introdução
O artigo Functional Programming in Financial Markets (Experience Report) apresenta um relato de experiência sobre a aplicação da programação funcional (PF) tipada em larga escala no Standard Chartered Bank, onde a linguagem Haskell — e seu dialeto proprietário, Mu — constitui a biblioteca de software central que suporta toda a divisão de Mercados. 
Esta divisão gera bilhões de dólares em receita e utiliza programação funcional em todo o seu stack de tecnologia, incluindo APIs, serviços server-side e GUIs (interfaces) para milhares de usuários.
Uso de PF na Orquestração de Fluxos de Trabalho, o foco principal do artigo é a utilização da PF para orquestrar fluxos de trabalho (workflows) de precificação em grande escala orientados por tipos.
Este artigo apresenta o resultado da  implementação simplificada do uso de programação funcional para o processamento de alto volume de dados em análise de transações bancárias.
Foi utilizado como data sets de arquivos no formato csv. Os arquivos csv são arquivos de texto com estrutura de cabeçalho na primeira linha sendo que cada coluna é separado por uma vírgula.
Foi utilizado um dataset público para o desenvolvimento do estudo, extraído do Banco Central do Brasil , especificamente  do Departamento de Monitoramento do Sistema Financeiro. Cada arquivo do dataset possuí quase 1 milhão de linhas, sendo necessário um grande poder de processamento para ler essa quantidade de linhas do arquivo. Os arquivos estão disponíveis no repositório publico https://dadosabertos.bcb.gov.br/it/dataset/scr_data e no repositório publico do github desse projeto que pode ser acessado nesse link: https://github.com/3wfactory-tech/ifp-final-work.	
O data set compõem dos seguintes dados: 


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

Foi um pipeline de análise de risco de transações. Para cada linha do dataset, o sistema executará um workflow de regras de análise (ex: número de transações durante o mês). Este pipeline será inspirado na arquitetura QuickRisk do artigo, onde regras podem ser executadas em paralelo e ter dependências, demonstrando a capacidade da PF de orquestrar tarefas complexas.

O campo de ocupação será usado como identificador único para agrupar as informações sendo equivalente a identificação de uma pessoa, ex: PF - Aposentado/pensionista seria igual a uma pessoa física e PF - MEI uma pessoa jurídica.

Implementação

Para a implementação do código fonte foi escolhida a linguagem de programação Elixir devido ser uma linguagem estudada durante o semestre na matéria de Introdução à Programação Funcional, sendo assim tendo plena possibilidade de implementar os conceitos de programação funcional necessários para a atividade. Também foi utilizado para gerir as dependências o gerenciador de pacote mix do próprio Elixir. 

Foi configurando dentro do arquivo mix.exs para usar somente versões iquais ou superiores ao Exilir 1.19.

Para desenvolver e executar a aplicação foram utilizados a IDE VS Code coma extensão ElixirLS: Elixir support and debugger for VS Code e como inteligência artificial para auxiliar no desenvolvimento foi utilizado o Github Copilot. 

Devido ao volume de dados a serem processados também será utilizado os seguintes recursos da linguagem:

Stream: Técnica utilizada para processamento de arquivos com a capacidade de processar uma quantidade limitada de linhas ou de bytes sem alocar todos os dados na memória, possibilitando processar um grande volume de dados sem consumir muito hardware.

Task.async_stream:  função do módulo Task que possibilita processar uma Stream configurando um número fixo de processamento concorrentes possibilitando o uso máximo de poder de processamento para processadores multicore.

Supervisor: Será utilizado para garantir a resiliência do nosso pipeline. O Supervisor principal irá monitorar os processos críticos, como o Agregador, garantindo que, se ele falhar, seja reiniciado automaticamente, preservando a integridade da aplicação, assim como a árvore de supervisão descrita no artigo garante a robustez dos serviços.

GenServer: Será implementado como um processo Agregador de resultados. Devido ao processamento paralelo de milhões de linhas via Task.async_stream, centenas de tasks tentarão atualizar o estado final (ex: a contagem total) simultaneamente. O GenServer atuará como um "guardião" desse estado, serializando as atualizações e prevenindo condições de corrida (race conditions), garantindo a consistência dos dados de forma atômica.

Código Fonte
O projeto que foi criado para armazenar esse código fonte está hospedado no github e pode ser acessado no seguinte repositório: https://github.com/3wfactory-tech/ifp-final-work
O código é simples e pequeno com o objetio de apenas demonstrar a implementação.
Foram criado 5 Módulos e cada um terá uma responsabilidade.

Móudlo App.Application. 
Módulo App.Processor
Módulo App.ScrRecord
App.WorkerAggregator
App.WorkerReadFile

Este módulo terá como responsabilidade navegar pelo systema de arquivos e fazer a leitura do ou dos arquivos utilizando a técnica Stream para processar os arquivos sob demanda.

defmodule App.Processor do
  alias App.ScrRecord
  alias App.WorkerAggregator

  def run(file_path) do
    max_value_risc_card_use = 100000
    max_concurrency = System.schedulers_online() * 2
    start_time = :erlang.monotonic_time(:millisecond)

    WorkerAggregator.reset()

    
results =
      file_path
      |> File.stream!()
      |> Stream.drop(1)
      |> Task.async_stream(&process_line(&1), max_concurrency: max_concurrency) 
      |> Enum.to_list()

    end_time = :erlang.monotonic_time(:millisecond)

    {:ok, aggregated, failed} = WorkerAggregator.process_results(results, max_value_risc_card_use)

    state = WorkerAggregator.get_result()

    IO.puts("\n=== Resumo do Processamento ===")
    IO.puts("Tempo: #{end_time - start_time} ms")
    IO.puts("Foi utilizado um total de #{max_concurrency} tarefas concorrentes.")
    IO.puts("Registros processados com sucesso: #{length(state.successful)}")
    IO.puts("Registros com erro: #{length(failed)}")

    {:ok, aggregated, failed}
  end

  defp process_line(line) do
    ScrRecord.from_csv_line(line)
  end

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


