<div align="center">

# 💸 PocketFin

**Super powerful, lightweight mobile app to track financial expenses.**

[![Flutter](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white)](https://flutter.dev/)
[![Dart](https://img.shields.io/badge/Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white)](https://dart.dev/)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg?style=for-the-badge)](LICENSE)

---

</div>

## 📌 Overview

**PocketFin** is a minimalist yet feature-packed mobile application built with Flutter to help users take control of their personal finances. Designed with speed and privacy in mind, PocketFin makes logging daily transactions friction-free while delivering deep statistical insights and financial advice to help you build better money habits.

---

## ✨ Features

- ⚡ **Frictionless Expense Logging:** Register incoming and outgoing transactions (income & expenses) in seconds with a clean, intuitive interface.
- 📊 **Tons of Advices & Statistics:** 
  - Dynamic charts and visual breakdowns of spending habits.
  - Smart financial tips and personalized advice based on historical spending data.
- 📁 **Data Export (Excel & XLS):** Easily export your transaction history to standard Excel formats (`.xlsx` and `.xls`) for tax filing, backup, or personal accounting.
- 🚀 **Lightweight & Fast:** Optimized for low memory footprint and high performance across both iOS and Android.

---

## 🛠️ Tech Stack

- **Framework:** [Flutter](https://flutter.dev/) (Dart)
- **State Management:** Provider / Riverpod / Bloc *(customize as needed)*
- **Data Export:** Excel output generation packages (`excel`, `csv`)
- **Storage:** Local database (SQLite / Hive) for complete offline capability and privacy.

---

## 🚀 Getting Started

Follow these instructions to set up and run PocketFin on your local machine.

### Prerequisites

Ensure you have installed:
- [Flutter SDK](https://flutter.dev/docs/get-started/install) (v3.0.0 or higher recommended)
- [Dart SDK](https://dart.dev/get-dart)
- Android Studio / Xcode (for emulation/device testing)

### Installation

1. **Clone the repository:**
   ```bash
   git clone https://github.com/your-username/pocketfin.git
   cd pocketfin
   ```

2. **Install dependencies:**
   ```bash
   flutter pub get
   ```

3. **Run the application:**
   ```bash
   flutter run
   ```

---

## 📂 Project Structure

```text
lib/
├── core/            # Themes, constants, helpers, and utilities
├── data/            # Models, local DB services, export handlers
├── logic/           # State management / Controllers
├── presentation/    # UI Screens, Widgets, and Dialogs
│   ├── screens/     # Dashboard, Stats, Add Transaction, Settings
│   └── widgets/     # Reusable buttons, cards, chart components
└── main.dart        # Entry point of the app
```

---

## 🤝 Contributing

Contributions are welcome! If you have suggestions or improvements:

1. Fork the Project
2. Create your Feature Branch (`git checkout -b feature/AmazingFeature`)
3. Commit your Changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the Branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

---

## 📄 License

Distributed under the MIT License. See `LICENSE` for more information.
