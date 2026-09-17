import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../grades.dart';
import '../models.dart';
import '../store.dart';

// Design system "liquid glass" — port di src/index.css + src/components/ui.tsx

extension GlassCtx on BuildContext {
  AppStore get store => read<AppStore>();
  bool get isDark => watch<AppStore>().prefs.dark;
  TemaId get temaId => watch<AppStore>().prefs.tema;
  Color get acc => temaId.acc;
  Color get accDeep => temaId.deep;
}

TextStyle inter({
  double size = 14,
  FontWeight weight = FontWeight.normal,
  Color? color,
  double? height,
  TextDecoration? decoration,
}) =>
    GoogleFonts.inter(fontSize: size, fontWeight: weight, color: color, height: height, decoration: decoration);

// ---------- Sfondo animato ----------

class AppWallpaper extends StatefulWidget {
  const AppWallpaper({super.key});
  @override
  State<AppWallpaper> createState() => _AppWallpaperState();
}

class _AppWallpaperState extends State<AppWallpaper> with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(seconds: 34))
      ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dark = context.isDark;
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: dark
              ? const [Color(0xFF0B1220), Color(0xFF0E1930)]
              : const [Color(0xFFF2F4FB), Color(0xFFE7EBF5)],
        ),
      ),
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, _) {
          final t = _c.value;
          final dx = 40 * t;
          final dy = 32 * t;
          return ImageFiltered(
            imageFilter: ImageFilter.blur(sigmaX: 60, sigmaY: 60),
            child: Opacity(
              opacity: dark ? 0.3 : 0.55,
              child: Stack(children: [
                _blob(-0.35, -0.30, 0.85, const Color(0xFF93C5FD), dx, dy),
                _blob(0.75, 0.10, 0.75, const Color(0xFF67E8F9), -dx, dy),
                _blob(0.10, 0.85, 0.80, const Color(0xFF7DD3FC), dx, -dy),
                _blob(0.70, 0.80, 0.45, const Color(0xFFBAE6FD), -dx * 0.6, -dy),
              ]),
            ),
          );
        },
      ),
    );
  }

  Widget _blob(double fx, double fy, double frac, Color color, double dx, double dy) {
    return LayoutBuilder(builder: (context, c) {
      final s = math.max(c.maxWidth, c.maxHeight) * frac;
      return Positioned(
        left: c.maxWidth * fx + dx,
        top: c.maxHeight * fy + dy,
        child: Container(
          width: s,
          height: s,
          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(s / 2)),
        ),
      );
    });
  }
}

// ---------- Card vetro ----------

class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  const GlassCard({super.key, required this.child, this.padding = const EdgeInsets.all(16), this.radius = 28});

  @override
  Widget build(BuildContext context) {
    final dark = context.isDark;
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(radius),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: dark
                  ? [const Color(0xFF1E2D4B).withValues(alpha: 0.72), const Color(0xFF14203A).withValues(alpha: 0.55)]
                  : [Colors.white.withValues(alpha: 0.60), Colors.white.withValues(alpha: 0.28)],
            ),
            border: Border.all(
              color: dark ? Colors.white.withValues(alpha: 0.14) : Colors.white.withValues(alpha: 0.65),
            ),
            boxShadow: [
              BoxShadow(
                color: dark ? Colors.black.withValues(alpha: 0.6) : const Color(0xFF1F2687).withValues(alpha: 0.22),
                blurRadius: 40,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}

/// Hero scuro (glass-dark del web).
class GlassDarkCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  const GlassDarkCard({super.key, required this.child, this.padding = const EdgeInsets.all(20)});

  @override
  Widget build(BuildContext context) {
    final acc = context.acc;
    final deep = context.accDeep;
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 28, sigmaY: 28),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [deep.withValues(alpha: 0.74), acc.withValues(alpha: 0.62)],
            ),
            border: Border.all(color: Colors.white.withValues(alpha: 0.30)),
            boxShadow: const [
              BoxShadow(color: Color(0x800A193C), blurRadius: 55, offset: Offset(0, 20)),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}

// ---------- Chip accento + titoli ----------

class AccChip extends StatelessWidget {
  final Widget icon;
  final double size;
  const AccChip({super.key, required this.icon, this.size = 36});
  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [context.accDeep, context.acc],
        ),
        boxShadow: [
          BoxShadow(color: context.acc.withValues(alpha: 0.5), blurRadius: 12, offset: const Offset(0, 4)),
        ],
      ),
      child: IconTheme(data: const IconThemeData(color: Colors.white, size: 16), child: Center(child: icon)),
    );
  }
}

