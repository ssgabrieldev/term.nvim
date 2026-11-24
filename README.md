# term.nvim

Plugin para [Neovim](https://neovim.io/) que gerencia múltiplas instâncias de terminal em buffers e permite exibi-las em janelas divididas (*splits*).

Com o `term.nvim`, você pode criar terminais independentes, reutilizar instâncias por identificador, abrir um terminal em diferentes janelas e alternar a visibilidade das janelas gerenciadas.

## Funcionalidades

- Gerenciamento de múltiplas instâncias de terminal.
- Criação de buffers de terminal com `jobstart()`.
- Reutilização de instâncias por meio de identificadores (`id`).
- Abertura de terminais em splits horizontais abaixo da janela atual.
- Criação de múltiplas janelas para exibir terminais.
- Seletor interativo para escolher uma janela quando há mais de uma disponível.
- Alternância da visibilidade das janelas gerenciadas.
- Callback `on_exit` para reagir ao encerramento de um processo.
- Fechamento das janelas associadas quando o processo do terminal termina.

## Requisitos

- Neovim com suporte às APIs utilizadas pelo plugin.
- Um shell ou executável de terminal disponível no ambiente.

> O comando padrão utilizado é o valor de `vim.o.shell`.

## Instalação

### lazy.nvim

Adicione a seguinte especificação à sua configuração:

```lua
{
  "ssgabrieldev/term.nvim",
  config = function()
    require("term").setup({})
  end,
}
```

Com outro gerenciador de plugins, instale o repositório e execute `require("term").setup({})` antes de utilizar a API.

## Configuração

A função `setup()` deve ser chamada antes das demais funções do módulo. Ela recebe uma tabela de opções.

Para utilizar o shell padrão do Neovim:

```lua
require("term").setup({})
```

Para definir um comando padrão para novas instâncias:

```lua
require("term").setup({
  term = {
    cmd = "bash",
  },
})
```

A opção `term.cmd` é utilizada quando uma nova instância é criada sem um comando específico.

## Uso

Após configurar o plugin, carregue o módulo:

```lua
local term = require("term")
```

### Abrir um terminal

A função `open()` abre um terminal em uma janela gerenciada. Se o identificador informado já existir, a instância será reutilizada; caso contrário, uma nova será criada.

```lua
-- Cria e abre um terminal usando vim.o.shell.
term.open()

-- Abre ou cria a instância de identificador 2.
term.open({ id = 2 })

-- Cria e abre um terminal executando um comando específico.
term.open({ cmd = "lazygit" })
```

Quando existem várias janelas gerenciadas, o seletor interativo permite escolher onde exibir o terminal:

- Pressione uma tecla de `1` a `9` para selecionar a janela correspondente.
- Pressione `Esc` para sair do seletor. Nesse caso, `open()` utiliza a primeira janela como alternativa.
- O seletor suporta no máximo nove janelas.

### Criar um terminal

A função `new()` cria uma instância de terminal sem abrir uma janela para ela. O processo é iniciado imediatamente e o objeto da instância é retornado.

```lua
local terminal = term.new({
  id = 3,
  cmd = "top",
})
```

Os campos são opcionais:

- `id`: identificador da instância. Quando omitido ou não positivo, um identificador disponível é gerado automaticamente.
- `cmd`: comando executado no terminal. Quando omitido, utiliza `vim.o.shell`.
- `on_exit`: função chamada quando o processo do terminal termina. Recebe a instância encerrada como argumento.

Exemplo com callback:

```lua
local terminal = term.new({
  cmd = "bash",
  on_exit = function(closed_terminal)
    print("Terminal encerrado:", closed_terminal.id)
  end,
})
```

### Criar uma janela

A função `new_window()` cria uma janela dividida horizontalmente abaixo da janela atual e associa um terminal a ela.

```lua
-- Utiliza o primeiro terminal disponível ou cria um novo.
local window = term.new_window()
```

Para associar uma instância específica:

```lua
term.new_window({ id = 2 })
```

Se o identificador informado não corresponder a uma instância existente, uma nova instância será criada.

### Alternar as janelas

A função `toggle_windows()` alterna a visibilidade de todas as janelas gerenciadas pelo plugin. Se nenhuma janela tiver sido criada, uma nova será aberta.

```lua
term.toggle_windows()
```

## API

| Função | Descrição |
| --- | --- |
| `setup(opts)` | Inicializa o módulo com as opções informadas. Deve ser chamada antes das demais funções. |
| `new(opts)` | Cria uma instância de terminal e retorna seu objeto. |
| `open(opts)` | Abre uma instância em uma janela gerenciada, criando-a quando necessário. |
| `new_window(opts)` | Cria uma janela e associa um terminal a ela. |
| `toggle_windows(opts)` | Alterna a visibilidade das janelas gerenciadas. Se não houver janelas, cria uma. |

### Opções de terminal

As funções `new()`, `open()` e `new_window()` recebem uma tabela com as seguintes opções:

| Opção | Tipo | Descrição |
| --- | --- | --- |
| `id` | `integer` | Identificador da instância de terminal. |
| `cmd` | `string` | Comando executado no terminal quando uma nova instância é criada. |
| `on_exit` | `function` | Callback executado quando o processo termina. Recebe a instância como argumento. |

A opção `on_exit` é relevante quando a chamada resulta na criação de uma nova instância. Se `open()` reutilizar um terminal existente, as opções de criação não substituem as opções daquela instância.

### Opções de configuração

| Opção | Tipo | Descrição |
| --- | --- | --- |
| `term.cmd` | `string` | Comando padrão utilizado na criação de novas instâncias. |

## Exemplo de configuração com atalhos

O plugin não registra comandos Ex nem mapeamentos de teclas automaticamente. Você pode definir seus próprios atalhos:

```lua
local term = require("term")

term.setup({
  term = {
    cmd = vim.o.shell,
  },
})

vim.keymap.set("n", "<leader>tt", function()
  term.toggle_windows()
end, { desc = "Alternar janelas de terminal" })

vim.keymap.set("n", "<leader>tn", function()
  term.open()
end, { desc = "Abrir terminal" })

vim.keymap.set("n", "<leader>tg", function()
  term.open({ cmd = "lazygit" })
end, { desc = "Abrir Lazygit no terminal" })
```

## Comportamentos e limitações

- Os terminais são criados em buffers do Neovim e executados como processos associados a esses buffers.
- O shell padrão é obtido de `vim.o.shell`.
- As janelas são abertas em splits horizontais abaixo da janela atual.
- O seletor interativo suporta até nove janelas.
- `toggle_windows()` atua somente sobre as janelas gerenciadas pelo plugin.
- Quando um processo termina, suas janelas associadas são fechadas e a instância é removida do registro interno.
- O plugin não configura atalhos ou comandos Ex automaticamente.

## Estrutura do projeto

```text
lua/
└── term/
    ├── init.lua       # API pública e gerenciamento das instâncias
    ├── terminal.lua  # Buffers e processos de terminal
    ├── window.lua    # Janelas e eventos de fechamento
    └── picker.lua    # Seleção interativa de janelas
```

## Licença

Este projeto está licenciado sob a [MIT License](LICENSE).
