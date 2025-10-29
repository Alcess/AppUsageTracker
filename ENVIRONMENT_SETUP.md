# Environment Setup

This project uses environment variables and configuration files to securely manage sensitive information like API keys.

## Setup Instructions

1. **Copy the example environment file:**
   ```
   copy .env.example .env
   ```

2. **Edit the .env file with your actual values:**
   ```
   FIREBASE_API_KEY=your_actual_firebase_api_key_here
   ```

3. **Copy the Firebase configuration template:**
   ```
   copy android\app\google-services.json.template android\app\google-services.json
   ```

4. **Edit android/app/google-services.json with your actual Firebase values:**
   - Replace `YOUR_PROJECT_NUMBER` with your Firebase project number
   - Replace `YOUR_PROJECT_ID` with your Firebase project ID
   - Replace `YOUR_MOBILE_SDK_APP_ID` with your mobile SDK app ID
   - Replace `YOUR_FIREBASE_API_KEY_HERE` with your Firebase API key

5. **Never commit sensitive configuration files to version control**
   - The .env file and google-services.json are already added to .gitignore
   - Only commit template files with placeholder values

## Required Environment Variables

- `FIREBASE_API_KEY`: Your Firebase Web API key from the Firebase Console

## Required Configuration Files

- `android/app/google-services.json`: Firebase configuration for Android
- `ios/Runner/GoogleService-Info.plist`: Firebase configuration for iOS (if using iOS)

## Getting Your Firebase Configuration

1. Go to your Firebase Console
2. Select your project
3. Go to Project Settings (gear icon)
4. In the "General" tab, scroll down to "Your apps"
5. For Android: Click "Add app" or select existing Android app, download google-services.json
6. For iOS: Click "Add app" or select existing iOS app, download GoogleService-Info.plist

## Security Notes

- **Never hardcode API keys in source code**
- **Never commit .env files or google-services.json to version control**
- **Rotate API keys if they are accidentally exposed**
- **Use different API keys for different environments (dev, staging, prod)**
- **Keep template files updated but with placeholder values only**