class SectionTitle extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? sub;
  const SectionTitle({super.key, required this.icon, required this.title, this.sub});
  @override
  Widget build(BuildContext context) {
    final dark = context.isDark;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(children: [
        AccChip(icon: Icon(icon)),
        const SizedBox(width: 10),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: inter(size: 15, weight: FontWeight.w800, color: dark ? const Color(0xFFF1F5F9) : const Color(0xFF1E293B))),
            if (sub != null) Text(sub!, style: inter(size: 12, color: const Color(0xFF94A3B8))),
          ]),
        ),
      ]),
    );
  }
}

// ---------- Bottoni pill ----------

class PrimaryBtn extends StatelessWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final bool fullWidth;
  const PrimaryBtn({super.key, required this.child, this.onPressed, this.fullWidth = false});
  @override
  Widget build(BuildContext context) {
    final btn = Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        gradient: LinearGradient(colors: [context.accDeep.withValues(alpha: 0.9), context.acc.withValues(alpha: 0.9)]),
        border: Border.all(color: Colors.white.withValues(alpha: 0.4)),
        boxShadow: [BoxShadow(color: context.acc.withValues(alpha: 0.5), blurRadius: 18, offset: const Offset(0, 6))],
      ),
      child: DefaultTextStyle(
        style: inter(size: 14, weight: FontWeight.w700, color: Colors.white),
        textAlign: TextAlign.center,
        child: child,
      ),
    );
    return _pressable(
      onPressed: onPressed,
      child: fullWidth ? SizedBox(width: double.infinity, child: btn) : btn,
    );
  }
}

class SoftBtn extends StatelessWidget {
  final Widget child;
  final VoidCallback? onPressed;
  const SoftBtn({super.key, required this.child, this.onPressed});
  @override
  Widget build(BuildContext context) {
    final dark = context.isDark;
    return _pressable(
      onPressed: onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          gradient: LinearGradient(
            colors: dark
                ? [Colors.white.withValues(alpha: 0.16), Colors.white.withValues(alpha: 0.07)]
                : [Colors.white.withValues(alpha: 0.72), Colors.white.withValues(alpha: 0.40)],
          ),
          border: Border.all(color: dark ? Colors.white.withValues(alpha: 0.18) : Colors.white.withValues(alpha: 0.75)),
        ),
        child: DefaultTextStyle(
          style: inter(size: 13, weight: FontWeight.w700, color: dark ? const Color(0xFFDBEAFE) : const Color(0xFF1E3A5F)),
          textAlign: TextAlign.center,
          child: child,
        ),
      ),
    );
  }
}

Widget _pressable({required Widget child, VoidCallback? onPressed}) {
  return GestureDetector(
    onTap: onPressed,
    child: AnimatedScaleNote(child: child),
  );
}

/// Leggero ingrandimento alla pressione (come .press del web).
class AnimatedScaleNote extends StatefulWidget {
  final Widget child;
  const AnimatedScaleNote({super.key, required this.child});
  @override
  State<AnimatedScaleNote> createState() => _AnimatedScaleNoteState();
}

class _AnimatedScaleNoteState extends State<AnimatedScaleNote> {
  bool _down = false;
  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (_) => setState(() => _down = true),
      onPointerUp: (_) => setState(() => _down = false),
      onPointerCancel: (_) => setState(() => _down = false),
      child: AnimatedScale(scale: _down ? 1.05 : 1.0, duration: const Duration(milliseconds: 120), child: widget.child),
    );
  }
}

// ---------- Input pill ----------

