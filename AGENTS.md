# AGENTS.md — Guia para IAs

> Instruções operacionais para agentes de código trabalhando neste repositório.
> Leia as seções **Comandos**, **Mapa de código** e **Invariantes** antes de editar.

## Visão geral

Termac é um terminal macOS nativo mínimo (SwiftUI + [libghostty](https://github.com/Lakr233/libghostty-spm)). O host (SwiftUI) é dono de abas, settings e chrome; o libghostty é dono do parsing VT e da renderização Metal. Requer macOS 15.6+ e Xcode 16+.

## Comandos essenciais

| Tarefa | Comando |
| --- | --- |
| Build (Debug) | `xcodebuild -project Termac.xcodeproj -scheme Termac -configuration Debug build` |
| Testes (Swift Testing, 120+) | `xcodebuild -project Termac.xcodeproj -scheme Termac test -only-testing:TermacTests` |
| App Release | `xcodebuild -project Termac.xcodeproj -scheme Termac -configuration Release build` |
| DMG assinado | `./Script/make-dmg.sh` (ou `--skip-build`) |
| Criar identidade de assinatura | `./Script/setup-signing.sh` (uma vez) |

- Scheme correto: **Termac** (maiúsculo). O projeto usa file-system-synchronized groups — arquivos criados/removidos em disco entram no build automaticamente.
- Depois de mudar UI, rode testes **e** gere o app em `dist/` se o usuário pedir.
- Testes de timing (`debouncedPersistWritesAfterDelay`) podem falhar por flake; rode de novo antes de investigar.

## Mapa de código

| Camada | Path | Responsabilidade |
| --- | --- | --- |
| App | `Termac/App/` | Entry, menu commands, constantes (`TermacConstants`) |
| Terminal | `Termac/Terminal/` | `TerminalSession`, config do Ghostty, polling de título, find |
| Tabs | `Termac/Tabs/` | `TabManager`, `TabRoster` (ordem/selection pura), barras de aba |
| Agents | `Termac/Agents/` | `CustomAgent`, dropdown do header, settings de agentes |
| Settings | `Termac/Settings/` | `AppSettings`, `TermacConfigStore` (YAML), temas, fontes, shortcuts |
| Window | `Termac/Window/` | Chrome, drag region, geometria |
| Testes | `TermacTests/` | Unit tests hospedeiros (Swift Testing `#expect`) |

## Fluxo de agentes (executor manual)

1. Usuário cadastra agente em Settings → Agentes IA (Nome + Comando + Cor) → persiste em `custom_agents` no `~/.config/termac/config.yml`.
2. Dropdown do header lista os agentes; clique → `TabManager.runAgentInNewTab` → nova aba herdando o cwd.
3. A sessão spawna direto `zsh -l -c '<comando>; exec zsh -l'` (`TermacTerminalConfig.makeAgentLaunchCommand`) — pula zshrc/p10k (~0.9s → ~0.05s). NÃO cola comando em shell interativa.
4. `TerminalSession.markAsAgent` grava nome (vira o título da aba) e cor (tinta o chip). Precedência de título: **rename do usuário > nome do agente > título automático**.
5. Agentes não têm detecção de instalados nem ícones por processo (`AgentDetector`/`TabAgentIcon` foram removidos de propósito — não recriar).

## Config (`~/.config/termac/config.yml`)

Escrita por `AppSettings` (debounce) e `TermacConfigStore`; todas as chaves têm default e decodificam configs antigos sem falhar.

| Chave | Tipo | Observação |
| --- | --- | --- |
| `theme`, `font.*`, `window.*`, `zoom` | — | Aparência e janela |
| `header_size` | string | compact/regular/large — escala o chrome |
| `agents_menu_icon`, `settings_menu_icon` | string | SF Symbols validados por `ChromeIconOptions.sanitized` |
| `action_icon_scale` | float | 0.7–1.6, multiplica o glifo dos botões da direita |
| `custom_agents` | lista | `{name, command, colorHex}` — sem detecção, cadastro manual |

## Invariantes (não quebrar)

- **Sandbox off** (`ENABLE_APP_SANDBOX = NO`): o backend `.exec` do Ghostty spawna shell real de login. Ligar o sandbox quebra o spawn.
- **Host é dono da config**: `TermacTerminalConfig.terminalConfiguration` monta tudo; nada lê `ghostty.conf` externo.
- **`keybind=clear` + catálogo**: limpa os binds do Ghostty para ⌘T/⌘W ficarem com os menus SwiftUI; binds de terminal vêm de `ShortcutsCatalog`.
- **Tab parking**: abas inativas ficam montadas off-screen (`TerminalParkingView`) para o libghostty drenar eventos.
- **`unset CLAUDE_CODE_CHILD_SESSION`** antes de todo spawn de shell: garante que o Claude lançado numa aba nova seja sessão independente.
- **Assinatura**: builds de release usam a identidade estável **Termac Self-Signed** (`docs/SIGNING.md`, fingerprint `21:39:A4:…:C8:C6:7B`). Sem ela o app sai adhoc e o Gatekeeper acusa "danificado".

## Convenções

- Comentários explicam o **porquê** em contratos host↔lib; o resto é código limpo e nomes claros.
- Lógica testável fica em tipos puros (`TabRoster`, `hasRunningCommand`, `displayTitle`) — teste unitário > teste de UI.
- Novas settings: property `@Published` com `didSet` (clamp quando fizer sentido) + chave em `TermacConfigFile` com `decodeIfPresent ?? default` + teste de round-trip.
- Docs em português, curtas, com tabelas. Atualizar `docs/FEATURES.md` ao adicionar feature visível.

## Docs

| Arquivo | Conteúdo |
| --- | --- |
| [docs/FEATURES.md](docs/FEATURES.md) | Lista de features voltada ao usuário |
| [docs/TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md) | Gatekeeper, submódulos, sandbox |
| [docs/SIGNING.md](docs/SIGNING.md) | Identidade self-signed e fingerprint |
| [docs/HOMEBREW.md](docs/HOMEBREW.md) | Tap pessoal e bump de cask |
