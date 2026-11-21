# Lean 4 no Prelude

A configuração fica em `modules/lean.el`, carregada por `config.el`.

## Uso

Abra qualquer arquivo `.lean`: Lean4-Mode inicia automaticamente o servidor de linguagem do Lean, verificação incremental, diagnósticos Flycheck, sugestões Corfu, informações de tipos, navegação e painel `*Lean Goal*`. O painel acompanha a posição do cursor; as provas são verificadas enquanto você escreve, sem precisar executar um comando de compilação a cada alteração.

O método de entrada **Lean** fica ativo ao escrever (estado de inserção do Evil). Exemplos: `\forall` → ∀, `\exists` → ∃, `\and` → ∧, `\to` → →, `\alpha` → α. Complete com espaço ou Tab. `C-\` alterna o método de entrada. Snippets `theorem`, `example` e `induction` estão disponíveis pelo Yasnippet.

As sugestões do Copilot existentes continuam habilitadas. A verificação do Lean determina se uma sugestão constitui uma prova válida.

## Atalhos em buffers Lean

| Atalho | Função |
| --- | --- |
| `C-c C-i` ou `F6` | Mostrar/ocultar objetivos e mensagens |
| `C-c C-c` ou `F5` | Salvar e verificar o arquivo atual |
| `C-c C-b` | Salvar e executar `lake build` |
| `C-c C-d` | Recarregar o arquivo e seus imports |
| `C-c C-r` | Reiniciar o servidor Lean |
| `C-c C-h` | Consultar tipo/documentação no cursor |
| `C-c C-a` | Ações de código disponíveis naquela posição |
| `C-c C-e` | Listar diagnósticos |
| `C-c C-n` | Próximo diagnóstico |
| `C-c C-t` | Alternar dicas de tipos no código |
| `M-.` / `M-,` | Ir à definição / voltar |
| `M-TAB` | Solicitar autocompletar |
| `C-c C-p C-n` | Criar um projeto Lean |
| `C-c C-p C-c` | Baixar cache compilado do Mathlib |

No Evil, `C-c` continua sendo prefixo; se uma seleção estiver ativa, o CUA pode tratá-lo como copiar. Desative a seleção antes de usar sequências de comandos.

## Projetos e versões

Na tela inicial, **New Lean project** permite escolher a pasta pai, o nome e o modelo:

- `lib`: biblioteca básica para definições e provas.
- `std`: biblioteca e executável.
- `math-lax`: projeto com Mathlib.
- `math`: Mathlib com as convenções e verificações de estilo do projeto Mathlib.

A criação ocorre em segundo plano, com a saída em `*Lean new project*`. Abra os arquivos do diretório gerado após a conclusão. Os modelos Mathlib baixam dependências pela rede. Em um projeto com Mathlib, `C-c C-p C-c` obtém os arquivos pré-compilados em vez de reconstruir a biblioteca inteira.

O Elan foi instalado em `~/.elan`. O Prelude prioriza `~/.elan/bin` no PATH e no exec-path; cada projeto usa a versão de seu `lean-toolchain`. Versões ausentes são baixadas pelo Elan quando necessárias. O padrão é Lean **4.35.0**, reaproveitando `/opt/lean-4.35.0` por um vínculo de toolchain. A instalação do sistema foi preservada. O caminho do terminal não foi alterado; fora do Prelude pode-se usar `~/.elan/bin/lake` explicitamente.

Projeto inicial compilado e disponível em:
`~/Mathematics/Lean/FirstSteps/FirstSteps/Basic.lean`.

Lean4-Mode é instalado e atualizado como pacote VC de `leanprover-community/lean4-mode`, incluindo seus dados de símbolos Unicode. As dependências LSP são restritas ao modo Lean; os demais modos continuam usando a configuração Eglot existente.

## Compatibilidade e validação

O painel nativo do Emacs apresenta objetivos, tipos esperados e mensagens. Não executa os widgets web personalizados da extensão VS Code.

LSP-mode 20261109 não tem um handler para `workspace/inlayHint/refresh`, solicitado pelo Lean. A configuração adiciona esse handler apenas ao cliente Lean e apenas se ele estiver ausente, atualizando dicas nas janelas visíveis e respondendo normalmente ao servidor.

Validação com uma inicialização nova do Prelude: servidor real, objetivos, erro de prova incompleta, consulta de tipos, definição, sugestões e entrada Unicode em modo de inserção. Projeto FirstSteps compilado com sucesso. Registros locais em `~/.local/state/prelude-lean/`.

Fontes: [Lean4-Mode](https://github.com/leanprover-community/lean4-mode), [Elan](https://github.com/leanprover/elan).
