# CKT News

## Project Overview
CKT News is a Flutter application that utilizes a WebView to display web content. The app is designed for both Android and iOS platforms, and can also run on the web.

## Features
- Displays web content using a WebView.
- Supports Android, iOS, and web platforms.
- Easy setup and deployment.

## Setup Instructions
1. **Clone the repository:**
   ```sh
   git clone https://gitlab.com/masare954-group/ckt-news.git
   cd ckt-news
   ```

2. **Install dependencies:**
   ```sh
   flutter pub get
   ```

3. **Run the application:**
   - For Android:
     ```sh
     flutter run -d android
     ```
   - For iOS:
     ```sh
     flutter run -d ios
     ```
   - For Web:
     ```sh
     flutter run -d chrome
     ```

## Usage
- The main entry point is `lib/main.dart`.
- WebView functionality is implemented in your Dart code.

## Contributing
Contributions are welcome! Please submit a pull request or open an issue for any enhancements or bug fixes.

## License
This project is licensed under the MIT License. See the LICENSE file for more details.