# Media (Flutter)

Copia Flutter dell'app web [Media](https://github.com/Andreito08/Media): voti, medie a due decimali per materia, grafici e backup locale — con la stessa grafica "liquid glass".

**Provala:** sito https://andreito08.github.io/MediaFlutter/ · APK Android nelle [Release](https://github.com/Andreito08/MediaFlutter/releases)

## Stato

Prototipo funzionante per confronto con la versione web:
- onboarding in 3 passi, header con media generale, tab Panoramica / Materie e voti
- Panoramica: hero con anello, andamento, confronto materie, dettaglio, torta, simulatore
- Materie: aggiunta/rinomina/nascondi/elimina, voti con `6+`/`6½`/`7/8`, pesi, tipi, periodi
- Impostazioni: profilo, 5 temi, dark mode, anni scolastici
- persistenza sul dispositivo (SharedPreferences)

Manca rispetto al web: backup export/import JSON, stampa, reset totale.

## Sviluppo

```sh
flutter pub get
flutter run
```

APK debug: `flutter build apk --debug` → `build/app/outputs/flutter-apk/app-debug.apk`
