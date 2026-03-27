// RhythmLevel model

class RhythmLevel {
  final String title;
  final String status;
  final int stars; 
  final bool isLocked;
  final List<int> pattern;

  const RhythmLevel({
    required this.title,
    required this.status,
    required this.stars,
    this.isLocked = false,
    required this.pattern,
  });
}

const List<RhythmLevel> rhythmLevels = [
  RhythmLevel(
    title: 'Tutorial', 
    status: 'Completed', 
    stars: 0,
    pattern: [1, 1, 1, 1],
  ),
  RhythmLevel(
    title: 'Level 01', 
    status: 'Completed', 
    stars: 3,
    pattern: [1, 1, 1, 1, 1, 1, 1, 0, 1, 1, 1, 1, 1, 1, 0, 0],
  ),
  RhythmLevel(
    title: 'Level 02', 
    status: 'Completed', 
    stars: 3,
    pattern: [
      1, 1, 1, 1, // Bar 1
      1, 0, 0, 0, // Bar 2
      1, 1, 1, 1, // Bar 3
      0, 0, 0, 0, // Bar 4
      1, 1, 1, 1, // Bar 5
      0, 1, 0, 1, // Bar 6
      1, 1, 1, 1, // Bar 7
      0, 0, 1, 1, // Bar 8
    ],
  ),
  RhythmLevel(
    title: 'Level 03', 
    status: 'Completed', 
    stars: 3,
    isLocked: false,
    pattern: [
      1, 0, 1, 0, // Bar 1
      1, 1, 0, 1, // Bar 2
      1, 0, 1, 1, // Bar 3
      0, 1, 1, 0, // Bar 4
      1, 1, 1, 1, // Bar 5
      0, 1, 0, 1, // Bar 6
      1, 0, 1, 1, // Bar 7
      0, 1, 0, 1, // Bar 8
    ],
  ),
  RhythmLevel(
    title: 'Level 04', 
    status: 'On Progress', 
    stars: 0, 
    isLocked: false,
    pattern: [
      1, 1, 1, 1,     // Bar 1
      2, -1, 2, -1,   // Bar 2 (Half Notes)
      1, 1, 1, 1,     // Bar 3
      1, 1, 2, -1,   // Bar 4
      1, 1, 1, 1,     // Bar 5
      2, -1, 1, 1,   // Bar 6
      2, -1, 2, -1,   // Bar 7
      0, 1, 2, -1,   // Bar 8
    ],
  ),
  RhythmLevel(
    title: 'Level 05', 
    status: 'Locked', 
    stars: 0, 
    isLocked: false, // User requested implementing it
    pattern: [
      1, 0, 2, -1,   // Bar 1
      2, -1, 0, 1,   // Bar 2
      2, -1, 2, -1,   // Bar 3
      1, 1, 2, -1,   // Bar 4
      0, 2, -1, 1,   // Bar 5
      2, -1, 2, -1,   // Bar 6
      0, 2, -1, 1,   // Bar 7
      1, 1, 2, -1,   // Bar 8
      1, 1, 1, 1,     // Bar 9
      0, 1, 0, 1,     // Bar 10
      2, -1, 2, -1,   // Bar 11
      1, 1, 2, -1,   // Bar 12
    ],
  ),
  RhythmLevel(
    title: 'Level 06', 
    status: 'Locked', 
    stars: 0, 
    isLocked: true,
    pattern: [],
  ),
];
