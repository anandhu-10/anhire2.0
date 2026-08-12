# AI Placement Preparation Platform

This file documents the structure and conventions of the AI Placement Preparation Platform to help future AI agents navigate and modify the codebase.

## Tech Stack
- Frontend: Flutter (Android + Web), Riverpod (State Management), GoRouter (Routing)
- Backend: Firebase (Auth, Firestore, Cloud Functions in TypeScript)
- External APIs: Cloudinary (File Uploads), Piston API (Code Execution), Google Gemini (via Cloud Functions)

## Architecture Conventions
We use a **Clean Architecture** approach:
1. **UI Layer (`/screens`, `/widgets`)**: Contains all Flutter UI code. Uses Riverpod `ref.watch` and `ref.read` to get data and trigger actions. Should never call Firebase directly.
2. **State Layer (`/providers`)**: Contains Riverpod providers that bridge the UI and Repositories.
3. **Repository Layer (`/repositories`)**: Interfaces and implementations for data access (Firestore, Auth).
4. **Service Layer (`/services`)**: External integrations (Cloudinary, Cloud Functions).
5. **Data Layer (`/models`)**: Data classes (often with `freezed` or simple `fromJson`/`toJson`).

## Database Design
- `users`: `{ uid, email, role }`
- `profiles`: `{ uid, fullName, branch, targetSemester, preferredRole, targetCompanies, cgpa, resumeCloudinaryUrl, createdAt }`
- `coding_problems`, `aptitude_problems`, `coding_submissions`, `resume_reports`, `interview_results`, `roadmaps`.

## Important Rules
- Do NOT hardcode the Gemini API Key or Cloudinary Secret in the Flutter app. They must only exist in Cloud Functions (`functions/src`).
- Piston API calls for code execution also happen via Cloud Functions.
- Always use Material 3 and provide Loading, Error, and Empty states in UI.
- Use `flutter run -d chrome` for web testing.
