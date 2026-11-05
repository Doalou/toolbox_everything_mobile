import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:toolbox_everything_mobile/core/design/expressive_shapes.dart';
import 'package:toolbox_everything_mobile/core/services/haptics_service.dart';
import 'package:toolbox_everything_mobile/core/services/notification_service.dart';
import 'package:toolbox_everything_mobile/shared/widgets/editorial_tool_scaffold.dart';
import 'package:toolbox_everything_mobile/shared/widgets/expressive_card.dart';

class TimerScreen extends StatefulWidget {
  final String heroTag;

  const TimerScreen({super.key, required this.heroTag});

  @override
  State<TimerScreen> createState() => _TimerScreenState();
}

class _TimerScreenState extends State<TimerScreen> {
  TimerMode _currentMode = TimerMode.timer;

  // Timer variables
  Timer? _activeTimer;
  Timer? _stopwatchUpdater;
  int _timerSeconds = 300;
  int _initialTimerSeconds = 300; // 5 minutes par défaut
  bool _timerRunning = false;
  int? _timerEndEpochMs;

  // Stopwatch variables
  final Stopwatch _stopwatch = Stopwatch();
  String _stopwatchDisplay = '00:00:00';
  final List<String> _laps = [];
  int _stopwatchBaseMs = 0;
  int? _stopwatchStartEpochMs;

  @override
  void initState() {
    super.initState();
    _startStopwatchUpdater();
    _restoreState();
  }

  void _startStopwatchUpdater() {
    _stopwatchUpdater = Timer.periodic(const Duration(milliseconds: 50), (
      timer,
    ) {
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
    _stopwatchUpdater?.cancel();
    super.dispose();
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String twoDigitsMs(int n) => (n ~/ 10).toString().padLeft(2, '0');

    return '${twoDigits(duration.inMinutes)}:${twoDigits(duration.inSeconds.remainder(60))}:${twoDigitsMs(duration.inMilliseconds.remainder(1000))}';
  }

  String _formatTime(int seconds) {
    final hrs = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    final remainingSeconds = seconds % 60;
    if (hrs > 0) {
      return '${hrs.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  void _setTimerDuration(int seconds) {
    HapticsService.perform(context, HapticType.selection);
    setState(() {
      _initialTimerSeconds = seconds;
      _timerSeconds = seconds;
    });
    _persistTimerState(running: false);
  }

  void _addSeconds(int delta) {
    HapticsService.perform(context, HapticType.light);
    setState(() {
      _timerSeconds = (_timerSeconds + delta).clamp(0, 24 * 3600);
      if (_timerSeconds > _initialTimerSeconds) {
        _initialTimerSeconds = _timerSeconds;
      }
      if (_timerRunning && _timerEndEpochMs != null) {
        _timerEndEpochMs = _timerEndEpochMs! + (delta * 1000);
      }
    });
    _persistTimerState(running: _timerRunning);
  }

  void _startTimer() {
    if (_timerSeconds <= 0) return;
    HapticsService.perform(context, HapticType.medium);

    setState(() {
      _timerRunning = true;
    });

    final now = DateTime.now().millisecondsSinceEpoch;
    _timerEndEpochMs = now + (_timerSeconds * 1000);
    _persistTimerState(running: true);

    _activeTimer?.cancel();
    _activeTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      final remainingMs =
          (_timerEndEpochMs ?? DateTime.now().millisecondsSinceEpoch) -
          DateTime.now().millisecondsSinceEpoch;
      final nextSeconds = (remainingMs / 1000).ceil().clamp(0, 24 * 3600);
      setState(() {
        _timerSeconds = nextSeconds;
      });

      if (_timerSeconds <= 0) {
        _stopTimer();
        _showTimerNotification();
        HapticFeedback.heavyImpact();
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
    HapticsService.perform(context, HapticType.light);
    _stopTimer();
    setState(() {
      _timerSeconds = _initialTimerSeconds;
    });
    _persistTimerState(running: false);
  }

  void _startStopwatch() {
    HapticsService.perform(context, HapticType.medium);
    setState(() {
      _stopwatch.start();
    });
    _stopwatchStartEpochMs = DateTime.now().millisecondsSinceEpoch;
    _persistStopwatchState(running: true);
  }

  void _stopStopwatch() {
    HapticsService.perform(context, HapticType.light);
    setState(() {
      _stopwatch.stop();
      _stopwatchBaseMs += _stopwatch.elapsedMilliseconds;
      _stopwatch.reset();
    });
    _persistStopwatchState(running: false);
  }

  void _resetStopwatch() {
    HapticsService.perform(context, HapticType.light);
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
      HapticsService.perform(context, HapticType.selection);
      setState(() {
        _laps.insert(0, 'Tour ${_laps.length + 1} · $_stopwatchDisplay');
      });
    }
  }

  Future<void> _showCustomDurationDialog() async {
    int minutes = _initialTimerSeconds ~/ 60;
    int seconds = _initialTimerSeconds % 60;
    final minController = TextEditingController(text: minutes.toString());
    final secController = TextEditingController(
      text: seconds.toString().padLeft(2, '0'),
    );

    final result = await showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.fromLTRB(
            24,
            12,
            24,
            MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Durée personnalisée',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: minController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: const InputDecoration(
                        labelText: 'Minutes',
                        suffixText: 'min',
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: secController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: const InputDecoration(
                        labelText: 'Secondes',
                        suffixText: 's',
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: () {
                  final m = int.tryParse(minController.text) ?? 0;
                  final s = int.tryParse(secController.text) ?? 0;
                  final total = (m * 60 + s).clamp(1, 24 * 3600);
                  Navigator.pop(context, total);
                },
                icon: const Icon(Icons.check_rounded),
                label: const Text('Appliquer'),
              ),
            ],
          ),
        );
      },
    );

