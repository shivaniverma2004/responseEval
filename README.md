# SpeakEasy
Screenshots: https://photos.app.goo.gl/zZ1xNmrEqWeRGBge9
SpeakEasy is an iOS application designed to help English learners improve reading, vocabulary, and pronunciation skills using real-world materials like menus, notes, slides, screenshots, handouts, and printed text.

The app uses on-device text recognition to extract text from images, then provides a clean reading experience with pronunciation support, AI-powered tools, vocabulary saving, dictionary guide and speaking practice.

---

# App Overview

## What SpeakEasy Does

SpeakEasy allows users to:

* Capture text using the iPhone camera
* Import screenshots or images from the gallery
* Extract readable English text using Apple Vision OCR
* Read extracted text in a distraction-free reader
* Listen to text using text-to-speech
* Save difficult words into a personal word basket
* Practice pronunciation and track progress
* Organize learning materials into projects
* Use AI tools for summaries, simplification, grammar help, and quizzes

The app is built for practical English learning using real content instead of only textbook exercises.

---

# Main Features

## Home

* Quick camera capture
* Import from Photos
* Recent projects access
* Daily practice target
* Fast access to saved words

## Projects

* Save groups of images into folders
* Rename projects
* Delete projects or images
* Open saved images directly in the Reader

## Reader

* On-device OCR text extraction using Apple Vision
* Adjustable typography and reading layout
* Read-aloud support using iOS speech synthesis
* Word tap actions:

  * Hear pronunciation
  * Save word
  * Open pronunciation practice
  * Dictionary lookup

## AI Tools

The Reader includes optional AI-powered features:

* Summarize text
* Simplify difficult passages
* Generate quizzes
* Explain grammar

These features require internet access and Supabase Edge Functions.

## Words & Pronunciation

* Personal vocabulary basket
* Pronunciation scoring
* Progress tracking
* Speaking practice history

## Profile

* Practice statistics
* Guest mode support
* Optional Supabase authentication
* User settings

---

# Offline vs Online Features

## Works Offline

* Text extraction
* Reading saved content
* Projects and local storage
* Text-to-speech
* Word saving
* Pronunciation practice
* Progress tracking

## Requires Internet

* AI tools
* Dictionary lookups
* Supabase authentication
* Cloud-related services

---

# Tech Stack

* SwiftUI
* Core Data
* Apple Vision Framework
* AVSpeechSynthesizer
* Supabase Authentication
* Supabase Edge Functions
* Free Dictionary API

---

# Requirements

## Mac Requirements

Before running SpeakEasy, make sure you have:

* macOS with Xcode installed
* Apple Developer tools enabled
* An iPhone running iOS
* USB cable for device connection
* Apple ID signed into Xcode

Recommended:

* Latest stable version of Xcode
* iOS 17+ device

---

# Installing Xcode on Mac

## Step 1 — Install Xcode

Download Xcode from:

* App Store on macOS
* Or Apple Developer website

After installation:

1. Open Xcode
2. Accept license agreements
3. Allow additional components to install

## Step 2 — Sign Into Apple ID

Inside Xcode:

1. Open Xcode
2. Go to:

```text
Xcode → Settings → Accounts
```

3. Click the + icon
4. Sign in using your Apple ID

A free Apple Developer account works for testing on your own device.

---

# Downloading the Project

## Option 1 — ZIP Download

1. Download the project ZIP
2. Extract the folder
3. Open the extracted folder

## Option 2 — Git Clone

```bash
git clone <[repository-url](https://github.com/shivaniverma2004/SpeakEasy.git)>
```

---

# Opening the Project in Xcode

1. Open the project folder
2. Navigate to:

```text
Speakeasy/Speakeasy.xcodeproj
```

3. Double-click the `.xcodeproj` file

OR

1. Open Xcode
2. Click:

```text
Open a project or file
```

3. Select `Speakeasy.xcodeproj`

---

# Configuring the App

## Supabase Configuration

The project includes configurable backend settings.

Open:

```text
Speakeasy/Speakeasy/Config.swift
```

