# List It 🛒

**List It** is a smart, offline-first grocery shopping assistant designed to make the shopping process efficient and insightful. Built with **Flutter**, it leverages Generative AI and on-device Machine Learning to automate list organization and track spending habits.

> **Course:** Design and Implementation of Mobile Applications (DIMA)  
> **Institution:** Politecnico di Milano  
> **Academic Year:** 2025-2026  
> **Professor:** Luciano Baresi

<p align="center">
  <img src="assets/images/app_logo.png" alt="List It Logo" width="120" height="120" />
</p>

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

`UI` ↔ `Controllers/Notifiers (Riverpod)` ↔ `Repositories` ↔ `Data Sources (Local/Remote)`

1.  **Offline-First Strategy:** All reads/writes happen against the local SQLite database.
2.  **Sync Engine:** A background process monitors a local `sync_box` table. It pushes changes to Firestore and pulls remote updates using a "Last Write Wins" conflict resolution strategy.

## 📂 Folder Structure

The project structure is organized by feature and layer:

```text
/lib
├── l10n/          # Localization files (En/It)
├── models/        # Core data entities (ShoppingList, Product, User...)
├── providers/     # Riverpod state notifiers
├── repositories/  # Data access layer (Abstract, Mock, and Real implementations)
├── screens/       # UI Screens (Adaptive layouts)
├── services/      # External API clients (Gemini, OCR, Location)
├── styles/        # Theme and typography definitions
├── utils/         # Helper functions (Loggers, Formatters)
├── widgets/       # Reusable UI components
└── main.dart      # App entry point
