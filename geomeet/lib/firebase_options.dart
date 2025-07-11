import 'package:flutter/foundation.dart'; 
import 'package:firebase_core/firebase_core.dart'; 
class DefaultFirebaseOptions {  static FirebaseOptions get currentPlatform {
 
    if (kIsWeb) {
      return web; 
    }
    
    return mobile;
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey:
        'AIzaSyAilj9OYi3IwyzCkvwoFI4paclJ79D_edI', 
    appId:
        '1:331650897885:web:01cb19e6df9a02eb580834', 
    messagingSenderId:
        '331650897885',
    projectId: 'phonetracking-6c6fc', 
    storageBucket:
        'phonetracking-6c6fc.firebasestorage.app',
    authDomain:
        'phonetracking-6c6fc.firebaseapp.com',
    databaseURL:
        'https://phonetracking-6c6fc-default-rtdb.firebaseio.com', 
  );
  static const FirebaseOptions mobile = FirebaseOptions(
    apiKey:
        'AIzaSyAilj9OYi3IwyzCkvwoFI4paclJ79D_edI', 
    appId:
        '1:331650897885:android:01cb19e6df9a02eb580834', 
    messagingSenderId:
        '331650897885', 
    projectId:
        'phonetracking-6c6fc', 
    storageBucket:
        'phonetracking-6c6fc.firebasestorage.app', 
    authDomain:
        'phonetracking-6c6fc.firebaseapp.com', 
    databaseURL:
        'https://phonetracking-6c6fc-default-rtdb.firebaseio.com', 
  );
}
