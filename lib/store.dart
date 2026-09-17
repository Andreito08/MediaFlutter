import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'grades.dart';
import 'models.dart';

// Store centrale. Port di src/store.tsx (Dexie -> SharedPreferences JSON).

class AppStore extends ChangeNotifier {
  static const _kPrefs = 'medie-prefs-v1';
  static const _kProfile = 'media-fl-profile';
  static const _kAnni = 'media-fl-anni';
  static const _kMaterie = 'media-fl-materie';
  static const _kVoti = 'media-fl-voti';

  bool pronto = false;
  Profile? profile;
  Prefs prefs = const Prefs();
  List<Anno> anni = [];
  List<Materia> materieTutte = [];
  List<Voto> votiTutti = [];

  Anno? get anno {
    if (anni.isEmpty) return null;
    return anni.where((a) => a.id == profile?.annoAttivoId).firstOrNull ?? anni.first;
  }

  List<Materia> get materie {
    final a = anno;
    if (a == null) return [];
    return materieTutte.where((m) => m.annoId == a.id).toList();
  }

  List<Voto> get voti {
    final ids = materie.map((m) => m.id).toSet();
    return votiTutti.where((v) => ids.contains(v.materiaId)).toList();
  }

  double? mediaMateria(String materiaId) => mediaPesata(votiTutti
      .where((v) => v.materiaId == materiaId)
      .map((v) => (valore: v.valore, peso: v.peso))
      .toList());

  double? get generale {
    final visibili = materie.where((m) => !m.nascosta).toList();
    return mediaGenerale(visibili.map((m) => mediaMateria(m.id)).toList());
  }

  Future<void> load() async {
    final sp = await SharedPreferences.getInstance();
    try {
      final p = sp.getString(_kPrefs);
      if (p != null) prefs = Prefs.fromJson(jsonDecode(p) as Map<String, dynamic>);
      final pr = sp.getString(_kProfile);
      if (pr != null) profile = Profile.fromJson(jsonDecode(pr) as Map<String, dynamic>);
      anni = _decodeList(sp.getString(_kAnni), Anno.fromJson)..sort((a, b) => a.label.compareTo(b.label));
      materieTutte = _decodeList(sp.getString(_kMaterie), Materia.fromJson)
        ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
      votiTutti = _decodeList(sp.getString(_kVoti), Voto.fromJson);
    } catch (_) {/* dati corrotti: si riparte */}
    pronto = true;
    notifyListeners();
  }

  List<T> _decodeList<T>(String? raw, T Function(Map<String, dynamic>) from) {
    if (raw == null) return [];
    final l = jsonDecode(raw) as List;
    return l.map((e) => from((e as Map).cast<String, dynamic>())).toList();
  }

  Future<void> _save() async {
    final sp = await SharedPreferences.getInstance();
    await sp.setString(_kPrefs, jsonEncode(prefs.toJson()));
    if (profile != null) await sp.setString(_kProfile, jsonEncode(profile!.toJson()));
    await sp.setString(_kAnni, jsonEncode(anni.map((e) => e.toJson()).toList()));
    await sp.setString(_kMaterie, jsonEncode(materieTutte.map((e) => e.toJson()).toList()));
    await sp.setString(_kVoti, jsonEncode(votiTutti.map((e) => e.toJson()).toList()));
  }

  Future<void> _commit() async {
    await _save();
    notifyListeners();
  }

  // ---------- preferenze ----------

  Future<void> impostaTema(TemaId t) async {
    prefs = Prefs(tema: t, dark: prefs.dark);
    await _commit();
  }

  Future<void> toggleDark() async {
    prefs = Prefs(tema: prefs.tema, dark: !prefs.dark);
    await _commit();
  }

  // ---------- onboarding / profilo ----------

  Future<void> completaOnboarding({
    required String nome,
    required Grado grado,
    required String indirizzoId,
    required String indirizzoNome,
    required PeriodoTipo periodoTipo,
    required ScalaPlusMinus scala,
  }) async {
    final annoId = uid();
    final nomi = materieDefaultPerIndirizzo(grado, indirizzoId);
    final now = DateTime.now().millisecondsSinceEpoch;
    anni.add(Anno(id: annoId, label: annoLabelCorrente(), createdAt: now));
    materieTutte.addAll([
      for (var i = 0; i < nomi.length; i++)
        Materia(
          id: '${uid()}$i',
          annoId: annoId,
          nome: nomi[i],
          colore: coloriMaterie[i % coloriMaterie.length],
          isCustom: false,
          nascosta: false,
          createdAt: now + i,
        ),
    ]);
    profile = Profile(
      nome: nome.trim().isEmpty ? 'Studente' : nome.trim(),
      grado: grado,
      indirizzoId: grado == Grado.superiori ? indirizzoId : grado.name,
      indirizzoNome: indirizzoNome,
      periodoTipo: periodoTipo,
      scala: scala,
      annoAttivoId: annoId,
      completato: true,
    );
    await _commit();
  }

  Future<void> aggiornaProfilo(Profile p) async {
    profile = p;
    await _commit();
  }

