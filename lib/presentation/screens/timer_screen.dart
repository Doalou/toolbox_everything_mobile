import 'dart:async';
import 'dart:convert';

import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:toolbox_everything_mobile/core/design/expressive_motion.dart';
import 'package:toolbox_everything_mobile/core/design/expressive_shapes.dart';
import 'package:toolbox_everything_mobile/core/providers/settings_provider.dart';
import 'package:toolbox_everything_mobile/core/services/app_feedback.dart';
import 'package:toolbox_everything_mobile/core/services/haptics_service.dart';
import 'package:toolbox_everything_mobile/core/services/notification_service.dart';
import 'package:toolbox_everything_mobile/shared/widgets/editorial_tool_scaffold.dart';
import 'package:toolbox_everything_mobile/shared/widgets/expressive_card.dart';
import 'package:toolbox_everything_mobile/shared/widgets/status_badge.dart';

enum TimerMode { timer, stopwatch, pomodoro }

enum _PomodoroPhase { work, shortBreak, longBreak }

class _StopwatchLap {
  final int index;
  final int totalMs;
  final int lapMs;

  const _StopwatchLap({
    required this.index,
    required this.totalMs,
    required this.lapMs,
  });

  Map<String, dynamic> toJson() => {
    'index': index,
    'totalMs': totalMs,
    'lapMs': lapMs,
  };

  factory _StopwatchLap.fromJson(Map<String, dynamic> json) => _StopwatchLap(
    index: (json['index'] as num?)?.toInt() ?? 1,
    totalMs: (json['totalMs'] as num?)?.toInt() ?? 0,
    lapMs: (json['lapMs'] as num?)?.toInt() ?? 0,
  );
}

class TimerScreen extends StatefulWidget {
  final String heroTag;

  const TimerScreen({super.key, required this.heroTag});

  @override
  State<TimerScreen> createState() => _TimerScreenState();
}

class _TimerScreenState extends State<TimerScreen> {
  static const List<int> _defaultPresetSeconds = [
    60,
    180,
    300,
    600,
    900,
    1800,
    3600,
  ];

  static const int _timerNotificationId = 100;
  static const int _pomodoroNotificationId = 101;

  TimerMode _currentMode = TimerMode.timer;

  // Minuteur classique
  Timer? _activeTimer;
  Timer? _stopwatchUpdater;
  int _timerSeconds = 300;
  int _initialTimerSeconds = 300;
  bool _timerRunning = false;
  int? _timerEndEpochMs;
  List<int> _customPresets = [];

  // Chronomètre
  final Stopwatch _stopwatch = Stopwatch();
  String _stopwatchDisplay = '00:00:00';
  final List<_StopwatchLap> _laps = [];
  int _stopwatchBaseMs = 0;
  int? _stopwatchStartEpochMs;
  int _lastLapTotalMs = 0;

