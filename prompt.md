# SpeakEasy — iOS App Build Brief

> An iOS app for people who lack confidence in speaking, writing, or understanding English. SpeakEasy helps users learn vocabulary, practice pronunciation, and build fluency through AI feedback, structured reading, and a reward-based progress system.

---

## The Problem

Millions of people struggle with English not because they lack intelligence, but because they've never had a safe, private space to practice. SpeakEasy is that space. A user should be able to photograph any text in the real world — a menu, a letter, a sign — have it extracted, read it at their own pace, tap any word they don't understand, practice saying it out loud, get honest feedback, and save it for later review.

The core engineering challenges are **offline reliability**, **audio session management**, and **UI responsiveness under load**:

- OCR must work with no internet connection
- Audio recording and playback must not conflict
- Scrolling through large extracted text must never stutter
- A word saved to the basket must be there the next time the app opens, regardless of whether the user ever logged in

Everything else is secondary to getting those four things right.

---

## Tech Stack

> Use exactly this. Don't substitute anything.

| Concern | Technology |
|---|---|
| Language | Swift (latest) — protocols, async/await, value types |
| UI Framework | SwiftUI — native performance, declarative state management |
| Architecture | MVVM |
| Local Storage | Core Data |
| Auth / Backend | Supabase — login, signup, session persistence only |
| Apple Frameworks | AVFoundation, Speech, Vision |
| APIs | Gemini (free tier), Free Dictionary API |
| Security | JWT + Keychain, no hardcoded keys |

**MVVM responsibilities:**
- **Views** — rendering and state binding only
- **ViewModels** — all API calls, business logic, and state
- **Managers** — cross-cutting concerns (audio, OCR, CoreData)
- **Utilities** — pure helpers

If a View contains business logic or a ViewModel imports UIKit directly, something is wrong.

---

## Performance Targets

These are **hard requirements**, not aspirational goals.

- OCR runs fully offline using Apple Vision — no network call under any condition
- Reader screen scrolls smoothly for extracted text up to 10,000 words — no blocking the main thread
- Audio recording and TTS playback use a shared `AVAudioSession` managed centrally — no conflicts, no crashes on rapid tap
- Multi-image import (up to 20 images) processes without freezing the UI — async background queues
- Core Data reads never block the main thread — use `NSAsynchronousFetchRequest` or background contexts for heavy fetches
- Camera and gallery permission prompts appear exactly once, when the feature is first triggered — not on app launch

---

## Project Structure

```
SpeakEasy/
├── App/
│   ├── SpeakEasyApp.swift
│   └── AppState.swift
├── Core/
│   ├── Models/               # Swift structs/classes mirroring Core Data entities
│   ├── Managers/
│   │   ├── CoreDataManager.swift
│   │   ├── AudioSessionManager.swift
│   │   ├── OCRManager.swift
│   │   ├── SpeechManager.swift
│   │   └── PermissionManager.swift
│   ├── Utilities/
│   │   ├── TextFormatter.swift
│   │   ├── ScoreCalculator.swift
│   │   └── KeychainHelper.swift
│   └── Extensions/
├── Features/
│   ├── Auth/
│   │   ├── Views/
│   │   └── ViewModels/
│   ├── Dashboard/
│   │   ├── Views/
│   │   └── ViewModels/
│   ├── Projects/
│   │   ├── Views/
│   │   └── ViewModels/
│   ├── Reader/
│   │   ├── Views/
│   │   └── ViewModels/
│   ├── WordBasket/
│   │   ├── Views/
│   │   └── ViewModels/
│   └── Profile/
│       ├── Views/
│       └── ViewModels/
├── Services/
│   ├── SupabaseService.swift
│   ├── GeminiService.swift
│   └── DictionaryService.swift
├── Resources/
│   └── SpeakEasy.xcdatamodeld
└── Configuration/
    └── Config.swift           # reads keys from Info.plist / xcconfig — never hardcoded
```

---

## Data Model (Core Data)

### `Project`

| Field | Type |
|---|---|
| `id` | UUID |
| `name` | String |
| `createdAt` | Date |
| `lastOpenedAt` | Date |
| `images` | `[ProjectImage]` (to-many) |

### `ProjectImage`

| Field | Type |
|---|---|
| `id` | UUID |
| `imageData` | Binary |
| `order` | Int16 |
| `extractedText` | String (nullable) |
| `project` | `Project` (to-one inverse) |

### `WordEntry`

| Field | Type | Notes |
|---|---|---|
| `id` | UUID | |
| `word` | String | |
| `meaning` | String | |
| `difficultyLevel` | String | `easy` \| `medium` \| `hard` |
| `addedAt` | Date | |
| `practiceHistory` | `[PracticeSession]` (to-many) | |

