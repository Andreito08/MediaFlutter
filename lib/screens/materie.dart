import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../grades.dart';
import '../models.dart';
import '../store.dart';
import '../widgets/glass.dart';

// Materie e voti — port di src/components/Materie.tsx

class MaterieView extends StatefulWidget {
  const MaterieView({super.key});
  @override
  State<MaterieView> createState() => _MaterieViewState();
}

class _MaterieViewState extends State<MaterieView> {
  final nuova = TextEditingController();
  String? aperta;
  String? editingId;
  final nomeEdit = TextEditingController();
  final input = TextEditingController();
  final peso = TextEditingController(text: '100');
  TipoVoto tipo = TipoVoto.orale;
  bool primo = true;
  DateTime data = DateTime.now();
  final nota = TextEditingController();
  String errore = '';
  String? confermaElimina;

  @override
  void dispose() {
    nuova.dispose();
    nomeEdit.dispose();
    input.dispose();
    peso.dispose();
    nota.dispose();
    super.dispose();
  }

  Future<void> salvaVoto(AppStore store, String materiaId) async {
    setState(() => errore = '');
    final scala = store.profile?.scala ?? const ScalaPlusMinus();
    final r = parseVoto(input.text, scala);
    if (!r.ok || r.valore == null) {
      setState(() => errore = r.errore ?? 'Voto non valido');
      return;
    }
    final p = double.tryParse(peso.text.replaceAll(',', '.'));
    if (p == null || p <= 0 || p > 300) {
      setState(() => errore = 'Il peso deve stare tra 1 e 300 (100 = normale).');
      return;
    }
    await store.aggiungiVoto(
      materiaId: materiaId,
      valore: r.valore!,
      input: input.text.trim(),
      peso: p,
      tipo: tipo,
      primo: primo,
      data: _iso(data),
      nota: nota.text,
    );
    setState(() {
      input.clear();
      nota.clear();
      peso.text = '100';
    });
  }

