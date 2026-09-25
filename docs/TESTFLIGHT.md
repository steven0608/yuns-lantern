# Getting Yun's Lantern onto your iPhone and iPad (TestFlight)

GitHub builds the iOS app on a Mac for you. To sign it and send it to TestFlight it needs
**one key file and three IDs** from your Apple Developer account. No certificates or
provisioning profiles to export: Xcode creates and manages those itself using the key.

You do steps 1–4 once (≈15 minutes). After that every push to `master` delivers a new
TestFlight build automatically.

## 1. Register the app's ID
1. Go to <https://developer.apple.com/account> → **Certificates, IDs & Profiles** → **Identifiers** → **+**.
2. Choose **App IDs** → **App** → Continue.
3. Description: `Yun's Lantern`. Bundle ID: **Explicit** → `com.yunslantern.yunsLantern`
   (exactly this — it's what the app uses).
4. Capabilities: leave the defaults (In-App Purchase is on by default). **Continue** → **Register**.

## 2. Create the app in App Store Connect
1. Go to <https://appstoreconnect.apple.com> → **Apps** → **+** → **New App**.
2. Platform **iOS**. Name: `Yun's Lantern` (if taken, try `Yun's Lantern – Mandarin` or similar;
   the name can change later). Primary language **English (U.S.)**.
3. Bundle ID: pick `com.yunslantern.yunsLantern`. SKU: `yunslantern001`. User access: Full.
4. **Create**. (Store listing, price and review questions can wait — TestFlight for yourself
   doesn't need them.)

## 3. Create the API key
1. App Store Connect → **Users and Access** → **Integrations** tab → **App Store Connect API** →
   **Team Keys** → **+** (if asked, request access first — only the Account Holder can).
2. Name: `GitHub Actions`. Access: **Admin** (needed so Xcode can create the signing certificate).
3. **Generate**, then **Download API Key**. You get a file like `AuthKey_ABC123DEFG.p8`.
   ⚠️ It can be downloaded only once — keep it somewhere safe (not in the repo).
4. Note two values on that page: the **Key ID** (e.g. `ABC123DEFG`) and the **Issuer ID**
   (a long code above the keys list, like `69a6de7e-…`).

## 4. Find your Team ID
<https://developer.apple.com/account> → **Membership details** → **Team ID** (10 characters).

## 5. Give them to GitHub (you run these; they never pass through Claude)
In the Claude desktop app, open a terminal in the `yuns_lantern` folder and run the four
commands below, replacing the example values. `gh` is already logged in as you.

```bash
gh secret set APPSTORE_API_KEY_P8 < "$HOME/Downloads/AuthKey_ABC123DEFG.p8"
```
```bash
gh secret set APPSTORE_API_KEY_ID --body "ABC123DEFG"
```
```bash
gh secret set APPSTORE_API_ISSUER_ID --body "69a6de7e-0000-0000-0000-000000000000"
```
```bash
gh secret set APPLE_TEAM_ID --body "ABCDE12345"
```

Then start a build:
```bash
gh workflow run ios.yml
```

## 6. Install
About 20–30 minutes later the build appears in App Store Connect → your app → **TestFlight**.
1. Add yourself under **Internal Testing** (+ next to Testers), plus family members with Apple IDs
   (they must be added as users in App Store Connect first).
2. Install the **TestFlight** app from the App Store on your iPhone and iPad, open the invite email,
   tap **Install**.

If "Missing Compliance" appears on the build: the app already declares it uses no special
encryption (`ITSAppUsesNonExemptEncryption = NO`), so it should not — if it does, answer **None
of the algorithms mentioned above**.

## Notes
- TestFlight builds unlock everything (`YL_ALL_FREE`) so all content can be tested. The App Store
  release build will have the real free tier and the in-app purchase.
- Voices are machine-generated placeholders; native-speaker recordings replace them before release.
- Region: United States (no mainland China listing, so no ICP filing needed).
