import 'package:flutter/material.dart';
import 'grades.dart';

// Modelli + catalogo scuola. Port di src/lib/tema.ts, src/lib/db.ts, src/data/indirizzi.ts

// ---------- Temi ----------

enum TemaId { blu, ciano, verde, ambra, rosa }

extension TemaIdX on TemaId {
  String get nome => switch (this) {
        TemaId.blu => 'Blu',
        TemaId.ciano => 'Ciano',
        TemaId.verde => 'Verde',
        TemaId.ambra => 'Ambra',
        TemaId.rosa => 'Rosa',
      };
  Color get acc => switch (this) {
        TemaId.blu => const Color(0xFF2563EB),
        TemaId.ciano => const Color(0xFF0891B2),
        TemaId.verde => const Color(0xFF059669),
        TemaId.ambra => const Color(0xFFD97706),
        TemaId.rosa => const Color(0xFFDB2777),
      };
  Color get deep => switch (this) {
        TemaId.blu => const Color(0xFF16294D),
        TemaId.ciano => const Color(0xFF0B3546),
        TemaId.verde => const Color(0xFF07352A),
        TemaId.ambra => const Color(0xFF472A02),
        TemaId.rosa => const Color(0xFF4D0F2C),
      };
}

class Prefs {
  final TemaId tema;
  final bool dark;
  const Prefs({this.tema = TemaId.blu, this.dark = false});

  factory Prefs.fromJson(Map<String, dynamic> j) {
    final t = j['tema'] as String?;
    return Prefs(
      tema: TemaId.values.asNameMap()[t] ?? TemaId.blu,
      dark: j['dark'] == true,
    );
  }

  Map<String, dynamic> toJson() => {'tema': tema.name, 'dark': dark};
}

// ---------- Gradi / indirizzi ----------

enum Grado { elementari, medie, superiori, universita }

extension GradoX on Grado {
  String get nome => switch (this) {
        Grado.elementari => 'Primaria',
        Grado.medie => 'Secondaria di I grado',
        Grado.superiori => 'Secondaria di II grado',
        Grado.universita => 'Università',
      };
  String get descrizione => switch (this) {
        Grado.elementari => 'Scuola elementare',
        Grado.medie => 'Scuole medie',
        Grado.superiori => 'Superiori: licei, tecnici, professionali',
        Grado.universita => 'Esami universitari (voti in trentesimi convertiti)',
      };
  String get indirizzoDefault => switch (this) {
        Grado.elementari => 'Scuola primaria',
        Grado.medie => 'Secondaria di I grado',
        Grado.superiori => 'Liceo Scientifico',
        Grado.universita => 'Università',
      };
}

class Indirizzo {
  final String id;
  final String nome;
  final List<String> materie;
  const Indirizzo({required this.id, required this.nome, required this.materie});
}

const materieMedie = [
  'Italiano', 'Storia', 'Geografia', 'Matematica', 'Scienze',
  'Inglese', 'Seconda lingua', 'Tecnologia', 'Arte', 'Musica',
  'Ed. Fisica', 'Religione / Alternativa', 'Ed. Civica',
];

const materieElementari = [
  'Italiano', 'Matematica', 'Storia', 'Geografia', 'Scienze',
  'Inglese', 'Arte', 'Musica', 'Ed. Fisica', 'Religione / Alternativa', 'Ed. Civica',
];

