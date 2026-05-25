PROMPT 
Think as an iOS engineer, and AI architect. You are developing a production ready, modern iOS app called “SpeakEasy” for people lacking confidence due to the ability to speak, write or understand English so that they can Learn, Listen and Speak with confidence.
Context and Role
As an iOS developer working on an improvement app to help users work on there pronunciation, conversational skills and fluency through feedbacks, guidance and reward based system. The app must analyze the users level of understanding English, and there goals.
The application should allow user to login/signup or continue as guest, upload/capture multiple images, save words, use AI tools and dictionary and practice pronunciation and capable of extracting text from images using OCR, give pronunciation feedback and percent of correctness, AI feature, and track learning along with responsive user interface.
The application must follow apples human interface guidelines and maintain Offline -first structures , clean codebase and smooth user interface. 
Tech Stack 
Framework : SwiftUI (native apple performance, scalable, state management and fast development), AVFoundation, Speech, Vision.
Programming Language: Swift (latest version, use protocols, models, concurrency)
Backend: Supabase for authorization control and authentication.
Requirements: JWT session handling, secure token storage, persistent sessions.
Local Storage: Projects, Images, Practiced words, pronunciation scores, word basket, recents.
Architecture: MVVM (Models, Views, ViewModels, Managers, Utilities)  
Views for UI render, interaction and state binds.
ViewModels for API calls and state management.
API: Gemini, free dictionary 
Objective
Users should be able to login and create new account using supabase authentication or continue as a guest.
User able to capture or upload one or more than one images.
Allows users to save those images to existing or new projects or continue without saving.
Extracts text from the selected image from a project or manually.
Provides reading interface, with formatting features (font size, spacing, theme, read out loud (custom speed).
Tap on words with haptic feedback to listen pronunciation, practice and feedback, see meanings, add to word basket.
Integrate Gemini free API for AI tools, for features : Summarize, Simplify, generate quiz, Explain grammar, for extracted text.
Display recent projects and words on dashboard.
Display all Projects on Projects tab.
Display all words added to word basket on word basked tab.
Use Core data as primary local storage.
Use Supabase only for Login, Signup, Session persistence and auth state handling.
Do not store projects, ocr text, images, words, reader history or any response on supabase.
Core data should store Projects, Images, word basket words, pronunciation scores, recent activity and practice history.
UI should mandatory follow apple hig and native apple designs.

UI navigation flow
Rounded cards, shadows, Blue gradients, Clean typography, smooth.

Authentication
Login Screen : Email field, Password field, Login button, skip button, if new create new account button to get to signup screen.
Use supabase login, input validate.
Signup Screen : Full name, Email, password, create account button.
Secure account creation, validation and error alerts.
Navigation
There should be four bottom tabs : dashboard, projects, words, profile
Navigation should safely handle states.
Dashboard
Greeting, project count, word count, reading goal, camera and gallery upload button, recent reading projects, recent practiced words, 
There should be a gradient summary card on top, in recent projects and words there should be 5 each, rounded cards, soft shadows, scrollable sections.
Image upload
On tapping camera button from summary card on dashboard, user should be able to capture images using camera, or on tapping gallery should be able to select multiple images form gallery.

After image selection there should be review screen to preview all selected images, remove images or add more, save to project or read now then continue to extract text.  
Text extraction
Use OCR using apple vision framework.
User selects image, ocr extracts text, extracted text is formatted and opened on reader screen
It should use offline ocr function, handle noisy image
Project
Each project can have one or more images, and the first image should be its thumbnail image. Project card should dicplay thumbnail, image count.
Each project should have a name, images.
User should be able to create, rename, delete a project, add additional to it or delete images from it or open reader directly.
Reader screen 
Display extracted text, scrollable, custom controls, AI tool access, text to speech controls, and also each word should be interactive.
Bottom bar: Format, Listen and AI
Text formatting(Format): font size, letter spacing, line height
Text to speech(Listen): read out loud, pause, resume, speech rate
AI: Option to Summarize, Simplify, generate quiz, Explain grammar
Word interaction: on tap a word, open word options for that word to hear pronunciation, practice, get meaning, add to word basket
Pronunciation
Use speech and AVAudioRecorder frameworks.
If tapped practice pronunciation, user can record there voice, the speech is converted to text then its compared to actual word and a score is generated. 
Display Percentage score, a small message and retryoption 
Word Basket
Here saved words are stored
Each word has a meaning, score, difficulty level and practice history.


Profile Screen
Display user name, email, total projects, save words, practice sessions, provide logout button to return to login screen and keep safe the cpre data contents.
Performance :
Handle large text, support multi image import, do not block main thread, maintain smooth scrolling, minimal memory usage
Handle permissions efficiently along wih API failures and empty OCR results.
The Folder structure should be well organized for each component maintaining readability and cleanly documented. 
Do not expose API keys and auth tokens. 

The App should be production ready, scalable, secure and fast, feel premium, smooth transitioned, follow apple hig, use reusable components. 
Develop the app following all requirements complete in one response.
