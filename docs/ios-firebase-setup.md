# JourneyFaith — Setup Firebase no iOS

> **Status:** Bypass temporário. Implementar antes de publicar na App Store.

## Informações do App

| Campo | Valor |
|---|---|
| **Bundle ID** | `com.journeyfaith.app` |
| **App Name** | JourneyFaith |
| **Firebase Project** | `journeyfaith-b78bd` |
| **Team ID** | A definir (Apple Developer Account) |

---

## Passo a Passo

### 1. Registrar app iOS no Firebase Console

1. Acesse [console.firebase.google.com](https://console.firebase.google.com) → projeto `journeyfaith-b78bd`
2. Clique em **"Adicionar app"** → selecione **iOS**
3. **iOS bundle ID:** `com.journeyfaith.app`
4. Clique em **Registrar app**
5. Baixe o arquivo **`GoogleService-Info.plist`**

### 2. Adicionar o arquivo ao projeto Flutter

```bash
# Copiar para a pasta correta
cp ~/Downloads/GoogleService-Info.plist journeyfaith/app/ios/Runner/
```

No Xcode:
1. Abra `app/ios/Runner.xcworkspace` no Xcode
2. Clique com botão direito em `Runner` → **Add Files to "Runner"**
3. Selecione `GoogleService-Info.plist`
4. Marque **"Copy items if needed"** e **"Add to target: Runner"**
5. Confirme

### 3. Configurar Bundle ID no Xcode

1. Selecione o projeto `Runner` na sidebar
2. Aba **Signing & Capabilities**
3. **Bundle Identifier:** `com.journeyfaith.app`
4. Selecione seu **Team** (Apple Developer Account)

### 4. Ativar Push Notifications no Xcode

1. Aba **Signing & Capabilities**
2. Clique em **"+ Capability"**
3. Adicione **Push Notifications**
4. Adicione **Background Modes** → marque **Remote notifications**

### 5. Configurar APNs no Firebase

Para enviar push no iOS, o Firebase precisa do certificado APNs:

1. Acesse [developer.apple.com](https://developer.apple.com) → Certificates
2. Crie um **Apple Push Notification service (APNs) Key**
3. Baixe o arquivo `.p8`
4. No Firebase Console → Projeto → Configurações → Cloud Messaging
5. Na seção **Apple app configuration** → faça upload do `.p8`
6. Preencha **Key ID** e **Team ID**

### 6. Configurar flutter_local_notifications (opcional — para foreground no iOS)

No `ios/Runner/AppDelegate.swift`, adicionar:

```swift
import UIKit
import Flutter
import FirebaseCore
import FirebaseMessaging

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    FirebaseApp.configure()

    // Solicitar permissão de notificação
    UNUserNotificationCenter.current().delegate = self
    let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
    UNUserNotificationCenter.current().requestAuthorization(
      options: authOptions,
      completionHandler: { _, _ in }
    )
    application.registerForRemoteNotifications()

    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
```

### 7. Remover o bypass temporário no main.dart

Quando o iOS estiver configurado, descomentar em `app/lib/main.dart`:

```dart
// ANTES (bypass):
// await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

// DEPOIS (ativo):
await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
```

E instalar o FlutterFire CLI para gerar `firebase_options.dart`:

```bash
dart pub global activate flutterfire_cli
cd journeyfaith/app
flutterfire configure --project=journeyfaith-b78bd
```

---

## Checklist Final iOS

- [ ] `GoogleService-Info.plist` adicionado ao projeto Xcode
- [ ] Bundle ID configurado: `com.journeyfaith.app`
- [ ] Push Notifications capability ativada
- [ ] Background Modes → Remote notifications ativado
- [ ] APNs Key (.p8) configurada no Firebase Console
- [ ] `firebase_options.dart` gerado com FlutterFire CLI
- [ ] `main.dart` atualizado (Firebase.initializeApp descomentado)
- [ ] Testado no simulador iOS e dispositivo físico
- [ ] Testado recebimento de push em foreground e background
