# Assinatura

Builds de release são assinados com a identidade estável **Termac Self-Signed** (não é Apple Developer ID, não é notarizado). A mesma identidade é usada em toda distribuição para que os usuários possam verificar a assinatura.

**Não confie só no string da Authority** — qualquer um pode criar um certificado com CN `Termac Self-Signed`. Confira sempre o fingerprint SHA-256 da folha:

```bash
codesign -dv --verbose=4 Termac.app
# esperado: Authority=Termac Self-Signed
codesign --verify --verbose=4 Termac.app

codesign -d --extract-certificates=/tmp/termac-cert Termac.app
openssl x509 -inform DER -in /tmp/termac-cert0 -noout -fingerprint -sha256
# esperado: SHA256 Fingerprint=BD:34:10:13:1B:F1:D6:58:CD:0E:82:C6:58:5C:0A:B1:EC:30:C9:C8:F8:26:C9:85:61:4C:58:25:14:C5:EE:D4
rm -f /tmp/termac-cert*
```

## Caminho rápido

Na raiz do repo:

```bash
./Script/setup-signing.sh
```

Cria a identidade se não existir e imprime os comandos `gh secret set` (ou roda-os se o `gh` estiver autenticado). Se a identidade já existe, o script imprime o fingerprint e instruções para exportar **só** ela (nunca exporta o keychain inteiro).

## 1. Criar a identidade (uma vez)

Prefira `./Script/setup-signing.sh`. Equivalente manual:

```sh
TMP="$(mktemp -d)"
openssl req -x509 -newkey rsa:2048 -nodes -days 3650 \
  -keyout "$TMP/key.pem" -out "$TMP/cert.pem" \
  -subj "/CN=Termac Self-Signed" \
  -addext "basicConstraints=critical,CA:false" \
  -addext "keyUsage=critical,digitalSignature" \
  -addext "extendedKeyUsage=critical,codeSigning"

openssl x509 -in "$TMP/cert.pem" -noout -fingerprint -sha256
# Se rotacionar: atualize o fingerprint nos docs (README / TROUBLESHOOTING / aqui).

# Defaults do OpenSSL 3 quebram o `security import` do macOS — use PBE clássico.
LOCAL_PASS="$(openssl rand -hex 12)"
openssl pkcs12 -export -inkey "$TMP/key.pem" -in "$TMP/cert.pem" \
  -name "Termac Self-Signed" -out "$TMP/termac.p12" -passout "pass:${LOCAL_PASS}" \
  -keypbe PBE-SHA1-3DES -certpbe PBE-SHA1-3DES -macalg sha1

security import "$TMP/termac.p12" -k ~/Library/Keychains/login.keychain-db \
  -P "$LOCAL_PASS" -T /usr/bin/codesign

rm -rf "$TMP"
```

Verificar:

```sh
security find-identity -p codesigning | grep "Termac Self-Signed"
```

## 2. Gerar o DMG assinado

```bash
./Script/make-dmg.sh          # build Release + assina + empacota
./Script/make-dmg.sh --skip-build   # reempacota o build atual
```

O script assina o app com a identidade, monta o volume com o `Termac.app` + link `/Applications`, cria `dist/Termac-<versão>.dmg` e remonta o DMG para verificar a assinatura.

## 3. Segredos de CI

O workflow [`.github/workflows/release.yml`](../.github/workflows/release.yml) importa a identidade destes secrets e confere o fingerprint contra o `EXPECTED_FINGERPRINT` hardcodeado. Sem os secrets, o build roda com identidade descartável e publica só artifacts (nunca release).

Exporte **só** a identidade Termac (Keychain Access → selecione `Termac Self-Signed` → File → Export Items… como PKCS#12). **Não** rode `security export -t identities` no keychain inteiro — isso pode empacotar chaves alheias no secret.

```sh
P12_PASSWORD="$(openssl rand -hex 24)"; echo "password: $P12_PASSWORD"
# use a senha no diálogo de exportação do Keychain Access, então:
base64 -i /caminho/Termac.p12 | tr -d '\n' > /tmp/signing.p12.base64
rm -f /caminho/Termac.p12

gh secret set SIGNING_P12_BASE64 < /tmp/signing.p12.base64
gh secret set SIGNING_P12_PASSWORD --body "$P12_PASSWORD"
rm -f /tmp/signing.p12.base64
```

Perdeu os secrets mas a identidade ainda está no keychain? Re-exporte **só ela** (seção 3). Perdeu a identidade inteira? Recrie (seção 1), atualize o fingerprint nos docs e refaça os secrets — a Authority continua `Termac Self-Signed`, mas é uma chave nova.

## Quarantine

Self-signing não satisfaz o Gatekeeper para downloads. O cask do Homebrew limpa o quarantine no `postflight` — [HOMEBREW.md](HOMEBREW.md). Instalação manual: [TROUBLESHOOTING.md](TROUBLESHOOTING.md).
