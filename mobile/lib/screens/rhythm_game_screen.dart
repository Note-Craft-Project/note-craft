import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import 'package:record/record.dart';
import 'package:google_fonts/google_fonts.dart';
import '../main.dart'; // For GradientBackground
import '../widgets/score_modal.dart';
import '../models/level_data.dart';

// Providers
class BpmNotifier extends Notifier<double> {
  @override
  double build() => 60.0;
  void set(double val) => state = val;
}
final bpmProvider = NotifierProvider<BpmNotifier, double>(BpmNotifier.new);

class InputTypeNotifier extends Notifier<InputType> {
  @override
  InputType build() => InputType.tap;
  void set(InputType val) => state = val;
}
final inputTypeProvider = NotifierProvider<InputTypeNotifier, InputType>(InputTypeNotifier.new);

enum InputType { tap, clap }
enum GameState { idle, countdown, playing, completed }

class RhythmGameScreen extends ConsumerStatefulWidget {
  final int levelIndex;

  const RhythmGameScreen({
    super.key, 
    required this.levelIndex,
  });

  @override
  ConsumerState<RhythmGameScreen> createState() => _RhythmGameScreenState();
}

class _RhythmGameScreenState extends ConsumerState<RhythmGameScreen> with TickerProviderStateMixin {
  late AudioPlayer _audioPlayerHigh;
  late AudioPlayer _audioPlayerLow;
  late AudioRecorder _recorder;
  late AnimationController _animationController;
  late AnimationController _tapAnimationController;
  StreamSubscription? _amplitudeSubscription;
  Timer? _feedbackTimer;
  Timer? _countdownTimer;

  GameState _gameState = GameState.idle;
  String _feedbackText = "";
  int _countdownValue = -1; // 3, 2, 1, 0 (START), -1 (Hidden)

  // Removed hardcoded _rhythmPattern
  int _currentBeatGlobal = 0;
  int _lastSoundBeat = -1;
  int _perfectCount = 0;
  final Set<int> _hitNotes = {}; // Track which notes have been hit
  DateTime? _lastClapTriggerTime; // For debouncing clap input
  double _currentAmplitude = -160.0; // Current decibel level
  bool _isButtonPressed = false; // For Start/Stop button effect

  @override
  void initState() {
    super.initState();
    _audioPlayerHigh = AudioPlayer();
    _audioPlayerLow = AudioPlayer();
    _recorder = AudioRecorder();
    _animationController = AnimationController(vsync: this);
    _animationController.addListener(_onAnimationTick);
    _animationController.addStatusListener(_onAnimationStatus);
    
    _tapAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _setupAudio();
  }

  void _onAnimationTick() {
    if (_gameState != GameState.playing) return;
    double progress = _animationController.value;
    
    // Notes are visually at 0.125, 0.375, 0.625, 0.875
    // We determine which beat we are currently in
    int currentBeatInMeasure = (progress * 4).floor().clamp(0, 3);
    
    // Trigger metronome precisely at the center of each beat (where the note is)
    double beatCenter = (currentBeatInMeasure + 0.5) / 4.0;
    
    if (progress >= beatCenter && currentBeatInMeasure != _lastSoundBeat) {
      _lastSoundBeat = currentBeatInMeasure;
      _playMetronomeSound(currentBeatInMeasure);
      setState(() {
        int measureIndex = _currentBeatGlobal ~/ 4;
        _currentBeatGlobal = (measureIndex * 4) + currentBeatInMeasure;
        if (_currentBeatGlobal >= currentLevel.pattern.length) {
          _completeGame();
        }
      });
    }
  }

