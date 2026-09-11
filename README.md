# Long-Term Date-Based Alarm App

## Setup Instructions

Since this app uses native packages and permissions, please follow these steps to build and run it:

1. **Initialize the Flutter Project**
   Open your terminal in this directory and run:
   ```bash
   flutter create .
   ```
   This will generate the `android`, `ios`, and other platform folders.

2. **Install Dependencies**
   ```bash
   flutter pub get
   ```

3. **Android Configuration**
   To support exact alarms and background notifications, ensure the generated `android/app/src/main/AndroidManifest.xml` includes these permissions:
   ```xml
   <uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED"/>
   <uses-permission android:name="android.permission.WAKE_LOCK"/>
   <uses-permission android:name="android.permission.SCHEDULE_EXACT_ALARM" />
   <uses-permission android:name="android.permission.USE_EXACT_ALARM" />
   <uses-permission android:name="android.permission.POST_NOTIFICATIONS" />
   ```

4. **Run the App**
   ```bash
   flutter run
   ```

## Features
- **12-Month Future Scheduling**: Pick any date up to 12 months ahead.
- **IST Timezone**: Alarms are precisely scheduled using `Asia/Kolkata` time.
- **Persistent Storage**: Alarms are saved locally.
- **Background Execution**: Notifications trigger reliably using Android/iOS native alarms.