### `PracticeSession`

| Field | Type | Notes |
|---|---|---|
| `id` | UUID | |
| `score` | Float | 0.0 to 1.0 |
| `recordedAt` | Date | |
| `word` | `WordEntry` (to-one inverse) | |

### `RecentActivity`

| Field | Type | Notes |
|---|---|---|
| `id` | UUID | |
| `activityType` | String | `project_opened` \| `word_practiced` |
| `referenceId` | UUID | |
| `timestamp` | Date | |

---

## Authentication Flow

Supabase handles auth. Core Data is untouched by auth state — data persists regardless of login status.

### Login Screen
- Email field, password field, Login button
- "Continue as Guest" button
- "Create Account" link
- Validate inputs before any network call: empty fields, malformed email, and password under 8 characters are caught client-side with **inline error messages**, not alerts

### Signup Screen
- Full name, email, password, "Create Account" button
- Same validation rules
- On success, navigate directly to the dashboard

### Guest Mode
- Full app access
- Core Data works identically
- Auth-gated features show a non-blocking prompt to create an account

### Session Persistence
- On app launch, check Keychain for a stored JWT
- If valid → skip auth screens entirely
- If expired → show login with a non-alarming message
- Supabase refresh tokens handled silently

### Logout
- Clears Keychain token
- Calls Supabase `signOut`
- Navigates to login
- Core Data is **not** touched — all local data remains

---

## Navigation Structure

Four bottom tabs. Tab state is preserved on switch — no resets.

```
TabView
├── Dashboard
├── Projects
├── Word Basket
└── Profile
```

Navigation uses `NavigationStack` throughout. `Sheet` and `fullScreenCover` presentations are used for capture/review flows only — not for primary navigation.

---

## Dashboard

**Top:** A gradient summary card (blue gradient) showing:
- Greeting by name, or "Hey there" for guests
- Project count, word count, reading streak / goal
- Camera and gallery upload buttons

Tapping **Camera** requests permission if not granted, then opens the native camera. Tapping **Gallery** opens `PHPickerViewController` for multi-select.

**Below:** Two horizontal scrollable sections:
- **Recent Projects** — last 5 opened, rounded cards with thumbnail and image count
- **Recent Words** — last 5 practiced words, showing word, score badge, difficulty level

---

## Image Capture and Review

After selection (camera or gallery), open a **Review Screen**:

- Horizontal scroll preview of all selected images
- Remove individual images with a swipe or tap
- "Add More" opens gallery again
- Two CTAs: **"Save to Project"** and **"Read Now"**

**Save to Project:** Show a sheet listing existing projects plus a "New Project" option. If new, prompt for a name inline. Save images to Core Data under that project. Then continue to text extraction.

**Read Now:** Skip saving, extract text immediately, open Reader. Offer to save at any point from within the Reader.

---

## OCR and Text Extraction

Use `VNRecognizeTextRequest` from Apple Vision. Runs entirely offline.

- Use `.accurate` recognition level
- Flag low-confidence results visually in the reader (lighter color or underline)
- If OCR returns empty for an image, show inline: *"We couldn't read text from this image. Try a clearer photo."*
- For multiple images, extract and concatenate text in order, with a visible page-break divider between each image's content
- Store extracted text back to `ProjectImage.extractedText` in Core Data after extraction

---

## Reader Screen

The reader is the core screen of the app. Every element of it matters.

**Text display:** Scrollable, formatted text. Every word is individually tappable. Use a custom `TextTokenizer` to split text into word tokens and render them as a flow layout or using `Text` with custom tap gestures.

**Bottom bar — three controls:**

- **Format** — Font size (slider, 14–28pt), letter spacing, line height, theme toggle (light / sepia / dark)
- **Listen** — Play/pause TTS using `AVSpeechSynthesizer`. Speech rate slider. Highlight the current word being spoken as it plays.
- **AI** — Four options: Summarize, Simplify, Explain Grammar, Generate Quiz. Each sends extracted text to Gemini and displays the response in a sheet. Show a loading state during the API call. Handle failures gracefully with a retry option.

**Word tap:** On tapping any word, open a bottom sheet (not full screen) showing:

- The word, large and clear
- Pronunciation audio button (uses `AVSpeechSynthesizer` to speak the word)
- Meaning (fetched from Free Dictionary API, cached in memory for the session)
- "Practice" button → opens Pronunciation Practice
- "Add to Word Basket" button → saves to Core Data with haptic feedback confirmation

---

## Pronunciation Practice

Triggered from the word tap sheet or from the Word Basket.

