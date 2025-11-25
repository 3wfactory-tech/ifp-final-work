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



### Módulo App.Application

Este módulo é responsável por iniciar a aplicação e supervisionar os processos críticos. Utiliza o padrão OTP Supervisor, garantindo resiliência e reinicialização automática dos workers em caso de falha. Os workers supervisionados são:

- `App.WorkerReadFile`: responsável pela leitura dos arquivos.
- `App.WorkerAggregator`: responsável pela agregação dos resultados.

```elixir
defmodule App.Application do
  use Application

  @impl true
  def start(_type, _args) do
    children = [
      {App.WorkerReadFile, %{}},
      {App.WorkerAggregator, %{}},
    ]
    opts = [strategy: :one_for_one, name: App.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
```

---

### Módulo App.WorkerReadFile

Este módulo implementa um GenServer simples, que pode ser expandido para gerenciar o estado da leitura dos arquivos. Inicializa com um estado vazio e imprime uma mensagem ao iniciar, facilitando o monitoramento do pipeline.

```elixir
defmodule App.WorkerReadFile do
  use GenServer

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: :my_worker)
  end

  @impl true
  def init(_opts) do
    IO.puts("--- O Worker Read Files iniciou! ---")
    {:ok, %{}}
  end
end
```

---

### Módulo App.WorkerAggregator

Este GenServer é o agregador central do pipeline. Ele recebe os resultados processados, agrega por ocupação e realiza a análise de risco. Garante consistência dos dados, serializando as atualizações e prevenindo condições de corrida (race conditions).

**Principais funções públicas:**

- `start_link/1`: inicia o GenServer com estado inicial.
- `tally/1`: agrega resultados conforme são processados (sucesso ou erro).
- `get_result/0`: retorna o resultado final, já com análise de risco.
- `get_stats/0`: retorna estatísticas do processamento (sucessos, falhas, ocupações, total de operações).
- `reset/0`: reseta o estado do agregador.
- `set_max_value_risc/1`: configura o valor máximo para análise de risco.

**Fluxo de funcionamento:**
Cada vez que uma linha do CSV é processada, o resultado é enviado para o agregador via `tally/1`. Se o processamento for bem-sucedido, o registro é agregado por ocupação e o número de operações é somado. Se houver erro, o motivo é registrado. Ao final, o método `get_result/0` aplica a análise de risco, classificando cada ocupação como risco alto ou baixo, conforme o número de operações.

**Exemplo de análise de risco:**
```elixir
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
```

**Exemplo de uso:**
```elixir
WorkerAggregator.reset()
WorkerAggregator.set_max_value_risc(100000)
WorkerAggregator.tally({:ok, record})
{:ok, result, failed} = WorkerAggregator.get_result()
stats = WorkerAggregator.get_stats()
```

Esse design garante que, mesmo com processamento paralelo, o estado final seja consistente e livre de condições de corrida.

---

### Módulo App.ScrRecord

Define a estrutura de dados que representa uma linha do arquivo SCR (Sistema de Informações de Créditos). O módulo utiliza uma struct para garantir tipagem e organização dos dados.

**Estrutura da struct:**
```elixir
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
```

**Função principal:**
- `from_csv_line/1`: converte uma linha CSV em uma struct ScrRecord, realizando parsing seguro dos campos e tratamento de erros.

**Exemplo de uso:**
```elixir
line = "2025-08-31;AC;Bancário;S1;PF;PF - Aposentado/pensionista;..."
App.ScrRecord.from_csv_line(line)
# {:ok, %App.ScrRecord{uf: "AC", tcb: "Bancário", ...}}
```

**Funções privadas:**
- `parse_date/1`, `parse_integer/1`, `parse_float/1`, `clean_string/1`: garantem robustez ao converter os dados do CSV para os tipos corretos, evitando erros de parsing e inconsistências.

Esse módulo é fundamental para garantir que os dados lidos do arquivo estejam corretos e prontos para processamento funcional.

---

### Módulo App.Processor

Este módulo orquestra o pipeline de processamento, integrando leitura eficiente, concorrência e agregação dos resultados.

**Principais funções:**
- `run/2`: executa o processamento do arquivo CSV, configurando concorrência e valor de risco, e envia os resultados para o agregador.
- `aggregate_by_occupation/1`: exemplo de agregação dos dados por ocupação.

**Fluxo detalhado do processamento:**
1. Reseta e configura o agregador (`WorkerAggregator.reset/0` e `set_max_value_risc/1`).
2. Lê o arquivo CSV em modo streaming (`File.stream!`).
3. Processa cada linha em paralelo usando `Task.async_stream`, aproveitando todos os núcleos do processador.
4. Para cada resultado, chama `WorkerAggregator.tally/1` para agregar o dado ou registrar erro.
5. Ao final, obtém o resultado agregado e estatísticas com `get_result/0` e `get_stats/0`.
6. Imprime estatísticas detalhadas do processamento.

**Exemplo de uso:**
```elixir
{:ok, aggregated, failed} = App.Processor.run("dados.csv", max_value_risc: 100000)
IO.inspect(aggregated)
IO.inspect(failed)
```

**Função de agregação por ocupação:**
```elixir
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
```

Esse módulo demonstra como aplicar padrões funcionais e concorrentes para processar grandes volumes de dados de forma eficiente e segura.

---

Esses módulos juntos implementam um pipeline funcional, concorrente e resiliente para análise de grandes volumes de dados bancários, demonstrando os conceitos de programação funcional estudados na disciplina.
---

## Lições Aprendidas sobre Programação Funcional

Durante o desenvolvimento deste projeto, algumas lições importantes sobre programação funcional (PF) ficaram evidentes:

**1. Imutabilidade facilita a concorrência:**
A imutabilidade dos dados em PF elimina problemas clássicos de concorrência, como condições de corrida e estados compartilhados. Isso permitiu processar milhões de linhas em paralelo sem preocupação com corrupção de dados.

**2. Composição e modularidade:**
Funções puras e pequenas são facilmente compostas, tornando o código mais legível, testável e reutilizável. A separação clara de responsabilidades entre módulos (leitura, processamento, agregação) tornou o pipeline flexível e fácil de manter.

**3. Concorrência simplificada:**
Recursos como `Task.async_stream` e GenServer do Elixir mostram como PF pode simplificar o uso eficiente de múltiplos núcleos, aproveitando ao máximo o hardware disponível sem complexidade extra.

**4. Robustez e resiliência:**
O uso de supervisores e processos isolados (GenServer) garante que falhas sejam tratadas automaticamente, aumentando a confiabilidade do sistema.

**5. Parsing seguro e tipagem:**
O uso de structs e funções de parsing robustas garantiu que os dados fossem processados corretamente, evitando erros silenciosos e facilitando a depuração.

**6. Facilidade de testes:**
Funções puras e sem efeitos colaterais são naturalmente mais fáceis de testar, permitindo identificar rapidamente problemas e garantir a qualidade do código.

**7. Mudança de mentalidade:**
Pensar em termos de transformação de dados, pipelines e composição funcional exige uma mudança de paradigma em relação à programação imperativa, mas traz ganhos claros em clareza e manutenção.

Essas lições reforçam o valor da programação funcional para aplicações que exigem alta concorrência, robustez e processamento eficiente de grandes volumes de dados.


