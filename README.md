<div align="center">

# 📚 MarkPro+ 📊

### A Comprehensive Academic Mark Management System

<img src="https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white" />
<img src="https://img.shields.io/badge/Firebase-FFCA28?style=for-the-badge&logo=firebase&logoColor=black" />
<img src="https://img.shields.io/badge/Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white" />

</div>

## 🌟 Overview

MarkPro+ is a powerful and intuitive Flutter application designed for educational institutions to manage student marks across different assessment types. Teachers can easily record, import, export, and analyze marks for various assessment formats including assignments, lab sessions, seminars, and mid-term examinations.

## ✨ Key Features

### 📋 Multi-Assessment Type Support
- **Assignment Sessions**: Manage regular assignment submissions and grading
- **Lab Sessions**: Track experiment marks, lab reports, and viva performance
- **Seminar Sessions**: Record presentation marks, report grades, and overall seminar performance
- **Mid Exam Sessions**: Manage mid-term examination marks efficiently

### 📥 Data Import/Export
- One-click Excel export for all mark types
- Batch import from Excel files with validation
- Multiple import options for different assessment types
- Smart student mapping and validation

### 📊 Mark Management
- Real-time mark entry with instant saving
- Quick keyboard navigation for efficient mark entry
- Detailed student information integration
- Visual status indicators for assessment completion

### 🔍 Filtering and Search
- Filter sessions by branch, year, and section
- Search functionality for quick access to specific sessions
- Custom filters for each assessment type

### 🧰 User Experience
- Modern, intuitive UI with responsive design
- Hover effects and visual feedback
- Context menus for quick access to common operations
- Confirmation dialogs for destructive actions

## 🚀 Getting Started

### Prerequisites
- Flutter SDK (2.5.0 or higher)
- Dart (2.14.0 or higher)
- Firebase account for backend services

### Installation

1. Clone the repository
   ```bash
   git clone https://github.com/kinghoys/MarkPro-premium.git
   cd markpro_plus
   ```

2. Install dependencies
   ```bash
   flutter pub get
   ```

3. Configure Firebase
   - Create a new project in Firebase console
   - Add your Flutter application to Firebase
   - Download and add the `google-services.json` (Android) or `GoogleService-Info.plist` (iOS) to your project

4. Run the application
   ```bash
   flutter run
   ```

## 📱 Usage

### Creating a New Session
1. Navigate to the desired session type (Assignment/Lab/Seminar/Mid)
2. Tap the + button to create a new session
3. Fill in the required details and add students
4. Save to create the session

### Entering Marks
1. Select a session from the list
2. Navigate to the marks entry screen
3. Enter marks for each student
4. Marks are saved automatically

### Importing/Exporting Marks
1. Open the session menu via the three-dots button
2. Select "Import Marks" or "Export Marks"
3. For imports, select an Excel file with student IDs and marks
4. For exports, specify a filename to save the Excel report

## 🏗️ Project Structure

```
lib/
├── main.dart           # Application entry point
├── models/            # Data models
├── screens/           # Application screens
├── services/          # Firebase and business logic
├── widgets/           # Reusable UI components
└── utils/             # Utility functions and constants
```

## 🛠️ Technologies Used

- **Flutter & Dart**: For cross-platform UI development
- **Firebase Firestore**: For real-time database functionality
- **Excel**: For import/export functionality
- **Provider**: For state management
- **Intl**: For internationalization and date formatting

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 📞 Contact

For any inquiries or support, please contact the development team at development@markproplus.edu

---

<div align="center">

**MarkPro+** - Empowering Educators with Efficient Mark Management

</div>
