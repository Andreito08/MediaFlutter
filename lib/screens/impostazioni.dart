import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../grades.dart';
import '../models.dart';
import '../store.dart';
import '../widgets/glass.dart';

// Impostazioni: profilo + aspetto + anni — port di ProfiloForm + SezioneImpostazioni

class ImpostazioniSheet extends StatefulWidget {
  const ImpostazioniSheet({super.key});
  @override
  State<ImpostazioniSheet> createState() => _ImpostazioniSheetState();
}

class _ImpostazioniSheetState extends State<ImpostazioniSheet> {
  final nome = TextEditingController();
  final plus = TextEditingController();
  final minus = TextEditingController();
  final nuovoAnno = TextEditingController();
  bool copiaMaterie = true;
  bool _init = false;
  String msgMaterie = '';

  @override
  void dispose() {
    nome.dispose();
    plus.dispose();
    minus.dispose();
    nuovoAnno.dispose();
    super.dispose();
  }

  void _sync(AppStore store) {
    if (_init) return;
    _init = true;
    final p = store.profile;
    if (p == null) return;
    nome.text = p.nome;
    plus.text = p.scala.plus.toString().replaceAll('.', ',');
    minus.text = p.scala.minus.toString().replaceAll('.', ',');
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<AppStore>();
    final dark = store.prefs.dark;
    final p = store.profile;
    _sync(store);
    if (p == null) return const SizedBox.shrink();

    return Container(
      decoration: BoxDecoration(
        color: dark ? const Color(0xFF101B31).withValues(alpha: 0.92) : Colors.white.withValues(alpha: 0.75),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border.all(color: Colors.white.withValues(alpha: dark ? 0.14 : 0.65)),
      ),
      child: SafeArea(
        top: false,
        child: ListView(padding: const EdgeInsets.all(16), children: [
          Row(children: [
            const SectionTitle(icon: Icons.settings_outlined, title: 'Impostazioni', sub: 'Profilo, aspetto e anni'),
            const Spacer(),
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: dark ? Colors.white.withValues(alpha: 0.10) : Colors.white.withValues(alpha: 0.6),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.6)),
                ),
                child: Icon(Icons.close, size: 18, color: dark ? const Color(0xFFCBD5E1) : const Color(0xFF64748B)),
              ),
            ),
          ]),
          // PROFILO
          GlassCard(
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              SectionTitle(icon: Icons.person_outlined, title: 'Profilo e scuola', sub: 'Le stesse scelte del primo avvio'),
              FieldLabel(
                label: 'Nome alunno',
                child: GlassInput(
                  controller: nome,
                  hint: 'Es. Giulia',
                  onChanged: (v) {
                    p.nome = v;
                    store.aggiornaProfilo(p);
                  },
                ),
              ),
              const SizedBox(height: 12),
              FieldLabel(
                label: 'Grado di scuola',
                child: _dropdown<Grado>(
                  value: p.grado,
                  items: [for (final g in Grado.values) (value: g, label: g.nome)],
                  onChanged: (g) {
                    if (g == null) return;
                    setState(() => msgMaterie = '');
                    if (g == Grado.superiori) {
                      final valido = indirizziSuperiori.any((i) => i.id == p.indirizzoId);
                      final id = valido ? p.indirizzoId : 'scientifico';
                      p.grado = g;
                      p.indirizzoId = id;
                      p.indirizzoNome = indirizziSuperiori.where((i) => i.id == id).firstOrNull?.nome ?? 'Liceo Scientifico';
                    } else {
                      p.grado = g;
                      p.indirizzoId = g.name;
                      p.indirizzoNome = g.indirizzoDefault;
                    }
                    store.aggiornaProfilo(p);
                  },
                ),
              ),
              const SizedBox(height: 12),
              if (p.grado == Grado.superiori)
                FieldLabel(
                  label: 'Indirizzo',
                  child: _dropdown<String>(
                    value: p.indirizzoId,
                    items: [for (final i in indirizziSuperiori) (value: i.id, label: i.nome)],
                    onChanged: (id) {
                      if (id == null) return;
                      setState(() => msgMaterie = '');
                      p.indirizzoId = id;
                      p.indirizzoNome = indirizziSuperiori.where((i) => i.id == id).firstOrNull?.nome ?? '';
                      store.aggiornaProfilo(p);
                    },
                  ),
                )
              else
                FieldLabel(label: 'Indirizzo', child: GlassInput(controller: TextEditingController(text: p.indirizzoNome), enabled: false)),
              const SizedBox(height: 12),
              FieldLabel(
                label: 'Divisione anno',
                child: _dropdown<PeriodoTipo>(
                  value: p.periodoTipo,
                  items: const [(value: PeriodoTipo.quadrimestre, label: 'Quadrimestri'), (value: PeriodoTipo.trimestrePenta, label: 'Trimestre + Penta'), (value: PeriodoTipo.unico, label: 'Anno unico')],
                  onChanged: (v) {
                    if (v == null) return;
                    p.periodoTipo = v;
                    store.aggiornaProfilo(p);
                  },
                ),
              ),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(
                  child: FieldLabel(
                    label: "Quanto vale '+'?",
                    hint: 'Es. 0,25 → 6+ = 6,25',
                    child: GlassInput(
                      controller: plus,
                      hint: '0,25',
                      keyboard: const TextInputType.numberWithOptions(decimal: true),
                      maxLength: 4,
                      onChanged: (v) => _commitScala(store, p, v, true),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FieldLabel(
                    label: "Quanto vale '−'?",
                    hint: 'Es. 0,25 → 6− = 5,75',
                    child: GlassInput(
                      controller: minus,
                      hint: '0,25',
                      keyboard: const TextInputType.numberWithOptions(decimal: true),
                      maxLength: 4,
                      onChanged: (v) => _commitScala(store, p, v, false),
                    ),
                  ),
                ),
              ]),
              const SizedBox(height: 12),
              Wrap(spacing: 8, crossAxisAlignment: WrapCrossAlignment.center, children: [
                SoftBtn(
                  onPressed: () async {
                    final n = await store.aggiungiMaterieMancanti(materieDefaultPerIndirizzo(p.grado, p.indirizzoId));
                    setState(() => msgMaterie = n == 0
                        ? "Hai già tutte le materie di questo indirizzo."
                        : "Aggiunte $n ${n == 1 ? 'materia' : 'materie'} dell'indirizzo. Le tue restano tutte.");
                  },
                  child: const Text("Aggiungi materie dell'indirizzo"),
                ),
                if (msgMaterie.isNotEmpty) Text(msgMaterie, style: inter(size: 13, weight: FontWeight.w700, color: dark ? const Color(0xFFCBD5E1) : const Color(0xFF64748B))),
              ]),
            ]),
          ),
          const SizedBox(height: 16),
          // ASPETTO
          GlassCard(
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              const SectionTitle(icon: Icons.palette_outlined, title: 'Aspetto', sub: 'Tema e modalità scura'),
              Text('Tema colore', style: inter(size: 13, weight: FontWeight.w700, color: dark ? const Color(0xFFCBD5E1) : const Color(0xFF475569))),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final t in TemaId.values)
                    GestureDetector(
                      onTap: () => store.impostaTema(t),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(999),
                          gradient: LinearGradient(colors: [t.deep, t.acc]),
                          border: Border.all(
                            color: store.prefs.tema == t ? Colors.white : Colors.white.withValues(alpha: 0.3),
                            width: store.prefs.tema == t ? 2.5 : 1,
                          ),
                        ),
                        child: Text(t.nome, style: inter(size: 13, weight: FontWeight.w700, color: Colors.white)),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: () => store.toggleDark(),
                behavior: HitTestBehavior.opaque,
                child: Row(children: [
                  Expanded(child: Text('Modalità scura', style: inter(size: 14, weight: FontWeight.w700, color: dark ? const Color(0xFFF1F5F9) : const Color(0xFF1E293B)))),
                  Switch(value: dark, onChanged: (_) => store.toggleDark(), activeThumbColor: context.acc),
                ]),
              ),
            ]),
          ),
          const SizedBox(height: 16),
          // ANNI
          GlassCard(
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              const SectionTitle(icon: Icons.calendar_month_outlined, title: 'Anni scolastici', sub: 'Passa da un anno all’altro senza perdere nulla'),
              for (final a in store.anni)
                GestureDetector(
                  onTap: () => store.cambiaAnno(a.id),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      color: a.id == store.anno?.id
                          ? context.acc.withValues(alpha: 0.15)
                          : (dark ? Colors.white.withValues(alpha: 0.05) : Colors.white.withValues(alpha: 0.5)),
                      border: Border.all(
                        color: a.id == store.anno?.id ? context.acc : (dark ? Colors.white.withValues(alpha: 0.10) : const Color(0xFFE2E8F0)),
                        width: a.id == store.anno?.id ? 2 : 1,
                      ),
                    ),
                    child: Row(children: [
                      Expanded(child: Text(a.label, style: inter(size: 15, weight: FontWeight.w800, color: dark ? const Color(0xFFF1F5F9) : const Color(0xFF1E293B)))),
                      if (a.id == store.anno?.id) Icon(Icons.check_circle, size: 20, color: context.acc),
                    ]),
                  ),
                ),
              Row(children: [
                Expanded(child: GlassInput(controller: nuovoAnno, hint: 'Nuovo anno (es. 2026/27)')),
                const SizedBox(width: 8),
                PrimaryBtn(
                  onPressed: () async {
                    await store.creaAnno(nuovoAnno.text, copiaMaterie);
                    nuovoAnno.clear();
                  },
                  child: const Text('Crea'),
                ),
              ]),
              Row(children: [
                Checkbox(value: copiaMaterie, onChanged: (v) => setState(() => copiaMaterie = v ?? true), activeColor: context.acc),
                Expanded(
                  child: Text('Copia le materie dal corrente',
                      style: inter(size: 13, color: dark ? const Color(0xFFCBD5E1) : const Color(0xFF475569))),
                ),
              ]),
            ]),
          ),
          const SizedBox(height: 16),
          PrimaryBtn(fullWidth: true, onPressed: () => Navigator.pop(context), child: const Text('Fatto')),
          const SizedBox(height: 24),
        ]),
      ),
    );
  }

  void _commitScala(AppStore store, Profile p, String grezzo, bool isPlus) {
    final f = soloNumeriDecimali(grezzo);
    final ctl = isPlus ? plus : minus;
    if (f != grezzo) ctl.value = TextEditingValue(text: f, selection: TextSelection.collapsed(offset: f.length));
    if (f.isEmpty || f == ',' || f == '.') return;
    final v = double.tryParse(f.replaceAll(',', '.'));
    if (v == null || v < 0 || v > 1) return;
    p.scala = isPlus ? ScalaPlusMinus(plus: v, minus: p.scala.minus) : ScalaPlusMinus(plus: p.scala.plus, minus: v);
    store.aggiornaProfilo(p);
  }

  Widget _dropdown<T>({required T value, required List<({T value, String label})> items, required ValueChanged<T?> onChanged}) {
    final dark = context.isDark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: dark ? const Color(0xFF0A1426).withValues(alpha: 0.55) : Colors.white.withValues(alpha: 0.55),
        border: Border.all(color: dark ? Colors.white.withValues(alpha: 0.16) : Colors.white.withValues(alpha: 0.70)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          isExpanded: true,
          dropdownColor: dark ? const Color(0xFF14203A) : Colors.white,
          style: inter(size: 15, color: dark ? const Color(0xFFE2E8F0) : const Color(0xFF1E293B)),
          items: [for (final e in items) DropdownMenuItem(value: e.value, child: Text(e.label, overflow: TextOverflow.ellipsis))],
          onChanged: onChanged,
        ),
      ),
    );
  }
}
