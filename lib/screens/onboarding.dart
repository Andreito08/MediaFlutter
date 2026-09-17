import 'package:flutter/material.dart';
import '../grades.dart';
import '../models.dart';
import '../store.dart';
import '../widgets/glass.dart';

// Onboarding in 3 passi — port di Onboarding in src/components/ui.tsx

class OnboardingScreen extends StatefulWidget {
  final AppStore store;
  const OnboardingScreen({super.key, required this.store});
  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  int step = 1;
  final nome = TextEditingController();
  Grado grado = Grado.superiori;
  String indirizzoId = 'scientifico';
  PeriodoTipo periodoTipo = PeriodoTipo.quadrimestre;
  final plus = TextEditingController(text: '0,25');
  final minus = TextEditingController(text: '0,25');
  bool salvataggio = false;
  String errore = '';

  @override
  void dispose() {
    nome.dispose();
    plus.dispose();
    minus.dispose();
    super.dispose();
  }

  String get indirizzoNome {
    if (grado == Grado.medie) return 'Secondaria di I grado';
    if (grado == Grado.elementari) return 'Scuola primaria';
    if (grado == Grado.universita) return 'Università';
    return indirizziSuperiori.where((i) => i.id == indirizzoId).firstOrNull?.nome ?? 'Indirizzo personalizzato';
  }

