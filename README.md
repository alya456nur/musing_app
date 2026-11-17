MUSING - MUSIC PLAYER APPLICATION
================================

ABOUT THE PROJECT
-----------------

Musing is a Flutter-based mobile music player application designed to provide users with a personalized music listening experience.

The application allows users to discover music, play audio, manage playlists, and access music stored locally on their devices.

FEATURES
--------

1. User Authentication
   - User registration and login.
   - Password recovery.

2. Music Discovery
   - Browse available music.
   - View music recommendations.
   - Search for songs.

3. Music Player
   - Play and pause music.
   - Manage playback queue.
   - Control audio playback.

4. Playlist Management
   - Create playlists.
   - Rename playlists.
   - Delete playlists.

5. Local Music
   - Access music stored on the device.
   - Play local audio files.

6. Download Management
   - Manage downloaded music.

7. Listening History
   - View recently played songs.

8. User Profile
   - View and edit profile information.
   - Manage account settings.

TECHNOLOGIES USED
-----------------

- Flutter - Mobile application framework.
- Dart - Programming language.
- Firebase Authentication - User authentication.
- Cloud Firestore - Cloud database.
- Firebase Storage - Cloud file storage.
- Provider - State management.
- Shared Preferences - Local data storage.
- just_audio - Audio playback.
- audioplayers - Audio playback support.
- on_audio_query - Access local device music.

PROJECT STRUCTURE
-----------------

musing-music-player/
|
|-- android/
|-- ios/
|-- assets/
|-- lib/
|-- test/
|-- .gitignore
|-- pubspec.yaml
|-- README.md


GETTING STARTED
---------------

PREREQUISITES

Before running the application, make sure you have installed:

- Flutter SDK
- Dart SDK
- Android Studio or Visual Studio Code
- Android Emulator or a physical Android device

INSTALLATION

1. Clone the repository:

   git clone https://github.com/alya456nur/musing_app.git

2. Navigate to the project directory:

   cd musing-music-player

3. Install the required dependencies:

   flutter pub get

4. Configure Firebase:

   - Create a Firebase project.
   - Register your Android application.
   - Configure Firebase Authentication.
   - Configure Cloud Firestore and Firebase Storage.
   - Add the required Firebase configuration files.

5. Run the application:

   flutter run


DOWNLOAD APK
------------

Want to try Musing on your Android device?

Download the latest APK from the GitHub Releases page:

https://github.com/alya456nur/musing_app/releases

Installation instructions:

1. Open the GitHub Releases page.
2. Select the latest available release.
3. Download the APK file under Assets.
4. Install the APK on your Android device.

Note: Android may require permission to install applications from
unknown sources.


DEVELOPMENT COMMANDS
--------------------

Check Flutter environment:

   flutter doctor

Install dependencies:

   flutter pub get

Run the application:

   flutter run

Build release APK:

   flutter build apk --release

Analyze source code:

   flutter analyze


DEVELOPER
---------

Developed using Flutter and Dart.

This project was developed for educational purposes.