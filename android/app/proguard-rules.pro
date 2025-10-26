# Keep ML Kit classes
-keep class com.google.mlkit.** { *; }
-keep class com.google.android.gms.** { *; }

# Keep text recognition classes specifically  
-keep class com.google.mlkit.vision.text.** { *; }
-keep class com.google.mlkit.vision.text.chinese.** { *; }
-keep class com.google.mlkit.vision.text.devanagari.** { *; }
-keep class com.google.mlkit.vision.text.japanese.** { *; }
-keep class com.google.mlkit.vision.text.korean.** { *; }

# Keep Firebase classes
-keep class com.google.firebase.** { *; }

# Keep Flutter and Dart classes
-keep class io.flutter.** { *; }
-keep class dart.** { *; }

# Keep permission handler classes
-keep class com.baseflow.permissionhandler.** { *; }

# Keep camera classes
-keep class io.flutter.plugins.camera.** { *; }

# Keep image picker classes  
-keep class io.flutter.plugins.imagepicker.** { *; }

# Don't obfuscate any class that uses native methods
-keepclasseswithmembernames class * {
    native <methods>;
}