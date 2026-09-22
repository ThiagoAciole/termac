# Homebrew

O Termac é distribuído pelo tap pessoal [`ThiagoAciole/homebrew-termac`](https://github.com/ThiagoAciole/homebrew-termac) (não é o `homebrew-cask` oficial — o app é self-signed, sem notarização).

## Install

O Homebrew 6+ exige confiar em taps de terceiros antes de instalar:

```bash
brew trust --tap ThiagoAciole/termac
brew tap ThiagoAciole/termac
brew install --cask termac
```

O cask limpa o quarantine do Gatekeeper no `postflight`, então quem usa brew não precisa do passo manual de `xattr`. Os builds continuam self-signed — verifique o fingerprint SHA-256 da folha ([SIGNING.md](SIGNING.md)).

## Mantenedor: auto-bump na release

O workflow de release atualiza o `Casks/termac.rb` (`version` + `sha256`) após cada tag `v*` quando este secret existir:

| Secret               | Finalidade                                                                        |
| -------------------- | --------------------------------------------------------------------------------- |
| `HOMEBREW_TAP_TOKEN` | PAT (classic ou fine-grained) com **contents: write** em `ThiagoAciole/homebrew-termac` |

Crie um token fine-grained com escopo só nesse repo, então:

```bash
gh secret set HOMEBREW_TAP_TOKEN --repo ThiagoAciole/termac
```

Sem o secret, a release publica o zip normalmente e pula o bump do cask com um aviso.
