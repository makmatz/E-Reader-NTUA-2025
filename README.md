# BookReader

## Links
Το παρακάτω link οδηγεί σε φάκελο στο Google Drive στον οποίο υπάρχει το αρχείο release.apk 
καθώς και ένα σύντομο βίντεο στο οποίο παρουσιάζουμε τις λειτουργίες της εφαρμογής.
- https://drive.google.com/drive/folders/1H5snWCbnTseysG4zo8Q5mYcEBsbs7gud?usp=sharing

## Οδηγίες εγκατάστασης & χρήσης

### Εγκατάσταση από APK (User).
1. Βρείτε το αρχείο:
   `release.apk`
2. Μεταφέρετέ το στη συσκευή σας (USB, email, cloud) και ανοίξτε το.
3. Αν ζητηθεί, επιτρέψτε εγκατάσταση από "Άγνωστες πηγές".

### Εκτέλεση από πηγαίο κώδικα (Developer).
1. Εγκαταστήστε Flutter SDK και Android Studio.
2. Από τον φάκελο του έργου:
   `flutter pub get`
3. Συνδέστε συσκευή ή ξεκινήστε emulator:
   `flutter run`
4. Χρήση εφαρμογής:
   - Ανοίξτε ένα βιβλίο από την καρτέλα Library.
   - Μετακινηθείτε με Next/Previous ή με swipe.

### Απαιτήσεις Android SDK / Emulator
- Χρησιμοποιούμε Android 16.0 "Baklava" (API 36).
- Το project χρησιμοποιεί τις default τιμές του Flutter για compile/target SDK
  (βλ. `android/app/build.gradle.kts`).
- Δοκιμάστηκε σε Android Emulator: `sdk gphone64 x86 64`, API 36, Google APIs.


## Manual χρήσης εφαρμογής.

### Είσοδος (demo)
1. Ανοίξτε την εφαρμογή.
2. Πατήστε **Log In** ή **Sign Up** για είσοδο (demo χρήστης).
3. Για έξοδο, πατήστε το εικονίδιο **Log out** στην πάνω μπάρα.

### Βιβλιοθήκη
1. Αναζητήστε βιβλία με το πεδίο αναζήτησης.
2. Χρησιμοποιήστε φίλτρα genre.
3. Μετακινηθείτε στις καρτέλες **All Books**, **Continue Reading**, **Collections**, **Bookmarks**.

### Ανάγνωση
1. Ανοίξτε ένα βιβλίο από τη Βιβλιοθήκη.
2. Μετακινηθείτε με **Next/Previous** ή swipe.
3. Η πρόοδος αποθηκεύεται αυτόματα.

### Bookmarks
1. Πατήστε το εικονίδιο bookmark μέσα στον reader.
2. Δείτε όλα τα βιβλία με bookmarks στην καρτέλα **Bookmarks** της Βιβλιοθήκης.

### Ρυθμίσεις ανάγνωσης
Από το εικονίδιο **settings** στον reader:
- **Appearance**: γραμματοσειρά, μέγεθος, line height, theme.
- **Audio**: text‑to‑speech, volume, ambience.
- **Flow**: auto‑scroll ή word‑cursor.
- **Interaction**: voice commands.

### Voice Commands
1. Ενεργοποιήστε **Voice Commands**.
2. Χρησιμοποιήστε wake word και εντολή, π.χ.:
   - “reader next page”
   - “reader bookmark”
   - “reader summary”
   - “reader start reading”

### Smart Companion (AI εργαλεία demo)
1. Επιλέξτε κείμενο μέσα στον reader.
2. Ανοίγει το Smart Companion.
3. Επιλέξτε **Explain**, **Summary**, **Translate**, ή **Q&A** στο κάτω μέρος για mock απάντηση.
