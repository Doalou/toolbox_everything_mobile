import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';

class TimerScreen extends StatefulWidget {
  const TimerScreen({super.key});

  @override
  State<TimerScreen> createState() => _TimerScreenState();
}

class _TimerScreenState extends State<TimerScreen> {
  late FlutterLocalNotificationsPlugin _notificationsPlugin;

  TimerMode _currentMode = TimerMode.timer;

  // Timer variables
  Timer? _activeTimer;
  int _timerSeconds = 0;
  int _initialTimerSeconds = 300; // 5 minutes par défaut
  bool _timerRunning = false;
  int? _timerEndEpochMs; // pour restauration/background

  // Stopwatch variables
  Stopwatch _stopwatch = Stopwatch();
  String _stopwatchDisplay = '00:00:00';
  List<String> _laps = [];
  int _stopwatchBaseMs = 0; // accumulation quand l'écran est quitté
  int? _stopwatchStartEpochMs; // pour restauration

  @override
  void initState() {
    super.initState();
    _initializeNotifications();
    _startStopwatchUpdater();
    _restoreState();
  }

  Future<void> _initializeNotifications() async {
    _notificationsPlugin = FlutterLocalNotificationsPlugin();

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notificationsPlugin.initialize(settings);
  }

  void _startStopwatchUpdater() {
    // Réduit la fréquence d'update pour éviter les saccades et la charge CPU,
    // et conserve une bonne précision visuelle (centièmes)
    Timer.periodic(const Duration(milliseconds: 50), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_stopwatch.isRunning) {
        setState(() {
          final effective =
              Duration(milliseconds: _stopwatchBaseMs) + _stopwatch.elapsed;
          _stopwatchDisplay = _formatDuration(effective);
        });
      }
    });
  }

  @override
  void dispose() {
    _activeTimer?.cancel();
    super.dispose();
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String twoDigitsMs(int n) => (n ~/ 10).toString().padLeft(2, '0');

    return '${twoDigits(duration.inMinutes)}:${twoDigits(duration.inSeconds.remainder(60))}:${twoDigitsMs(duration.inMilliseconds.remainder(1000))}';
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  void _setTimerDuration(int seconds) {
    setState(() {
      _initialTimerSeconds = seconds;
      _timerSeconds = seconds;
    });
  }

  void _startTimer() {
    if (_timerSeconds <= 0) return;

    setState(() {
      _timerRunning = true;
    });

    final now = DateTime.now().millisecondsSinceEpoch;
    _timerEndEpochMs = now + (_timerSeconds * 1000);
    _persistTimerState(running: true);

    _activeTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _timerSeconds--;
        });

        if (_timerSeconds <= 0) {
          _stopTimer();
          _showTimerNotification();
          HapticFeedback.heavyImpact();
        }
      }
    });
  }

  void _stopTimer() {
    _activeTimer?.cancel();

    setState(() {
      _timerRunning = false;
    });
    _persistTimerState(running: false);
  }

  void _resetTimer() {
    _stopTimer();
    setState(() {
      _timerSeconds = _initialTimerSeconds;
    });
    _persistTimerState(running: false);
  }

  void _startStopwatch() {
    setState(() {
      _stopwatch.start();
    });
    _stopwatchStartEpochMs = DateTime.now().millisecondsSinceEpoch;
    _persistStopwatchState(running: true);
  }

  void _stopStopwatch() {
    setState(() {
      _stopwatch.stop();
      _stopwatchBaseMs += _stopwatch.elapsedMilliseconds;
      _stopwatch.reset();
    });
    _persistStopwatchState(running: false);
  }

  void _resetStopwatch() {
    setState(() {
      _stopwatch.reset();
      _stopwatchDisplay = '00:00:00';
      _laps.clear();
      _stopwatchBaseMs = 0;
    });
    _persistStopwatchState(running: false);
  }

  void _addLap() {
    if (_stopwatch.isRunning) {
      setState(() {
        _laps.insert(0, 'Tour ${_laps.length + 1}: $_stopwatchDisplay');
      });
    }
  }

  Future<void> _showTimerNotification() async {
    const androidDetails = AndroidNotificationDetails(
      'timer_channel',
      'Timer Notifications',
      channelDescription: 'Notifications pour le minuteur',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notificationsPlugin.show(
      0,
      'Minuteur terminé !',
      'Votre minuteur de ${_formatTime(_initialTimerSeconds)} est arrivé à terme.',
      details,
    );
  }

  Future<void> _persistTimerState({required bool running}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('timer_running', running);
    await prefs.setInt('timer_initial', _initialTimerSeconds);
    await prefs.setInt('timer_remaining', _timerSeconds);
    if (_timerEndEpochMs != null) {
      await prefs.setInt('timer_end_epoch', _timerEndEpochMs!);
    }
  }

  Future<void> _persistStopwatchState({required bool running}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('stopwatch_running', running);
    await prefs.setInt('stopwatch_base_ms', _stopwatchBaseMs);
    if (running && _stopwatchStartEpochMs != null) {
      await prefs.setInt('stopwatch_start_epoch', _stopwatchStartEpochMs!);
    }
  }

  Future<void> _restoreState() async {
    final prefs = await SharedPreferences.getInstance();
    // Timer
    final wasTimerRunning = prefs.getBool('timer_running') ?? false;
    _initialTimerSeconds =
        prefs.getInt('timer_initial') ?? _initialTimerSeconds;
    final savedEnd = prefs.getInt('timer_end_epoch');
    if (wasTimerRunning && savedEnd != null) {
      final now = DateTime.now().millisecondsSinceEpoch;
      final remainingMs = savedEnd - now;
      if (remainingMs > 0) {
        setState(() {
          _timerSeconds = (remainingMs / 1000).ceil();
          _timerRunning = true;
          _timerEndEpochMs = savedEnd;
        });
        _activeTimer?.cancel();
        _activeTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
          if (!mounted) return;
          setState(() {
            _timerSeconds--;
          });
          if (_timerSeconds <= 0) {
            _stopTimer();
            _showTimerNotification();
          }
        });
      } else {
        // Timer complet pendant l'absence
        setState(() {
          _timerSeconds = 0;
          _timerRunning = false;
        });
        _showTimerNotification();
        _persistTimerState(running: false);
      }
    } else {
      _timerSeconds = _initialTimerSeconds;
    }

    // Stopwatch
    _stopwatchBaseMs = prefs.getInt('stopwatch_base_ms') ?? 0;
    final wasStopwatchRunning = prefs.getBool('stopwatch_running') ?? false;
    final startEpoch = prefs.getInt('stopwatch_start_epoch');
    if (wasStopwatchRunning && startEpoch != null) {
      final now = DateTime.now().millisecondsSinceEpoch;
      final elapsedSinceStart = now - startEpoch;
      _stopwatchBaseMs += elapsedSinceStart;
      _stopwatchStartEpochMs = now;
      _stopwatch
        ..reset()
        ..start();
    }
    setState(() {
      _stopwatchDisplay = _formatDuration(
        Duration(milliseconds: _stopwatchBaseMs) + _stopwatch.elapsed,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: const Text('Minuteur & Chronomètre'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Mode selector
          Container(
            margin: const EdgeInsets.all(20),
            child: SegmentedButton<TimerMode>(
              segments: const [
                ButtonSegment(
                  value: TimerMode.timer,
                  icon: Icon(Icons.timer, size: 20),
                  label: Text('Minuteur'),
                ),
                ButtonSegment(
                  value: TimerMode.stopwatch,
                  icon: Icon(Icons.timer_outlined, size: 20),
                  label: Text('Chronomètre'),
                ),
              ],
              selected: {_currentMode},
              onSelectionChanged: (newSelection) {
                setState(() {
                  _currentMode = newSelection.first;
                });
                // Stop any running timers when switching modes
                _stopTimer();
                _stopStopwatch();
              },
            ),
          ),

          Expanded(
            child: _currentMode == TimerMode.timer
                ? _buildTimerView()
                : _buildStopwatchView(),
          ),
        ],
      ),
    );
  }

  Widget _buildTimerView() {
    final colorScheme = Theme.of(context).colorScheme;
    final progress = _initialTimerSeconds > 0
        ? (_initialTimerSeconds - _timerSeconds) / _initialTimerSeconds
        : 0.0;

    return SingleChildScrollView(
      physics: const ClampingScrollPhysics(),
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Timer display
          Container(
            width: 250,
            height: 250,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  colorScheme.primaryContainer.withValues(alpha: 0.8),
                  colorScheme.secondaryContainer.withValues(alpha: 0.6),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: colorScheme.primary.withValues(alpha: 0.2),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Progress indicator
                SizedBox(
                  width: 220,
                  height: 220,
                  child: CircularProgressIndicator(
                    value: progress,
                    strokeWidth: 8,
                    backgroundColor: colorScheme.outline.withValues(alpha: 0.2),
                    valueColor: AlwaysStoppedAnimation(
                      _timerSeconds <= 10 ? Colors.red : colorScheme.primary,
                    ),
                  ),
                ),
                // Time display
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _formatTime(_timerSeconds),
                      style: Theme.of(context).textTheme.displayLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: _timerSeconds <= 10
                            ? Colors.red
                            : colorScheme.onPrimaryContainer,
                        fontFamily: 'monospace',
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _timerRunning ? 'En cours...' : 'Minuteur',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: colorScheme.onPrimaryContainer.withValues(
                          alpha: 0.7,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 40),

          // Preset buttons
          if (!_timerRunning) ...[
            Text(
              'Durées prédéfinies',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _buildPresetButton('1 min', 60),
                _buildPresetButton('5 min', 300),
                _buildPresetButton('10 min', 600),
                _buildPresetButton('15 min', 900),
                _buildPresetButton('30 min', 1800),
                _buildPresetButton('1 heure', 3600),
              ],
            ),
            const SizedBox(height: 32),
          ],

          // Control buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              if (!_timerRunning) ...[
                FloatingActionButton.large(
                  heroTag: "timer_start",
                  onPressed: _timerSeconds > 0 ? _startTimer : null,
                  backgroundColor: colorScheme.primary,
                  foregroundColor: colorScheme.onPrimary,
                  child: const Icon(Icons.play_arrow, size: 32),
                ),
              ] else ...[
                FloatingActionButton.large(
                  heroTag: "timer_stop",
                  onPressed: _stopTimer,
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  child: const Icon(Icons.pause, size: 32),
                ),
              ],
              FloatingActionButton(
                heroTag: "timer_reset",
                onPressed: _resetTimer,
                backgroundColor: colorScheme.surfaceContainer,
                foregroundColor: colorScheme.onSurface,
                child: const Icon(Icons.refresh),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStopwatchView() {
    final colorScheme = Theme.of(context).colorScheme;

    return SingleChildScrollView(
      physics: const ClampingScrollPhysics(),
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Stopwatch display
          Container(
            width: 280,
            height: 200,
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  colorScheme.primaryContainer.withValues(alpha: 0.8),
                  colorScheme.secondaryContainer.withValues(alpha: 0.6),
                ],
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: colorScheme.primary.withValues(alpha: 0.2),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _stopwatchDisplay,
                  style: Theme.of(context).textTheme.displayMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: colorScheme.onPrimaryContainer,
                    fontFamily: 'monospace',
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _stopwatch.isRunning ? 'En cours...' : 'Chronomètre',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: colorScheme.onPrimaryContainer.withValues(
                      alpha: 0.7,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),

          // Control buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              if (!_stopwatch.isRunning) ...[
                FloatingActionButton.large(
                  heroTag: "stopwatch_start",
                  onPressed: _startStopwatch,
                  backgroundColor: colorScheme.primary,
                  foregroundColor: colorScheme.onPrimary,
                  child: const Icon(Icons.play_arrow, size: 32),
                ),
              ] else ...[
                FloatingActionButton.large(
                  heroTag: "stopwatch_stop",
                  onPressed: _stopStopwatch,
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  child: const Icon(Icons.pause, size: 32),
                ),
              ],
              FloatingActionButton(
                heroTag: "stopwatch_lap",
                onPressed: _stopwatch.isRunning ? _addLap : null,
                backgroundColor: colorScheme.secondaryContainer,
                foregroundColor: colorScheme.onSecondaryContainer,
                child: const Icon(Icons.flag),
              ),
              FloatingActionButton(
                heroTag: "stopwatch_reset",
                onPressed: _resetStopwatch,
                backgroundColor: colorScheme.surfaceContainer,
                foregroundColor: colorScheme.onSurface,
                child: const Icon(Icons.refresh),
              ),
            ],
          ),

          if (_laps.isNotEmpty) ...[
            const SizedBox(height: 32),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainer,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: colorScheme.outline.withValues(alpha: 0.1),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.flag, color: colorScheme.primary, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Tours enregistrés',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ...(_laps
                      .take(5)
                      .map(
                        (lap) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Text(
                            lap,
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(fontFamily: 'monospace'),
                          ),
                        ),
                      )),
                  if (_laps.length > 5)
                    Text(
                      '... et ${_laps.length - 5} autres tours',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPresetButton(String label, int seconds) {
    final colorScheme = Theme.of(context).colorScheme;
    final isSelected = _timerSeconds == seconds;

    return InkWell(
      onTap: () => _setTimerDuration(seconds),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? colorScheme.primaryContainer
              : colorScheme.surfaceContainer,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? colorScheme.primary
                : colorScheme.outline.withValues(alpha: 0.2),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: isSelected
                ? colorScheme.onPrimaryContainer
                : colorScheme.onSurface,
          ),
        ),
      ),
    );
  }
}

enum TimerMode { timer, stopwatch }
