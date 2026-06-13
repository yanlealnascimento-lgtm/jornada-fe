# JourneyFaith — Setup Firebase no Android

## Package Name

```
com.journeyfaith.app
```

## Onde baixar o google-services.json

1. Acesse: https://console.firebase.google.com/project/journeyfaith-b78bd/overview
2. Clique no ícone de **Android** (ou "Adicionar app" → Android)
3. **Package name:** `com.journeyfaith.app`
4. Clique em **Registrar app**
5. Baixe o **`google-services.json`**
6. Coloque o arquivo em:

```
journeyfaith/app/android/app/google-services.json
```

## O que já foi configurado (não precisa fazer)

- ✅ `applicationId = "com.journeyfaith.app"` no `build.gradle.kts`
- ✅ Plugin `com.google.gms.google-services` adicionado
- ✅ Dependências Firebase no `pubspec.yaml`

## Após colocar o google-services.json

```bash
cd journeyfaith/app
flutter run
```

O app já vai inicializar o Firebase e registrar o FCM token automaticamente.
