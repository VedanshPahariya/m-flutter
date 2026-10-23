import 'package:flutter/material.dart';

import '../../app/app_theme.dart';

/// One pulsing animation shared by every placeholder below it, so a screen
/// of skeletons costs a single ticker.
class SkeletonScope extends StatefulWidget {
  const SkeletonScope({super.key, required this.child});

  final Widget child;

  @override
  State<SkeletonScope> createState() => _SkeletonScopeState();
}

class _SkeletonScopeState extends State<SkeletonScope>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Loading',
      liveRegion: true,
      child: ExcludeSemantics(
        child: FadeTransition(
          opacity: Tween(begin: 1.0, end: 0.45).animate(
            CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
          ),
          child: widget.child,
        ),
      ),
    );
  }
}

class SkeletonBox extends StatelessWidget {
  const SkeletonBox({super.key, this.width, this.height = 14, this.radius = 6});

  final double? width;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: context.kora.sunken,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}

/// Two-line list rows, matching the lead / ticket / customer rows.
class SkeletonList extends StatelessWidget {
  const SkeletonList({super.key, this.rows = 6, this.lines = 2});

  final int rows;
  final int lines;

  @override
  Widget build(BuildContext context) {
    return SkeletonScope(
      child: ListView.separated(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        itemCount: rows,
        separatorBuilder: (_, _) => const SizedBox(height: 18),
        itemBuilder: (_, i) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: SkeletonBox(height: 16, width: 180.0 + (i % 3) * 30),
                ),
                const SizedBox(width: 40),
                const SkeletonBox(width: 48),
              ],
            ),
            for (var l = 1; l < lines; l++) ...[
              const SizedBox(height: 8),
              SkeletonBox(width: 140.0 + (i % 2) * 60, height: 12),
            ],
          ],
        ),
      ),
    );
  }
}

/// Dashboard placeholder: a few cards and a stat strip.
class SkeletonDashboard extends StatelessWidget {
  const SkeletonDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return SkeletonScope(
      child: ListView(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: [
          const SkeletonBox(width: 160, height: 14),
          const SizedBox(height: 16),
          for (var i = 0; i < 3; i++) ...[
            const SkeletonBox(height: 56, radius: 12),
            const SizedBox(height: 10),
          ],
          const SizedBox(height: 10),
          const SkeletonBox(height: 110, radius: 14),
          const SizedBox(height: 16),
          const Row(
            children: [
              Expanded(child: SkeletonBox(height: 70, radius: 12)),
              SizedBox(width: 10),
              Expanded(child: SkeletonBox(height: 70, radius: 12)),
              SizedBox(width: 10),
              Expanded(child: SkeletonBox(height: 70, radius: 12)),
            ],
          ),
          const SizedBox(height: 16),
          for (var i = 0; i < 3; i++) ...[
            const SkeletonBox(height: 44, radius: 10),
            const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }
}

/// Detail page placeholder: title, chips and key/value rows.
class SkeletonDetail extends StatelessWidget {
  const SkeletonDetail({super.key});

  @override
  Widget build(BuildContext context) {
    return SkeletonScope(
      child: ListView(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: [
          const SkeletonBox(width: 220, height: 22),
          const SizedBox(height: 10),
          const SkeletonBox(width: 160),
          const SizedBox(height: 24),
          for (var i = 0; i < 6; i++) ...[
            const Row(
              children: [
                SkeletonBox(width: 90),
                Spacer(),
                SkeletonBox(width: 120),
              ],
            ),
            const SizedBox(height: 18),
          ],
        ],
      ),
    );
  }
}
