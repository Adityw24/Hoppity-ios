# Hoppity iOS — Build & Ship Guide

This is a cleaned, ready-to-build version of your project. The original zip was **not buildable**:
its `.xcodeproj` was empty, every source file was duplicated, and there was a junk folder from a
broken shell command. This package fixes all of that. The Xcode project is generated from
`project.yml` using **XcodeGen** (one command), so you always get a clean, conflict-free project.

---

## Prerequisites (you have these)
- A Mac with **Xcode 15+** installed.
- An **Apple Developer Program** account ($99/yr).

## One-time tool install
Install XcodeGen (generates the `.xcodeproj` from `project.yml`):
```bash
brew install xcodegen
```
(No Homebrew? Install from https://brew.sh first, or `mint install yonaskolb/XcodeGen`.)

---

## Step 1 — Set your Team ID and Bundle ID
Open `project.yml` and edit two lines under `settings: base:`
- `PRODUCT_BUNDLE_IDENTIFIER: in.hoppity.app` → your reverse-DNS App ID (must be unique on the App Store).
- `DEVELOPMENT_TEAM: ""` → your 10-character Apple Team ID
  (find it at https://developer.apple.com/account → Membership details).

## Step 2 — Generate the Xcode project
From the folder containing `project.yml`:
```bash
cd HoppityProject
xcodegen generate
open Hoppity.xcodeproj
```
Xcode opens and automatically resolves the Supabase Swift package (give it a minute on first open).

## Step 3 — Run it
1. Pick an iPhone simulator (e.g. iPhone 15) in the toolbar.
2. Press **⌘R**. The app should build and launch.
3. Test sign-up / sign-in, the feed, tours, booking, and profile flows.

> Fonts have a built-in system fallback, so the app runs even if a font fails to load.
> Google sign-in goes through Supabase OAuth (no Google SDK dependency).

---

## Step 4 — Register the App ID, capabilities & redirect URLs
Before shipping, make sure these match your Bundle ID:
- **Apple Developer → Certificates, IDs & Profiles → Identifiers**: create an App ID matching
  `PRODUCT_BUNDLE_IDENTIFIER`. Enable **Sign in with Apple** only if you add it (not currently used).
- **Supabase → Authentication → URL Configuration**: confirm the redirect scheme
  `io.supabase.hoppity://` is allowed (already wired in Info.plist).
- **Google Cloud Console**: the iOS OAuth client `...-6ke194as54ppgiphr2itrvri6rod4261` must have
  your Bundle ID registered. If you change the Bundle ID, update it here too.

## Step 5 — App Store Connect setup
1. Go to https://appstoreconnect.apple.com → **Apps → +** → New App.
2. Fill in: name (e.g. "Hoppity – Discover Real India"), primary language, bundle ID, SKU.
3. Prepare required metadata (see checklist below).

## Step 6 — Archive & upload
1. In Xcode, set the run destination to **Any iOS Device (arm64)** (not a simulator).
2. **Product → Archive**.
3. When the Organizer opens: **Distribute App → App Store Connect → Upload**.
4. Let Xcode manage signing automatically (it creates the distribution cert + provisioning profile).
5. After upload, the build appears in App Store Connect under **TestFlight** in ~5–30 min.

## Step 7 — TestFlight, then submit for review
1. Test the uploaded build via **TestFlight** on a real device first.
2. In App Store Connect, attach the build to your app version, complete all metadata,
   answer the **App Privacy** and **Encryption (ITSAR)** questions, then **Submit for Review**.
3. Apple review typically takes 24–48 hours.

---

## App Store submission checklist
- [ ] App icon (1024×1024) — already included in the asset catalog.
- [ ] Screenshots: 6.7" (iPhone 15 Pro Max) and 6.5" sizes at minimum.
- [ ] App description, keywords, support URL, marketing URL.
- [ ] **Privacy Policy URL** (required — your app collects accounts, photos, location-style data).
- [ ] App Privacy "nutrition label": declare data collected (email, name, photos, usage).
- [ ] Age rating questionnaire.
- [ ] Demo account credentials for the reviewer (they must be able to log in to test).
- [ ] Export compliance: standard HTTPS only → usually "No" to custom encryption.

## Common pitfalls
- **"No account for team"** → set `DEVELOPMENT_TEAM` in project.yml, re-run `xcodegen generate`.
- **Package resolution fails** → File → Packages → Reset Package Caches, then resolve again.
- **Bundle ID already in use** → pick a different `PRODUCT_BUNDLE_IDENTIFIER`.
- **Guideline 4.3 / 5.1.1 rejections** → ensure a working demo login and a reachable privacy policy.
- **Sign-in fails on device** → re-check the Supabase redirect URL and Google iOS client Bundle ID.

## Re-generating after edits
Any time you add/rename files or change settings, just re-run:
```bash
xcodegen generate
```
You never hand-edit the `.xcodeproj`, so there are no merge conflicts.
