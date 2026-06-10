import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final settingsProvider = NotifierProvider<SettingsController, SettingsState>(SettingsController.new);

class SettingsController extends Notifier<SettingsState> {
  @override
  SettingsState build() => const SettingsState(themeMode: ThemeMode.system);

  void setThemeMode(ThemeMode mode) {
    state = state.copyWith(themeMode: mode);
  }
}

class SettingsState {
  const SettingsState({required this.themeMode});

  final ThemeMode themeMode;

  SettingsState copyWith({ThemeMode? themeMode}) {
    return SettingsState(themeMode: themeMode ?? this.themeMode);
  }
}

