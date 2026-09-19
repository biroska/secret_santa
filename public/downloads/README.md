# Pasta de downloads do APK (uso local apenas)

O Firebase Hosting no plano Spark (gratuito) bloqueia o deploy de arquivos
executáveis como `.apk` (`Executable files are forbidden on the Spark billing
plan`). Por isso o APK **não é mais servido pelo Firebase Hosting** nem
commitado neste repositório (veja `.gitignore`: `public/downloads/*.apk`).

O botão de download em `public/install.html` aponta para o asset de uma
GitHub Release:

```
https://github.com/biroska/secret_santa/releases/latest/download/secretsanta.apk
```

## Como publicar uma nova versão

```powershell
flutter build apk --release
Copy-Item build\app\outputs\flutter-apk\app-release.apk public\downloads\secretsanta.apk
gh release create vX.Y.Z public\downloads\secretsanta.apk --title "vX.Y.Z" --notes "Release vX.Y.Z"
```

Sempre nomeie o asset exatamente `secretsanta.apk` para que o link
`releases/latest/download/secretsanta.apk` continue funcionando sem precisar
atualizar `install.html` a cada versão.

**Importante:** o SHA-256 da chave usada para assinar esse APK precisa ser o
mesmo cadastrado em `public/.well-known/assetlinks.json`, senão a verificação
de Android App Links falha.
