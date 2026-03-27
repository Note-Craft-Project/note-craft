import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:notecraft/main.dart'; 
import 'package:notecraft/screens/rhythm_game_screen.dart';
import 'package:notecraft/models/level_data.dart';

// Removed local Level class (now imported from level_data.dart)

class LevelSelectionScreen extends StatelessWidget {
  final String mode;

  const LevelSelectionScreen({super.key, required this.mode});

  @override
  Widget build(BuildContext context) {
    final List<RhythmLevel> levels = rhythmLevels;

    return Scaffold(
      body: GradientBackground(
        child: SafeArea(
          child: Column(
            children: [
              // Header (Exact Figma Dimensions)
              Container(
                height: 63,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.85),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(13),
                    bottomRight: Radius.circular(13),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF1A3D7C).withValues(alpha: 0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: SvgPicture.asset(
                        'assets/icons/back_arrow.svg',
                        width: 22,
                        height: 22,
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                    Expanded(
                      child: Text(
                        mode,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.ubuntu(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF1A3D7C),
                        ),
                      ),
                    ),
                    const SizedBox(width: 48),
                  ],
                ),
              ),

              // Level List
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 24),
                  itemCount: levels.length,
                  itemBuilder: (context, index) {
                    return _buildLevelCard(context, levels[index], index);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLevelCard(BuildContext context, RhythmLevel level, int index) {
    final bool unlocked = !level.isLocked;

    return GestureDetector(
      onTap: level.isLocked
          ? null
          : () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => RhythmGameScreen(
                    levelIndex: index,
                  ),
                ),
              );
            },
      child: Container(
        height: 60,
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: unlocked ? Colors.white : const Color(0xFFC5CBE4).withAlpha(160),
          borderRadius: BorderRadius.circular(5),
          boxShadow: unlocked
              ? [
                  const BoxShadow(
                    color: Color(0x1A4F8BFB),
                    blurRadius: 8,
                    offset: Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    level.title,
                    style: GoogleFonts.ubuntu(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF1A3D7C),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        level.status,
                        style: GoogleFonts.ubuntu(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF4F8BFB),
                        ),
                      ),
                      if (level.stars > 0) ...[
                        const SizedBox(width: 8),
                        Row(
                          children: List.generate(3, (i) {
                            return Padding(
                              padding: const EdgeInsets.only(right: 2),
                              child: SvgPicture.asset(
                                i < level.stars
                                    ? 'assets/icons/star_filled.svg'
                                    : 'assets/icons/star_notfilled.svg',
                                width: 14,
                                height: 14,
                              ),
                            );
                          }),
                        ),
                      ] else if (level.status == 'On Progress') ...[
                        const SizedBox(width: 8),
                        Row(
                          children: List.generate(3, (i) {
                            return Padding(
                              padding: const EdgeInsets.only(right: 2),
                              child: SvgPicture.asset(
                                'assets/icons/star_notfilled.svg',
                                width: 14,
                                height: 14,
                              ),
                            );
                          }),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            if (level.isLocked)
              const Icon(Icons.lock_rounded, color: Colors.white, size: 28)
            else
              SvgPicture.asset(
                'assets/icons/right_arrow.svg',
                width: 16,
                height: 16,
              ),
          ],
        ),
      ),
    );
  }
}
