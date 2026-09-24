# Funcionalidades

Termac é um terminal macOS nativo e minimalista (SwiftUI + [libghostty](https://github.com/Lakr233/libghostty-spm)). O foco é o dia a dia, não paridade total com o Ghostty. Requer macOS 15.6+.

## Janelas e abas

- **Nova janela** — ⌘N abre outra janela principal.
- **Barra de abas** — título, fechar por aba, **+** (nova aba), menu de agentes (⌘) e botão de configurações. Abas que transbordam rolam com as setas laterais. O chrome vazio é arrastável; duplo clique amplia a janela.
- **Abas verticais** — Settings → Janela → **Abas verticais** troca a barra por um rail à esquerda sob os traffic lights (largura arrastável, persistida no `config.yml`).
- **Renomear aba** — menu de contexto da aba → **Rename Tab…**; nome vazio restaura o título automático.
- **Fixar aba** — menu de contexto → **Pin Tab**; abas fixadas vão para o início da fila com glifo de pin e seleção preservada.
- **Atalhos** — ⌘T nova aba, ⌘W fechar, ⌘⇧]/⌘⇧[ próxima/anterior, ⌘⇧←/⌘⇧→ mover.
- **Títulos** — mostram o basename do comando em foreground (ex.: `node` para `node index.js`), título OSC do programa enquanto roda, e a shell de login em idle. Por padrão recebem o prefixo do diretório atual (`dir - node`); toggle em Settings → Janela.
- **Diretório da nova aba** — ⌘T / **+** abrem no diretório da aba ativa (cwd da shell ou OSC 7). Janelas novas e abas de reposição após exit abrem em `$HOME`.
- **Fechar com comando rodando** — fechar aba com processo em foreground pede confirmação (toggle em Settings → Janela).
- **Última aba** — fechar a última fecha a janela; se a shell sair na última, uma aba nova é aberta no lugar.

## Command Palette

- **Abrir** — botão Commands no header ou `⌘K`.
- **Busca fuzzy** — encontra ações, abas e agentes por texto parcial (ex.: `cld`).
- **Navegação** — `↑`/`↓` seleciona, `Enter` executa e `Esc` fecha.
- **Ações de abas** — reabrir aba fechada (`⌘⇧T`), duplicar e mover.
- **Drag-and-drop** — arraste uma aba para reordenar na barra horizontal ou no rail vertical.
- A palette não intercepta comandos digitados no terminal.

## Agentes de IA

- **Cadastro manual** — Settings → Agentes IA → **Add Agent…** (Nome + Comando + Cor). Nada é detectado do sistema: só roda o que você cadastrou.
- **Dropdown no header** — cada item mostra a cor do agente; clique abre **nova aba** no diretório da aba ativa e executa o comando.
- **Boot direto** — o agente spawna via `zsh -l -c '<comando>; exec zsh -l'`, pulando o init da shell interativa (zshrc/p10k). Ao sair, uma shell de login assume a mesma aba.
- **Cor do agente** — o chip da aba inteiro recebe o tint da cor (selecionada, hover e idle).
- **Título** — a aba fica com o nome do agente. Um rename manual pelo menu de contexto tem precedência.
- **Padrão** — a lista nova vem com Tompero, Claude Code, Codex e OpenCode (cores configuráveis).

## Terminal

- **Login shell** — PTY real via Ghostty `.exec`; shell da conta do usuário (`$SHELL`/passwd), lançada como login shell.
- **Renderização** — superfície Metal do libghostty.
- **Bell** — beep do sistema; bounce no dock quando o app está inativo.
- **URLs** — links do terminal abrem no browser padrão.
- **Find** — ⌘F abre a barra de busca; matches destacados no scrollback. Próximo/anterior pela barra; Esc fecha.
- **Zoom de fonte** — ⌘+/⌘− mudam o tamanho da aba ativa temporariamente; ⌘0 volta ao valor das Settings. Recarregar a config também limpa o zoom (não persiste no `config.yml`).
- **Chrome temático** — fundo de janela/barra de abas e aparência do app seguem o tema escolhido.

## Settings

Abre com ⌘, ou o botão de configurações. Os valores persistem em `~/.config/termac/config.yml` (criado com defaults no primeiro boot). Mudanças nas Settings gravam o arquivo na hora; editou à mão? **File → Reload Configuration** (⌘⇧,). Tamanho/posição de janela valem só para **novas** janelas.

| Seção | Controles |
| --- | --- |
| **Aparência** | Tema (catálogo GhosttyTheme, Light/Dark), fonte (família, tamanho 8–32 px, line height 0.8–2.0×, peso), zoom de interface e terminal |
| **Janela** | Confirmar fechamento com comando rodando (on), diretório no título (on), abas verticais (off), padding 0–64 px, posição X×Y a partir do topo-esquerda, tamanho em grid de caracteres (20–500 × 5–200, default 80×24) |
| **Header** | Tamanho do chrome (compact/regular/large); **Right Buttons**: ícone do menu de agentes, ícone de configurações (SF Symbols curados) e tamanho dos dois (70–160%) |
| **Agentes IA** | Lista de agentes cadastrados (Nome + Comando + Cor, editável), remover, **Add Agent…** |
| **Atalhos** | Sheet somente leitura com a lista de atalhos |
| **Configuração** | **Open Configuration…** abre o `config.yml` no editor padrão |

## Atalhos de teclado

Fonte da verdade: `Termac/Settings/ShortcutsCatalog.swift` (também alimenta os keybinds do Ghostty após `keybind=clear`).

### Janelas e abas (menus do app)

| Ação | Teclas |
| --- | --- |
| Nova janela | ⌘N |
| Nova aba | ⌘T |
| Fechar aba | ⌘W |
| Próxima aba | ⌘⇧] |
| Aba anterior | ⌘⇧[ |
| Mover aba à esquerda | ⌘⇧← |
| Mover aba à direita | ⌘⇧→ |
| Find | ⌘F |
| Aumentar | ⌘+ |
| Diminuir | ⌘− |
| Tamanho real | ⌘0 |
| Reload Configuration | ⌘⇧, |

### Terminal (keybinds do Ghostty)

| Ação | Teclas |
| --- | --- |
| Palavra à esquerda | ⌥← |
| Palavra à direita | ⌥→ |
| Início da linha | ⌘← |
| Fim da linha | ⌘→ |
| Apagar até o início da linha | ⌘⌫ |
| Copiar | ⌘C |
| Colar | ⌘V |
| Rolar ao topo | ⌘↖ |
| Rolar ao fim | ⌘↘ |
| Página acima | ⌘⇞ |
| Página abaixo | ⌘⇟ |

## Comportamento fixo do Ghostty

Defaults donos do host, sem exposição em Settings:

- Scrollback ~4 MB; scrollbar nunca exibida
- Option como Alt; cursor bloco piscante
- Clipboard: leitura negada (OSC 52), escrita liberada; paste protection off até o libghostty ter UI de confirmação
- Shell integration off
- `TERM=xterm-256color`, `COLORTERM=truecolor`, `TERM_PROGRAM=Termac` (+ versão quando disponível)

## Fora de escopo

- Splits/panes
- Inspector
- `ghostty.conf` customizado / perfis
- Atalhos remapeáveis na UI
- Backends sandboxed/in-memory (sandbox do app fica off para shells reais)
