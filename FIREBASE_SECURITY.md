# Firebase Security Setup

## Mô tả
Dự án này đã được cấu hình để bảo vệ các Firebase API keys và config files quan trọng bằng cách sử dụng environment variables.

## Setup cho Developer mới

### 1. Tạo file .env
```bash
cp .env.example .env
```

### 2. Điền các giá trị thực tế vào .env
Lấy các giá trị từ Firebase Console của project `music-player-app-85a31`:
- Truy cập: https://console.firebase.google.com/project/music-player-app-85a31
- Vào Project Settings → General → Your apps
- Copy các API keys và config tương ứng vào file .env

### 3. Config files cần thiết
Đảm bảo các files sau được đặt đúng vị trí (KHÔNG commit vào Git):
- `android/app/google-services.json`
- `ios/Runner/GoogleService-Info.plist`
- `macos/Runner/GoogleService-Info.plist`

## Files bị ignore trong Git
- `.env` - Environment variables
- `lib/firebase_options.dart` - Firebase config (dùng firebase_options_secure.dart thay thế)
- `**/google-services.json` - Android Firebase config
- `**/GoogleService-Info.plist` - iOS/macOS Firebase config
- `firebase.json` - Firebase project config

## Cấu trúc bảo mật

### Environment Variables (.env)
Chứa tất cả API keys và config nhạy cảm:
- Firebase API keys cho từng platform
- Project IDs và App IDs
- SoundCloud Client ID

### Secure Firebase Options
File `lib/firebase_options_secure.dart` đọc config từ environment variables thay vì hardcode.

## Lưu ý quan trọng
1. **KHÔNG BAO GIỜ** commit file `.env` vào Git
2. **KHÔNG** chia sẻ API keys qua chat/email
3. Khi deploy production, sử dụng secure environment management
4. Thường xuyên rotate API keys nếu bị lộ

## Production Deployment
Đối với production, sử dụng:
- Flutter build-time environment variables
- Cloud secret management (AWS Secrets Manager, Google Secret Manager)
- CI/CD environment variables