Add your:

* Supabase URL
* Supabase API Key
* AI Endpoint URL

Example:

```swift
static let supabaseURL = "YOUR_SUPABASE_URL"
static let supabaseKey = "YOUR_SUPABASE_KEY"
```

---

# Running on iPhone Simulator

## Step 1 — Select Simulator

At the top of Xcode:

1. Select the device dropdown
2. Choose an iPhone simulator

Example:

* iPhone 15
* iPhone 16 Pro

## Step 2 — Run the App

Press:

```text
⌘ + R
```

OR click the Run button.

Xcode will:

* Build the app
* Launch the simulator
* Install SpeakEasy automatically

---

# Running on a Real iPhone

## Step 1 — Connect iPhone

1. Connect your iPhone to your Mac using USB
2. Unlock the iPhone
3. Tap:

```text
Trust This Computer
```

if prompted.

---

## Step 2 — Enable Developer Mode (If Required)

On iPhone:

```text
Settings → Privacy & Security → Developer Mode
```

Enable Developer Mode and restart the device if required.

---

## Step 3 — Select Your Device in Xcode

In Xcode:

1. Open the device selector
2. Choose your connected iPhone

---

## Step 4 — Configure Signing

Inside Xcode:

1. Select the project
2. Open:

```text
Targets → speakEasy → Signing & Capabilities
```

3. Enable:

```text
Automatically manage signing
```

4. Select your Apple Team

Xcode will generate the required provisioning profile automatically.

---

## Step 5 — Install the App

Press:

```text
⌘ + R
```

The app will:

* Build
* Install on your iPhone
* Launch automatically

---

# First-Time iPhone Trust Setup

If the app does not open:

On iPhone:

```text
Settings → General → VPN & Device Management
```

Select your developer profile and tap:

```text
Trust
```

Then reopen the app.

---

# Permissions Used

SpeakEasy may request:

| Permission | Purpose                             |
| ---------- | ----------------------------------- |
| Camera     | Capture text from real-world images |
| Photos     | Import screenshots and images       |
| Microphone | Pronunciation practice              |
| Speech     | Text-to-speech playback             |

---

# Project Structure

```text
SpeakEasy/
├── Speakeasy/
│   ├── Views/
│   ├── Models/
│   ├── Services/
│   ├── CoreData/
│   ├── Config.swift
│   └── Assets/
```

---

# Screenshots

This repository includes screenshots of the app UI and user flow. Link: https://photos.app.goo.gl/zZ1xNmrEqWeRGBge9

Screenshots demonstrate:

* Home screen
* Reader view
* OCR extraction
* Word basket
* Pronunciation practice
* Projects organization
* AI features

You can find screenshots attached in the repository/project assets.

---

# Troubleshooting

## Xcode Build Errors

Try:

```text
Product → Clean Build Folder
```

Then rebuild.

---

## Device Not Showing in Xcode

* Reconnect USB cable
* Unlock iPhone
* Trust the computer
* Restart Xcode

---

## Signing Issues

Make sure:

* Apple ID is signed into Xcode
* Automatically manage signing is enabled
* Team is selected correctly

---

## AI Features Not Working

Check:

* Internet connection
* Supabase configuration
* Edge Function deployment
* API keys

---

# Credits

## APIs & Services

* Apple Vision Framework
* Supabase
* Free Dictionary API
* Gemini AI API

---

# Author Notes

This project includes:

* Native iOS development with SwiftUI
* OCR integration
* AI-assisted learning tools
* Local data persistence
* Pronunciation and accessibility features
* Modern mobile UX patterns

The repository also contains screenshots showcasing the full app experience.

---

# Quick Start Summary

## Mac Setup

1. Install Xcode
2. Sign into Apple ID
3. Open `Speakeasy.xcodeproj`
4. Configure signing
5. Press Run

## iPhone Setup

1. Connect iPhone
2. Enable Developer Mode
3. Trust computer
4. Select device in Xcode
5. Build and run

---

# SpeakEasy

Learn, Listen and Speak with Confidence.
