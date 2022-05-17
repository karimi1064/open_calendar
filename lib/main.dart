import 'package:calendar_app/components/app_rounded_button.dart';
import 'package:calendar_app/utils/app_colors.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import 'modules/pages/open_calendar.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();

  runApp(
    EasyLocalization(
        supportedLocales: const [Locale('en', 'US'), Locale('de', 'DE')],
        path: 'assets/translations',
        // <-- change the path of the translation files
        fallbackLocale: const Locale('en', 'US'),
        useFallbackTranslations: true,
        child: const MyApp()),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      localizationsDelegates: context.localizationDelegates,
      supportedLocales: context.supportedLocales,
      locale: context.locale,
      title: 'Calendar',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'Calendar Application'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: AppRoundedButton(
            text: 'open_calendar'.tr(),
            isBorder: true,
            color: AppColors.indigoLight,
            textColor: AppColors.darkBlue,
            onPressed: _buildCalendarModalBottomSheet,
          ),
        ),
      ),
    );
  }

  Future<void> _buildCalendarModalBottomSheet(
      {bool isAlert = false, bool isCalendar = false}) async {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: true,
      enableDrag: true,
      useRootNavigator: true,
      builder: (BuildContext context) {
        return OpenCalendar(isAlert: isAlert, isCalendar: isCalendar);
      },
    );
  }
}
