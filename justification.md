Ratings & Evaluations(RLHF)
Dimension Scores for ChatGPT Response
Dimension 1: Correctness — 1/5
LLM was asked to make a working app with Supabase auth, Gemini AI and Core Data. Response was an app that does not work. The Supabase client is broken as it has syntax errors. This means the app will not even start. The Gemini part of the app is also wrong. It sends the API key in the auth header which needs to be sent in a query. The Core data file is missing. The app does not work all. There are a few things that are okay, like the app entry point and a basic persistence controller. 
Dimension 2: Relevance — 1/5
The prompt asked for an iOS app with four tabs, a login screen and the ability to upload from camera and gallery. The app also had to do OCR extraction have a reader, pronunciation practice, a word basket and some AI tools. The response from ChatGPT gave a network wrapper and a shell, for the app but none of the actual features we asked for.
Dimension 3: Completeness — 1/5
The response was missing the core functionalities but response was a structure for the app and a way to connect to the internet but that was it. There was no page, no projects section, no reader, no way to practice pronunciation and no word basket. These are the things that make this app special. The AI feature was also not implemented 
Dimension 4: Style & Presentation — 2/5
The code is clean, comments, clear naming, structure. But the prompt was explicit: Apple HIG, blue gradients, rounded cards, soft shadows, smooth transitions, premium feel. There is no UI code at all, so we can’t know the remaining styles.
Dimension 5: Coherence — 2/5
The Supabase file has a class called SupabaseClient.. Then it has a property that is also called SupabaseClient. This is a syntax issue. The Gemini cache uses the request URL as a key. The URL is always the same when we make a call. The key is actually in the query, not the URL. So the cache does not work all. AuthViewModel (the entrypoint) is not included. 
Dimension 6: Helpfulness — 2/5
The task was to create an app in one response to provide a developer with production ready app, What ChatGPT gave was not helpful at all. The files do not work key features are missing there is no guide on how to set up no list of permissions, no model details.
Dimension 7: Creativity — 3/5
The GeminiFeature enum is as per requirements in prompt. The idea of using an NSCache response to store results when the internet is not working is correct as that is what offline-first means. The problem is that it does not work right and the ideas are not used to make anything real.



Dimension Scores for Gemini Response
Dimension 1: Correctness — 4/5
Gemini got the technical details right. They use Supabase auth. The Gemini API is also implemented. The OCR uses Apples Vision framework. It formats the extracted text it makes sense. They also implemented the pronunciation algorithm correct. The Core Data schema matches the entity. The problem is that they store the JWT in UserDefaults not in the Keychain, which's what the prompt said to do. 
Dimension 2: Relevance — 4/5
App has all four tabs. The Dashboard has a summary card with a gradient, recent projects and recent words. The Reader has a feature where you can tap on a word and interact with it. There are also three bar options: Format, Listen and AI. All four Gemini tools are there too. The Pronunciation feature lets you record your voice. And all other implementations are also relevant.
Dimension 3: Completeness — 4/5
This folder has all the managers and views. CoreData, Supabase, Gemini, OCR, Speech, Dictionary, Haptic. There is a ViewModel for every screen in the folder. The folder also has all the views.
The folder has a Core Data model in XML format. It also has a file for design constants and a config file that gets API keys from Info.plist. There is a file with extensions that includes the pronunciation algorithm. The folder even has a README file that explains how to set up Xcode step by step. But It is missing the Xcode project file and asset catalog.
Dimension 4: Style & Presentation — 5/5
The code is clean, comments, clear naming, structure it also follows the prompt explicit mentioned: Apple HIG, blue gradients, rounded cards, soft shadows, smooth transitions, premium feel. All of the ui follows the prompt.  All ViewModels use @MainActor and async/await consistently — no mixing of old patterns. API keys come from Info.plist through a Config enum. 
Dimension 5: Coherence — 4/5
The architecture is clear and authentication state is stored in the SupabaseManager, it gets saved to the UserDefaults. When the app starts up the AuthViewModel picks up this authentication state. Then the app decides where to go from there. This is a simple and easy to follow process. For the pronunciation flow The SpeechManager makes a recording, then goes to the PracticeViewModel where it gets scored. After that the CoreDataManager saves everything. Each part of this process works smoothly with the one. But The AVPlayer that plays the audio is made as a local variable in the ReaderViewModel. This is a problem because the AVPlayer will get rid of itself right before the audio can play. This is a bug but it is still something that needs to be fixed.
Dimension 6: Helpfulness — 5/5
The task was to create an app in one response to provide a developer with production ready app, What Gemini gave was a complete app following all the requirements clearly.  A developer can set up the project and just put the api keys and app actually works and ready to run on any iOS device.
Dimension 7: Creativity — 5/5
The UI is actually like a production ready app. The decision to split the reader token into raw text is a good solution. It solves a problem with interactive word tapping by having one for layout rendering and one for dictionary and speech. It forces structured output of hoping the model gets it right. The streak system is also well thought out. The WordBasket feature lets users filter by difficulty and, by score, newest or alphabetical order. These small features show they thought about how people use a vocabulary list. The time-of-day greeting and pronunciation feedback messages and four tiers of feedback messages make an app feel premium.


Likert Score — 7
Justification
Response B (Gemini) is better than Response A (ChatGPT).
ChatGPT gave us 4 files and they do not work. The Supabase client has a type issue that refers to itself, the Gemini API uses the authentication header and there is no file for Core Data schema. This means the project does not work all. It does not have any screens, ViewModels, OCR pipeline, Speech layer or AI features. Gemini gave us an application with 27 files that covers everything. It has all 4 tabs, an authentication flow OCR that sorts text correctly a custom scorer for pronunciation all 4 Gemini AI tools that can generate quizzes in JSON mode and a proper design system. It also has a README file for developers.