  Future<void> avvia() async {
    setState(() => errore = '');
    final p = double.tryParse(plus.text.replaceAll(',', '.'));
    final m = double.tryParse(minus.text.replaceAll(',', '.'));
    if (p == null || m == null || p < 0 || p > 1 || m < 0 || m > 1) {
      setState(() => errore = 'I valori di + e − devono stare tra 0 e 1 (es. 0,25).');
      return;
    }
    setState(() => salvataggio = true);
    try {
      await widget.store.completaOnboarding(
        nome: nome.text.trim().isEmpty ? 'Studente' : nome.text,
        grado: grado,
        indirizzoId: grado == Grado.superiori ? indirizzoId : grado.name,
        indirizzoNome: indirizzoNome,
        periodoTipo: periodoTipo,
        scala: ScalaPlusMinus(plus: p, minus: m),
      );
    } catch (_) {
      setState(() {
        errore = 'Qualcosa è andato storto, riprova.';
        salvataggio = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final anteprima = materieDefaultPerIndirizzo(grado, indirizzoId);
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Column(children: [
                GlassDarkCard(
                  padding: const EdgeInsets.all(28),
                  child: Column(children: [
                    Row(children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.30)),
                        ),
                        child: Center(child: Text('M', style: inter(size: 20, weight: FontWeight.w900, color: Colors.white))),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text('Media', style: inter(size: 24, weight: FontWeight.w900, color: Colors.white)),
                          Text('Voti, medie a due decimali e grafici.',
                              style: inter(size: 13, color: const Color(0xFFE0F2FE).withValues(alpha: 0.9))),
                        ]),
                      ),
                    ]),
                    const SizedBox(height: 24),
                    Row(children: [
                      for (var i = 0; i < 3; i++) ...[
                        _dot(i + 1),
                        if (i < 2)
                          Expanded(
                            child: Container(
                              height: 2,
                              margin: const EdgeInsets.symmetric(horizontal: 6),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.20),
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          ),
                      ],
                    ]),
                  ]),
                ),
                const SizedBox(height: 16),
                GlassCard(
                  padding: const EdgeInsets.all(24),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    child: switch (step) {
                      1 => _step1(),
                      2 => _step2(anteprima),
                      _ => _step3(),
                    },
                  ),
                ),
              ]),
            ),
          ),
        ),
      ),
    );
  }

  Widget _dot(int n) {
    const labels = ['Tu', 'Scuola', 'Voti'];
    final active = step == n;
    final done = step > n;
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: active ? Colors.white : done ? const Color(0xFF6EE7B7) : Colors.white.withValues(alpha: 0.20),
        ),
        child: Center(
          child: done
              ? const Icon(Icons.check, size: 14, color: Color(0xFF064E3B))
              : Text('$n',
                  style: inter(size: 12, weight: FontWeight.w900, color: active ? const Color(0xFF1E3A5F) : Colors.white70)),
        ),
      ),
      const SizedBox(width: 6),
      Text(labels[n - 1], style: inter(size: 12, weight: FontWeight.w700, color: active ? Colors.white : Colors.white60)),
    ]);
  }

  Widget _step1() {
    return Column(
      key: const ValueKey(1),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FieldLabel(label: 'Come ti chiami?', child: GlassInput(controller: nome, hint: 'Es. Giulia')),
        const SizedBox(height: 20),
        Text('Che scuola fai?',
            style: inter(size: 13, weight: FontWeight.w700, color: context.isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569))),
        const SizedBox(height: 8),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 2.1,
          children: [
            for (final g in Grado.values)
              _gradoCard(g),
          ],
        ),
        const SizedBox(height: 16),
        Align(alignment: Alignment.centerRight, child: PrimaryBtn(onPressed: () => setState(() => step = 2), child: const Text('Avanti →'))),
      ],
    );
  }

  Widget _gradoCard(Grado g) {
    final sel = grado == g;
    final dark = context.isDark;
    return GestureDetector(
      onTap: () => setState(() => grado = g),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: sel ? const Color(0xFF3B82F6) : (dark ? Colors.white.withValues(alpha: 0.10) : const Color(0xFFF1F5F9)),
            width: 2,
          ),
          color: sel
              ? const Color(0xFF3B82F6).withValues(alpha: dark ? 0.15 : 0.08)
              : (dark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFF8FAFC).withValues(alpha: 0.6)),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
          Text(g.nome,
              style: inter(
                  size: 13,
                  weight: FontWeight.w800,
                  color: sel ? (dark ? const Color(0xFFDBEAFE) : const Color(0xFF1E3A5F)) : (dark ? const Color(0xFFE2E8F0) : const Color(0xFF334155)))),
          Text(g.descrizione, maxLines: 1, overflow: TextOverflow.ellipsis, style: inter(size: 11, color: const Color(0xFF94A3B8))),
        ]),
      ),
    );
  }

  Widget _step2(List<String> anteprima) {
    final dark = context.isDark;
    return Column(
      key: const ValueKey(2),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (grado == Grado.superiori)
          FieldLabel(
            label: "Scegli l'indirizzo",
            hint: 'Carico le materie giuste. Poi potrai aggiungere e togliere a piacere.',
            child: _dropdown(
              value: indirizzoId,
              items: [for (final i in indirizziSuperiori) (value: i.id, label: i.nome)],
              onChanged: (v) => setState(() => indirizzoId = v!),
            ),
          )
        else
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: dark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(16)),
            child: Text.rich(
              TextSpan(
                style: inter(size: 14, color: dark ? const Color(0xFFCBD5E1) : const Color(0xFF475569)),
                children: [
                  const TextSpan(text: 'Per '),
                  TextSpan(text: indirizzoNome, style: inter(size: 14, weight: FontWeight.w800)),
                  const TextSpan(text: ' ho già pronto il set di materie standard. Potrai personalizzarlo dopo.'),
                ],
              ),
            ),
          ),
        const SizedBox(height: 16),
        Text('Anteprima materie · ${anteprima.length}',
            style: inter(size: 13, weight: FontWeight.w700, color: dark ? const Color(0xFFCBD5E1) : const Color(0xFF475569))),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [for (final m in anteprima) _chipPreview(m)],
        ),
        const SizedBox(height: 16),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          SoftBtn(onPressed: () => setState(() => step = 1), child: const Text('← Indietro')),
          PrimaryBtn(onPressed: () => setState(() => step = 3), child: const Text('Avanti →')),
        ]),
      ],
    );
  }

  Widget _chipPreview(String m) {
    final dark = context.isDark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        gradient: LinearGradient(colors: dark ? [Colors.white.withValues(alpha: 0.10), Colors.white.withValues(alpha: 0.05)] : [const Color(0xFFF1F5F9), const Color(0xFFEFF6FF)]),
        border: Border.all(color: dark ? Colors.white.withValues(alpha: 0.10) : const Color(0xFFE2E8F0).withValues(alpha: 0.7)),
      ),
      child: Text(m, style: inter(size: 12, weight: FontWeight.w700, color: dark ? const Color(0xFFCBD5E1) : const Color(0xFF475569))),
    );
  }

  Widget _step3() {
    return Column(
      key: const ValueKey(3),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FieldLabel(
          label: "Come è diviso l'anno nella tua scuola?",
          child: _dropdown(
            value: periodoTipo.name,
            items: const [(value: 'quadrimestre', label: 'Quadrimestre + Quadrimestre'), (value: 'trimestrePenta', label: 'Trimestre + Pentamestre'), (value: 'unico', label: 'Anno unico (senza periodi)')],
            onChanged: (v) => setState(() => periodoTipo = PeriodoTipo.values.asNameMap()[v]!),
          ),
        ),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(
            child: FieldLabel(
              label: "Quanto vale '+'?",
              hint: 'Tipico 0,25 → 6+ = 6,25',
              child: GlassInput(
                controller: plus,
                hint: '0,25',
                keyboard: const TextInputType.numberWithOptions(decimal: true),
                maxLength: 4,
                onChanged: (v) {
                  final f = soloNumeriDecimali(v);
                  if (f != v) {
                    plus.value = TextEditingValue(text: f, selection: TextSelection.collapsed(offset: f.length));
                  }
                },
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: FieldLabel(
              label: "Quanto vale '−'?",
              hint: 'Tipico 0,25 → 6− = 5,75',
              child: GlassInput(
                controller: minus,
                hint: '0,25',
                keyboard: const TextInputType.numberWithOptions(decimal: true),
                maxLength: 4,
                onChanged: (v) {
                  final f = soloNumeriDecimali(v);
                  if (f != v) {
                    minus.value = TextEditingValue(text: f, selection: TextSelection.collapsed(offset: f.length));
                  }
                },
              ),
            ),
          ),
        ]),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(colors: context.isDark ? [const Color(0xFF3B82F6).withValues(alpha: 0.15), const Color(0xFF06B6D4).withValues(alpha: 0.10)] : [const Color(0xFFEFF6FF), const Color(0xFFECFEFF)]),
            border: Border.all(color: context.isDark ? Colors.white.withValues(alpha: 0.10) : const Color(0xFFDBEAFE)),
          ),
          child: Text('Accetto voti come 6 · 6,5 · 6+ · 6− · 6½ · 7/8. Il peso è opzionale (100% = normale). I dati restano sul tuo dispositivo.',
              style: inter(size: 13, color: context.isDark ? const Color(0xFFDBEAFE) : const Color(0xFF1E3A5F))),
        ),
        if (errore.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(errore, style: inter(size: 13, weight: FontWeight.w700, color: const Color(0xFFE11D48))),
        ],
        const SizedBox(height: 16),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          SoftBtn(onPressed: () => setState(() => step = 2), child: const Text('← Indietro')),
          PrimaryBtn(
            onPressed: salvataggio ? null : avvia,
            child: Text(salvataggio ? 'Creazione…' : 'Crea la mia app ✓'),
          ),
        ]),
      ],
    );
  }

  Widget _dropdown({
    required String value,
    required List<({String value, String label})> items,
    required ValueChanged<String?> onChanged,
  }) {
    final dark = context.isDark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: dark ? const Color(0xFF0A1426).withValues(alpha: 0.55) : Colors.white.withValues(alpha: 0.55),
        border: Border.all(color: dark ? Colors.white.withValues(alpha: 0.16) : Colors.white.withValues(alpha: 0.70)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: items.any((e) => e.value == value) ? value : items.first.value,
          isExpanded: true,
          dropdownColor: dark ? const Color(0xFF14203A) : Colors.white,
          style: inter(size: 15, weight: FontWeight.w500, color: dark ? const Color(0xFFE2E8F0) : const Color(0xFF1E293B)),
          items: [for (final e in items) DropdownMenuItem(value: e.value, child: Text(e.label, overflow: TextOverflow.ellipsis))],
          onChanged: onChanged,
        ),
      ),
    );
  }
}