  // Pomodoro
  Timer? _pomodoroTimer;
  int _pomodoroWorkMin = 25;
  int _pomodoroShortMin = 5;
  int _pomodoroLongMin = 15;
  _PomodoroPhase _pomodoroPhase = _PomodoroPhase.work;
  int _pomodoroSeconds = 25 * 60;
  int _pomodoroInitialSeconds = 25 * 60;
  bool _pomodoroRunning = false;
  int? _pomodoroEndEpochMs;
  int _pomodoroCompletedSessions = 0;
  bool _pomodoroAutoContinue = false;

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
    _pomodoroTimer?.cancel();
    super.dispose();
  }

  int _currentStopwatchMs() =>
      _stopwatchBaseMs +
      (_stopwatch.isRunning ? _stopwatch.elapsedMilliseconds : 0);

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

  String _presetLabel(int seconds) {
    if (seconds < 60) return '$seconds s';
    if (seconds % 3600 == 0) return '${seconds ~/ 3600} h';
    final min = seconds ~/ 60;
    final sec = seconds % 60;
    return sec == 0 ? '$min min' : '$min m ${sec}s';
  }

  // --- Minuteur ---------------------------------------------------------

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
    if (_timerRunning && _timerSeconds > 0) {
      NotificationService.instance.scheduleTimerNotification(
        id: _timerNotificationId,
        delay: Duration(seconds: _timerSeconds),
        title: 'Minuteur terminé !',
        body:
            'Votre minuteur de ${_formatTime(_initialTimerSeconds)} est arrivé à terme.',
      );
    }
  }

  void _startTimer({bool scheduleSystemNotification = true}) {
    if (_timerSeconds <= 0) return;
    HapticsService.perform(context, HapticType.medium);

    final now = DateTime.now().millisecondsSinceEpoch;
    _timerEndEpochMs ??= now + (_timerSeconds * 1000);
    if (scheduleSystemNotification) {
      _timerEndEpochMs = now + (_timerSeconds * 1000);
      NotificationService.instance.scheduleTimerNotification(
        id: _timerNotificationId,
        delay: Duration(seconds: _timerSeconds),
        title: 'Minuteur terminé !',
        body:
            'Votre minuteur de ${_formatTime(_initialTimerSeconds)} est arrivé à terme.',
      );
    }

    setState(() => _timerRunning = true);
    _persistTimerState(running: true);

    _activeTimer?.cancel();
    _activeTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      final remainingMs =
          (_timerEndEpochMs ?? DateTime.now().millisecondsSinceEpoch) -
          DateTime.now().millisecondsSinceEpoch;
      final nextSeconds = (remainingMs / 1000).ceil().clamp(0, 24 * 3600);
      setState(() => _timerSeconds = nextSeconds);

      if (_timerSeconds <= 0) {
        _stopTimer();
        _showTimerNotification();
        HapticFeedback.heavyImpact();
      }
    });
  }

  void _stopTimer() {
    _activeTimer?.cancel();
    _timerEndEpochMs = null;
    NotificationService.instance.cancelTimerNotification(
      id: _timerNotificationId,
    );
    if (mounted) {
      setState(() => _timerRunning = false);
    }
    _persistTimerState(running: false);
  }

  void _resetTimer() {
    HapticsService.perform(context, HapticType.light);
    _stopTimer();
    setState(() => _timerSeconds = _initialTimerSeconds);
    _persistTimerState(running: false);
  }

  Future<void> _saveCurrentAsPreset() async {
    if (_initialTimerSeconds <= 0) return;
    if (_defaultPresetSeconds.contains(_initialTimerSeconds) ||
        _customPresets.contains(_initialTimerSeconds)) {
      AppFeedback.show(context, 'Cette durée est déjà dans les préréglages');
      return;
    }
    HapticsService.perform(context, HapticType.selection);
    setState(() {
      _customPresets = [..._customPresets, _initialTimerSeconds]..sort();
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      'timer_custom_presets',
      _customPresets.map((e) => e.toString()).toList(),
    );
    if (mounted) {
      AppFeedback.show(
        context,
        'Préréglage ${_presetLabel(_initialTimerSeconds)} enregistré',
        tone: FeedbackTone.success,
      );
    }
  }

  Future<void> _removeCustomPreset(int seconds) async {
    HapticsService.perform(context, HapticType.light);
    setState(() {
      _customPresets = _customPresets.where((e) => e != seconds).toList();
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      'timer_custom_presets',
      _customPresets.map((e) => e.toString()).toList(),
    );
  }

  Future<void> _showTimerNotification() async {
    await NotificationService.instance.notifyTimerComplete(
      id: _timerNotificationId,
      body:
          'Votre minuteur de ${_formatTime(_initialTimerSeconds)} est arrivé à terme.',
    );
  }

  // --- Chronomètre ------------------------------------------------------

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
      _lastLapTotalMs = 0;
      _stopwatchStartEpochMs = null;
    });
    _persistStopwatchState(running: false);
  }

  void _addLap() {
    if (!_stopwatch.isRunning) return;
    HapticsService.perform(context, HapticType.selection);
    final totalMs = _currentStopwatchMs();
    final lapMs = (totalMs - _lastLapTotalMs).clamp(0, totalMs);
    setState(() {
      _lastLapTotalMs = totalMs;
      _laps.insert(
        0,
        _StopwatchLap(index: _laps.length + 1, totalMs: totalMs, lapMs: lapMs),
      );
    });
    _persistStopwatchState(running: true);
  }

  void _copyLaps() {
    if (_laps.isEmpty) return;
    final text = _laps
        .map(
          (l) =>
              'Tour ${l.index}: ${_formatDuration(Duration(milliseconds: l.totalMs))} '
              '(+${_formatDuration(Duration(milliseconds: l.lapMs))})',
        )
        .join('\n');
    Clipboard.setData(ClipboardData(text: text));
    AppFeedback.copied(context, '${_laps.length} tour(s) copiés');
  }

  // --- Pomodoro ---------------------------------------------------------

  int _durationSecondsForPhase(_PomodoroPhase phase) => switch (phase) {
    _PomodoroPhase.work => _pomodoroWorkMin * 60,
    _PomodoroPhase.shortBreak => _pomodoroShortMin * 60,
    _PomodoroPhase.longBreak => _pomodoroLongMin * 60,
  };

  String _labelForPhase(_PomodoroPhase phase) => switch (phase) {
    _PomodoroPhase.work => 'Concentration',
    _PomodoroPhase.shortBreak => 'Pause courte',
    _PomodoroPhase.longBreak => 'Pause longue',
  };

  void _startPomodoro({bool scheduleSystemNotification = true}) {
    if (_pomodoroSeconds <= 0) return;
    HapticsService.perform(context, HapticType.medium);

    final now = DateTime.now().millisecondsSinceEpoch;
    _pomodoroEndEpochMs ??= now + (_pomodoroSeconds * 1000);
    if (scheduleSystemNotification) {
      _pomodoroEndEpochMs = now + (_pomodoroSeconds * 1000);
      NotificationService.instance.scheduleTimerNotification(
        id: _pomodoroNotificationId,
        delay: Duration(seconds: _pomodoroSeconds),
        title: 'Pomodoro : ${_labelForPhase(_pomodoroPhase)} terminée !',
        body: _pomodoroPhase == _PomodoroPhase.work
            ? 'Temps de prendre une pause.'
            : 'C’est reparti pour une session de concentration.',
      );
    }

    setState(() => _pomodoroRunning = true);
    _persistPomodoroState(running: true);

    _pomodoroTimer?.cancel();
    _pomodoroTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      final remainingMs =
          (_pomodoroEndEpochMs ?? DateTime.now().millisecondsSinceEpoch) -
          DateTime.now().millisecondsSinceEpoch;
      final nextSeconds = (remainingMs / 1000).ceil().clamp(0, 24 * 3600);
      setState(() => _pomodoroSeconds = nextSeconds);
      if (_pomodoroSeconds <= 0) {
        _onPomodoroPhaseComplete(triggerNotification: true);
      }
    });
  }

  void _stopPomodoro() {
    _pomodoroTimer?.cancel();
    _pomodoroEndEpochMs = null;
    NotificationService.instance.cancelTimerNotification(
      id: _pomodoroNotificationId,
    );
    if (mounted) {
      setState(() => _pomodoroRunning = false);
    }
    _persistPomodoroState(running: false);
  }

  void _resetPomodoro() {
    HapticsService.perform(context, HapticType.light);
    _stopPomodoro();
    final target = _durationSecondsForPhase(_pomodoroPhase);
    setState(() {
      _pomodoroInitialSeconds = target;
      _pomodoroSeconds = target;
    });
    _persistPomodoroState(running: false);
  }

  void _onPomodoroPhaseComplete({bool triggerNotification = true}) {
    final finishedPhase = _pomodoroPhase;
    _stopPomodoro();

    if (triggerNotification) {
      HapticFeedback.heavyImpact();
      NotificationService.instance.notifyTimerComplete(
        id: _pomodoroNotificationId,
        title: 'Pomodoro : ${_labelForPhase(finishedPhase)} terminée !',
        body: finishedPhase == _PomodoroPhase.work
            ? 'Temps de prendre une pause.'
            : 'Prêt pour la prochaine session de concentration.',
      );
    }

    _PomodoroPhase nextPhase;
    var nextSessions = _pomodoroCompletedSessions;
    if (finishedPhase == _PomodoroPhase.work) {
      nextSessions++;
      nextPhase = nextSessions % 4 == 0
          ? _PomodoroPhase.longBreak
          : _PomodoroPhase.shortBreak;
    } else {
      nextPhase = _PomodoroPhase.work;
    }

    final nextDuration = _durationSecondsForPhase(nextPhase);
    setState(() {
      _pomodoroCompletedSessions = nextSessions;
      _pomodoroPhase = nextPhase;
      _pomodoroInitialSeconds = nextDuration;
      _pomodoroSeconds = nextDuration;
    });
    _persistPomodoroState(running: false);

    if (_pomodoroAutoContinue && triggerNotification && mounted) {
      _startPomodoro();
    }
  }

  Future<void> _showPomodoroConfigSheet() async {
    var work = _pomodoroWorkMin;
    var shortBreak = _pomodoroShortMin;
    var longBreak = _pomodoroLongMin;

    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setModalState) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Durées Pomodoro',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                Text('Concentration : $work min'),
                Slider(
                  value: work.toDouble(),
                  min: 5,
                  max: 90,
                  divisions: 17,
                  label: '$work min',
                  onChanged: (v) => setModalState(() => work = v.round()),
                ),
                Text('Pause courte : $shortBreak min'),
                Slider(
                  value: shortBreak.toDouble(),
                  min: 1,
                  max: 30,
                  divisions: 29,
                  label: '$shortBreak min',
                  onChanged: (v) => setModalState(() => shortBreak = v.round()),
                ),
                Text('Pause longue : $longBreak min'),
                Slider(
                  value: longBreak.toDouble(),
                  min: 5,
                  max: 45,
                  divisions: 8,
                  label: '$longBreak min',
                  onChanged: (v) => setModalState(() => longBreak = v.round()),
                ),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: () => Navigator.pop(sheetContext, true),
                  icon: const Icon(Icons.check_rounded),
                  label: const Text('Appliquer'),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    if (saved == true && mounted) {
      _stopPomodoro();
      setState(() {
        _pomodoroWorkMin = work;
        _pomodoroShortMin = shortBreak;
        _pomodoroLongMin = longBreak;
        final next = _durationSecondsForPhase(_pomodoroPhase);
        _pomodoroInitialSeconds = next;
        _pomodoroSeconds = next;
      });
      await _persistPomodoroState(running: false);
    }
  }

  // --- Dialogs & Persistance --------------------------------------------

  Future<void> _showCustomDurationDialog() async {
    var minText = (_initialTimerSeconds ~/ 60).toString();
    var secText = (_initialTimerSeconds % 60).toString().padLeft(2, '0');

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
                    child: TextFormField(
                      initialValue: minText,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: const InputDecoration(
                        labelText: 'Minutes',
                        suffixText: 'min',
                      ),
                      onChanged: (v) => minText = v,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      initialValue: secText,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: const InputDecoration(
                        labelText: 'Secondes',
                        suffixText: 's',
                      ),
                      onChanged: (v) => secText = v,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: () {
                  final m = int.tryParse(minText) ?? 0;
                  final s = int.tryParse(secText) ?? 0;
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

  Future<void> _persistTimerState({required bool running}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('timer_running', running);
    await prefs.setInt('timer_initial', _initialTimerSeconds);
    await prefs.setInt('timer_remaining', _timerSeconds);
    if (running && _timerEndEpochMs != null) {
      await prefs.setInt('timer_end_epoch', _timerEndEpochMs!);
    } else {
      await prefs.remove('timer_end_epoch');
    }
  }

  Future<void> _persistStopwatchState({required bool running}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('stopwatch_running', running);
    await prefs.setInt('stopwatch_base_ms', _stopwatchBaseMs);
    await prefs.setInt('stopwatch_last_lap_ms', _lastLapTotalMs);
    await prefs.setString(
      'stopwatch_laps_v2',
      json.encode(_laps.map((e) => e.toJson()).toList()),
    );
    if (running && _stopwatchStartEpochMs != null) {
      await prefs.setInt('stopwatch_start_epoch', _stopwatchStartEpochMs!);
    } else {
      await prefs.remove('stopwatch_start_epoch');
    }
  }

  Future<void> _persistPomodoroState({required bool running}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('pomodoro_work_min', _pomodoroWorkMin);
    await prefs.setInt('pomodoro_short_min', _pomodoroShortMin);
    await prefs.setInt('pomodoro_long_min', _pomodoroLongMin);
    await prefs.setInt('pomodoro_phase', _pomodoroPhase.index);
    await prefs.setInt('pomodoro_completed_count', _pomodoroCompletedSessions);
    await prefs.setBool('pomodoro_auto_continue', _pomodoroAutoContinue);
    await prefs.setBool('pomodoro_running', running);
    await prefs.setInt('pomodoro_remaining', _pomodoroSeconds);
    if (running && _pomodoroEndEpochMs != null) {
      await prefs.setInt('pomodoro_end_epoch', _pomodoroEndEpochMs!);
    } else {
      await prefs.remove('pomodoro_end_epoch');
    }
  }

  Future<void> _restoreState() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;

    // Presets perso
    final savedPresets = prefs.getStringList('timer_custom_presets') ?? [];
    final parsedPresets =
        savedPresets
            .map(int.tryParse)
            .whereType<int>()
            .where((e) => e > 0)
            .toList()
          ..sort();

    // Minuteur
    final wasTimerRunning = prefs.getBool('timer_running') ?? false;
    _initialTimerSeconds =
        prefs.getInt('timer_initial') ?? _initialTimerSeconds;
    final savedEnd = prefs.getInt('timer_end_epoch');
    final savedRemaining = prefs.getInt('timer_remaining');

    if (wasTimerRunning && savedEnd != null) {
      final remainingMs = savedEnd - DateTime.now().millisecondsSinceEpoch;
      if (remainingMs > 0) {
        setState(() {
          _customPresets = parsedPresets;
          _timerSeconds = (remainingMs / 1000).ceil();
          _timerEndEpochMs = savedEnd;
        });
        _startTimer(scheduleSystemNotification: false);
      } else {
        setState(() {
          _customPresets = parsedPresets;
          _timerSeconds = 0;
          _timerRunning = false;
        });
        await _persistTimerState(running: false);
      }
    } else {
      setState(() {
        _customPresets = parsedPresets;
        _timerSeconds = savedRemaining ?? _initialTimerSeconds;
      });
    }

    // Chronomètre & Tours
    _stopwatchBaseMs = prefs.getInt('stopwatch_base_ms') ?? 0;
    _lastLapTotalMs = prefs.getInt('stopwatch_last_lap_ms') ?? 0;
    final rawLaps = prefs.getString('stopwatch_laps_v2');
    if (rawLaps != null && rawLaps.isNotEmpty) {
      try {
        final decoded = json.decode(rawLaps);
        if (decoded is List) {
          _laps
            ..clear()
            ..addAll(
              decoded.whereType<Map>().map(
                (m) => _StopwatchLap.fromJson(
                  m.map((k, v) => MapEntry(k.toString(), v)),
                ),
              ),
            );
        }
      } catch (_) {}
    }

    final wasStopwatchRunning = prefs.getBool('stopwatch_running') ?? false;
    final startEpoch = prefs.getInt('stopwatch_start_epoch');
    if (wasStopwatchRunning && startEpoch != null) {
      final now = DateTime.now().millisecondsSinceEpoch;
      _stopwatchBaseMs += now - startEpoch;
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

    // Pomodoro
    _pomodoroWorkMin = prefs.getInt('pomodoro_work_min') ?? 25;
    _pomodoroShortMin = prefs.getInt('pomodoro_short_min') ?? 5;
    _pomodoroLongMin = prefs.getInt('pomodoro_long_min') ?? 15;
    final phaseIdx = (prefs.getInt('pomodoro_phase') ?? 0).clamp(
      0,
      _PomodoroPhase.values.length - 1,
    );
    _pomodoroPhase = _PomodoroPhase.values[phaseIdx];
    _pomodoroCompletedSessions = prefs.getInt('pomodoro_completed_count') ?? 0;
    _pomodoroAutoContinue = prefs.getBool('pomodoro_auto_continue') ?? false;
    _pomodoroInitialSeconds = _durationSecondsForPhase(_pomodoroPhase);

    final wasPomodoroRunning = prefs.getBool('pomodoro_running') ?? false;
    final pomEnd = prefs.getInt('pomodoro_end_epoch');
    final pomRemaining = prefs.getInt('pomodoro_remaining');

    if (wasPomodoroRunning && pomEnd != null) {
      final remMs = pomEnd - DateTime.now().millisecondsSinceEpoch;
      if (remMs > 0) {
        setState(() {
          _pomodoroSeconds = (remMs / 1000).ceil();
          _pomodoroEndEpochMs = pomEnd;
        });
        _startPomodoro(scheduleSystemNotification: false);
      } else {
        _onPomodoroPhaseComplete(triggerNotification: false);
      }
    } else {
      setState(() {
        _pomodoroSeconds = pomRemaining ?? _pomodoroInitialSeconds;
      });
    }
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
              showSelectedIcon: false,
              segments: const [
                ButtonSegment(
                  value: TimerMode.timer,
                  icon: Icon(Icons.timer_rounded, size: 18),
                  label: Text('Minuteur'),
                ),
                ButtonSegment(
                  value: TimerMode.stopwatch,
                  icon: Icon(Icons.timer_outlined, size: 18),
                  label: Text('Chrono'),
                ),
                ButtonSegment(
                  value: TimerMode.pomodoro,
                  icon: Icon(Icons.self_improvement_rounded, size: 18),
                  label: Text('Pomodoro'),
                ),
              ],
              selected: {_currentMode},
              onSelectionChanged: (newSelection) {
                HapticsService.perform(context, HapticType.selection);
                setState(() => _currentMode = newSelection.first);
              },
            ),
          ),
          Expanded(
            child: switch (_currentMode) {
              TimerMode.timer => _buildTimerView(),
              TimerMode.stopwatch => _buildStopwatchView(),
              TimerMode.pomodoro => _buildPomodoroView(),
            },
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
                          strokeCap: StrokeCap.round,
                          trackGap: 6,
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
                  runSpacing: 8,
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
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Durées prédéfinies',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                      TextButton.icon(
                        onPressed: _saveCurrentAsPreset,
                        icon: const Icon(Icons.bookmark_add_rounded, size: 18),
                        label: const Text('+ Preset'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      for (final sec in _defaultPresetSeconds)
                        _buildPresetChip(_presetLabel(sec), sec),
                      for (final customSec in _customPresets)
                        InputChip(
                          label: Text(_presetLabel(customSec)),
                          selected:
                              _initialTimerSeconds == customSec &&
                              _timerSeconds == customSec,
                          onSelected: (_) => _setTimerDuration(customSec),
                          onDeleted: () => _removeCustomPreset(customSec),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
          _ExpressiveTransportBar(
            running: _timerRunning,
            onToggle: _timerRunning
                ? _stopTimer
                : (_timerSeconds > 0 ? () => _startTimer() : null),
            secondary: [
              _ExpressiveSecondaryButton(
                icon: Icons.refresh_rounded,
                tooltip: 'Réinitialiser',
                backgroundColor: colorScheme.secondaryContainer,
                foregroundColor: colorScheme.onSecondaryContainer,
                onPressed: _resetTimer,
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
          _ExpressiveTransportBar(
            running: _stopwatch.isRunning,
            onToggle: _stopwatch.isRunning ? _stopStopwatch : _startStopwatch,
            secondary: [
              _ExpressiveSecondaryButton(
                icon: Icons.flag_rounded,
                tooltip: 'Tour',
                backgroundColor: colorScheme.secondaryContainer,
                foregroundColor: colorScheme.onSecondaryContainer,
                onPressed: _stopwatch.isRunning ? _addLap : null,
              ),
              _ExpressiveSecondaryButton(
                icon: Icons.refresh_rounded,
                tooltip: 'Réinitialiser',
                backgroundColor: colorScheme.surfaceContainerHigh,
                foregroundColor: colorScheme.onSurface,
                onPressed: _resetStopwatch,
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
                      Expanded(
                        child: Text(
                          'Tours enregistrés (${_laps.length})',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                      IconButton(
                        onPressed: _copyLaps,
                        icon: const Icon(Icons.copy_rounded, size: 18),
                        tooltip: 'Copier les tours',
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
                          Text(
                            '#${lap.index}',
                            style: Theme.of(context).textTheme.labelLarge
                                ?.copyWith(
                                  color: colorScheme.primary,
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _formatDuration(
                                Duration(milliseconds: lap.totalMs),
                              ),
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(fontFamily: 'monospace'),
                            ),
                          ),
                          Text(
                            '+${_formatDuration(Duration(milliseconds: lap.lapMs))}',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  fontFamily: 'monospace',
                                  color: colorScheme.onSurfaceVariant,
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

  Widget _buildPomodoroView() {
    final colorScheme = Theme.of(context).colorScheme;
    final progress = _pomodoroInitialSeconds > 0
        ? ((_pomodoroInitialSeconds - _pomodoroSeconds) /
                  _pomodoroInitialSeconds)
              .clamp(0.0, 1.0)
        : 0.0;
    final isWork = _pomodoroPhase == _PomodoroPhase.work;
    final cycleIndex = (_pomodoroCompletedSessions % 4) + (isWork ? 1 : 0);

    return SingleChildScrollView(
      physics: const ClampingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
      child: Column(
        children: [
          ExpressiveCard.hero(
            color:
                (isWork
                        ? colorScheme.primaryContainer
                        : colorScheme.tertiaryContainer)
                    .withValues(alpha: 0.65),
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 18),
            child: Column(
              children: [
                StatusBadge(
                  label: _labelForPhase(_pomodoroPhase),
                  icon: isWork
                      ? Icons.psychology_rounded
                      : Icons.coffee_rounded,
                  tone: isWork ? BadgeTone.accent : BadgeTone.success,
                ),
                const SizedBox(height: 14),
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
                          strokeCap: StrokeCap.round,
                          trackGap: 6,
                          backgroundColor: colorScheme.surface.withValues(
                            alpha: 0.5,
                          ),
                          valueColor: AlwaysStoppedAnimation(
                            isWork ? colorScheme.primary : colorScheme.tertiary,
                          ),
                        ),
                      ),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            _formatTime(_pomodoroSeconds),
                            style: Theme.of(context).textTheme.displayMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  fontFamily: 'monospace',
                                ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Cycle $cycleIndex/4 · $_pomodoroCompletedSessions terminée(s)',
                            style: Theme.of(context).textTheme.labelMedium
                                ?.copyWith(color: colorScheme.onSurfaceVariant),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 10,
                  runSpacing: 8,
                  alignment: WrapAlignment.center,
                  children: [
                    ActionChip(
                      onPressed: _showPomodoroConfigSheet,
                      avatar: const Icon(Icons.tune_rounded, size: 16),
                      label: Text(
                        '$_pomodoroWorkMin / $_pomodoroShortMin / $_pomodoroLongMin min',
                      ),
                    ),
                    FilterChip(
                      label: const Text('Enchaîner'),
                      selected: _pomodoroAutoContinue,
                      onSelected: (v) async {
                        setState(() => _pomodoroAutoContinue = v);
                        await _persistPomodoroState(running: _pomodoroRunning);
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _ExpressiveTransportBar(
            running: _pomodoroRunning,
            onToggle: _pomodoroRunning ? _stopPomodoro : () => _startPomodoro(),
            secondary: [
              _ExpressiveSecondaryButton(
                icon: Icons.skip_next_rounded,
                tooltip: 'Phase suivante',
                backgroundColor: colorScheme.secondaryContainer,
                foregroundColor: colorScheme.onSecondaryContainer,
                onPressed: () =>
                    _onPomodoroPhaseComplete(triggerNotification: false),
              ),
              _ExpressiveSecondaryButton(
                icon: Icons.refresh_rounded,
                tooltip: 'Réinitialiser',
                backgroundColor: colorScheme.surfaceContainerHigh,
                foregroundColor: colorScheme.onSurface,
                onPressed: _resetPomodoro,
              ),
            ],
          ),
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

class _ExpressiveTransportBar extends StatelessWidget {
  final bool running;
  final VoidCallback? onToggle;
  final List<_ExpressiveSecondaryButton> secondary;

  const _ExpressiveTransportBar({
    required this.running,
    required this.onToggle,
    required this.secondary,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final lowResource = context.select<SettingsProvider, bool>(
      (s) => s.lowResourceMode,
    );
    final bg = onToggle == null
        ? scheme.surfaceContainerHighest
        : (running ? scheme.errorContainer : scheme.primary);
    final fg = onToggle == null
        ? scheme.onSurfaceVariant
        : (running ? scheme.onErrorContainer : scheme.onPrimary);
    final icon = Icon(
      running ? Icons.pause_rounded : Icons.play_arrow_rounded,
      key: ValueKey(running),
      size: 34,
      color: fg,
    );

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Semantics(
          button: true,
          label: running ? 'Mettre en pause' : 'Démarrer',
          child: AnimatedContainer(
            duration: lowResource ? Duration.zero : ExpressiveMotion.medium2,
            curve: ExpressiveMotion.spatialMorph,
            width: running ? 104 : 136,
            height: 68,
            child: Material(
              color: bg,
              borderRadius: BorderRadius.circular(running ? 20 : 34),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: onToggle,
                child: Center(
                  child: lowResource
                      ? icon
                      : AnimatedSwitcher(
                          duration: ExpressiveMotion.short4,
                          switchInCurve: ExpressiveMotion.springStandard,
                          transitionBuilder: (child, anim) =>
                              ScaleTransition(scale: anim, child: child),
                          child: icon,
                        ),
                ),
              ),
            ),
          ),
        ),
        ...secondary,
      ],
    );
  }
}

class _ExpressiveSecondaryButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final Color backgroundColor;
  final Color foregroundColor;
  final VoidCallback? onPressed;

  const _ExpressiveSecondaryButton({
    required this.icon,
    required this.tooltip,
    required this.backgroundColor,
    required this.foregroundColor,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    return Opacity(
      opacity: enabled ? 1.0 : 0.45,
      child: Tooltip(
        message: tooltip,
        child: SizedBox(
          width: 64,
          height: 68,
          child: Material(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(22),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: onPressed,
              child: Center(
                child: Icon(icon, color: foregroundColor, size: 24),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
