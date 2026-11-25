# term.nvim

Plugin para [Neovim](https://neovim.io/) que gerencia múltiplas instâncias de terminal em buffers e permite exibi-las em janelas divididas (*splits*).

O plugin oferece uma API Lua para criar e reutilizar terminais, abrir janelas associadas a eles, alternar a visibilidade dessas janelas e selecionar uma instância existente.

## Funcionalidades

- Gerenciamento de múltiplas instâncias de terminal.
- Criação de buffers de terminal e processos por meio de `jobstart()`.
- Reutilização de instâncias por identificador (`id`).
- Abertura de terminais em splits horizontais abaixo da janela atual.
- Criação de várias janelas gerenciadas, associadas a instâncias de terminal.
- Seleção de uma janela para receber um terminal quando há várias janelas gerenciadas.
- Seleção interativa de uma instância de terminal por meio de `vim.ui.select()`.
- Alternância da visibilidade das janelas gerenciadas.
- Callback `on_exit` quando o processo de uma instância termina.
- Fechamento das janelas associadas quando o processo do terminal termina.

## Requisitos

- Neovim com suporte às APIs utilizadas pelo plugin.
- Um shell ou executável de terminal disponível no ambiente.

O comando padrão é obtido de `vim.o.shell`. Não há uma versão mínima do Neovim declarada pelo projeto.

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

Chame `setup()` antes das demais funções do módulo. A função recebe uma tabela de opções; use uma tabela vazia quando não precisar personalizar o comando padrão.

Para utilizar o shell configurado no Neovim:

```lua
local term = require("term")

term.setup({})
```

Para definir um comando padrão para novas instâncias:

```lua
term.setup({
  term = {
    cmd = "bash",
  },
})
```

A opção `term.cmd` é usada quando uma nova instância é criada sem um `cmd` específico.

## Uso

### Abrir um terminal

`open()` abre uma instância em uma janela gerenciada. Se o `id` informado corresponder a uma instância existente, ela será reutilizada; caso contrário, uma nova instância será criada.

```lua
-- Cria e abre um terminal usando vim.o.shell.
term.open()

-- Abre ou cria a instância de identificador 2.
term.open({ id = 2 })

-- Cria e abre um terminal executando um comando específico.
term.open({ cmd = "lazygit" })
```

Quando há mais de uma janela gerenciada, o plugin apresenta um seletor temporário na `winbar`:

- Pressione uma tecla de `1` a `9` para escolher a janela correspondente.
- Pressione `Esc` para sair do seletor; nesse caso, `open()` utiliza a primeira janela como alternativa.
- O seletor aceita no máximo nove janelas.

### Criar uma instância de terminal

`new()` cria uma instância sem abrir uma janela gerenciada. O processo é iniciado imediatamente e o objeto da instância é retornado.

```lua
local terminal = term.new({
  id = 3,
  cmd = "top",
})
```

Opções aceitas:

- `id`: identificador da instância. Se omitido ou não positivo, um identificador disponível é gerado automaticamente.
- `cmd`: comando executado no terminal. Se omitido, utiliza `vim.o.shell` ou o valor padrão configurado em `term.cmd`.
- `on_exit`: função chamada quando o processo termina. Recebe a instância encerrada como argumento.

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

`new_window()` cria uma janela dividida horizontalmente abaixo da janela atual e associa uma instância de terminal a ela.

```lua
-- Usa o primeiro terminal registrado ou cria um novo.
local window = term.new_window()
```

Para associar uma instância específica:

```lua
term.new_window({ id = 2 })
```

Se o `id` não corresponder a uma instância existente, uma nova instância será criada usando as opções recebidas e a configuração padrão.

### Selecionar uma instância de terminal

`pick()` abre o seletor da interface `vim.ui.select()` com as instâncias registradas. Ao selecionar uma delas, o plugin chama `open()` para exibi-la.

```lua
term.pick()
```

Se não houver instâncias registradas, o plugin exibe a notificação `No terminals available`.

### Alternar as janelas

`toggle_windows()` alterna a visibilidade de todas as janelas gerenciadas pelo plugin. Se ainda não houver janelas registradas, cria uma.

```lua
term.toggle_windows()
```

## API

| Função | Descrição |
| --- | --- |
| `setup(opts)` | Inicializa o módulo com as opções informadas. Deve ser chamada antes das demais funções. |
| `new(opts)` | Cria uma instância de terminal e retorna seu objeto. |
| `open(opts)` | Abre uma instância em uma janela gerenciada, criando-a quando necessário. |
| `new_window(opts)` | Cria uma janela e associa uma instância de terminal. |
| `pick()` | Exibe as instâncias registradas em `vim.ui.select()` e abre a selecionada. |
| `toggle_windows(opts)` | Alterna a visibilidade das janelas gerenciadas; cria uma janela se não houver nenhuma. |

### Opções de terminal

As funções `new()`, `open()` e `new_window()` podem receber uma tabela com estas opções:

| Opção | Tipo | Descrição |
| --- | --- | --- |
| `id` | `integer` | Identificador da instância de terminal. |
| `cmd` | `string` | Comando executado quando uma nova instância é criada. |
| `on_exit` | `function` | Callback executado quando o processo termina. Recebe a instância como argumento. |

A opção `on_exit` é aplicada quando a chamada cria uma nova instância. Se `open()` reutilizar um terminal existente, as opções de criação não substituem as opções já associadas à instância.

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

vim.keymap.set("n", "<leader>tn", function()
  term.new_window()
end, { desc = "Nova janela de terminal" })

vim.keymap.set("n", "<leader>tt", function()
  term.toggle_windows()
end, { desc = "Alternar janelas de terminal" })

vim.keymap.set("n", "<leader>to", function()
  term.open()
end, { desc = "Abrir terminal" })

vim.keymap.set("n", "<leader>tp", function()
  term.pick()
end, { desc = "Selecionar terminal" })
```

## Comportamentos e limitações

- As instâncias são buffers do Neovim associados a processos iniciados com `jobstart()`.
- O comando padrão é obtido de `vim.o.shell`, salvo configuração de `term.cmd`.
- As janelas são abertas em splits horizontais abaixo da janela atual.
- O seletor de janelas exibido por `open()` suporta até nove opções.
- `pick()` seleciona uma instância de terminal; o seletor usado por `open()` seleciona uma janela. São operações diferentes.
- `toggle_windows()` atua somente sobre as janelas registradas pelo módulo.
- Ao terminar um processo, o callback `on_exit` é executado e as janelas que o plugin consegue localizar na tabpage atual são fechadas.
- O plugin não registra atalhos ou comandos Ex automaticamente.
- O projeto não declara uma versão mínima do Neovim nem apresenta, no momento, uma suíte automatizada de testes identificável. `test_init.lua` é um arquivo de configuração de desenvolvimento que prepara o ambiente e os atalhos usados localmente.

## Estrutura do projeto

```text
.
├── lua/
│   └── term/
│       ├── init.lua       # API pública e gerenciamento das instâncias
│       ├── terminal.lua   # Buffers e processos de terminal
│       ├── window.lua     # Janelas e eventos de fechamento
│       └── picker.lua     # Seleção interativa de janelas
├── test_init.lua          # Configuração local de desenvolvimento
├── doc/
│   └── term.txt           # Arquivo de documentação Vim (atualmente vazio)
├── LICENSE
└── README.md
```

## Licença

Este projeto está licenciado sob a [MIT License](LICENSE).
