# List It 🛒

**List It** is a smart, offline-first grocery shopping assistant designed to make the shopping process efficient and insightful. Built with **Flutter**, it leverages Generative AI and on-device Machine Learning to automate list organization and track spending habits.

<div align="center">
  <img src="app_code/assets/images/app_logo.png" alt="List It Logo" width="200" height="200"/>
  
  [![Flutter](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white)](https://flutter.dev/)
  [![Dart](https://img.shields.io/badge/Dart-3.9.2-0175C2?style=for-the-badge&logo=dart&logoColor=white)](https://dart.dev/)
  [![Firebase](https://img.shields.io/badge/Firebase-FFCA28?style=for-the-badge&logo=firebase&logoColor=black)](https://firebase.google.com/?_gl=1*1som8j*_up*MQ..&gclid=CjwKCAiAtLvMBhB_EiwA1u6_Pg4fqRTGb7QH1aNcPyIUfjXRpmRlNDXXJ9n7DhN59HPhoy2GkEMRZRoCjL0QAvD_BwE&gclsrc=aw.ds)
  [![SQLite](https://img.shields.io/badge/SQLite-003B57?style=for-the-badge&logo=sqlite&logoColor=white)](https://sqlite.org/)
  [![Riverpod](https://img.shields.io/badge/State-Riverpod-purple?style=for-the-badge)](https://riverpod.dev/)
</div>

> **Course:** Design and Implementation of Mobile Applications (DIMA)  
> **Institution:** Politecnico di Milano  
> **Academic Year:** 2025-2026  
> **Professor:** Luciano Baresi

---

## 📋 Overview

Grocery shopping is often inefficient due to disorganized lists and difficult expense tracking. **List It** solves these problems by:
1.  **Automating Organization:** Automatically categorizing products to match supermarket aisles using AI.
2.  **Tracking Expenses:** extracting prices from receipts via OCR and AI to provide detailed spending statistics.

## ✨ Key Features

### 🧠 AI-Powered Intelligence
-   **Smart Categorization:** Uses **Google Gemini Flash 2.5** to automatically assign categories to products (e.g., "Apples" → "Fruit & Veg").
-   **Recipe Import:** Generate shopping lists from recipe names using GenAI.
-   **Receipt Scanning:** Snap a photo of your receipt; the app uses **Google ML Kit (OCR)** and Gemini to match prices and quantities to your list items automatically.

### 📍 Location & Context
-   **Supermarket Awareness:** Retrieves the nearest supermarkets using **OpenStreetMap (Overpass API)**.

### 📊 Data & Sync
-   **Offline-First:** Works entirely without an internet connection using a local SQLite database.
-   **Multi-Device Sync:** Custom synchronization engine (Push/Pull) with **Firestore** for seamless cross-device usage.
-   **Statistics:** Aggregated expense charts by time period and category.

### 📱 User Experience
-   **Cross-Platform:** Android 5+ & iOS 3+, iPadOS 13+.
-   **Adaptive UI:** Optimized layouts for both **Smartphones** and **Tablets** (Master-Detail view).
-   **Accessibility:** Dark Mode, Font Size Scaling, and Localization (English/Italian).

## 🛠️ Architecture & Tech Stack

The application follows a clean, layered architecture to ensure separation of concerns and testability.

### High-Level Architecture
The app implements a **Repository Pattern** with a custom sync layer.

`UI` ↔ `UI Controllers` ↔  `Notifiers (Riverpod)` ↔ `Repositories` ↔ `Data Sources (Local/Remote Services)`

1.  **Offline-First Strategy:** All reads/writes happen against the local SQLite database.
2.  **Sync Engine:** A background process monitors a local `sync_box` table. It pushes changes to Firestore and pulls remote updates using a "Last Write Wins" conflict resolution strategy.
3. **Soft Deletes**: Data is marked as deleted (`isDeleted`) rather than immediately removed to ensure sync consistency.

### Core Technologies
*   **Framework:** Flutter
*   **State Management:** [Riverpod](https://riverpod.dev/)
*   **Local Database:** [sqflite](https://pub.dev/packages/sqflite) (SQLite) for offline persistance
*   **Remote Backend:** [Firebase (Auth, Firestore)](https://firebase.google.com/?_gl=1*1som8j*_up*MQ..&gclid=CjwKCAiAtLvMBhB_EiwA1u6_Pg4fqRTGb7QH1aNcPyIUfjXRpmRlNDXXJ9n7DhN59HPhoy2GkEMRZRoCjL0QAvD_BwE&gclsrc=aw.ds) 
*   **AI & ML:** [Google Gemini](https://pub.dev/packages/google_generative_ai), [Google ML Kit](https://pub.dev/packages/google_mlkit_text_recognition)
*   **Maps**: [OpenStreetMap](https://www.openstreetmap.org/#map=6/42.09/12.56) via [Overpass API](https://wiki.openstreetmap.org/wiki/Overpass_API)
*   **Location:** [geolocator](https://pub.dev/packages/geolocator)
*   **Camera:** [camera](https://pub.dev/packages/camera)

## 📱 Screenshots

<div align="center">
  <h3>Home Screen - Dark Themed</h3>
  <img src="app_code/assets/images/home_screen_dark_themed.png" alt="List It Home Screen - Dark Themed" width="00"/>
  
  <h3>Stats Screen - Light Themed</h3>
  <img src="app_code/assets/images/statistics_tab.png" alt="List It Stats Screen - Light Themed" width="00"/>

  <h3>Settings Screen - Font Size Comparison</h3>

<div style="display: flex; justify-content: center; gap: 40px; flex-wrap: wrap;">

  <div style="text-align: center;">
    <h4>Small Font Size</h4>
    <img src="app_code/assets/images/min_text_dim.jpg"
         alt="List It Settings Screen - Small Font"
         width="200"/>
  </div>

  <div style="text-align: center;">
    <h4>Large Font Size</h4>
    <img src="app_code/assets/images/max_text_dim.jpg"
         alt="List It Settings Screen - Large Font"
         width="200"/>
  </div>

</div>
  
  <h3>Home Screen Tablet View with List Detail Screen</h3>
  <img src="app_code/assets/images/tablet_view.jpg" alt="List It - Tablet View" width="500"/>
</div>

### Showcased Features 

- **Lists Home Tab**: Interface for the creation of new shopping lists.
- **Theme Support**: Both light and dark mode available.
- **Statistics Tab**: Intuitive interface for the management and analysis of historical purchases through time.
- **List Edit Screen**: The tablet screen shows the interface to automatically add products in a list. The list edit screen reserves its layout on both mobile and tablet devices.


## 🔐 Security & Privacy

- **Authentication**: Supports Anonymous login, Email/Password, and Google Sign-In via Firebase Auth.
- **Verification**: Users signing up are requestd to vrify their emails through a verification link sent to them.
- **Credential Recovery**: Users can recover their forgotten passwords through a recovery link.
- **Data Privacy**: Anonymous users keep data locally until account linking. Receipt processing happens on-device (OCR) before secure AI processing.

## 📊 AI Integration Details

| Feature | AI Model | Description |
| :--- | :--- | :--- |
| **Product Categorization** | Gemini 2.5 Flash | Assigns category (e.g., "Dairy") based on product name. |
| **Recipe Generation** | Gemini 2.5 Flash | Generates ingredient lists and quantities from a recipe name. |
| **Receipt Scanning** | ML Kit + Gemini | ML Kit extracts text; Gemini parses the unstructured text into JSON (Product, Price, Quantity). |

## 🌐 Internationalization

The application supports multiple languages through Flutter's internationalization system:

- English (default)
- Italian
- Additional languages can be added via ARB files

## 🧪 Testing

The project maintains a high standard of quality assurance with approximately **70% code coverage**.

Testing environemets were dsigned by mocking calls to Local/Remote Services for dependency isolation.
Testing is mainly performed by the `flutter_test` library. Mocked interactions were built by the usage of custom mocked classes and the `mocktail` library

- **Unit Tests**: Validate models, repositories, and the synchronization logic.
- **Widget Tests**: Verify UI components and screen interactions.
- **Integration Tests**: Cover 6 critical user flows:
    1.  Authentication Flow.
    2.  List Registration & Persistence.
    3.  Category Management.
    4.  Supermarket Management.
    5.  Statistics Updates.
    6.  Category Persistence.
 - **User Tests**: A user was given the possibility to test the application for 48h. Afterwars, th user was submitted a structured questioneer to return feedback. The user's answers are reported in the Design Document. The feedback positive.

## 🚀 Getting Started

### Prerequisites

- **Flutter SDK** 3.22.0 or higher
- **Dart SDK** 3.9.2 or higher
- **Google Gemini API Key**
- **Firebase Project Configuration**

### Installation

1.  **Clone the Repository**
    ```bash
    git clone <repository-url>
    cd app_code
    ```

2.  **Install Dependencies**
    ```bash
    flutter pub get
    ```

3.  **Environment Configuration**
    *   Ensure `firebase_options.dart` is present in `lib/` (configured via `flutterfire configure`).
    *   The app requires a Gemini API key passed at compile time.

### Running the Application

To run the app, you must provide the Gemini API key using the `--dart-define` flag:

```bash
flutter run --dart-define=GEMINI_API_KEY=your_actual_api_key_here
```

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

## 👥 Authors

- **Leonardo Ratti** - [GitHub](https://github.com/LRatti)
- **Mattia Peruzzi** - [GitHub](https://github.com/MattiaPeru)

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
```
