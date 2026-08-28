# AI Placement Preparation Platform (ANHIRE)

A modern, responsive AI Placement Preparation web and mobile application built with Flutter, Riverpod, Firebase, Gemini 2.0 Flash AI, Cloudinary, and Syncfusion PDF.

## Security Note
> **Note**: This is a student project MVP. The Gemini API key and Cloudinary upload credentials are configured client-side via `.env` for simplicity. In a production release, API calls would be routed through a secure backend proxy server.

## Features
- **Authentication**: Firebase Auth with password reset & persistent auto-login.
- **AI Resume Analyzer**: PDF text extraction, direct Cloudinary upload, Gemini 2.0 Flash ATS score evaluation, missing keyword identification, and actionable suggestions.
- **Practice Hub**: Coding playground with multi-language execution and aptitude assessments.
- **Mock Interviews**: Interactive AI-evaluated interview questions with score gauges.
- **Responsive Layout**: Adapts from 375px mobile phones to wide 1440px desktop screens.

## Setup Instructions
1. Copy `.env.example` to `.env`.
2. Configure your `GEMINI_API_KEY`, `CLOUDINARY_CLOUD_NAME`, `CLOUDINARY_UPLOAD_PRESET`, and `PISTON_API_URL`.
3. Run `flutter pub get`.
4. Launch with `flutter run -d chrome --web-port=8080`.
