local vim = vim

-- Evita recarregar o plugin caso já esteja carregado
if vim.g.loaded_term_nvim == 1 then
  return
end

vim.g.loaded_term_nvim = 1