class GlassInput extends StatelessWidget {
  final TextEditingController controller;
  final String? hint;
  final TextInputType keyboard;
  final int? maxLength;
  final int maxLines;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onSubmitted;
  final bool enabled;
  const GlassInput({
    super.key,
    required this.controller,
    this.hint,
    this.keyboard = TextInputType.text,
    this.maxLength,
    this.maxLines = 1,
    this.onChanged,
    this.onSubmitted,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final dark = context.isDark;
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            color: dark ? const Color(0xFF0A1426).withValues(alpha: 0.55) : Colors.white.withValues(alpha: 0.55),
            border: Border.all(color: dark ? Colors.white.withValues(alpha: 0.16) : Colors.white.withValues(alpha: 0.70)),
          ),
          child: TextField(
            controller: controller,
            enabled: enabled,
            keyboardType: keyboard,
            maxLength: maxLength,
            maxLines: maxLines,
            onChanged: onChanged,
            onSubmitted: (_) => onSubmitted?.call(),
            style: inter(size: 15, weight: FontWeight.w500, color: dark ? const Color(0xFFE2E8F0) : const Color(0xFF1E293B)),
            decoration: InputDecoration(
              hintText: hint,
              counterText: '',
              hintStyle: inter(size: 15, color: const Color(0xFF94A3B8)),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
            ),
          ),
        ),
      ),
    );
  }
}

class FieldLabel extends StatelessWidget {
  final String label;
  final String? hint;
  final Widget child;
  const FieldLabel({super.key, required this.label, this.hint, required this.child});
  @override
  Widget build(BuildContext context) {
    final dark = context.isDark;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: inter(size: 13, weight: FontWeight.w700, color: dark ? const Color(0xFFCBD5E1) : const Color(0xFF475569))),
      const SizedBox(height: 6),
      child,
      if (hint != null) ...[
        const SizedBox(height: 4),
        Text(hint!, style: inter(size: 12, color: const Color(0xFF94A3B8))),
      ],
    ]);
  }
}

// ---------- Pill media ----------

class MediaPill extends StatelessWidget {
  final double? media;
  final double size;
  const MediaPill({super.key, required this.media, this.size = 13});
  @override
  Widget build(BuildContext context) {
    final c = pillMedia(media);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(color: c.bg, borderRadius: BorderRadius.circular(999), border: Border.all(color: c.fg.withValues(alpha: 0.25))),
      child: Text(formatMedia(media), style: inter(size: size, weight: FontWeight.w900, color: c.fg)),
    );
  }
}

// ---------- Count-up ----------

class CountUp extends StatefulWidget {
  final double? target;
  final TextStyle? style;
  const CountUp({super.key, required this.target, this.style});
  @override
  State<CountUp> createState() => _CountUpState();
}

class _CountUpState extends State<CountUp> {
  double? _from;
  @override
  Widget build(BuildContext context) {
    final target = widget.target;
    final from = _from ?? target;
    if (target == null || from == null) return Text('—', style: widget.style);
    if ((from - target).abs() < 0.001) return Text(formatMedia(target), style: widget.style);
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: from, end: target),
      duration: const Duration(milliseconds: 700),
      curve: Curves.easeOutCubic,
      builder: (context, v, _) => Text(formatMedia(round2(v)), style: widget.style),
      onEnd: () => _from = target,
    );
  }

  @override
  void didUpdateWidget(CountUp old) {
    super.didUpdateWidget(old);
    if (old.target != widget.target) _from = old.target;
  }
}

// ---------- Anello media (Gauge) ----------

class Gauge extends StatelessWidget {
  final double? value;
  final double size;
  const Gauge({super.key, required this.value, this.size = 144});
  @override
  Widget build(BuildContext context) {
    final acc = context.acc;
    return SizedBox(
      width: size,
      height: size,
      child: Stack(alignment: Alignment.center, children: [
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: value == null ? 0 : (value! / 10).clamp(0.0, 1.0)),
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeOutCubic,
          builder: (context, pct, _) => CustomPaint(
            size: Size(size, size),
            painter: _GaugePainter(pct: pct, color: gaugeColor(value, acc)),
          ),
        ),
        Column(mainAxisSize: MainAxisSize.min, children: [
          CountUp(
            target: value,
            style: inter(size: 30, weight: FontWeight.w900, color: Colors.white),
          ),
          Text('MEDIA', style: inter(size: 10, weight: FontWeight.w900, color: Colors.white70)),
        ]),
      ]),
    );
  }
}

class _GaugePainter extends CustomPainter {
  final double pct;
  final Color color;
  _GaugePainter({required this.pct, required this.color});
  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = size.width / 2 - 8;
    final bg = Paint()
      ..color = Colors.white.withValues(alpha: 0.25)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 11;
    canvas.drawCircle(c, r, bg);
    final fg = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 11
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(Rect.fromCircle(center: c, radius: r), -math.pi / 2, pct * 2 * math.pi, false, fg);
  }

  @override
  bool shouldRepaint(_GaugePainter old) => old.pct != pct || old.color != color;
}
