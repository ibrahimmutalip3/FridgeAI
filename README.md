# FridgeAI

An AI-powered food assistant. Photograph your fridge, groceries, or food on
the table — FridgeAI identifies the ingredients and generates recipes you can
actually cook, using the [Groq API](https://groq.com) directly from the app.
There is no backend server.

This repository is built to be managed entirely from GitHub (including from
an iPhone) via GitHub Actions — no local computer or Xcode/Android Studio
install is required to produce installable builds.

## Repository layout

```
/
├── .github/workflows/
│   ├── android.yml     # builds a release APK on every push to main
│   └── ios.yml         # builds an unsigned iOS .ipa on every push to main
└── fridge_ai/           # the Flutter project itself
    ├── android/
    ├── ios/
    ├── lib/
    ├── assets/
    ├── test/
    └── pubspec.yaml
```

## One-time setup

1. Push this repository to GitHub.
2. Go to **Settings → Secrets and variables → Actions → New repository
   secret**.
3. Add a secret named exactly `GROQ_API_KEY` with your Groq API key as the
   value. Get a key at [console.groq.com](https://console.groq.com).

That's it — no other configuration is needed. Both workflows also support
**Actions → (workflow) → Run workflow** for a manual trigger
(`workflow_dispatch`), in addition to running automatically on every push to
`main`.

## Getting the Android build

1. Push a commit to `main` (or run the **Android Build** workflow manually).
2. Open the **Actions** tab → the latest **Android Build** run → scroll to
   **Artifacts** → download `FridgeAI-release-apk`.
3. Unzip it and install `app-release.apk` on an Android device (you'll need
   to allow installs from unknown sources, since it isn't signed for the
   Play Store).

## Getting the iOS build (unsigned)

1. Push a commit to `main` (or run the **iOS Build (Unsigned)** workflow
   manually).
2. Open the **Actions** tab → the latest **iOS Build (Unsigned)** run →
   download the `FridgeAI-unsigned-ipa` artifact.
3. Unzip it to get `FridgeAI-unsigned.ipa`.
4. Sign it yourself with a tool like **ESign**, **AltStore**, or **Sideloadly**
   using your own Apple ID, then install it on your iPhone.

No Apple Developer certificate, provisioning profile, or Mac is used or
required anywhere in this repository — signing happens entirely on your end,
after the fact.

## How the AI integration works

- `lib/core/constants/groq_config.dart` centralizes the Groq model names and
  reads the API key via `String.fromEnvironment('GROQ_API_KEY')` — the key is
  baked in at **build time** by the `--dart-define=GROQ_API_KEY=...` flag in
  both workflows, sourced from the `GROQ_API_KEY` repository secret. It is
  never written to a file, never logged, and never hardcoded.
- `lib/services/groq_service.dart` is the only place that talks to the Groq
  API — one call for vision-based ingredient detection, one for recipe
  generation from a confirmed ingredient list.

Because the key ships inside the compiled app, it can technically be
extracted by someone with the APK/IPA (this is inherent to any backend-less,
client-only architecture, and is an accepted tradeoff here — see the Groq
dashboard for usage limits/rotation if that's a concern).

## App icon & splash screen

- The app icon (`fridge_ai/assets/icons/app_icon.png`, 1024×1024) is used to
  generate every Android/iOS launcher icon size via `flutter_launcher_icons`
  (configured in `pubspec.yaml`, run automatically in both CI workflows
  before the build step).
- The **native** launch screen (Android `launch_background.xml`, iOS
  `LaunchScreen.storyboard`) shows the same warm-orange gradient and logo
  mark as the icon, at rest, for the brief instant before the Flutter engine
  draws its first frame.
- The **Flutter** splash screen (`lib/features/splash/splash_screen.dart` +
  `lib/features/splash/widgets/morph_logo_painter.dart`) then takes over with
  a full morph animation: the logo mark draws itself on stroke-by-stroke,
  scales in with a soft overshoot, the sparkle twinkles, the wordmark fades
  up, and the whole scene cross-fades into onboarding or home — one
  continuous motion, no hard cuts.

## Running tests / analysis locally

If you ever do have access to a machine with the Flutter SDK:

```bash
cd fridge_ai
flutter pub get
flutter analyze
flutter test
```

Both CI workflows run `flutter analyze` and `flutter test` before building,
so a broken build will fail fast in the Actions tab rather than silently
producing a bad artifact.
