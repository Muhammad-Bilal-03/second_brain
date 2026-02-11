# 🧠 Second Brain

**RAG-Powered Note Taking App — Chat with your notes using AI**

[![Flutter](https://img.shields.io/badge/Flutter-3.38.4-02569B?logo=flutter)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.10.3-0175C2?logo=dart)](https://dart.dev)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![CI](https://github.com/Muhammad-Bilal-03/second_brain/actions/workflows/ci.yml/badge.svg)](https://github.com/Muhammad-Bilal-03/second_brain/actions/workflows/ci.yml)

## 📖 Overview

Second Brain is a local-first, AI-powered note-taking application that lets you "chat" with your notes using Retrieval Augmented Generation (RAG). Built with Flutter for cross-platform support, it combines the power of local storage with optional cloud sync for a seamless note-taking experience.

## ✨ Features (Planned)

- 📝 **Notes CRUD** — Create, read, update, and delete notes with a clean interface
- 🔍 **Semantic Search** — Find notes using natural language queries powered by embeddings
- 💬 **RAG Chat** — Have conversations with your notes using AI (Google Gemini)
- 🎤 **Voice-to-Note** — Convert speech to text for quick note capture
- ☁️ **Cloud Sync** — Optional synchronization with Supabase (pgvector for embeddings)
- 🌓 **Dark Mode** — Beautiful Material 3 theme with light and dark modes

## 🛠️ Tech Stack

| Category | Technology |
|----------|-----------|
| **Framework** | Flutter 3.38.4 |
| **Language** | Dart 3.10.3 |
| **State Management** | Riverpod 2.6+ |
| **Local Database** | Isar DB 4.0 |
| **AI Framework** | LangChain.dart |
| **LLM** | Google Gemini API |
| **Cloud Backend** | Supabase (pgvector) |

## 🏗️ Architecture

Second Brain follows **Clean Architecture** principles combined with **MVVM** pattern in a feature-based folder structure:

```
lib/
├── app.dart                    # App root widget
├── main.dart                   # Entry point
├── core/                       # Core utilities
│   ├── constants/             # App constants
│   ├── errors/                # Error handling
│   ├── theme/                 # App theme
│   └── utils/                 # Extensions & helpers
├── features/                   # Feature modules
│   ├── notes/                 # Notes feature
│   │   ├── data/             # Data sources & models
│   │   ├── domain/           # Entities & use cases
│   │   └── presentation/     # UI & state
│   ├── chat/                  # AI chat feature
│   ├── search/                # Semantic search
│   └── voice/                 # Voice input
└── shared/                     # Shared widgets & providers
```

### Key Architecture Decisions

- **Local-First**: All data stored locally in Isar DB for instant access
- **Optional Cloud Sync**: Supabase integration for cross-device synchronization
- **Clean Separation**: Domain logic isolated from UI and data layers
- **Testable**: Architecture enables comprehensive unit and integration testing

## 🚀 Getting Started

### Prerequisites

- Flutter SDK 3.38.4 or higher
- Dart SDK 3.10.3 or higher
- Android Studio / VS Code with Flutter extensions
- Git

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/Muhammad-Bilal-03/second_brain.git
   cd second_brain
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Run the app**
   ```bash
   flutter run
   ```

### Running Tests

```bash
flutter test
```

### Code Generation

For Riverpod and Isar code generation:

```bash
dart run build_runner build --delete-conflicting-outputs
```

## 🗺️ Roadmap

### Phase 1: Foundation (Notes CRUD) ⬅️ **Current**
- [x] Project setup with clean architecture
- [x] Core dependencies and folder structure
- [x] CI/CD with GitHub Actions
- [ ] Basic notes CRUD with Isar DB
- [ ] Material 3 UI with dark mode

### Phase 2: Intelligence Layer (Embeddings + Vector Search)
- [ ] Text embedding generation
- [ ] Vector similarity search
- [ ] Semantic search UI

### Phase 3: RAG Chat (LangChain.dart + Gemini)
- [ ] LangChain.dart integration
- [ ] Google Gemini API setup
- [ ] RAG pipeline implementation
- [ ] Chat UI with conversation history

### Phase 4: Cloud Sync (Supabase + pgvector)
- [ ] Supabase backend setup
- [ ] pgvector for cloud embeddings
- [ ] Sync engine implementation
- [ ] Conflict resolution

### Phase 5: Voice-to-Note
- [ ] Speech-to-text integration
- [ ] Voice recording UI
- [ ] Real-time transcription

### Phase 6: Polish & Ship
- [ ] Performance optimization
- [ ] Comprehensive testing
- [ ] User documentation
- [ ] App store deployment

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 👨‍💻 Author

**Muhammad Bilal**
- GitHub: [@Muhammad-Bilal-03](https://github.com/Muhammad-Bilal-03)

---

*Built with ❤️ using Flutter*
