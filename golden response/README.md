# SpeakEasy

**Turn photos into readable English.** SpeakEasy helps learners capture text from the world around them, study it in a focused Reader, grow a personal word list, and sharpen pronunciation—on their own device, with optional sign-in and AI when you are online.

It is built for real materials: menus, handouts, slides, and screenshots—not only textbook PDFs—so practice stays relevant to how people actually encounter English.

## How it works

You add images from the camera or photo library, review them, then **read now** or **save to a project**. The app extracts text on-device and opens a **Reader** where you can adjust layout, listen with text-to-speech, and tap any word for actions. Saved **projects** and **word basket** entries live in **Core Data** on your device, so your library stays available without a network connection.

## Features

| Area | What you get |
|------|----------------|
| **Home** | Quick capture, gallery import, shortcuts to recent projects and words, daily practice target |
| **Projects** | Folders of images; open any image in the Reader; rename or delete projects and images |
| **Reader** | On-device text recognition (Apple Vision), typography controls, read-aloud, word tap menu |
| **Words** | Word basket with sorting; pronunciation practice and scores tracked over time |
| **Profile** | Practice statistics; account or guest mode via Supabase; app settings |

**Word actions (from the Reader):** hear the word, add it to your basket, open pronunciation practice, and **look up meanings** (definitions and examples from a public dictionary API).

**AI tools (Reader):** summarize, simplify, generate a short quiz, and grammar explanations—these run against a **Supabase Edge Function** using text you have already extracted.

## Offline vs online

- **Works offline:** browsing projects and saved images, text extraction, reading and editing extracted text in the Reader, text-to-speech, saving words locally, pronunciation practice, and viewing stats for past attempts.
- **Requires internet:** **dictionary** lookups, all **AI** Reader tools, and **sign-in / account** flows (Supabase). Guest-style use of the rest of the app does not depend on being signed in.

## Tech stack (brief)

SwiftUI, Core Data, Vision, AVSpeechSynthesizer, optional Supabase Auth; dictionary data from [Free Dictionary API](https://dictionaryapi.dev); AI via your Supabase project’s `ai` function.

## Building

Open `Speakeasy/Speakeasy.xcodeproj`, select the **speakEasy** scheme, choose a simulator or device, and run. Backend URLs and keys are set in `Speakeasy/Speakeasy/Config.swift` for Supabase and the AI endpoint; use your own project if you fork the app.

---

**SpeakEasy** — *confidence in English, one page at a time.*
