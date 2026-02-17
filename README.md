# 🧠 Second Brain

**A Local-First, AI-Powered Note Taking App**

## 📖 Overview

**Second Brain** is an intelligent note-taking application designed to capture thoughts in any format—text, voice, code, or checklists—and retrieve them instantly using AI. Unlike traditional apps that rely on keyword matching, Second Brain uses **Vector Embeddings** and **Google Gemini** to understand the *meaning* of your notes, allowing you to find information even if you don't remember the exact words.

Built with a **Local-First** architecture using Hive, it ensures your data is always accessible, blazing fast, and private on your device.

## ✨ Key Features

### 📝 Multi-Modal Note Taking

Capture ideas in the format that fits best:

* **Text Notes**: Rich text support for daily thoughts.
* **✅ Smart Checklists**: Interactive tasks with reordering and strikethrough.
* **💻 Code Snippets**: A full IDE-like experience with **syntax highlighting** (Atom One Dark theme) and language detection.
* **🎙️ Dual-Mode Voice**:
* **Transcribe**: Convert speech to text instantly.
* **Record**: Save actual audio files (`.m4a`) with an in-note playback player.



### 🧠 AI & Intelligence

* **Semantic Search**: Search by meaning, not just keywords. (e.g., searching for "groceries" will find "milk and eggs").
* **Local Embeddings**: Vector search logic runs efficiently on-device.
* **Google Gemini Integration**: Uses Gemini 1.5 Flash for reasoning and data processing.

### ⚡ Performance & UI

* **Offline-First**: Powered by **Hive** (NoSQL), making it faster than SQL-based apps.
* **Material 3 Design**: A modern, clean interface with Dark Mode support.
* **Gatekeeper Logic**: Prevents AI hallucinations by verifying relevance before answering.

## 🛠️ Tech Stack

| Category | Technology | Usage |
| --- | --- | --- |
| **Framework** | Flutter | Cross-platform UI |
| **Language** | Dart | Business Logic |
| **State Management** | Riverpod 2.6+ | App State & Dependency Injection |
| **Local Database** | Hive | NoSQL Storage (Replaces SharedPreferences) |
| **AI Model** | Google Gemini API | RAG & Embeddings |
| **Code Editor** | Flutter Code Editor | Syntax Highlighting |
| **Audio Engine** | Record & Audioplayers | Voice Recording & Playback |

## 🏗️ Architecture

The app follows **Clean Architecture** principles to ensure scalability and testability:

```
lib/
├── core/                   # Global utilities (Theme, Constants, Errors)
├── features/
│   ├── notes/              # Main Feature
│   │   ├── data/           # Hive Models, Repositories, Data Sources
│   │   ├── domain/         # Entities & Abstract Repositories
│   │   └── presentation/   # Screens (Editor, List), Providers, Widgets
│   ├── chat/               # RAG Chat Interface
│   └── search/             # Vector Search Logic
└── main.dart               # App Entry & DI Setup

```

## 🚀 Getting Started

### Prerequisites

* Flutter SDK (`>=3.5.0`)
* A Google Cloud API Key (for Gemini)

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


3. **Configure Environment**
Create a `.env` file in the root directory and add your API key:
```env
GEMINI_API_KEY=your_api_key_here

```


4. **Run the app**
```bash
flutter run

```



## 🗺️ Roadmap

* [x] **Phase 1: Core Foundation** (CRUD, Riverpod, Hive Migration)
* [x] **Phase 2: Multi-Modal Input** (Code Editor, Voice Recorder, Checklists)
* [x] **Phase 3: Intelligence** (Vector Embeddings, Semantic Search)
* [x] **Phase 4: RAG Chatbot** (Full conversational interface with notes)

## 🤝 Contributing

Contributions are welcome! Please fork the repository and submit a pull request.

## 📄 License

This project is licensed under the MIT License - see the [LICENSE]() file for details.

---

**Built by [Muhammad Bilal**]() *Empowering thoughts with AI.*
