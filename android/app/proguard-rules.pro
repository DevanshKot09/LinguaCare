# Flutter wrapper and plugins
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.* { *; }
-keep class io.flutter.plugins.** { *; }

# SharedPreferences plugin & AndroidX preference
-keep class io.flutter.plugins.sharedpreferences.** { *; }
-keep class androidx.preference.** { *; }

# Keep annotations and generic signatures
-keepattributes *Annotation*,Signature,EnclosingMethod,InnerClasses
-dontwarn android.support.**
