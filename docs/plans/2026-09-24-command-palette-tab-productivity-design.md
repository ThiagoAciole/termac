# Command Palette e produtividade de abas

## Contexto

O Termac já oferece abas, agentes de IA e um catálogo de atalhos, mas ações de produtividade ficam distribuídas entre header, menus e atalhos. O objetivo é criar um ponto de acesso único sem interferir na entrada do terminal.

## Escopo do MVP

### Command Palette

- Overlay SwiftUI central dentro da janela atual.
- Abertura pelo botão `Commands` no header ou `⌘K`.
- Fechamento com `Esc`.
- Foco automático no campo de busca.
- Lista única ranqueada, sem seções visuais.
- Itens de ações, abas abertas e agentes cadastrados.
- Navegação com `↑`/`↓` e execução com `Enter`.
- Fuzzy matching leve por subsequência, implementado sem dependência externa.
- Exemplos: `cld` encontra `Claude Code`; `mv dir` encontra `Move Tab Right`.
- Ações de abas selecionam a aba e fecham a palette.
- Ações de agentes abrem uma aba nova e executam o agente.
- A palette não intercepta `/` nem qualquer entrada do terminal.

### Produtividade de abas

- Reabrir a última aba fechada com `⌘⇧T` e pela palette.
- Pilha limitada a 10 snapshots de metadados.
- Snapshot: diretório de trabalho, título customizado, agente/cor, posição e pin.
- Processos, PTY e scrollback não são restaurados.
- Duplicar a aba selecionada no mesmo diretório.
- Para abas de agente, duplicar relança o mesmo agente.
- Reordenar abas por arraste na barra horizontal e no rail vertical.
- O `TabRoster` permanece como fonte de verdade da ordem.
- Drag-and-drop entre janelas fica fora do MVP.
- Persistência de sessão entre reinicializações fica fora do MVP.

## Arquitetura

### Catálogo da palette

Criar um catálogo de itens independente da view:

```swift
struct CommandPaletteItem: Identifiable {
    let id: String
    let title: String
    let subtitle: String?
    let icon: String
    let kind: Kind
    let searchTerms: [String]
    let execute: () -> Void
}
```

`Kind` terá `.action`, `.tab` e `.agent`.

`CommandPaletteView` cuidará apenas da apresentação, busca, seleção, teclado e execução. O `TabManager` montará os itens porque já conhece abas, seleção, criação de sessões, ações e agentes. A palette poderá exibir atalhos associados como subtítulo, reutilizando o `ShortcutsCatalog` sem transformá-lo na fonte do catálogo de ações.

### Overlay

Inserir a view em `ContentView`, acima do terminal e do chrome, usando material translúcido e largura máxima fixa. O terminal permanece montado por baixo. O estado de apresentação pode ser mantido no `TabManager` junto aos demais estados de UI (`isFindPresented`, query e foco).

### Fuzzy matching

Criar tipos puros para ranqueamento, sem dependência externa. A busca será case-insensitive e aceitará subsequência. A ordenação priorizará correspondência exata, prefixo, subsequência e menor distância/posição. Com a busca vazia, todos os itens disponíveis serão retornados em ordem estável.

### Snapshot de abas

Criar `ClosedTabSnapshot` com os metadados necessários para reabrir e um armazenamento limitado no `TabManager`. O fechamento deve capturar o snapshot antes de remover e terminar a sessão. Reabrir cria uma nova `TerminalSession` no diretório salvo e reaplica título, agente, cor, pin e posição sem tentar recuperar o processo anterior.

### Reordenação

Adicionar ao `TabRoster` uma operação pura que receba o ID arrastado e o índice/destino. A UI calcula o destino usando a posição visual; o roster aplica a ordem e preserva a seleção. A mesma operação deve atender às barras horizontal e vertical.

## Testes

### Matcher e catálogo

- Busca vazia retorna todos os itens.
- Busca case-insensitive.
- `cld` encontra `Claude Code`.
- `mv dir` encontra `Move Tab Right`.
- Exatos vêm antes de subsequências.
- Nenhum resultado não causa crash nem seleção inválida.

### Palette

- `⌘K` abre.
- `Esc` fecha.
- Campo recebe foco inicial.
- `↑`/`↓` percorrem com wrap-around.
- `Enter` executa somente o item selecionado.
- Selecionar aba ativa a aba correta.
- Selecionar agente cria uma sessão.
- Mudanças no catálogo mantêm o índice dentro dos limites.

### Abas

- Fechar e reabrir preserva o snapshot.
- Pilha mantém no máximo 10 itens.
- Reabertura respeita a ordem LIFO.
- Duplicação usa o mesmo diretório.
- Reordenação por destino preserva seleção.
- Pinning continua correto após reordenação.
- Nenhum processo existente é destruído durante busca ou reordenação.

## Critérios de aceite

- Ações não enviam texto acidentalmente ao PTY.
- A palette não captura `/` nem modifica o comportamento do shell.
- Executar um item fecha a palette automaticamente.
- A busca continua responsiva com muitas abas e agentes.
- A sessão Ghostty existente permanece intacta durante a interação.
- O projeto compila e a suíte `TermacTests` passa.

## Fora de escopo

- Autocomplete de `/` no terminal.
- Interceptação ou composição da entrada da shell.
- Restauração de processos, PTY ou scrollback.
- Persistência de workspace entre reinicializações.
- Arraste de abas entre janelas.
- Nova dependência para fuzzy matching.
- Splits/panes.
