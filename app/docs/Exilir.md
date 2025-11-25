O Supervisor é um componente fundamental do modelo de concorrência do Elixir/Erlang. Ele é responsável por monitorar e gerenciar outros processos (como GenServers), garantindo que, se algum deles falhar, seja reiniciado automaticamente conforme uma estratégia definida.

Principais funções do Supervisor:

Resiliência: Mantém o sistema funcionando mesmo diante de falhas, reiniciando processos filhos quando necessário.
Estratégias de reinício: Pode reiniciar apenas o processo que falhou, todos os filhos, ou um grupo, dependendo da configuração (:one_for_one, :one_for_all, :rest_for_one).
Organização: Estrutura a aplicação em uma árvore supervisionada, facilitando o controle e a manutenção.
No seu projeto, o Supervisor inicia e monitora processos como WorkerAggregator e WorkerReadFile, garantindo robustez e alta disponibilidade do pipeline de processamento.



O GenServer (Generic Server) é um módulo da biblioteca padrão do Elixir/Erlang que facilita a implementação de servidores de processos concorrentes e com estado. Ele abstrai o padrão de processo que recebe mensagens, mantém estado interno e responde a requisições de forma síncrona ou assíncrona.

Principais características:

Permite criar processos que mantêm estado entre chamadas.
Garante isolamento e concorrência segura, pois cada GenServer roda em seu próprio processo.
Oferece callbacks (init, handle_call, handle_cast, etc.) para tratar requisições e atualizar o estado.
É usado para implementar serviços, agregadores, caches, filas, entre outros.
No seu projeto, o WorkerAggregator é um GenServer que recebe resultados do processamento, agrega dados e garante consistência, mesmo com múltiplos processos concorrentes enviando atualizações.