    if (result != null && result > 0) {
      _setTimerDuration(result);
    }
  }

  Future<void> _showTimerNotification() async {
    await NotificationService.instance.notifyTimerComplete(
      body:
          'Votre minuteur de ${_formatTime(_initialTimerSeconds)} est arrivé à terme.',
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
    if (!mounted) return;
    setState(() {
      _stopwatchDisplay = _formatDuration(
        Duration(milliseconds: _stopwatchBaseMs) + _stopwatch.elapsed,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return EditorialToolScaffold(
      title: 'Minuteur & chronomètre',
      heroTag: widget.heroTag,
      body: Column(
        children: [
          Container(
            width: double.infinity,
            margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: SegmentedButton<TimerMode>(
              segments: const [
                ButtonSegment(
                  value: TimerMode.timer,
                  icon: Icon(Icons.timer_rounded, size: 20),
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
                HapticsService.perform(context, HapticType.selection);
                setState(() {
                  _currentMode = newSelection.first;
                });
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
        ? ((_initialTimerSeconds - _timerSeconds) / _initialTimerSeconds).clamp(
            0.0,
            1.0,
          )
        : 0.0;
    final isUrgent = _timerRunning && _timerSeconds <= 10;

    return SingleChildScrollView(
      physics: const ClampingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
      child: Column(
        children: [
          ExpressiveCard.hero(
            color: colorScheme.primaryContainer.withValues(alpha: 0.65),
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 18),
            child: Column(
              children: [
                SizedBox(
                  width: 196,
                  height: 196,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 184,
                        height: 184,
                        child: CircularProgressIndicator(
                          value: progress,
                          strokeWidth: 9,
                          backgroundColor: colorScheme.surface.withValues(
                            alpha: 0.5,
                          ),
                          valueColor: AlwaysStoppedAnimation(
                            isUrgent ? colorScheme.error : colorScheme.primary,
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 18),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                _formatTime(_timerSeconds),
                                style: Theme.of(context).textTheme.displayMedium
                                    ?.copyWith(
                                      fontWeight: FontWeight.w800,
                                      color: isUrgent
                                          ? colorScheme.error
                                          : colorScheme.onPrimaryContainer,
                                      fontFamily: 'monospace',
                                    ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _timerRunning ? 'En cours…' : 'Prêt',
                              style: Theme.of(context).textTheme.labelLarge
                                  ?.copyWith(
                                    color: colorScheme.onPrimaryContainer
                                        .withValues(alpha: 0.78),
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 10,
                  alignment: WrapAlignment.center,
                  children: [
                    ActionChip(
                      onPressed: () => _addSeconds(30),
                      avatar: const Icon(Icons.add_rounded, size: 16),
                      label: const Text('+30 s'),
                    ),
                    ActionChip(
                      onPressed: () => _addSeconds(60),
                      avatar: const Icon(Icons.add_rounded, size: 16),
                      label: const Text('+1 min'),
                    ),
                    if (!_timerRunning)
                      ActionChip(
                        onPressed: _showCustomDurationDialog,
                        avatar: const Icon(Icons.edit_rounded, size: 16),
                        label: const Text('Personnaliser'),
                      ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          if (!_timerRunning) ...[
            ExpressiveCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Durées prédéfinies',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      _buildPresetChip('1 min', 60),
                      _buildPresetChip('3 min', 180),
                      _buildPresetChip('5 min', 300),
                      _buildPresetChip('10 min', 600),
                      _buildPresetChip('15 min', 900),
                      _buildPresetChip('30 min', 1800),
                      _buildPresetChip('1 h', 3600),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FloatingActionButton.large(
                heroTag: _timerRunning ? 'timer_stop' : 'timer_start',
                onPressed: _timerRunning
                    ? _stopTimer
                    : (_timerSeconds > 0 ? _startTimer : null),
                backgroundColor: _timerRunning
                    ? colorScheme.errorContainer
                    : colorScheme.primary,
                foregroundColor: _timerRunning
                    ? colorScheme.onErrorContainer
                    : colorScheme.onPrimary,
                child: Icon(
                  _timerRunning
                      ? Icons.pause_rounded
                      : Icons.play_arrow_rounded,
                  size: 36,
                ),
              ),
              const SizedBox(width: 20),
              FloatingActionButton(
                heroTag: 'timer_reset',
                onPressed: _resetTimer,
                backgroundColor: colorScheme.secondaryContainer,
                foregroundColor: colorScheme.onSecondaryContainer,
                child: const Icon(Icons.refresh_rounded),
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
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
      child: Column(
        children: [
          ExpressiveCard.hero(
            color: colorScheme.primaryContainer.withValues(alpha: 0.65),
            padding: const EdgeInsets.symmetric(vertical: 26, horizontal: 20),
            child: Column(
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    _stopwatchDisplay,
                    style: Theme.of(context).textTheme.displayMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: colorScheme.onPrimaryContainer,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _stopwatch.isRunning ? 'En cours…' : 'Chronomètre prêt',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onPrimaryContainer.withValues(
                      alpha: 0.75,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FloatingActionButton.large(
                heroTag: _stopwatch.isRunning
                    ? 'stopwatch_stop'
                    : 'stopwatch_start',
                onPressed: _stopwatch.isRunning
                    ? _stopStopwatch
                    : _startStopwatch,
                backgroundColor: _stopwatch.isRunning
                    ? colorScheme.errorContainer
                    : colorScheme.primary,
                foregroundColor: _stopwatch.isRunning
                    ? colorScheme.onErrorContainer
                    : colorScheme.onPrimary,
                child: Icon(
                  _stopwatch.isRunning
                      ? Icons.pause_rounded
                      : Icons.play_arrow_rounded,
                  size: 36,
                ),
              ),
              const SizedBox(width: 16),
              FloatingActionButton(
                heroTag: 'stopwatch_lap',
                onPressed: _stopwatch.isRunning ? _addLap : null,
                backgroundColor: colorScheme.secondaryContainer,
                foregroundColor: colorScheme.onSecondaryContainer,
                tooltip: 'Tour',
                child: const Icon(Icons.flag_rounded),
              ),
              const SizedBox(width: 16),
              FloatingActionButton(
                heroTag: 'stopwatch_reset',
                onPressed: _resetStopwatch,
                backgroundColor: colorScheme.surfaceContainerHigh,
                foregroundColor: colorScheme.onSurface,
                tooltip: 'Réinitialiser',
                child: const Icon(Icons.refresh_rounded),
              ),
            ],
          ),
          if (_laps.isNotEmpty) ...[
            const SizedBox(height: 24),
            ExpressiveCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.flag_rounded,
                        color: colorScheme.primary,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Tours enregistrés (${_laps.length})',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ..._laps.map(
                    (lap) => Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(
                          ExpressiveShapes.medium,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.timer_outlined,
                            size: 16,
                            color: colorScheme.primary,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              lap,
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(fontFamily: 'monospace'),
                            ),
                          ),
                        ],
                      ),
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

  Widget _buildPresetChip(String label, int seconds) {
    final isSelected =
        _initialTimerSeconds == seconds && _timerSeconds == seconds;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => _setTimerDuration(seconds),
    );
  }
}

enum TimerMode { timer, stopwatch }