  // ---------- materie ----------

  Future<void> aggiungiMateria(String nome) async {
    final a = anno;
    final n = nome.trim();
    if (a == null || n.isEmpty) return;
    final usati = materieTutte.where((m) => m.annoId == a.id).map((m) => m.colore).toSet();
    var colore = coloriMaterie.firstWhere((c) => !usati.contains(c), orElse: () => coloriMaterie[materie.length % coloriMaterie.length]);
    materieTutte.add(Materia(
      id: uid(),
      annoId: a.id,
      nome: n,
      colore: colore,
      isCustom: true,
      nascosta: false,
      createdAt: DateTime.now().millisecondsSinceEpoch,
    ));
    await _commit();
  }

  /// Aggiunge solo le materie che mancano. Ritorna quante ne ha aggiunte.
  Future<int> aggiungiMaterieMancanti(List<String> nomi) async {
    final a = anno;
    if (a == null) return 0;
    final presenti = materieTutte.where((m) => m.annoId == a.id).map((m) => m.nome.trim().toLowerCase()).toSet();
    final viste = <String>{};
    final daAggiungere = nomi.map((n) => n.trim()).where((n) {
      final k = n.toLowerCase();
      if (n.isEmpty || presenti.contains(k) || viste.contains(k)) return false;
      viste.add(k);
      return true;
    }).toList();
    if (daAggiungere.isEmpty) return 0;
    final usati = materieTutte.where((m) => m.annoId == a.id).map((m) => m.colore).toSet();
    final now = DateTime.now().millisecondsSinceEpoch;
    for (var i = 0; i < daAggiungere.length; i++) {
      final c = coloriMaterie.firstWhere((c) => !usati.contains(c),
          orElse: () => coloriMaterie[(materieTutte.length + i) % coloriMaterie.length]);
      usati.add(c);
      materieTutte.add(Materia(
        id: '${uid()}$i',
        annoId: a.id,
        nome: daAggiungere[i],
        colore: c,
        isCustom: false,
        nascosta: false,
        createdAt: now + i,
      ));
    }
    await _commit();
    return daAggiungere.length;
  }

  Future<void> rinominaMateria(String id, String nome) async {
    final n = nome.trim();
    if (n.isEmpty) return;
    for (final m in materieTutte) {
      if (m.id == id) m.nome = n;
    }
    await _commit();
  }

  Future<void> toggleNascondiMateria(String id) async {
    for (final m in materieTutte) {
      if (m.id == id) m.nascosta = !m.nascosta;
    }
    await _commit();
  }

  Future<void> eliminaMateria(String id) async {
    materieTutte.removeWhere((m) => m.id == id);
    votiTutti.removeWhere((v) => v.materiaId == id);
    await _commit();
  }

  // ---------- voti ----------

  Future<void> aggiungiVoto({
    required String materiaId,
    required double valore,
    required String input,
    required double peso,
    required TipoVoto tipo,
    required bool primo,
    required String data,
    String? nota,
  }) async {
    votiTutti.add(Voto(
      id: uid(),
      materiaId: materiaId,
      valore: valore,
      input: input.trim(),
      peso: peso,
      tipo: tipo,
      primo: primo,
      data: data.isEmpty ? oggiISO() : data,
      nota: nota?.trim().isEmpty == true ? null : nota?.trim(),
      createdAt: DateTime.now().millisecondsSinceEpoch,
    ));
    await _commit();
  }

  Future<void> eliminaVoto(String id) async {
    votiTutti.removeWhere((v) => v.id == id);
    await _commit();
  }

  // ---------- anni ----------

  Future<void> cambiaAnno(String id) async {
    final p = profile;
    if (p == null) return;
    p.annoAttivoId = id;
    await _commit();
  }

  Future<void> creaAnno(String label, bool copiaMaterie) async {
    final l = label.trim().isEmpty ? annoLabelCorrente() : label.trim();
    final nuovoId = uid();
    final now = DateTime.now().millisecondsSinceEpoch;
    anni.add(Anno(id: nuovoId, label: l, createdAt: now));
    if (copiaMaterie) {
      final a = anno;
      if (a != null) {
        final correnti = materieTutte.where((m) => m.annoId == a.id).toList();
        for (var i = 0; i < correnti.length; i++) {
          final m = correnti[i];
          materieTutte.add(Materia(
            id: '${uid()}$i',
            annoId: nuovoId,
            nome: m.nome,
            colore: m.colore,
            isCustom: m.isCustom,
            nascosta: false,
            createdAt: now + i,
          ));
        }
      }
    }
    final p = profile;
    if (p != null) p.annoAttivoId = nuovoId;
    await _commit();
  }

  Future<void> resetTutto() async {
    final sp = await SharedPreferences.getInstance();
    for (final k in [_kProfile, _kAnni, _kMaterie, _kVoti]) {
      await sp.remove(k);
    }
    profile = null;
    anni = [];
    materieTutte = [];
    votiTutti = [];
    notifyListeners();
  }
}