const indirizziSuperiori = [
  Indirizzo(id: 'classico', nome: 'Liceo Classico', materie: ['Italiano', 'Latino', 'Greco', 'Inglese', 'Storia', 'Filosofia', 'Matematica', 'Fisica', 'Scienze', 'Storia dell’arte', 'Ed. Fisica', 'Religione / Alternativa', 'Ed. Civica']),
  Indirizzo(id: 'scientifico', nome: 'Liceo Scientifico', materie: ['Italiano', 'Latino', 'Inglese', 'Storia', 'Filosofia', 'Matematica', 'Fisica', 'Scienze', 'Disegno', 'Ed. Fisica', 'Religione / Alternativa', 'Ed. Civica']),
  Indirizzo(id: 'scienze-applicate', nome: 'Scientifico – Scienze Applicate', materie: ['Italiano', 'Inglese', 'Storia', 'Filosofia', 'Matematica', 'Fisica', 'Scienze', 'Informatica', 'Disegno', 'Ed. Fisica', 'Religione / Alternativa', 'Ed. Civica']),
  Indirizzo(id: 'linguistico', nome: 'Liceo Linguistico', materie: ['Italiano', 'Inglese', 'Francese', 'Spagnolo/Tedesco', 'Latino', 'Storia', 'Filosofia', 'Matematica', 'Fisica', 'Scienze', 'Storia dell’arte', 'Ed. Fisica', 'Religione / Alternativa', 'Ed. Civica']),
  Indirizzo(id: 'scienze-umane', nome: 'Liceo Scienze Umane', materie: ['Italiano', 'Latino', 'Inglese', 'Storia', 'Filosofia', 'Scienze umane', 'Matematica', 'Fisica', 'Scienze', 'Storia dell’arte', 'Ed. Fisica', 'Religione / Alternativa', 'Ed. Civica']),
  Indirizzo(id: 'artistico', nome: 'Liceo Artistico', materie: ['Italiano', 'Inglese', 'Storia', 'Filosofia', 'Matematica', 'Fisica', 'Scienze', 'Discipline grafiche', 'Discipline plastiche', 'Storia dell’arte', 'Ed. Fisica', 'Religione / Alternativa', 'Ed. Civica']),
  Indirizzo(id: 'afm', nome: 'Tecnico AFM (Ragioneria)', materie: ['Italiano', 'Inglese', 'Seconda lingua', 'Storia', 'Matematica', 'Economia aziendale', 'Diritto', 'Economia politica', 'Informatica', 'Ed. Fisica', 'Religione / Alternativa', 'Ed. Civica']),
  Indirizzo(id: 'informatica', nome: 'Tecnico Informatica e Telecomunicazioni', materie: ['Italiano', 'Inglese', 'Storia', 'Matematica', 'Informatica', 'Sistemi e reti', 'TPSIT', 'Telecomunicazioni', 'Fisica', 'Ed. Fisica', 'Religione / Alternativa', 'Ed. Civica']),
  Indirizzo(id: 'meccanica', nome: 'Tecnico Meccanica / Energia', materie: ['Italiano', 'Inglese', 'Storia', 'Matematica', 'Fisica', 'Meccanica', 'Sistemi', 'Disegno tecnico', 'Tecnologie', 'Ed. Fisica', 'Religione / Alternativa', 'Ed. Civica']),
  Indirizzo(id: 'turismo', nome: 'Tecnico Turismo', materie: ['Italiano', 'Inglese', 'Seconda lingua', 'Terza lingua', 'Storia', 'Matematica', 'Discipline turistiche', 'Diritto', 'Arte e territorio', 'Ed. Fisica', 'Religione / Alternativa', 'Ed. Civica']),
  Indirizzo(id: 'enogastronomia', nome: 'Professionale Enogastronomia', materie: ['Italiano', 'Inglese', 'Seconda lingua', 'Storia', 'Matematica', 'Enogastronomia', 'Sala e vendita', 'Accoglienza', 'Diritto', 'Ed. Fisica', 'Religione / Alternativa', 'Ed. Civica']),
  Indirizzo(id: 'manutenzione', nome: 'Professionale Manutenzione e Assistenza', materie: ['Italiano', 'Inglese', 'Storia', 'Matematica', 'Fisica', 'Tecnologie meccaniche', 'Tecnologie elettriche', 'Laboratorio', 'Ed. Fisica', 'Religione / Alternativa', 'Ed. Civica']),
];

