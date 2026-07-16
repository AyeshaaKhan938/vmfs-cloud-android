# VMFS Cloud Mobile

Native **Flutter** app (Android + iOS) for VMFS USA Cloud — mirrors the web admin panel via REST API.

## Project location

```
/Users/pl/vmfs_cloud_mobile   ← Flutter app (this project)
/Users/pl/vms-cloud-laravel   ← Laravel backend + mobile API
```

## Features

- Login (Sanctum token, same credentials as web)
- Dashboard KPIs
- Machines list + hub detail (slots, stock)
- Products list + product hub (deployments, lotteries)
- Orders list + order detail
- Support tickets + create + chat messages
- **More tab:** full menu matching web navigation groups:
  - Reports & analytics (30-day sales & profit)
  - Machine map, groups, alarms
  - Product categories, tags, types, coupons, lotteries
  - Advertising list, groups, tags
  - Wallet + recharge records
  - Team members
- Role-based menu (uses `features` from API)
- VMFS amber theme

## Run locally

```bash
cd /Users/pl/vmfs_cloud_mobile
flutter pub get

# Laravel must be running with mobile API:
cd /Users/pl/vms-cloud-laravel && php artisan serve

# Flutter (Android emulator / device):
flutter run --dart-define=API_BASE_URL=http://127.0.0.1:8000/api/mobile/v1
```

**Login:** `customer@test.com` / `password` (or your web admin user)

## Build APK (Android)

```bash
flutter build apk --release \
  --dart-define=API_BASE_URL=https://cloud.vmfsusa.com/api/mobile/v1
```

APK output: `build/app/outputs/flutter-apk/app-release.apk`

## Backend requirements

Laravel mobile API under `/api/mobile/v1` (Sanctum + migrations). Deploy API to production before pointing the release APK at `cloud.vmfsusa.com`.

## Store checklist

- Privacy policy URL
- Demo account for App Review
- Screenshots (no placeholder screens)
- Google Play + Apple signing configured in store consoles
