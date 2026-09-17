import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'models.dart';
import 'screens/home.dart';
import 'screens/onboarding.dart';
import 'store.dart';
import 'widgets/glass.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final store = AppStore();
  await store.load();
  runApp(MediaApp(store: store));
}

class MediaApp extends StatelessWidget {
  final AppStore store;
  const MediaApp({super.key, required this.store});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: store,
      child: Consumer<AppStore>(
        builder: (context, s, _) {
          final dark = s.prefs.dark;
          return MaterialApp(
            title: 'Media — voti, medie e grafici',
            debugShowCheckedModeBanner: false,
            theme: ThemeData(
              useMaterial3: true,
              brightness: dark ? Brightness.dark : Brightness.light,
              textTheme: GoogleFonts.interTextTheme(dark ? ThemeData.dark().textTheme : ThemeData.light().textTheme),
              colorScheme: ColorScheme.fromSeed(
                seedColor: s.prefs.tema.acc,
                brightness: dark ? Brightness.dark : Brightness.light,
              ),
              appBarTheme: const AppBarTheme(systemOverlayStyle: SystemUiOverlayStyle.dark),
            ),
            home: Stack(children: [
              const Positioned.fill(child: AppWallpaper()),
              if (!s.pronto)
                const Scaffold(
                  backgroundColor: Colors.transparent,
                  body: Center(child: CircularProgressIndicator()),
                )
              else if (s.profile?.completato != true)
                OnboardingScreen(store: s)
              else
                const HomeScreen(),
            ]),
          );
        },
      ),
    );
  }
}
