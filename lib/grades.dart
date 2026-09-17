import 'package:flutter/material.dart';

// Logica voti italiani: decimali, +, -, mezzi voti, pesi. Port di src/lib/grades.ts

class ScalaPlusMinus {
  final double plus;
  final double minus;
  const ScalaPlusMinus({this.plus = 0.25, this.minus = 0.25});

  factory ScalaPlusMinus.fromJson(Map<String, dynamic> j) => ScalaPlusMinus(
        plus: (j['plus'] as num?)?.toDouble() ?? 0.25,
        minus: (j['minus'] as num?)?.toDouble() ?? 0.25,
      );

  Map<String, dynamic> toJson() => {'plus': plus, 'minus': minus};
}

class ParseResult {
  final bool ok;
  final double? valore;
  final String? errore;
  const ParseResult.ok(this.valore)
      : ok = true,
        errore = null;
  const ParseResult.err(this.errore)
      : ok = false,
        valore = null;
}

double round2(double n) => (n * 100).round() / 100;

/// Accetta: "6" "6.5" "6,5" "6+" "6-" "6½" "6 1/2" "7/8" "7 - 8"
ParseResult parseVoto(String raw, [ScalaPlusMinus scala = const ScalaPlusMinus()]) {
  if (raw.trim().isEmpty) return const ParseResult.err('Inserisci un voto');
  var s = raw.trim().toLowerCase().replaceAll(',', '.');
  s = s.replaceAll('½', '.5').replaceAll('1/2', '.5');

  final range = RegExp(r'^(\d+(?:\.\d+)?)\s*[/\-–;]\s*(\d+(?:\.\d+)?)$').firstMatch(s);
  if (range != null) {
    final a = double.tryParse(range.group(1)!);
    final b = double.tryParse(range.group(2)!);
    if (a != null && b != null && a >= 0 && a <= 10 && b >= 0 && b <= 10) {
      return ParseResult.ok(round2((a + b) / 2));
    }
  }

  var delta = 0.0;
  var base = s;
  final suffix = RegExp(r'^(\d+(?:\.\d+)?)\s*([+\-−]+)$').firstMatch(s);
  if (suffix != null) {
    base = suffix.group(1)!;
    for (final ch in suffix.group(2)!.split('')) {
      if (ch == '+') {
        delta += scala.plus;
      } else {
        delta -= scala.minus;
      }
    }
  }

  final invalido = '"$raw" non è un voto valido. Esempi: 6, 6.5, 6+, 6-, 6½';
  if (base.isEmpty || base == '+' || base == '-') return ParseResult.err(invalido);
  final n = double.tryParse(base);
  if (n == null) return ParseResult.err(invalido);
  final valore = round2(n + delta);
  if (valore < 1 || valore > 10) return const ParseResult.err('Il voto deve stare tra 1 e 10');
  return ParseResult.ok(valore);
}

/// Due decimali stile italiano (7,25), senza decimali se ,00 (7).
String formatMedia(double? n) {
  if (n == null || n.isNaN) return '—';
  final s = n.toStringAsFixed(2);
  if (s.endsWith('00')) return n.round().toString();
  return s.replaceAll('.', ',');
}

double? mediaPesata(List<({double valore, double peso})> voti) {
  final validi = voti.where((v) => v.valore.isFinite && v.peso > 0).toList();
  if (validi.isEmpty) return null;
  final sommaPesata = validi.fold(0.0, (a, v) => a + v.valore * v.peso);
  final sommaPesi = validi.fold(0.0, (a, v) => a + v.peso);
  if (sommaPesi == 0) return null;
  return round2(sommaPesata / sommaPesi);
}

/// Media generale = media delle medie di materia (standard scolastico italiano)
double? mediaGenerale(List<double?> medie) {
  final validi = medie.whereType<double>().where((m) => m.isFinite).toList();
  if (validi.isEmpty) return null;
  return round2(validi.reduce((a, b) => a + b) / validi.length);
}

/// Che voto (peso 100) servirebbe nel prossimo voto per portare la media a un obiettivo?
double? votoNecessarioPerObiettivo(List<({double valore, double peso})> attuali, double obiettivo) {
  final sommaPesata = attuali.fold(0.0, (a, v) => a + v.valore * v.peso);
  final sommaPesi = attuali.fold(0.0, (a, v) => a + v.peso);
  const pesoNuovo = 100.0;
  final x = (obiettivo * (sommaPesi + pesoNuovo) - sommaPesata) / pesoNuovo;
  if (!x.isFinite) return null;
  return round2(x);
}

/// Colori pill come pillColoreMedia del web.
({Color bg, Color fg}) pillMedia(double? m) {
  if (m == null) return (bg: const Color(0xFFF1F5F9), fg: const Color(0xFF64748B));
  if (m < 6) return (bg: const Color(0xFFFEF2F2), fg: const Color(0xFFB91C1C));
  if (m < 7) return (bg: const Color(0xFFFFFBEB), fg: const Color(0xFFB45309));
  if (m < 8) return (bg: const Color(0xFFEFF6FF), fg: const Color(0xFF1E3A5F));
  return (bg: const Color(0xFFECFDF5), fg: const Color(0xFF047857));
}

Color gaugeColor(double? m, Color acc) {
  if (m == null) return const Color(0xFFCBD5E1);
  if (m < 6) return const Color(0xFFF43F5E);
  if (m < 7) return const Color(0xFFF59E0B);
  if (m < 8) return acc;
  return const Color(0xFF10B981);
}

/// Tiene solo cifre + un unico separatore decimale (tastierino solo-numeri).
String soloNumeriDecimali(String v) {
  final pulito = v.replaceAll(RegExp(r'[^0-9.,]'), '');
  final i = pulito.indexOf(RegExp(r'[.,]'));
  if (i == -1) return pulito;
  return pulito.substring(0, i + 1) + pulito.substring(i + 1).replaceAll(RegExp(r'[.,]'), '');
}