  void _onAnimationStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed && _gameState == GameState.playing) {
      _lastSoundBeat = -1;
      setState(() {
        _currentBeatGlobal = ((_currentBeatGlobal ~/ 4) + 1) * 4;
        if (_currentBeatGlobal >= currentLevel.pattern.length) {
          _completeGame();
        } else {
          _animationController.forward(from: 0.0);
        }
      });
    }
  }

  void _playMetronomeSound(int beatIndex) {
    final player = (beatIndex == 0) ? _audioPlayerHigh : _audioPlayerLow;
    // stop() synchronously resets the player state so play() can re-trigger
    player.stop().then((_) {
      player.seek(Duration.zero);
      player.play();
    });
  }

  void _completeGame() {
    _gameState = GameState.completed;
    _animationController.stop();
    _stopClapDetection();
    int totalNotes = currentLevel.pattern.where((n) => n == 1 || n == 2).length;
    double ratio = _perfectCount / totalNotes;
    
    int stars = 0;
    if (ratio >= 0.9) {
      stars = 3;
    } else if (ratio >= 0.6) {
      stars = 2;
    } else if (ratio > 0.0) {
      stars = 1;
    }

    // Custom Score Calculation
    int score = (_perfectCount * 100); 
    if (ratio == 1.0) score += 500; // Bonus for Perfect Run

    _showCompletionDialog(stars, score);
  }

  RhythmLevel get currentLevel => rhythmLevels[widget.levelIndex];

  Future<void> _setupAudio() async {
    try {
      await _audioPlayerHigh.setAsset('assets/audio/click_high.wav');
      await _audioPlayerLow.setAsset('assets/audio/click_low.wav');
    } catch (e) {
      debugPrint("Audio load error: $e");
    }
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _feedbackTimer?.cancel();
    _audioPlayerHigh.dispose();
    _audioPlayerLow.dispose();
    _recorder.dispose();
    _animationController.dispose();
    _tapAnimationController.dispose();
    _amplitudeSubscription?.cancel();
    super.dispose();
  }

  Future<void> _togglePlay() async {
    debugPrint("DEBUG: _togglePlay called. State: $_gameState");
    if (_gameState == GameState.playing || _gameState == GameState.countdown) {
      setState(() {
        _gameState = GameState.idle;
        _animationController.stop();
        _countdownTimer?.cancel();
        _stopClapDetection();
      });
    } else {
      // Pre-check permission on user click to avoid browser blocking on Web/Mobile
      if (ref.read(inputTypeProvider) == InputType.clap) {
        debugPrint("DEBUG: Checking/Requesting microphone permission...");
        try {
          final hasPerm = await _recorder.hasPermission();
          if (!hasPerm) {
            debugPrint("DEBUG: Permission denied.");
            return;
          }
          debugPrint("DEBUG: Permission granted.");
        } catch (e) {
          debugPrint("DEBUG: Permission check error: $e");
          return;
        }
      }
      _startCountdown();
    }
  }

  void _startCountdown() {
    debugPrint("DEBUG: _startCountdown starting...");
    final bpm = ref.read(bpmProvider);
    final beatDurationMs = (60000 / bpm).round();
    
    setState(() {
      _gameState = GameState.countdown;
      _currentBeatGlobal = 0; // Reset to first measure
      _perfectCount = 0; // Reset score
      _feedbackText = ""; // Clear old feedback
      _lastSoundBeat = -1; // Reset beat sound trigger
      _countdownValue = 3;
      _animationController.value = 0.0; // Reset playhead to start
      _hitNotes.clear(); // Clear hit notes for new game
    });

    // Initial click for '3'
    _playMetronomeSound(0); // High click on beat 1

    _countdownTimer = Timer.periodic(Duration(milliseconds: beatDurationMs), (timer) {
      setState(() {
        if (_countdownValue > 1) {
          _countdownValue--;
          // Click for '2' and '1'
          _playMetronomeSound(1); // Low click
        } else if (_countdownValue == 1) {
          _countdownValue = 0; // Show "START"
          _playMetronomeSound(0); // High click for START
        } else {
          _countdownTimer?.cancel();
          _startGame();
        }
      });
    });
  }

  void _startGame() {
    debugPrint("DEBUG: _startGame called.");
    setState(() {
      _gameState = GameState.playing;
      _countdownValue = -1; // Hide countdown
    });
    final bpm = ref.read(bpmProvider);
    final beatDuration = Duration(milliseconds: (60000 / bpm).round());
    _animationController.duration = beatDuration * 4;
    _animationController.forward(from: 0.0);
    if (ref.read(inputTypeProvider) == InputType.clap) {
       _startClapDetection();
    }
  }

  Future<void> _startClapDetection() async {
    try {
      debugPrint("DEBUG: _startClapDetection called.");
      if (await _recorder.hasPermission()) {
        debugPrint("DEBUG: Starting stream...");
        // Use startStream for amplitude detection without saving to file
        await _recorder.startStream(const RecordConfig());
        debugPrint("DEBUG: Stream started.");
        
        _amplitudeSubscription = _recorder.onAmplitudeChanged(const Duration(milliseconds: 30)).listen((amp) {
          setState(() {
            _currentAmplitude = amp.max;
          });
          
          if (amp.max > -27) { // Re-calibrated to avoid noise floor triggers
            final now = DateTime.now();
            if (_lastClapTriggerTime == null || now.difference(_lastClapTriggerTime!).inMilliseconds > 250) {
              _lastClapTriggerTime = now;
              _onInputTriggered(); // This starts _tapAnimationController
            }
          }
        });
      }
    } catch (e) {
      debugPrint("DEBUG: Error in _startClapDetection: $e");
    }
  }

  Future<void> _stopClapDetection() async {
    await _amplitudeSubscription?.cancel();
    if (await _recorder.isRecording()) {
      await _recorder.stop();
    }
  }

  void _onInputTriggered() {
    if (_gameState != GameState.playing) return;
    
    _tapAnimationController.forward(from: 0.0);

    final bpm = ref.read(bpmProvider);
    final msPerBeat = 60000.0 / bpm;
    final msPerMeasure = msPerBeat * 4;
    
    // Total elapsed time in current measure (ms)
    final currentMeasureProgressMs = _animationController.value * msPerMeasure;
    
    // Notes are centered at 0.5, 1.5, 2.5, 3.5 beats
    double beatFloat = (currentMeasureProgressMs / msPerBeat) - 0.5;
    int beatOffset = beatFloat.round(); // 0, 1, 2, 3 (or 4 for next measure)

    int currentMeasureBaseIndex = (_currentBeatGlobal ~/ 4) * 4;
    int absoluteBeatIndex = currentMeasureBaseIndex + beatOffset;

    if (absoluteBeatIndex < 0 || absoluteBeatIndex >= currentLevel.pattern.length) {
      _showFeedback("MISS", Colors.red);
      return;
    }

    int expectedValue = currentLevel.pattern[absoluteBeatIndex];
    if (expectedValue <= 0) {
      _showFeedback("MISS", Colors.red);
      return;
    }

    if (_hitNotes.contains(absoluteBeatIndex)) return;

    // Perfect target is at the center of the beat (0.5, 1.5, etc.)
    double targetTimeMs = (beatOffset + 0.5) * msPerBeat;
    double diffMs = (currentMeasureProgressMs - targetTimeMs).abs();
    
    const perfectThresholdMs = 100.0; // Slightly more lenient to start
    const goodThresholdMs = 180.0;

    if (diffMs < perfectThresholdMs) {
      _showFeedback("PERFECT", Colors.green);
      _perfectCount++;
      _hitNotes.add(absoluteBeatIndex);
    } else if (diffMs < goodThresholdMs) {
      _showFeedback("GOOD", Colors.orange);
      _perfectCount++; 
      _hitNotes.add(absoluteBeatIndex);
    } else {
      _showFeedback("MISS", Colors.red);
      if (currentMeasureProgressMs > targetTimeMs) {
        _hitNotes.add(absoluteBeatIndex);
      }
    }
  }

  void _showFeedback(String text, Color color) {
    setState(() {
      _feedbackText = text;
    });
    _feedbackTimer?.cancel();
    _feedbackTimer = Timer(const Duration(milliseconds: 500), () => setState(() => _feedbackText = ""));
  }

  void _showMetronomeDialog() {
    final TextEditingController controller = TextEditingController(
      text: ref.read(bpmProvider).toInt().toString(),
    );

    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.3),
      builder: (context) => Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 24),
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(7),
          ),
          clipBehavior: Clip.antiAlias,
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 30),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: SvgPicture.asset(
                      'assets/icons/back_arrow.svg',
                      width: 24,
                      height: 24,
                      colorFilter: const ColorFilter.mode(
                        Color(0xFF0E2576),
                        BlendMode.srcIn,
                      ),
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Expanded(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        "Type Your Metronome",
                        textAlign: TextAlign.center,
                        style: GoogleFonts.ubuntu(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF0E2576),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 40),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 160,
                    height: 48,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEBEBEB),
                      borderRadius: BorderRadius.circular(7),
                    ),
                    child: Center(
                      child: TextField(
                        controller: controller,
                        textAlign: TextAlign.center,
                        keyboardType: TextInputType.number,
                        style: GoogleFonts.ubuntu(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF7B9DFE),
                        ),
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    "bpm",
                    style: GoogleFonts.ubuntu(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF0E2576),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                "You can only choose between 60-80",
                style: GoogleFonts.ubuntu(
                  fontSize: 11,
                  color: const Color(0xFF7B9DFE).withValues(alpha: 0.8),
                ),
              ),
              const SizedBox(height: 24),
              _build3DButton(
                text: "Done",
                width: 150,
                height: 46,
                fontSize: 18,
                onTap: () {
                  final double? val = double.tryParse(controller.text);
                  if (val != null && val >= 60 && val <= 80) {
                    ref.read(bpmProvider.notifier).set(val);
                    Navigator.pop(context);
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _build3DButton({
    required String text,
    required VoidCallback onTap,
    double width = double.infinity,
    double height = 50,
    double fontSize = 18,
  }) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isButtonPressed = true),
      onTapUp: (_) {
        setState(() => _isButtonPressed = false);
        onTap();
      },
      onTapCancel: () => setState(() => _isButtonPressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 60),
        width: width,
        height: height,
        margin: EdgeInsets.only(top: _isButtonPressed ? 4 : 0),
        decoration: BoxDecoration(
          color: _isButtonPressed ? const Color(0xFF5A8EE0) : const Color(0xFF6C9FFD),
          borderRadius: BorderRadius.circular(10),
          boxShadow: _isButtonPressed 
            ? [] 
            : [
                BoxShadow(
                  color: const Color(0xFF3B71D0),
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
              fontSize: fontSize,
            ),
          ),
        ),
      ),
    );
  }

  void _showCompletionDialog(int stars, int score) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.4),
      barrierDismissible: false,
      builder: (context) => ScoreModal(
        score: score,
        stars: stars,
        onHomePressed: () {
          Navigator.pop(context); // Close Dialog
          Navigator.pop(context); // Go back to Level Selection/Main
        },
        onNextLevelPressed: () {
          Navigator.pop(context); // Close Dialog
          
          if (widget.levelIndex < rhythmLevels.length - 1) {
            final nextLevel = rhythmLevels[widget.levelIndex + 1];
            if (nextLevel.isLocked) {
              // If next level is locked, just go back to selection
              Navigator.pop(context);
            } else {
              // Replace current screen with next level
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => RhythmGameScreen(
                    levelIndex: widget.levelIndex + 1,
                  ),
                ),
              );
            }
          } else {
            // No more levels
            Navigator.pop(context);
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bpm = ref.watch(bpmProvider);
    final inputType = ref.watch(inputTypeProvider);

    return Scaffold(
      body: GradientBackground(
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              // Header (White with rounded bottom corners)
              Container(
                height: 65,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(15),
                    bottomRight: Radius.circular(15),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
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
                          "Rhythm ${currentLevel.title}",
                          textAlign: TextAlign.center,
                          style: GoogleFonts.ubuntu(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF0E2576),
                          ),
                        ),
                      ),
                      const SizedBox(width: 48),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Controls Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildBpmBadge(bpm),
                    _buildInputToggle(inputType),
                  ],
                ),
              ),

              // Expanded Tap Area for Gameplay
              Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: (_gameState == GameState.playing && inputType == InputType.tap)
                      ? _onInputTriggered
                      : null,
                  child: Column(
                    children: [


                      // FEEDBACK & COUNTDOWN AREA
                      SizedBox(
                        height: 90,
                        child: Center(
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 100), // Much faster
                            transitionBuilder: (child, animation) {
                              return ScaleTransition(
                                scale: CurvedAnimation(
                                  parent: animation,
                                  curve: Curves.elasticOut, // Snappy pop effect
                                ),
                                child: FadeTransition(
                                  opacity: animation,
                                  child: child,
                                ),
                              );
                            },
                            child: _gameState == GameState.countdown
                                ? SvgPicture.asset(
                                    'assets/images/gameplay/${_countdownValue == 0 ? "START" : _countdownValue.toString()}.svg',
                                    key: ValueKey('countdown_$_countdownValue'),
                                    height: 60,
                                    fit: BoxFit.contain,
                                  )
                                : (_feedbackText.isNotEmpty)
                                    ? SvgPicture.asset(
                                        'assets/images/gameplay/feedback/$_feedbackText.svg',
                                        key: ValueKey('feedback_$_feedbackText'),
                                        height: 50,
                                        fit: BoxFit.contain,
                                      )
                                    : const SizedBox.shrink(),
                          ),
                        ),
                      ),

                      const SizedBox(height: 40),

                      // Area: Staff Music
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Stack(
                          clipBehavior: Clip.none,
                          alignment: Alignment.center,
                          children: [
                            // 1. Staff Background Container
                            Container(
                              height: 135, // Increased for more space
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF1A3D7C).withValues(alpha: 0.1),
                                    blurRadius: 15,
                                    spreadRadius: 1,
                                    offset: const Offset(0, 6),
                                  ),
                                ],
                              ),
                            ),

                            // 2. Staff Lines
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: SizedBox(
                                height: 135,
                                width: double.infinity,
                                child: CustomPaint(
                                  painter: StaffLinesPainter(),
                                ),
                              ),
                            ),

                            // 3. Notes Visualization
                            Positioned.fill(
                              child: CustomPaint(
                                  painter: NotesPainter(
                                    pattern: currentLevel.pattern,
                                    currentMeasure: (_currentBeatGlobal ~/ 4).clamp(0, (currentLevel.pattern.length - 1) ~/ 4),
                                  ),
                              ),
                            ),

                            // 4. Playhead
                            Positioned.fill(
                              child: AnimatedBuilder(
                                animation: _animationController,
                                builder: (context, _) {
                                  return CustomPaint(
                                    painter: PlayheadPainter(
                                      progress: _animationController.value,
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),
                      // Reserved area for Tap Area Hint (Now Expanded to fill space)
                      Expanded(
                        child: _gameState == GameState.playing
                            ? _buildTapHint(inputType)
                            : const SizedBox.shrink(),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),

              // Bottom Button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 32),
                child: _build3DButton(
                  text: _gameState == GameState.playing || _gameState == GameState.countdown ? "Stop" : "Start",
                  height: 58,
                  fontSize: 18,
                  onTap: () {
                    _togglePlay();
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTapHint(InputType type) {
    if (type == InputType.clap) {
      return _buildClapVisualizer();
    }
    
    return AnimatedBuilder(
      animation: _tapAnimationController,
      builder: (context, child) {
        final t = _tapAnimationController.value;
        // 1.0 at start, 1.2 at peak
        double scale = 1.0 + (0.2 * t);
        // Only visible when triggered (0.0 to 1.0 flash)
        // If not animating, stay very subtle (0.05) or invisible
        double opacity = (t > 0) ? (1.0 - t).clamp(0.0, 1.0) : 0.15;
        
        return Stack(
          alignment: Alignment.center,
          fit: StackFit.expand,
          clipBehavior: Clip.none,
          children: [
            // Pulsing outer glow - Refined radius
            Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  radius: 0.6, // Further reduced to be safe and cleaner
                  colors: [
                    const Color(0xFF6C9FFD).withValues(alpha: opacity * 0.4),
                    const Color(0xFF6C9FFD).withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
            // Inner core with scale effect
            Transform.scale(
              scale: scale,
              child: Container(
                width: 250,
                height: 140,
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    radius: 0.5,
                    colors: [
                      const Color(0xFF6C9FFD).withValues(alpha: opacity * 0.65),
                      const Color(0xFF6C9FFD).withValues(alpha: 0.0),
                    ],
                  ),
                ),
                child: Center(
                  child: Text(
                    type == InputType.tap ? "Tap Here" : "Clap Now",
                    style: GoogleFonts.ubuntu(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF4F8BFB).withValues(alpha: 0.3 + (opacity * 0.7)),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildClapVisualizer() {
    return AnimatedBuilder(
      animation: _tapAnimationController,
      builder: (context, child) {
        final t = _tapAnimationController.value;
        double scale = 1.0 + (0.05 * t);
        
        return Transform.scale(
          scale: scale,
          child: Container(
            width: 280,
            height: 90,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
              border: Border.all(
                color: t > 0 
                  ? const Color(0xFF4F8BFB).withValues(alpha: 0.8) 
                  : const Color(0xFF6C9FFD).withValues(alpha: 0.5),
                width: t > 0 ? 3 : 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF6C9FFD).withValues(alpha: t > 0 ? 0.3 : 0.15),
                  blurRadius: t > 0 ? 25 : 15,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Center(
              child: SizedBox(
                width: 180,
                height: 48,
                child: CustomPaint(
                  painter: VisualizerPainter(
                    amplitude: _currentAmplitude,
                    isTriggered: t > 0,
                    triggerProgress: t,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildBpmBadge(double bpm) {
    return GestureDetector(
      onTap: _gameState == GameState.idle ? _showMetronomeDialog : null,
      child: Center(
        child: SizedBox(
          height: 50,
          child: Stack(
            alignment: Alignment.centerLeft,
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 20, top: 5),
                child: Container(
                  height: 30, // Proportional height
                  padding: const EdgeInsets.only(left: 25, right: 15),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF2E6FE9).withValues(alpha: 0.15),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      "${bpm.toInt()} bpm",
                      style: GoogleFonts.ubuntu(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: const Color(0xFF0E2576),
                      ),
                    ),
                  ),
                ),
              ),
              Stack(
                alignment: Alignment.center,
                children: [
                  ClipPath(
                    clipper: TrapezoidClipper(),
                    child: Container(
                      width: 44,
                      height: 52,
                      color: Colors.white,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 2), // Precision centering
                    child: Image.asset(
                      'assets/images/metronome_icon.png',
                      width: 32,
                      height: 32,
                      fit: BoxFit.contain,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputToggle(InputType current) {
    bool isClap = current == InputType.clap;
    return GestureDetector(
      onTap: _gameState == GameState.idle 
          ? () => ref.read(inputTypeProvider.notifier).set(isClap ? InputType.tap : InputType.clap)
          : null,
      child: Container(
        width: 100,
        height: 38,
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: const Color(0xFF6C9FFD),
          borderRadius: BorderRadius.circular(19),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF2E6FE9).withValues(alpha: 0.15),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          children: [
            AnimatedAlign(
              duration: const Duration(milliseconds: 200),
              alignment: isClap ? Alignment.centerRight : Alignment.centerLeft,
              child: Container(
                width: 30,
                height: 30,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Center(
              child: Padding(
                padding: EdgeInsets.only(
                  right: isClap ? 32 : 0,
                  left: isClap ? 0 : 32,
                ),
                child: Text(
                  isClap ? "Clap" : "Tap",
                  style: GoogleFonts.ubuntu(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class TrapezoidClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    Path path = Path();
    double w = size.width;
    double h = size.height;
    double r = 12.0; // Larger radius for more organic feel

    // Top edge width (wider top based on design)
    double xTopLeft = w * 0.28;
    double xTopRight = w * 0.72;

    path.moveTo(xTopLeft + r, 0);
    path.lineTo(xTopRight - r, 0);
    path.quadraticBezierTo(xTopRight, 0, xTopRight + r * 0.3, r * 0.5); 
    path.lineTo(w - r * 0.3, h - r);
    path.quadraticBezierTo(w, h, w - r, h);
    path.lineTo(r, h);
    path.quadraticBezierTo(0, h, r * 0.3, h - r);
    path.lineTo(xTopLeft - r * 0.3, r * 0.5);
    path.quadraticBezierTo(xTopLeft, 0, xTopLeft + r, 0);
    
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => true;
}

/// Staff Coordinate Helper
double getYForPitch(String pitchName, double lineSpacing, double topPadding) {
  // Treble Clef mapping (B4 is the middle line 3)
  // Distance is measured in "half spaces" from B4
  final Map<String, int> pitchOffsetFromB4 = {
    'F5': 4,
    'E5': 3,
    'D5': 2,
    'C5': 1,
    'B4': 0, // On line 3
    'A4': -1,
    'G4': -2,
    'F4': -3,
    'E4': -4,
  };

  int offset = pitchOffsetFromB4[pitchName] ?? 0;
  
  // Line 5 is top (index 0), Line 3 is index 2
  double middleLineY = topPadding + 2 * lineSpacing;
  
  return middleLineY - (offset * (lineSpacing / 2));
}

/// Painter for the static Staff Lines and Barline
class StaffLinesPainter extends CustomPainter {
  static const int numLines = 5;
  static const double vPadding = 25.0; // Reduced for more spaced lines
  static const double hPadding = 16.0; 

  @override
  void paint(Canvas canvas, Size size) {
    final double innerHeight = size.height - (2 * vPadding);
    final double lineSpacing = innerHeight / (numLines - 1);

    final linePaint = Paint()
      ..color = const Color(0xFFB0C4DE).withValues(alpha: 0.6) // More visible
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.3;

    // Draw 5 Staff Lines
    for (int i = 0 ; i < numLines; i++) {
        final y = vPadding + (i * lineSpacing);
        canvas.drawLine(Offset(hPadding, y), Offset(size.width - hPadding, y), linePaint);
    }

    // Double Barline
    final double endX = size.width - hPadding;
    final thinPaint = Paint()
      ..color = const Color(0xFFB0C4DE).withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    canvas.drawLine(Offset(endX - 5, vPadding), Offset(endX - 5, size.height - vPadding), thinPaint);

    final thickPaint = Paint()
      ..color = const Color(0xFFB0C4DE).withValues(alpha: 0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5;
    canvas.drawLine(Offset(endX, vPadding), Offset(endX, size.height - vPadding), thickPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Painter for the long Playhead that can overflow the container
class PlayheadPainter extends CustomPainter {
  final double progress;
  static const double hPadding = 16.0;

  PlayheadPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final double innerWidth = size.width - (2 * hPadding);
    
    final playheadPaint = Paint()
      ..color = const Color(0xFF1E90FF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.square; 

    final x = hPadding + (progress * innerWidth);
    
    // Playhead length adjusted for subtle overflow (closer to design)
    canvas.drawLine(
      Offset(x, -15),
      Offset(x, size.height + 15),
      playheadPaint
    );
  }

  @override
  bool shouldRepaint(covariant PlayheadPainter oldDelegate) => oldDelegate.progress != progress;
}
/// Painter for drawing Notes and Rests using Noto Music font
class NotesPainter extends CustomPainter {
  final List<int> pattern;
  final int currentMeasure;
  static const double hPadding = 16.0;

  NotesPainter({required this.pattern, required this.currentMeasure});

  @override
  void paint(Canvas canvas, Size size) {
    double staffHeight = size.height - (StaffLinesPainter.vPadding * 2);
    double lineSpacing = staffHeight / (StaffLinesPainter.numLines - 1);
    
    // Modern notation scale
    double fontSize = lineSpacing * 3.8; 
    
    double measureWidth = size.width - (hPadding * 2);
    double beatWidth = measureWidth / 4;

    for (int i = 0 ; i < 4; i++) {
      int absoluteIndex = (currentMeasure * 4) + i;
      if (absoluteIndex >= pattern.length) break;

      int noteValue = pattern[absoluteIndex];
      if (noteValue == -1) continue; // Continuation beat, don't draw

      bool isNote = noteValue == 1 || noteValue == 2;
      String glyph = '';
      if (noteValue == 1) {
        glyph = '\u{1D15F}'; // Quarter Note
      } else if (noteValue == 2) {
        glyph = '\u{1D15E}'; // Half Note
      } else {
        glyph = '\u{1D13D}'; // Quarter Rest
      }
      
      final textPainter = TextPainter(
        text: TextSpan(
          text: glyph,
          style: GoogleFonts.notoMusic(
            color: const Color(0xFF0E2576),
            fontSize: fontSize,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      
      textPainter.layout();

      double x = hPadding + (i * beatWidth) + (beatWidth / 2);
      double y;

      if (isNote) {
          y = getYForPitch('B4', lineSpacing, StaffLinesPainter.vPadding);
          canvas.save();
          // Adjust translation for Half Note if needed (usually same as quarter)
          canvas.translate(x - (textPainter.width / 2.1), y - (textPainter.height * 0.77)); 
          textPainter.paint(canvas, Offset.zero);
          canvas.restore();
      } else {
          y = StaffLinesPainter.vPadding + (2 * lineSpacing);
          canvas.save();
          canvas.translate(x - (textPainter.width / 2), y - (textPainter.height * 0.5));
          textPainter.paint(canvas, Offset.zero);
          canvas.restore();
      }
    }
  }

  @override
  bool shouldRepaint(covariant NotesPainter oldDelegate) => 
    oldDelegate.pattern != pattern || oldDelegate.currentMeasure != currentMeasure;
}

class VisualizerPainter extends CustomPainter {
  final double amplitude;
  final bool isTriggered;
  final double triggerProgress;
  
  VisualizerPainter({
    required this.amplitude, 
    this.isTriggered = false,
    this.triggerProgress = 0.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = isTriggered 
          ? Color.lerp(const Color(0xFF4F8BFB), const Color(0xFF6C9FFD), triggerProgress)!
          : const Color(0xFF6C9FFD)
      ..style = PaintingStyle.fill
      ..strokeCap = StrokeCap.round;

    final int barCount = 15;
    final double spacing = size.width / barCount;
    final double midY = size.height / 2;

    // Normalize amplitude from decibels (-60 to 0 range for visualization) to 0.0 to 1.0
    double normalized = ((amplitude + 60) / 60).clamp(0.0, 1.0);

    for (int i = 0; i < barCount; i++) {
      double x = i * spacing + (spacing / 2);
      
      // Classic symmetrical visualizer pattern
      double distanceFromCenter = (i - (barCount / 2)).abs() / (barCount / 2);
      
      // Calculate height based on amplitude and distance from center
      double heightFactor = (1.0 - distanceFromCenter * 0.7) * normalized;
      double barHeight = size.height * heightFactor;

      if (barHeight < 5) {
        // Draw as a small dot when silent
        canvas.drawCircle(Offset(x, midY), 2.5, paint);
      } else {
        // Draw as a vertical bar
        canvas.drawLine(
          Offset(x, midY - barHeight / 2),
          Offset(x, midY + barHeight / 2),
          paint..strokeWidth = 4,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant VisualizerPainter oldDelegate) => 
    oldDelegate.amplitude != amplitude || oldDelegate.isTriggered != isTriggered || oldDelegate.triggerProgress != triggerProgress;
}