1. Show the target word prominently
2. **"Start Recording"** button — requests microphone permission if not granted
3. Record using `AVAudioRecorder`. Show a live waveform or animated indicator.
4. On stop, transcribe using `SFSpeechRecognizer`
5. Compare transcription to target word using normalized string similarity (case-insensitive, handle common phonetic variations)
6. Display: percentage score (0–100%), a short message ("Great job!", "Almost there — try again"), and a Retry button
7. On score ≥ 70%, save a `PracticeSession` to Core Data linked to the `WordEntry`. Update difficulty level based on score history.

Scores are never sent to any server. All processing is on-device.

---

## Word Basket

Displays all saved `WordEntry` records from Core Data, sorted by most recently added.

Each word card shows:
- The word
- Meaning (truncated to one line)
- Difficulty badge (color-coded: green / yellow / red)
- Best score from practice history

Tap to expand → full meaning, full practice history chart, Practice button.

Search bar at the top filters words **client-side**. No network call for search.

---

## Projects Tab

Displays all `Project` records from Core Data.

Each project card shows:
- Thumbnail (first image in the project)
- Project name
- Image count
- Last opened date

**Long press** on a card to: Rename, Add Images, Delete. Confirmation required for delete.

Tapping a project opens a detail screen showing all images in a grid. Tapping an image opens the reader for that image's extracted text (extracting on-demand if not yet extracted).

---

## Profile Screen

Displays:
- User's full name, email (or "Guest" if unauthenticated)
- Total projects, total saved words, total practice sessions
- Logout button — clears session, navigates to login (Core Data untouched)

For guests, show a non-intrusive banner: *"Create an account to back up your progress in the future."*

---

## AI Integration (Gemini)

All Gemini calls go through `GeminiService`. The service takes a `GeminiRequest` struct (text + feature type enum) and returns a `GeminiResponse` struct. The ViewModel never constructs raw JSON or manages URL sessions directly.

**Feature prompts:**

| Feature | Prompt |
|---|---|
| Summarize | `"Summarize the following text in 3–5 sentences for a learner with basic English: [text]"` |
| Simplify | `"Rewrite the following text using simple vocabulary and short sentences: [text]"` |
| Explain Grammar | `"Identify and explain 3–5 grammar patterns in this text suitable for an English learner: [text]"` |
| Generate Quiz | `"Generate 5 multiple-choice comprehension questions from this text. Return as JSON array with question, options[], answer fields."` |

Quiz responses are parsed and rendered as an **interactive quiz sheet** — not displayed as raw text.

API key is loaded from `Config.swift` which reads from a `.xcconfig` file excluded from version control. **Never hardcoded. Never logged.**

---

## Error Handling and Input Validation

Every failure is handled at the layer it occurs. No raw error strings reach the UI.

| Failure | Handling |
|---|---|
| Empty OCR result | Inline message in Reader, not an alert |
| Gemini API failure | Retry button in the AI sheet, no crash |
| Dictionary API failure | Show "Meaning unavailable" in word sheet |
| Microphone permission denied | Navigate to Settings with explanation |
| Camera permission denied | Navigate to Settings with explanation |
| Supabase auth failure | Inline error below the relevant field |
| Core Data write failure | Log internally, show generic save error to user |
| No internet (AI/Dictionary) | Show offline banner; OCR and Core Data features continue unaffected |

**Input validation rules:**
- **Email** — standard RFC format check before any network call
- **Password** — minimum 8 characters, validated client-side
- **Project name** — non-empty, max 50 characters, trimmed
- **Pronunciation recording** — minimum 0.5 seconds, reject silence

---

## Security

- JWT tokens stored in **Keychain only** — never `UserDefaults`, never logged
- Gemini and Supabase keys loaded from `.xcconfig`, excluded from version control via `.gitignore`
- No user content (images, text, words, scores) ever leaves the device to any backend
- Microphone and camera access requested contextually, with a clear usage description in `Info.plist`
- Supabase is the only external service that receives any user-identifying data (email, name)

---

## Deliverables

A complete, working Xcode project. **Not a skeleton.** Every file in the structure above must exist and contain real, runnable Swift code.

- All source files organized per the folder structure above
- Core Data model (`SpeakEasy.xcdatamodeld`) with all entities defined
- Supabase auth fully wired — login, signup, guest mode, session restore, logout
- OCR working offline on real device and simulator
- Pronunciation scoring working end-to-end
- Gemini integration with all four AI features
- Free Dictionary API integration with in-session caching
- Dashboard with real Core Data–backed counts and recents
- All four tabs functional with correct navigation
- `README.md` covering: Xcode setup, `.xcconfig` key configuration, Supabase project setup, running on simulator vs. device, known simulator limitations (camera)