List<String> materieDefaultPerIndirizzo(Grado grado, [String? indirizzoId]) {
  if (grado == Grado.elementari) return materieElementari;
  if (grado == Grado.medie) return materieMedie;
  if (grado == Grado.universita) return const ['Esame 1'];
  for (final i in indirizziSuperiori) {
    if (i.id == indirizzoId) return i.materie;
  }
  return const ['Italiano', 'Matematica', 'Inglese', 'Storia'];
}

const coloriMaterie = [
  0xFF1E3A5F, 0xFF2563EB, 0xFF0D9488, 0xFF0EA5E9, 0xFFDB2777,
  0xFFEA580C, 0xFF65A30D, 0xFF0891B2, 0xFF3B82F6, 0xFFBE123C,
  0xFF0F766E, 0xFFA16207, 0xFF6D28D9, 0xFF0369A1, 0xFF9A3412,
];

// ---------- Tipi voto / periodo ----------

enum TipoVoto { orale, scritto, pratico, verifica }

extension TipoVotoX on TipoVoto {
  String get label => switch (this) {
        TipoVoto.orale => 'Orale',
        TipoVoto.scritto => 'Scritto',
        TipoVoto.pratico => 'Pratico',
        TipoVoto.verifica => 'Verifica',
      };
  Color get chipBg => switch (this) {
        TipoVoto.orale => const Color(0xFFE0F2FE),
        TipoVoto.scritto => const Color(0xFFDBEAFE),
        TipoVoto.pratico => const Color(0xFFCCFBF1),
        TipoVoto.verifica => const Color(0xFFFFEDD5),
      };
  Color get chipFg => switch (this) {
        TipoVoto.orale => const Color(0xFF0369A1),
        TipoVoto.scritto => const Color(0xFF1D4ED8),
        TipoVoto.pratico => const Color(0xFF0F766E),
        TipoVoto.verifica => const Color(0xFFC2410C),
      };
}

enum PeriodoTipo { trimestrePenta, quadrimestre, unico }

extension PeriodoTipoX on PeriodoTipo {
  String get label => switch (this) {
        PeriodoTipo.trimestrePenta => 'Trimestre + Penta',
        PeriodoTipo.quadrimestre => 'Quadrimestri',
        PeriodoTipo.unico => 'Anno unico',
      };
}

String etichettaPeriodo(bool primo, PeriodoTipo tipo) {
  if (tipo == PeriodoTipo.unico) return 'Anno unico';
  if (tipo == PeriodoTipo.trimestrePenta) return primo ? 'Trimestre' : 'Pentamestre';
  return primo ? '1° Quadrimestre' : '2° Quadrimestre';
}

// ---------- Entità ----------

class Profile {
  String nome;
  Grado grado;
  String indirizzoId;
  String indirizzoNome;
  PeriodoTipo periodoTipo;
  ScalaPlusMinus scala;
  String annoAttivoId;
  bool completato;

  Profile({
    required this.nome,
    required this.grado,
    required this.indirizzoId,
    required this.indirizzoNome,
    required this.periodoTipo,
    required this.scala,
    required this.annoAttivoId,
    required this.completato,
  });

  factory Profile.fromJson(Map<String, dynamic> j) => Profile(
        nome: j['nome'] as String? ?? 'Studente',
        grado: Grado.values.asNameMap()[j['grado']] ?? Grado.superiori,
        indirizzoId: j['indirizzoId'] as String? ?? 'scientifico',
        indirizzoNome: j['indirizzoNome'] as String? ?? 'Liceo Scientifico',
        periodoTipo: PeriodoTipo.values.asNameMap()[j['periodoTipo']] ?? PeriodoTipo.quadrimestre,
        scala: ScalaPlusMinus.fromJson((j['scala'] as Map?)?.cast<String, dynamic>() ?? {}),
        annoAttivoId: j['annoAttivoId'] as String? ?? '',
        completato: j['completato'] == true,
      );

