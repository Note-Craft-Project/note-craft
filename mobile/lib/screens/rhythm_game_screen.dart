import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import 'package:record/record.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:google_fonts/google_fonts.dart';

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
  const RhythmGameScreen({super.key});

  @override
  ConsumerState<RhythmGameScreen> createState() => _RhythmGameScreenState();
}

class _RhythmGameScreenState extends ConsumerState<RhythmGameScreen> with SingleTickerProviderStateMixin {
  late AudioPlayer _audioPlayer;
  late AudioRecorder _recorder;
  late AnimationController _animationController;
  StreamSubscription? _amplitudeSubscription;
  Timer? _feedbackTimer;
  Timer? _countdownTimer;

  GameState _gameState = GameState.idle;
  String _feedbackText = "";
  String _countdownText = "";

  final List<int> _rhythmPattern = [1, 1, 1, 1, 1, 1, 1, 0, 1, 1, 1, 1, 1, 1, 0, 0];
  int _currentBeatGlobal = 0;
  int _lastSoundBeat = -1;
  int _perfectCount = 0;

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();
    _recorder = AudioRecorder();
    _animationController = AnimationController(vsync: this);
    _animationController.addListener(_onAnimationTick);
    _animationController.addStatusListener(_onAnimationStatus);
    _setupAudio();
  }

  void _onAnimationTick() {
    if (_gameState != GameState.playing) return;
    double progress = _animationController.value;
    int currentBeatInMeasure = (progress * 4).floor().clamp(0, 3);
    if (currentBeatInMeasure != _lastSoundBeat) {
      _lastSoundBeat = currentBeatInMeasure;
      _playMetronomeSound();
      setState(() {
        int measureIndex = _currentBeatGlobal ~/ 4;
        _currentBeatGlobal = (measureIndex * 4) + currentBeatInMeasure;
        if (_currentBeatGlobal >= _rhythmPattern.length) {
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
        if (_currentBeatGlobal >= _rhythmPattern.length) {
          _completeGame();
        } else {
          _animationController.forward(from: 0.0);
        }
      });
    }
  }

  void _playMetronomeSound() {
    _audioPlayer.seek(Duration.zero);
    _audioPlayer.play();
  }

  void _completeGame() {
    _gameState = GameState.completed;
    _animationController.stop();
    _stopClapDetection();
    int stars = 0;
    int totalNotes = _rhythmPattern.where((n) => n == 1).length;
    double ratio = _perfectCount / totalNotes;
    if (ratio >= 0.9) {
      stars = 3;
    } else if (ratio >= 0.6) {
      stars = 2;
    } else {
      stars = 1;
    }
    _showCompletionDialog(stars);
  }

  Future<void> _setupAudio() async {
    try {
      await _audioPlayer.setUrl('https://www.soundjay.com/button/button-10.mp3');
    } catch (e) {
      debugPrint("Audio load error: $e");
    }
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _feedbackTimer?.cancel();
    _audioPlayer.dispose();
    _recorder.dispose();
    _animationController.dispose();
    _amplitudeSubscription?.cancel();
    super.dispose();
  }

  void _togglePlay() {
    if (_gameState == GameState.playing || _gameState == GameState.countdown) {
      setState(() {
        _gameState = GameState.idle;
        _animationController.stop();
        _countdownTimer?.cancel();
        _stopClapDetection();
      });
    } else {
      _startCountdown();
    }
  }

  void _startCountdown() {
    setState(() {
      _gameState = GameState.countdown;
      _currentBeatGlobal = 0;
      _lastSoundBeat = -1;
      _perfectCount = 0;
    });
    int counter = 3;
    _countdownText = counter.toString();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      counter--;
      if (counter > 0) {
        setState(() => _countdownText = counter.toString());
      } else if (counter == 0) {
        setState(() => _countdownText = "GO!");
      } else {
        timer.cancel();
        _startGame();
      }
    });
  }

  void _startGame() {
    setState(() {
      _gameState = GameState.playing;
      _countdownText = "";
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
    if (await Permission.microphone.request().isGranted) {
      _amplitudeSubscription = _recorder.onAmplitudeChanged(const Duration(milliseconds: 50)).listen((amp) {
        if (amp.current > -20) _onInputTriggered();
      });
    }
  }

  void _stopClapDetection() => _amplitudeSubscription?.cancel();

  void _onInputTriggered() {
    if (_gameState != GameState.playing) return;
    setState(() {
      _feedbackText = "PERFECT";
      _perfectCount++;
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
      barrierColor: Colors.black.withOpacity(0.3),
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
                  color: const Color(0xFF7B9DFE).withOpacity(0.8),
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
      onTap: onTap,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: const Color(0xFF6C9FFD),
          borderRadius: BorderRadius.circular(7),
          boxShadow: const [
            BoxShadow(
              color: Color(0xFF3B71D0),
              offset: Offset(0, 4),
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

  void _showCompletionDialog(int stars) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text("Level Completed!", textAlign: TextAlign.center, style: GoogleFonts.ubuntu(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(3, (i) => Icon(i < stars ? Icons.star : Icons.star_border, color: Colors.orange, size: 40)),
            ),
            const SizedBox(height: 16),
            Text("Accuracy: ${((_perfectCount / _rhythmPattern.where((n)=>n==1).length)*100).toInt()}%", style: GoogleFonts.ubuntu()),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Home")),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bpm = ref.watch(bpmProvider);
    final inputType = ref.watch(inputTypeProvider);
    return Scaffold(
      backgroundColor: const Color(0xFFE8F0FF),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
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
                  Expanded(child: Text("Rhythm Level 1", textAlign: TextAlign.center, style: GoogleFonts.ubuntu(fontSize: 20, fontWeight: FontWeight.bold))),
                  const SizedBox(width: 48),
                ],
              ),
            ),
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
            const Spacer(),
            if (_countdownText.isNotEmpty) Text(_countdownText, style: GoogleFonts.ubuntu(fontSize: 80, fontWeight: FontWeight.bold, color: const Color(0xFF1A3D7C))),
            if (_feedbackText.isNotEmpty) Text(_feedbackText, style: GoogleFonts.ubuntu(fontSize: 30, fontWeight: FontWeight.bold, color: Colors.green)),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.all(32),
              child: _build3DButton(
                text: _gameState == GameState.playing ? "STOP" : "START",
                height: 60,
                fontSize: 20,
                onTap: _togglePlay,
              ),
            ),
          ],
        ),
      ),
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
                  height: 32,
                  padding: const EdgeInsets.only(left: 20, right: 15),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [BoxShadow(color: const Color(0xFF2E6FE9).withValues(alpha: 0.15), blurRadius: 10, offset: const Offset(0, 4))],
                  ),
                  child: Center(
                    child: Text("${bpm.toInt()} bpm", style: GoogleFonts.ubuntu(fontWeight: FontWeight.bold, fontSize: 15, color: const Color(0xFF0E2576))),
                  ),
                ),
              ),
              Stack(
                alignment: Alignment.center,
                children: [
                  ClipPath(clipper: TrapezoidClipper(), child: Container(width: 40, height: 44, color: Colors.white)),
                  Image.asset('assets/images/metronome_icon.png', width: 26, height: 26, fit: BoxFit.contain),
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
      onTap: () => ref.read(inputTypeProvider.notifier).set(isClap ? InputType.tap : InputType.clap),
      child: Container(
        width: 100,
        height: 38,
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: const Color(0xFF6C9FFD),
          borderRadius: BorderRadius.circular(19),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF2E6FE9).withOpacity(0.15),
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
    double w = size.width; double h = size.height;
    path.moveTo(w * 0.2, 0); path.lineTo(w * 0.8, 0); path.lineTo(w, h); path.lineTo(0, h); path.close();
    return path;
  }
  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
