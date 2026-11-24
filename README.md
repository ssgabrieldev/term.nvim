# term.nvim

Plugin para [Neovim](https://neovim.io/) que gerencia instâncias de terminal em buffers e permite exibi-las em janelas divididas. É possível criar terminais independentes, abrir um terminal existente e alternar a visibilidade das janelas.

## Funcionalidades

- Criação e gerenciamento de múltiplas instâncias de terminal.
- Reutilização de um terminal existente pelo seu identificador (`id`).
- Exibição dos terminais em janelas horizontais (split abaixo da janela atual).
- Alternância entre janelas de terminal abertas.
- Seletor interativo para escolher uma janela quando há várias disponíveis.
- Remoção do registro de uma instância quando seu processo de terminal termina.

## Instalação

Com [lazy.nvim](https://github.com/folke/lazy.nvim):

```lua
{
  "ssgabrieldev/term.nvim",
  config = function()
    require("term").setup()
  end,
}
```

Com outro gerenciador de plugins, adicione este repositório à configuração e execute `require("term").setup()` após o carregamento do plugin.

## Configuração

A configuração é opcional. O plugin utiliza o shell definido em `vim.o.shell` quando nenhum comando é informado.

Para definir um comando padrão para as novas instâncias:

```lua
require("term").setup({
  term = {
    cmd = "bash",
  },
})
```

Também é possível informar um comando ou identificador ao criar ou abrir um terminal.

## Uso

Carregue o módulo:

```lua
local term = require("term")
```

### Abrir um terminal

`open()` abre uma instância em uma janela. Se não houver uma instância com o identificador informado, uma nova será criada.

```lua
-- Abre um terminal novo usando o shell padrão.
term.open()

-- Abre (ou cria) o terminal de identificador 2.
term.open({ id = 2 })

-- Abre (ou cria) um terminal executando um comando específico.
term.open({ cmd = "lazygit" })
```

Quando já existem várias janelas gerenciadas, o plugin apresenta um seletor numerado para escolher onde exibir o terminal. Pressione `1` a `9` para selecionar uma janela ou `Esc` para cancelar. O seletor suporta até nove janelas.

### Criar uma instância sem abri-la em uma janela

`new()` cria o buffer e inicia o processo do terminal, retornando o objeto da instância:

```lua
local terminal = term.new({
  id = 3,
  cmd = "top",
})
```

Os campos `id` e `cmd` são opcionais. O identificador é gerado automaticamente quando não é informado ou quando seu valor não é positivo.

### Criar uma janela de terminal

`new_window()` cria uma janela dividida horizontalmente abaixo da janela atual e associa a ela um terminal. Se nenhum terminal existir, uma instância será criada.

```lua
local window = term.new_window()
```

É possível selecionar a instância pelo identificador:

```lua
term.new_window({ id = 2 })
```

### Alternar a visibilidade das janelas

`toggle_windows()` alterna todas as janelas gerenciadas. Se ainda não houver janelas, cria uma:

```lua
term.toggle_windows()
```

## API

| Função | Descrição |
| --- | --- |
| `setup(opts)` | Define as opções do plugin. Aceita `term.cmd` como comando padrão. |
| `new(opts)` | Cria uma instância de terminal e retorna seu objeto. |
| `open(opts)` | Abre uma instância em uma janela, criando-a se necessário. |
| `new_window(opts)` | Cria uma janela e associa um terminal a ela. |
| `toggle_windows(opts)` | Alterna a visibilidade das janelas gerenciadas. |

As opções de `new()`, `open()` e `new_window()` são:

| Opção | Tipo | Descrição |
| --- | --- | --- |
| `id` | `integer` | Identificador da instância de terminal. |
| `cmd` | `string` | Comando iniciado no terminal. |

## Comportamento e limitações

- Os terminais são executados em buffers criados pelo Neovim usando `jobstart()` com suporte a terminal.
- O comando padrão é `vim.o.shell`.
- As janelas são abertas como splits horizontais abaixo da janela atual.
- O seletor de janelas aceita no máximo nove opções; acima desse limite, exibe um aviso e não seleciona uma janela.
- `toggle_windows()` atua sobre as janelas gerenciadas pelo plugin, não sobre todas as janelas do Neovim.
- O plugin não registra comandos Ex ou mapeamentos de teclas automaticamente. Configure seus próprios atalhos se desejar.

## Exemplo de atalhos

Adicione à sua configuração do Neovim:

```lua
local term = require("term")

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

## Licença

Consulte o arquivo [LICENSE](LICENSE) para obter informações sobre a licença do projeto.
