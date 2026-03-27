import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';

class ScoreModal extends StatelessWidget {
  final int score;
  final int stars;
  final VoidCallback onHomePressed;
  final VoidCallback onNextLevelPressed;

  const ScoreModal({
    super.key,
    required this.score,
    required this.stars,
    required this.onHomePressed,
    required this.onNextLevelPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      elevation: 0,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(20, 32, 20, 32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF1A3D7C).withValues(alpha: 0.15),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "Game Completed !",
              style: GoogleFonts.ubuntu(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF0E2576),
              ),
            ),
            const SizedBox(height: 12),
            Stack(
              alignment: Alignment.center,
              children: [
                // Dark Shadow Offset
                Text(
                  "$score",
                  style: GoogleFonts.titanOne(
                    fontSize: 80,
                    height: 1.0,
                    color: const Color(0xFF1E3A8A).withOpacity(0.35),
                  ),
                ),
                // Main Score
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text(
                    "$score",
                    style: GoogleFonts.titanOne(
                      fontSize: 80,
                      height: 1.0,
                      color: const Color(0xFF4F8BFB),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(3, (i) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: SvgPicture.asset(
                    i < stars
                        ? 'assets/icons/star_filled.svg'
                        : 'assets/icons/star_notfilled.svg',
                    width: 36,
                    height: 36,
                  ),
                );
              }),
            ),
            const SizedBox(height: 32),
            Row(
              children: [
                Expanded(
                  child: _build3DButton(
                    text: "To Home",
                    color: const Color(0xFF7781DC),
                    shadowColor: const Color(0xFF4F5BAF),
                    onTap: onHomePressed,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _build3DButton(
                    text: "Next Level",
                    color: const Color(0xFF71A1F3),
                    shadowColor: const Color(0xFF4A7CAB),
                    onTap: onNextLevelPressed,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _build3DButton({
    required String text,
    required Color color,
    required Color shadowColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 54,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF0E2576).withOpacity(0.1), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: shadowColor,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Center(
          child: Text(
            text,
            style: GoogleFonts.ubuntu(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),
      ),
    );
  }
}
