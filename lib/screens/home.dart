import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../store.dart';
import '../widgets/glass.dart';
import 'dashboard.dart';
import 'impostazioni.dart';
import 'materie.dart';

// Shell: header sticky + tab Panoramica/Materie — port di Shell in src/App.tsx

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int tab = 0;

  void _apriImpostazioni() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: const Color(0xFF0F172A).withValues(alpha: 0.45),
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.92,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (_, controller) => const ImpostazioniSheet(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<AppStore>();
    final p = store.profile;
    if (p == null) return const SizedBox.shrink();
    final generale = store.generale;
    final sottoSei = generale != null && generale < 6;
    final dark = store.prefs.dark;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        bottom: false,
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
            child: GlassCard(
              radius: 28,
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
              child: Column(children: [
                Row(children: [
                  GestureDetector(
                    onTap: _apriImpostazioni,
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        gradient: LinearGradient(colors: [context.accDeep, context.acc]),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.4)),
                      ),
                      child: Center(
                        child: Text(
                          (p.nome.trim().isEmpty ? 'M' : p.nome.trim()[0]).toUpperCase(),
                          style: inter(size: 18, weight: FontWeight.w900, color: Colors.white),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('${p.nome} · ${p.indirizzoNome}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: inter(size: 15, weight: FontWeight.w800, color: dark ? const Color(0xFFF1F5F9) : const Color(0xFF1E293B))),
                      Text('Medie sempre a due decimali',
                          style: inter(size: 12, color: dark ? const Color(0xFF94A3B8) : const Color(0xFF64748B))),
                    ]),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      color: dark ? Colors.white.withValues(alpha: 0.08) : Colors.white.withValues(alpha: 0.5),
                      border: Border.all(color: dark ? Colors.white.withValues(alpha: 0.12) : Colors.white.withValues(alpha: 0.6)),
                    ),
                    child: Column(children: [
                      Text('GENERALE',
                          style: inter(size: 10, weight: FontWeight.w900, color: const Color(0xFF94A3B8))),
                      CountUp(
                        target: generale,
                        style: inter(
                          size: 24,
                          weight: FontWeight.w900,
                          color: sottoSei ? const Color(0xFFE11D48) : (dark ? const Color(0xFFDBEAFE) : const Color(0xFF16294D)),
                        ),
                      ),
                    ]),
                  ),
                ]),
                const SizedBox(height: 12),
                Row(children: [
                  Expanded(child: _tabBtn(0, Icons.show_chart, 'Panoramica')),
                  const SizedBox(width: 6),
                  Expanded(child: _tabBtn(1, Icons.book_outlined, 'Materie e voti')),
                ]),
              ]),
            ),
          ),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: tab == 0 ? const DashboardView(key: ValueKey('dash')) : const MaterieView(key: ValueKey('mat')),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _tabBtn(int i, IconData icon, String label) {
    final active = tab == i;
    final dark = context.isDark;
    final content = Row(mainAxisAlignment: MainAxisAlignment.center, children: [
      Icon(icon, size: 16, color: active ? Colors.white : (dark ? const Color(0xFFCBD5E1) : const Color(0xFF64748B))),
      const SizedBox(width: 6),
      Text(label,
          style: inter(
              size: 14,
              weight: FontWeight.w700,
              color: active ? Colors.white : (dark ? const Color(0xFFCBD5E1) : const Color(0xFF64748B)))),
    ]);
    if (!active) {
      return GestureDetector(
        onTap: () => setState(() => tab = i),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(999)),
          child: content,
        ),
      );
    }
    return GestureDetector(
      onTap: () => setState(() => tab = i),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          gradient: LinearGradient(colors: [context.accDeep.withValues(alpha: 0.9), context.acc.withValues(alpha: 0.9)]),
          border: Border.all(color: Colors.white.withValues(alpha: 0.4)),
        ),
        child: content,
      ),
    );
  }
}
