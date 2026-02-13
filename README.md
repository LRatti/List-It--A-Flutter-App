# List It 🛒

**List It** is a smart, offline-first grocery shopping assistant designed to make the shopping process efficient and insightful. Built with **Flutter**, it leverages Generative AI and on-device Machine Learning to automate list organization and track spending habits.

<div align="center">
<img src="assets/images/app_logo.png" alt="List It Logo" width="150" height="150"/>
<br>

![alt text](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white)


![alt text](https://img.shields.io/badge/Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white)


![alt text](https://img.shields.io/badge/Firebase-FFCA28?style=for-the-badge&logo=firebase&logoColor=black)


![alt text](https://img.shields.io/badge/SQLite-003B57?style=for-the-badge&logo=sqlite&logoColor=white)


![alt text](https://img.shields.io/badge/State-Riverpod-purple?style=for-the-badge)

</div>
<br>

> **Course:** Design and Implementation of Mobile Applications (DIMA)  
> **Institution:** Politecnico di Milano  
> **Academic Year:** 2025-2026  
> **Professor:** Luciano Baresi

---

## 📋 Overview

Grocery shopping is often inefficient due to disorganized lists and difficult expense tracking. **List It** solves these problems by:
1.  **Automating Organization:** Automatically categorizing products to match supermarket aisles using AI.
2.  **Tracking Expenses:** extracting prices from receipts via OCR and AI to provide detailed spending statistics.
3.  **Syncing Everywhere:** Implementing a custom **offline-first** synchronization engine to keep data consistent across devices.

## ✨ Key Features

### 🧠 AI-Powered Intelligence
-   **Smart Categorization:** Uses **Google Gemini Flash 2.5** to automatically assign categories to products (e.g., "Apples" → "Fruit & Veg").
-   **Recipe Import:** Generate shopping lists from recipe names using GenAI.
-   **Receipt Scanning:** Snap a photo of your receipt; the app uses **Google ML Kit (OCR)** and Gemini to match prices and quantities to your list items automatically.

### 📍 Location & Context
-   **Supermarket Awareness:** Retrieves the nearest supermarkets using **OpenStreetMap (Overpass API)**.
-   **Custom Layouts:** Reorder categories per supermarket to match the physical aisle layout.

### 📊 Data & Sync
-   **Offline-First:** Works entirely without an internet connection using a local SQLite database.
-   **Multi-Device Sync:** Custom synchronization engine (Push/Pull) with **Firestore** for seamless cross-device usage.
-   **Statistics:** Aggregated expense charts by time period and category.

### 📱 User Experience
-   **Cross-Platform:** Android & iOS.
-   **Adaptive UI:** Optimized layouts for both **Smartphones** and **Tablets** (Master-Detail view).
-   **Accessibility:** Dark Mode, Font Size Scaling, and Localization (English/Italian).

## 🛠️ Architecture & Tech Stack

The application follows a clean, layered architecture to ensure separation of concerns and testability.

### Core Technologies
*   **Framework:** Flutter
*   **State Management:** [Riverpod](https://riverpod.dev/)
*   **Local Database:** [sqflite](https://pub.dev/packages/sqflite) (SQLite)
*   **Remote Backend:** Firebase (Auth, Firestore)
*   **AI & ML:** [google_generative_ai](https://pub.dev/packages/google_generative_ai), [google_mlkit_text_recognition](https://pub.dev/packages/google_mlkit_text_recognition)
*   **Location:** [geolocator](https://pub.dev/packages/geolocator)

### High-Level Architecture
The app implements a **Repository Pattern** with a custom sync layer:

`UI` ↔ `UI Controllers` ↔  `Notifiers (Riverpod)` ↔ `Repositories` ↔ `Data Sources (Local/Remote)`

1.  **Offline-First Strategy:** All reads/writes happen against the local SQLite database.
2.  **Sync Engine:** A background process monitors a local `sync_box` table. It pushes changes to Firestore and pulls remote updates using a "Last Write Wins" conflict resolution strategy.

## 🔧 Project Structure

```text
/lib
├── l10n/          # Multi-language support (English/Italian).
├── models/        # Core data entities (ShoppingList, Product, User, etc.).
├── providers/     # Riverpod state management classes.
├── repositories/  # Abstractions for data access (Mock & Real implementations).
├── screens/       # UI Views and adaptive layouts.
├── services/      # External API clients (Gemini, OCR, Location).
├── styles/        # Theme, color, and style definitions.
├── utils/         # Helper functions and utilities.
├── widgets/       # Reusable UI components and custom widgets.
└── main.dart      # Application entry point.
```

## 🧪 Testing

The project maintains a high standard of quality assurance with approximately **70% code coverage**.

- **Unit Tests**: Validate models, repositories, and the synchronization logic.
- **Widget Tests**: Verify UI components and screen interactions using `mocktail` for dependency isolation.
- **Integration Tests**: Cover 6 critical user flows:
    1.  Authentication Flow.
    2.  List Registration & Persistence.
    3.  Category Management.
    4.  Supermarket Management.
    5.  Statistics Updates.
    6.  Category Persistence.

## 🚀 Getting Started

### Prerequisites
The application environment is configured for the following versions:
- **Flutter SDK**: `3.19.x` (Stable Channel)
- **Dart SDK**: `^3.9.2`

### Installation

1.  **Clone the Repository**
    ```bash
    git clone https://github.com/YOUR_USERNAME/List-It.git
    cd app_code
    ```

2.  **Install Dependencies**
    ```bash
    flutter pub get
    ```

3.  **Environment Configuration**
    The app requires a Gemini API key. Pass it as a dart-define during build/run:
    ```bash
    flutter run --dart-define=GEMINI_API_KEY=your_api_key_here
    ```

4.  **Firebase Setup**
    Ensure `google-services.json` (Android) and `GoogleService-Info.plist` (iOS) are placed in their respective directories (`android/app` and `ios/Runner`) to connect to the backend.

## 📸 Screenshots

<div align="center">
  <!-- You can upload your screenshots to an 'assets/screenshots' folder or link them here -->
  <img src="assets/images/app_logo.png" width="200" alt="Lists Screen" />
  <img src="assets/images/app_logo.png" width="200" alt="Recipe AI" />
  <img src="assets/images/app_logo.png" width="200" alt="Statistics" />
</div>

## 👥 Authors

- **Leonardo Ratti** - [GitHub](https://github.com/LRatti)
- **Mattia Peruzzi** - [GitHub](https://github.com/MattiaPeru)

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
```