  Map<String, dynamic> toJson() => {
        'nome': nome,
        'grado': grado.name,
        'indirizzoId': indirizzoId,
        'indirizzoNome': indirizzoNome,
        'periodoTipo': periodoTipo.name,
        'scala': scala.toJson(),
        'annoAttivoId': annoAttivoId,
        'completato': completato,
      };
}

class Anno {
  final String id;
  final String label;
  final int createdAt;
  Anno({required this.id, required this.label, required this.createdAt});

  factory Anno.fromJson(Map<String, dynamic> j) => Anno(
        id: j['id'] as String,
        label: j['label'] as String,
        createdAt: (j['createdAt'] as num?)?.toInt() ?? 0,
      );
  Map<String, dynamic> toJson() => {'id': id, 'label': label, 'createdAt': createdAt};
}

class Materia {
  final String id;
  final String annoId;
  String nome;
  final int colore;
  final bool isCustom;
  bool nascosta;
  final int createdAt;

  Materia({
    required this.id,
    required this.annoId,
    required this.nome,
    required this.colore,
    required this.isCustom,
    required this.nascosta,
    required this.createdAt,
  });

  factory Materia.fromJson(Map<String, dynamic> j) => Materia(
        id: j['id'] as String,
        annoId: j['annoId'] as String,
        nome: j['nome'] as String,
        colore: (j['colore'] as num).toInt(),
        isCustom: j['isCustom'] == true,
        nascosta: j['nascosta'] == true,
        createdAt: (j['createdAt'] as num?)?.toInt() ?? 0,
      );
  Map<String, dynamic> toJson() => {
        'id': id,
        'annoId': annoId,
        'nome': nome,
        'colore': colore,
        'isCustom': isCustom,
        'nascosta': nascosta,
        'createdAt': createdAt,
      };
}

class Voto {
  final String id;
  final String materiaId;
  final double valore;
  final String input;
  final double peso;
  final TipoVoto tipo;
  final bool primo; // true = primo periodo
  final String data; // ISO yyyy-mm-dd
  final String? nota;
  final int createdAt;

  Voto({
    required this.id,
    required this.materiaId,
    required this.valore,
    required this.input,
    required this.peso,
    required this.tipo,
    required this.primo,
    required this.data,
    this.nota,
    required this.createdAt,
  });

  factory Voto.fromJson(Map<String, dynamic> j) => Voto(
        id: j['id'] as String,
        materiaId: j['materiaId'] as String,
        valore: (j['valore'] as num).toDouble(),
        input: j['input'] as String,
        peso: (j['peso'] as num).toDouble(),
        tipo: TipoVoto.values.asNameMap()[j['tipo']] ?? TipoVoto.orale,
        primo: j['primo'] != false,
        data: j['data'] as String,
        nota: j['nota'] as String?,
        createdAt: (j['createdAt'] as num?)?.toInt() ?? 0,
      );
  Map<String, dynamic> toJson() => {
        'id': id,
        'materiaId': materiaId,
        'valore': valore,
        'input': input,
        'peso': peso,
        'tipo': tipo.name,
        'primo': primo,
        'data': data,
        'nota': nota,
        'createdAt': createdAt,
      };
}

String uid() => '${DateTime.now().millisecondsSinceEpoch.toRadixString(36)}${(1000 + (9000 * (DateTime.now().microsecond % 1000) / 1000).toInt()).toRadixString(36)}';

String oggiISO() {
  final n = DateTime.now();
  return '${n.year.toString().padLeft(4, '0')}-${n.month.toString().padLeft(2, '0')}-${n.day.toString().padLeft(2, '0')}';
}

String annoLabelCorrente() {
  final n = DateTime.now();
  final inizio = n.month >= 9 ? n.year : n.year - 1;
  return '$inizio/${((inizio + 1) % 100).toString().padLeft(2, '0')}';
}
