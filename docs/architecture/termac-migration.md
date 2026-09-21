# Termac — auditoria e migração

## Arquitetura preservada

- `ShellExecutor.swift` mantém SwiftTerm, PTY, processo local e terminal AppKit.
- `Session` mantém a lista de tabs, tab ativa, splits, diretório de trabalho e persistência.
- `Tab` mantém identidade, título, estado de notificação e a referência viva do terminal.
- `TabBarView` e `VerticalTabBar` consomem o mesmo `Session` (`TabStore`), sem duplicar processos.
- `PersistenceService` continua restaurando tabs, seleção e árvore de splits.

## Limpeza aplicada

- Removidos SSH, hosts remotos, reconexão automática e armazenamento de hosts.
- Removido o navegador/sidebar de sessões legado.
- Removidos WebKit/WebPanel e o dashboard de agentes da interface.
- O foco público agora é terminal local, tabs e splits.

## Apresentação

- `TabLayoutMode` persiste horizontal/vertical em `UserDefaults`.
- Horizontal usa `TabBarView`; vertical usa `VerticalTabBar`.
- `Cmd+Shift+B` alterna o layout sem recriar tabs ou sessões.
- A barra vertical suporta criar, selecionar, fechar e reordenar tabs.
