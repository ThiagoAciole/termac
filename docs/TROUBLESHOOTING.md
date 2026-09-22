# Solução de problemas

## Gatekeeper bloqueia o app

Os builds são self-signed (não notarizados). Na primeira abertura o macOS pode recusar executar.

**Recomendado:** botão direito (ou Control-click) no `Termac.app` → **Abrir** → **Abrir** de novo no diálogo. Só precisa uma vez.

**Alternativa:**

```bash
xattr -dr com.apple.quarantine /caminho/para/Termac.app
open /caminho/para/Termac.app
```

Para confirmar a assinatura (Authority **e** fingerprint da folha — o CN sozinho é falsificável):

```bash
codesign -dv --verbose=4 /caminho/para/Termac.app
# esperado: Authority=Termac Self-Signed
codesign -d --extract-certificates=/tmp/termac-cert /caminho/para/Termac.app
openssl x509 -inform DER -in /tmp/termac-cert0 -noout -fingerprint -sha256
# esperado: SHA256 Fingerprint=21:39:A4:00:00:4C:B8:14:D9:D2:30:4D:D3:20:80:4E:78:96:B7:C7:46:59:EF:C4:B5:02:C0:04:79:C8:C6:7B
rm -f /tmp/termac-cert*
```

Instalações via Homebrew limpam o quarantine automaticamente — [HOMEBREW.md](HOMEBREW.md). Veja também a seção Builds self-signed no [README](../README.md) e [SIGNING.md](SIGNING.md).

## Pacotes do Ghostty não resolvem / submódulo faltando

O app depende de `Vendor/libghostty-spm`. Depois de um clone sem `--recurse-submodules`:

```bash
git submodule update --init --recursive
```

Reabra o `Termac.xcodeproj` e build o scheme **Termac**.

## libghostty desatualizado após bump do submódulo

Se o binary framework parecer errado depois de atualizar `Vendor/libghostty-spm`, limpe o DerivedData do projeto (ou Product → Clean Build Folder no Xcode) e build de novo.

## Ícone antigo no Dock/Finder

O macOS cacheia ícones agressivamente. Após trocar o ícone do app:

```bash
killall Dock
```

## Shells falham / sem PTY

O App Sandbox precisa ficar **off** (`ENABLE_APP_SANDBOX = NO`). O Termac usa o backend `.exec` do Ghostty para spawnar uma shell de login real; ligar o sandbox quebra isso.
