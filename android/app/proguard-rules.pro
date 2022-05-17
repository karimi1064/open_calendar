-keepclassmembers enum * {
	public static **[] values();
	public static ** valueOf(java.lang.String);
}
-keepattributes InnerClasses
-dontoptimize
-keep class com.builttoroam.devicecalendar.** { *; }