import 'dart:math' as math;
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../grades.dart';
import '../models.dart';
import '../store.dart';
import '../widgets/glass.dart';

// Panoramica — port di src/components/Dashboard.tsx

class DashboardView extends StatefulWidget {
  const DashboardView({super.key});
  @override
  State<DashboardView> createState() => _DashboardViewState();
}

class _DashboardViewState extends State<DashboardView> {
  String? dettaglioId;
  String? materiaObiettivoId;
  final obiettivo = TextEditingController(text: '7,50');

  @override
  void dispose() {
    obiettivo.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<AppStore>();
    final dark = store.prefs.dark;
    final acc = store.prefs.tema.acc;
    final visibili = store.materie.where((m) => !m.nascosta).toList();
    final righe = [
      for (final m in visibili)
        (
          m: m,
          n: store.voti.where((v) => v.materiaId == m.id).length,
          media: store.mediaMateria(m.id),
        ),
    ];
    final generale = mediaGenerale(righe.map((r) => r.media).toList());
    final insufficienti = righe.where((r) => r.media != null && r.media! < 6).length;
    final conMedia = righe.where((r) => r.media != null).toList()..sort((a, b) => b.media!.compareTo(a.media!));
    final miglior = conMedia.isEmpty ? null : conMedia.first;

    final ordinati = store.voti.toList()..sort((a, b) => a.data.compareTo(b.data));
    final labels = <String>[];
    final punti = <double>[];
    var s = 0.0;
    var p = 0.0;
    for (final v in ordinati) {
      s += v.valore * v.peso;
      p += v.peso;
      labels.add(v.data.length >= 5 ? v.data.substring(5) : v.data);
      punti.add(round2(s / p));
    }
    final trendLabels = labels.length > 30 ? labels.sublist(labels.length - 30) : labels;
    final trendData = punti.length > 30 ? punti.sublist(punti.length - 30) : punti;

    final detId = dettaglioId ?? (visibili.isEmpty ? null : visibili.first.id);
    final detMat = visibili.where((m) => m.id == detId).firstOrNull;
    final detVoti = detMat == null
        ? <Voto>[]
        : (store.voti.where((v) => v.materiaId == detMat.id).toList()..sort((a, b) => a.data.compareTo(b.data)));
    final detMedia = detMat == null
        ? null
        : mediaPesata(detVoti.map((v) => (valore: v.valore, peso: v.peso)).toList());

    final simId = materiaObiettivoId ?? (visibili.isEmpty ? null : visibili.first.id);
    final simMat = visibili.where((m) => m.id == simId).firstOrNull;
    final obNum = double.tryParse(obiettivo.text.replaceAll(',', '.'));
    final simServe = (simMat != null && obNum != null && obNum >= 1 && obNum <= 10)
        ? votoNecessarioPerObiettivo(
            store.voti.where((v) => v.materiaId == simMat.id).map((v) => (valore: v.valore, peso: v.peso)).toList(),
            obNum)
        : null;
    final simOk = simMat != null && obNum != null && obNum >= 1 && obNum <= 10;

    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 16, 12, 40),
      children: [
        // HERO
        GlassDarkCard(
          child: Column(children: [
            Row(children: [
              Gauge(value: generale),
              const SizedBox(width: 16),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('MEDIA GENERALE · ${store.profile?.indirizzoNome ?? ''}'.toUpperCase(),
                      style: inter(size: 11, weight: FontWeight.w900, color: const Color(0xFFBAE6FD))),
                  const SizedBox(height: 4),
                  Text(
                    generale == null
                        ? 'Aggiungi i primi voti per partire'
                        : generale < 6
                            ? 'Sotto il 6: si recupera, un voto alla volta'
                            : generale < 7.5
                                ? 'Buon passo, punta in alto'
                                : 'Ottimo ritmo, continua così',
                    style: inter(size: 18, weight: FontWeight.w900, color: Colors.white, height: 1.2),
                  ),
                  const SizedBox(height: 12),
                  Row(children: [
                    _statTile('${visibili.length}', 'Materie'),
                    const SizedBox(width: 8),
                    _statTile('${store.voti.length}', 'Voti'),
                    const SizedBox(width: 8),
                    _statTile('$insufficienti', 'Sotto il 6'),
                  ]),
                ]),
              ),
            ]),
            if (miglior != null && miglior.media != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
                ),
                child: Row(children: [
                  const Icon(Icons.auto_awesome, size: 16, color: Color(0xFFFCD34D)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text.rich(
                      TextSpan(style: inter(size: 13, color: const Color(0xFFF0F9FF)), children: [
                        const TextSpan(text: 'Materia più forte: '),
                        TextSpan(text: miglior.m.nome, style: inter(size: 13, weight: FontWeight.w800)),
                        TextSpan(text: ' con ${formatMedia(miglior.media)}'),
                      ]),
                    ),
                  ),
                ]),
              ),
            ],
          ]),
        ),
        const SizedBox(height: 16),

        // ANDAMENTO
        GlassCard(
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            const SectionTitle(icon: Icons.show_chart, title: 'Andamento nel tempo', sub: 'La tua media dopo ogni voto'),
            if (trendLabels.isEmpty)
              _empty('Aggiungi i primi voti e qui vedrai la curva crescere.')
            else
              SizedBox(height: 208, child: _lineChart(trendLabels, trendData, acc, dark)),
          ]),
        ),
        const SizedBox(height: 16),

        // CONFRONTO
        GlassCard(
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            const SectionTitle(icon: Icons.show_chart, title: 'Confronto tra materie', sub: 'In rosso quelle sotto il 6'),
            if (righe.isEmpty)
              _empty('Nessuna materia.')
            else ...[
              for (final r in righe) _hBar(r.m.nome, r.media, Color(r.m.colore), acc, dark),
              const SizedBox(height: 12),
              for (final r in righe)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(children: [
                    Container(
                      width: 6,
                      height: 32,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(4),
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Color(r.m.colore), Color(r.m.colore).withValues(alpha: 0.6)],
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(r.m.nome,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: inter(size: 14, weight: FontWeight.w800, color: dark ? const Color(0xFFF1F5F9) : const Color(0xFF1E293B))),
                        Text('${r.n} ${r.n == 1 ? 'voto' : 'voti'}',
                            style: inter(size: 11, color: const Color(0xFF94A3B8))),
                      ]),
                    ),
                    MediaPill(media: r.media),
                  ]),
                ),
            ],
          ]),
        ),
        const SizedBox(height: 16),

        // DETTAGLIO
        GlassCard(
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            const SectionTitle(icon: Icons.book_outlined, title: 'Dettaglio materia', sub: 'Voto per voto'),
            _materiaDropdown(visibili, detId, (v) => setState(() => dettaglioId = v)),
            const SizedBox(height: 12),
            if (detMat == null || detVoti.isEmpty)
              _empty('Nessun voto per questa materia.')
            else ...[
              SizedBox(
                height: 192,
                child: _lineChart(
                  [for (final v in detVoti) v.data.length >= 5 ? v.data.substring(5) : v.data],
                  [for (final v in detVoti) v.valore],
                  Color(detMat.colore),
                  dark,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: dark ? Colors.white.withValues(alpha: 0.05) : Colors.white.withValues(alpha: 0.45),
                  border: Border.all(color: dark ? Colors.white.withValues(alpha: 0.10) : Colors.white.withValues(alpha: 0.5)),
                ),
                child: Text.rich(
                  textAlign: TextAlign.center,
                  TextSpan(
                    style: inter(size: 14, color: dark ? const Color(0xFFCBD5E1) : const Color(0xFF475569)),
                    children: [
                      const TextSpan(text: 'Media '),
                      TextSpan(
                          text: formatMedia(detMedia),
                          style: inter(size: 14, weight: FontWeight.w800, color: dark ? const Color(0xFFDBEAFE) : const Color(0xFF16294D))),
                      TextSpan(text: ' su ${detVoti.length} voti'),
                    ],
                  ),
                ),
              ),
            ],
          ]),
        ),
        const SizedBox(height: 16),

        // STATO + SIMULATORE
        GlassCard(
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            const SectionTitle(icon: Icons.shield_outlined, title: 'Stato e obiettivo', sub: 'Dove sei e dove vuoi arrivare'),
            SizedBox(height: 220, child: _doughnut(store, acc, dark)),
            Container(
              margin: const EdgeInsets.only(top: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: dark ? Colors.white.withValues(alpha: 0.05) : Colors.white.withValues(alpha: 0.45),
                border: Border.all(color: dark ? Colors.white.withValues(alpha: 0.10) : Colors.white.withValues(alpha: 0.5)),
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                Row(children: [
                  const Icon(Icons.auto_awesome, size: 16, color: Color(0xFF3B82F6)),
                  const SizedBox(width: 6),
                  Text('Simulatore: che voto mi serve?',
                      style: inter(size: 14, weight: FontWeight.w800, color: dark ? const Color(0xFFDBEAFE) : const Color(0xFF16294D))),
                ]),
                const SizedBox(height: 10),
                _materiaDropdown(visibili, simId, (v) => setState(() => materiaObiettivoId = v)),
                const SizedBox(height: 8),
                Row(children: [
                  Expanded(
                    child: GlassInput(
                      controller: obiettivo,
                      hint: '7,50',
                      keyboard: const TextInputType.numberWithOptions(decimal: true),
                      maxLength: 5,
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                  const SizedBox(width: 8),
                  SoftBtn(onPressed: () => setState(() {}), child: const Text('Calcola')),
                ]),
                if (simOk) ...[
                  const SizedBox(height: 10),
                  Text(
                    simServe == null
                        ? '—'
                        : simServe > 10
                            ? 'Non si può fare con un solo voto: servirebbe più di 10. Punta a più voti alti di fila.'
                            : simServe <= 0
                                ? 'Obiettivo già in tasca: ti basta qualsiasi voto.'
                                : 'Al prossimo voto in ${simMat.nome} ti serve ${formatMedia(simServe)} per arrivare a ${formatMedia(obNum)}.',
                    style: inter(size: 13, color: dark ? const Color(0xFFCBD5E1) : const Color(0xFF475569), height: 1.4),
                  ),
                ],
              ]),
            ),
          ]),
        ),
      ],
    );
  }

  Widget _statTile(String v, String k) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
        ),
        child: Column(children: [
          Text(v, style: inter(size: 20, weight: FontWeight.w900, color: Colors.white)),
          Text(k.toUpperCase(), style: inter(size: 10, weight: FontWeight.w700, color: const Color(0xFFBAE6FD).withValues(alpha: 0.8))),
        ]),
      ),
    );
  }

  Widget _empty(String testo) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.7), width: 2),
        color: Colors.white.withValues(alpha: 0.30),
      ),
      child: Column(children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
          child: const Icon(Icons.show_chart, color: Color(0xFF94A3B8)),
        ),
        const SizedBox(height: 8),
        Text(testo, textAlign: TextAlign.center, style: inter(size: 14, color: const Color(0xFF94A3B8))),
      ]),
    );
  }

  Widget _hBar(String nome, double? media, Color colore, Color acc, bool dark) {
    final frac = (media ?? 0) / 10;
    final barColor = media != null && media < 6 ? const Color(0xFFEF4444) : colore;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(children: [
        SizedBox(
          width: 110,
          child: Text(nome, maxLines: 1, overflow: TextOverflow.ellipsis, style: inter(size: 11, weight: FontWeight.w700, color: const Color(0xFF64748B))),
        ),
        Expanded(
          child: LayoutBuilder(builder: (context, c) {
            return Container(
              height: 14,
              decoration: BoxDecoration(color: (dark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFE2E8F0)), borderRadius: BorderRadius.circular(8)),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  width: math.max(14, c.maxWidth * frac.clamp(0.0, 1.0)),
                  decoration: BoxDecoration(color: barColor, borderRadius: BorderRadius.circular(8)),
                ),
              ),
            );
          }),
        ),
        const SizedBox(width: 8),
        SizedBox(width: 44, child: Text(formatMedia(media), textAlign: TextAlign.right, style: inter(size: 12, weight: FontWeight.w900, color: dark ? const Color(0xFFE2E8F0) : const Color(0xFF1E293B)))),
      ]),
    );
  }

  Widget _materiaDropdown(List<Materia> visibili, String? value, ValueChanged<String?> onChanged) {
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
          value: value,
          isExpanded: true,
          dropdownColor: dark ? const Color(0xFF14203A) : Colors.white,
          style: inter(size: 15, weight: FontWeight.w500, color: dark ? const Color(0xFFE2E8F0) : const Color(0xFF1E293B)),
          items: [for (final m in visibili) DropdownMenuItem(value: m.id, child: Text(m.nome, overflow: TextOverflow.ellipsis))],
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _lineChart(List<String> labels, List<double> data, Color acc, bool dark) {
    final grid = dark ? const Color(0x29A3B8C4) : const Color(0x1F64748B);
    final step = math.max(1, (labels.length / 6).ceil());
    return LineChart(
      LineChartData(
        minX: 0,
        maxX: math.max(1, data.length - 1).toDouble(),
        minY: 1,
        maxY: 10,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (_) => FlLine(color: grid, strokeWidth: 1),
        ),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 1,
              reservedSize: 26,
              getTitlesWidget: (v, _) => Text('${v.toInt()}',
                  style: inter(size: 10, weight: FontWeight.w700, color: const Color(0xFF94A3B8))),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: step.toDouble(),
              getTitlesWidget: (v, _) {
                final i = v.toInt();
                if (i < 0 || i >= labels.length) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(labels[i], style: inter(size: 10, color: const Color(0xFF94A3B8))),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (_) => const Color(0xFF0F2440),
            getTooltipItems: (spots) => [for (final s in spots) LineTooltipItem(formatMedia(s.y), inter(size: 12, weight: FontWeight.w700, color: Colors.white))],
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: [for (var i = 0; i < data.length; i++) FlSpot(i.toDouble(), data[i])],
            isCurved: true,
            color: acc,
            barWidth: 2.5,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, p, bar, i) => FlDotCirclePainter(
                radius: spot.y < 6 ? 4.5 : 2.5,
                color: spot.y < 6 ? const Color(0xFFEF4444) : acc,
                strokeWidth: 0,
              ),
            ),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [acc.withValues(alpha: 0.30), acc.withValues(alpha: 0.02)],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _doughnut(AppStore store, Color acc, bool dark) {
    final ok = store.voti.where((v) => v.valore >= 6).length;
    final ko = store.voti.where((v) => v.valore < 6).length;
    final tick = dark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    return Column(children: [
      Expanded(
        child: PieChart(
          PieChartData(
            centerSpaceRadius: 52,
            sectionsSpace: 3,
            sections: [
              PieChartSectionData(value: math.max(ok, 0).toDouble(), color: acc, radius: 26, showTitle: false),
              PieChartSectionData(value: math.max(ko, 0).toDouble(), color: const Color(0xFFEF4444), radius: 26, showTitle: false),
            ],
          ),
        ),
      ),
      const SizedBox(height: 8),
      Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        _legendDot(acc, 'Voti ≥ 6', tick),
        const SizedBox(width: 16),
        _legendDot(const Color(0xFFEF4444), 'Voti < 6', tick),
      ]),
    ]);
  }

  Widget _legendDot(Color c, String label, Color fg) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Container(width: 10, height: 10, decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(5))),
      const SizedBox(width: 6),
      Text(label, style: inter(size: 11, weight: FontWeight.w700, color: fg)),
    ]);
  }
}