  String _iso(DateTime d) => '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final store = context.watch<AppStore>();
    final dark = store.prefs.dark;
    final visibili = store.materie.where((m) => !m.nascosta).toList();
    final nascoste = store.materie.where((m) => m.nascosta).toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 16, 12, 40),
      children: [
        GlassCard(
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            SectionTitle(
              icon: Icons.book_outlined,
              title: 'Le tue materie',
              sub: '${visibili.length} visibili · indirizzo ${store.profile?.indirizzoNome ?? ''}',
            ),
            Row(children: [
              Expanded(child: GlassInput(controller: nuova, hint: 'Aggiungi una tua materia (es. Robotica)', onSubmitted: () => _aggiungi(store))),
              const SizedBox(width: 8),
              PrimaryBtn(onPressed: () => _aggiungi(store), child: const Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.add, size: 16, color: Colors.white), Text('Aggiungi')])),
            ]),
            const SizedBox(height: 8),
            Text('Nascondi (es. Religione) invece di eliminare se non vuoi perdere i voti.',
                style: inter(size: 12, color: const Color(0xFF94A3B8), height: 1.4)),
          ]),
        ),
        const SizedBox(height: 16),
        if (visibili.isEmpty)
          GlassCard(child: Center(child: Text('Nessuna materia visibile. Aggiungine una sopra.', style: inter(size: 14, color: const Color(0xFF94A3B8))))),
        for (final m in visibili) ...[
          _materiaCard(store, m, dark),
          const SizedBox(height: 16),
        ],
        if (nascoste.isNotEmpty)
          GlassCard(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text.rich(
                TextSpan(style: inter(size: 14, weight: FontWeight.w800, color: dark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)), children: const [
                  TextSpan(text: 'Nascoste'),
                  TextSpan(text: ' — tocca per mostrare di nuovo', style: TextStyle(fontWeight: FontWeight.normal)),
                ]),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final m in nascoste)
                    GestureDetector(
                      onTap: () => store.toggleNascondiMateria(m.id),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                        decoration: BoxDecoration(
                          color: dark ? Colors.white.withValues(alpha: 0.10) : const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(color: dark ? Colors.white.withValues(alpha: 0.10) : const Color(0xFFE2E8F0)),
                        ),
                        child: Text('👁 ${m.nome}',
                            style: inter(size: 12, weight: FontWeight.w700, color: dark ? const Color(0xFFCBD5E1) : const Color(0xFF64748B))),
                      ),
                    ),
                ],
              ),
            ]),
          ),
      ],
    );
  }

  Future<void> _aggiungi(AppStore store) async {
    await store.aggiungiMateria(nuova.text);
    nuova.clear();
  }

  Widget _materiaCard(AppStore store, Materia m, bool dark) {
    final vv = store.votiTutti.where((v) => v.materiaId == m.id).toList()..sort((a, b) => b.data.compareTo(a.data));
    final media = store.mediaMateria(m.id);
    final isOpen = aperta == m.id;
    return GlassCard(
      padding: EdgeInsets.zero,
      child: Column(children: [
        GestureDetector(
          onTap: () => setState(() => aperta = isOpen ? null : m.id),
          behavior: HitTestBehavior.opaque,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(children: [
              Container(
                width: 8,
                height: 44,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(m.colore), Color(m.colore).withValues(alpha: 0.6)],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: editingId == m.id
                    ? Row(children: [
                        Expanded(child: GlassInput(controller: nomeEdit)),
                        const SizedBox(width: 8),
                        SoftBtn(
                          onPressed: () async {
                            await store.rinominaMateria(m.id, nomeEdit.text);
                            setState(() => editingId = null);
                          },
                          child: const Text('OK'),
                        ),
                      ])
                    : Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(m.nome,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: inter(size: 15, weight: FontWeight.w800, color: dark ? const Color(0xFFF1F5F9) : const Color(0xFF1E293B))),
                        const SizedBox(height: 2),
                        Text(vv.isEmpty ? 'Nessun voto ancora' : '${vv.length} ${vv.length == 1 ? 'voto' : 'voti'} · ultimo ${vv.first.input}',
                            style: inter(size: 12, color: const Color(0xFF94A3B8))),
                      ]),
              ),
              MediaPill(media: media, size: 15),
              const SizedBox(width: 8),
              AnimatedRotation(
                turns: isOpen ? 0.5 : 0,
                duration: const Duration(milliseconds: 200),
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: dark ? Colors.white.withValues(alpha: 0.10) : const Color(0xFFF1F5F9),
                  ),
                  child: const Icon(Icons.keyboard_arrow_down, size: 18, color: Color(0xFF94A3B8)),
                ),
              ),
            ]),
          ),
        ),
        if (isOpen)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: dark ? Colors.white.withValues(alpha: 0.10) : Colors.white.withValues(alpha: 0.6))),
              color: dark ? Colors.black.withValues(alpha: 0.20) : Colors.white.withValues(alpha: 0.25),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Wrap(spacing: 8, runSpacing: 8, children: [
                _miniAction(Icons.edit, 'Rinomina', () => setState(() {
                      editingId = m.id;
                      nomeEdit.text = m.nome;
                    })),
                _miniAction(Icons.visibility_outlined, 'Nascondi', () => store.toggleNascondiMateria(m.id)),
                if (confermaElimina == m.id) ...[
                  GestureDetector(
                    onTap: () => store.eliminaMateria(m.id),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                      decoration: BoxDecoration(color: const Color(0xFFE11D48), borderRadius: BorderRadius.circular(999)),
                      child: Text('Conferma elimina + voti', style: inter(size: 12, weight: FontWeight.w700, color: Colors.white)),
                    ),
                  ),
                  _miniAction(Icons.close, 'Annulla', () => setState(() => confermaElimina = null)),
                ] else
                  GestureDetector(
                    onTap: () => setState(() => confermaElimina = m.id),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF1F2),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: const Color(0xFFFECDD3)),
                      ),
                      child: Text('Elimina', style: inter(size: 12, weight: FontWeight.w700, color: const Color(0xFFE11D48))),
                    ),
                  ),
              ]),
              const SizedBox(height: 12),
              _nuovoVotoBox(store, m, dark),
              const SizedBox(height: 8),
              if (vv.isEmpty)
                Center(child: Text('Ancora nessun voto: scrivi sopra “6+” e premi Salva.', style: inter(size: 13, color: const Color(0xFF94A3B8))))
              else
                for (final v in vv) _votoRow(store, v, dark),
            ]),
          ),
      ]),
    );
  }

  Widget _miniAction(IconData icon, String label, VoidCallback onTap) {
    final dark = context.isDark;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          color: dark ? Colors.white.withValues(alpha: 0.10) : Colors.white.withValues(alpha: 0.6),
          border: Border.all(color: dark ? Colors.white.withValues(alpha: 0.15) : Colors.white.withValues(alpha: 0.7)),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 14, color: dark ? const Color(0xFFCBD5E1) : const Color(0xFF64748B)),
          const SizedBox(width: 4),
          Text(label, style: inter(size: 12, weight: FontWeight.w700, color: dark ? const Color(0xFFCBD5E1) : const Color(0xFF64748B))),
        ]),
      ),
    );
  }

  Widget _nuovoVotoBox(AppStore store, Materia m, bool dark) {
    final periodoTipo = store.profile?.periodoTipo ?? PeriodoTipo.quadrimestre;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: dark ? Colors.white.withValues(alpha: 0.05) : Colors.white.withValues(alpha: 0.55),
        border: Border.all(color: dark ? Colors.white.withValues(alpha: 0.10) : Colors.white.withValues(alpha: 0.6)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [
          AccChip(icon: const Icon(Icons.add, size: 14)),
          const SizedBox(width: 8),
          Expanded(
            child: Text('Nuovo voto in ${m.nome}',
                style: inter(size: 14, weight: FontWeight.w800, color: dark ? const Color(0xFFE2E8F0) : const Color(0xFF334155))),
          ),
        ]),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 2.6,
          children: [
            FieldLabel(
              label: 'Voto',
              child: GlassInput(controller: input, hint: '6+ · 7,5 · 6½'),
            ),
            FieldLabel(
              label: 'Peso %',
              hint: '100 = normale',
              child: GlassInput(
                controller: peso,
                keyboard: const TextInputType.numberWithOptions(decimal: true),
                maxLength: 5,
                onChanged: (v) {
                  final f = soloNumeriDecimali(v);
                  if (f != v) peso.value = TextEditingValue(text: f, selection: TextSelection.collapsed(offset: f.length));
                },
              ),
            ),
            FieldLabel(
              label: 'Tipo',
              child: _smallDropdown<TipoVoto>(
                value: tipo,
                items: [for (final t in TipoVoto.values) (value: t, label: t.label)],
                onChanged: (v) => setState(() => tipo = v!),
              ),
            ),
            FieldLabel(
              label: 'Periodo',
              child: _smallDropdown<bool>(
                value: primo,
                items: [(value: true, label: etichettaPeriodo(true, periodoTipo)), (value: false, label: etichettaPeriodo(false, periodoTipo))],
                onChanged: (v) => setState(() => primo = v!),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        GestureDetector(
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: data,
              firstDate: DateTime(2020),
              lastDate: DateTime(2035),
            );
            if (picked != null) setState(() => data = picked);
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(999),
              color: dark ? const Color(0xFF0A1426).withValues(alpha: 0.55) : Colors.white.withValues(alpha: 0.55),
              border: Border.all(color: dark ? Colors.white.withValues(alpha: 0.16) : Colors.white.withValues(alpha: 0.70)),
            ),
            child: Text('📅 ${_iso(data)}',
                style: inter(size: 15, color: dark ? const Color(0xFFE2E8F0) : const Color(0xFF1E293B))),
          ),
        ),
        const SizedBox(height: 8),
        GlassInput(controller: nota, hint: 'Nota (es. interrogazione cap. 3)'),
        const SizedBox(height: 10),
        PrimaryBtn(fullWidth: true, onPressed: () => salvaVoto(store, m.id), child: const Text('Salva voto')),
        if (errore.isNotEmpty) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(color: const Color(0xFFFFF1F2), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFFECDD3))),
            child: Text(errore, style: inter(size: 13, weight: FontWeight.w700, color: const Color(0xFFE11D48))),
          ),
        ],
      ]),
    );
  }

  Widget _smallDropdown<T>({required T value, required List<({T value, String label})> items, required ValueChanged<T?> onChanged}) {
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
          style: inter(size: 14, color: dark ? const Color(0xFFE2E8F0) : const Color(0xFF1E293B)),
          items: [for (final e in items) DropdownMenuItem(value: e.value, child: Text(e.label, overflow: TextOverflow.ellipsis))],
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _votoRow(AppStore store, Voto v, bool dark) {
    return Container(
      margin: const EdgeInsets.only(top: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: dark ? Colors.white.withValues(alpha: 0.05) : Colors.white.withValues(alpha: 0.6),
        border: Border.all(color: dark ? Colors.white.withValues(alpha: 0.10) : Colors.white.withValues(alpha: 0.6)),
      ),
      child: Row(children: [
        Container(
          width: 56,
          padding: const EdgeInsets.symmetric(vertical: 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            gradient: const LinearGradient(colors: [Color(0xFF101F38), Color(0xFF1E3A5F)]),
          ),
          child: Text(v.input, textAlign: TextAlign.center, style: inter(size: 14, weight: FontWeight.w900, color: Colors.white)),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(color: v.tipo.chipBg, borderRadius: BorderRadius.circular(999)),
                child: Text(v.tipo.label, style: inter(size: 11, weight: FontWeight.w700, color: v.tipo.chipFg)),
              ),
              const SizedBox(width: 6),
              Expanded(child: Text('${v.data} · peso ${v.peso % 1 == 0 ? v.peso.toInt() : v.peso}%', style: inter(size: 11, color: const Color(0xFF94A3B8)))),
            ]),
            if (v.nota != null) Text(v.nota!, maxLines: 1, overflow: TextOverflow.ellipsis, style: inter(size: 12, color: dark ? const Color(0xFF94A3B8) : const Color(0xFF64748B))),
          ]),
        ),
        Text('= ${formatMedia(v.valore)}', style: inter(size: 12, weight: FontWeight.w900, color: const Color(0xFF94A3B8))),
        GestureDetector(
          onTap: () => store.eliminaVoto(v.id),
          child: const Padding(padding: EdgeInsets.only(left: 6), child: Icon(Icons.close, size: 16, color: Color(0xFFCBD5E1))),
        ),
      ]),
    );
  }
}
