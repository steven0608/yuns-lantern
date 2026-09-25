// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Yun\'s Lantern';

  @override
  String get grownUps => 'For grown-ups';

  @override
  String get gateTitle => 'For grown-ups';

  @override
  String gateQuestion(String a, String b) {
    return 'Enter the result of $a times $b';
  }

  @override
  String get gateClear => 'Clear';

  @override
  String get gateOk => 'OK';

  @override
  String get numberWord2 => 'two';

  @override
  String get numberWord3 => 'three';

  @override
  String get numberWord4 => 'four';

  @override
  String get numberWord5 => 'five';

  @override
  String get numberWord6 => 'six';

  @override
  String get numberWord7 => 'seven';

  @override
  String get numberWord8 => 'eight';

  @override
  String get numberWord9 => 'nine';

  @override
  String get parentTitle => 'Parent area';

  @override
  String get parentBack => 'Back to play';

  @override
  String get sectionLanguage => 'Language';

  @override
  String get languageAuto => 'Match device';

  @override
  String get languageEn => 'English';

  @override
  String get languageZh => '中文';

  @override
  String get bookLanguage => 'Story narration';

  @override
  String get bookLanguageApp => 'Same as the app';

  @override
  String get bookLanguageBoth => 'Both languages (app language first)';

  @override
  String get sectionSound => 'Sound';

  @override
  String get voiceVolume => 'Voice volume';

  @override
  String get musicVolume => 'Music volume';

  @override
  String get effectsVolume => 'Sound effects volume';

  @override
  String get sectionChild => 'Your child';

  @override
  String get childAge => 'Child\'s age';

  @override
  String childAgeValue(int age) {
    return '$age years';
  }

  @override
  String get childAgeHelp =>
      'Activities marked 4+ appear once your child is 4. This is about fit, not a lock.';

  @override
  String get sectionActivities => 'Activities';

  @override
  String get activitiesHelp =>
      'Hide any activity your child finds frustrating.';

  @override
  String get sectionBreak => 'Break reminder';

  @override
  String get breakHelp =>
      'Yun suggests a break after a round ends. It never interrupts a game.';

  @override
  String get breakOff => 'Off';

  @override
  String breakMinutes(int minutes) {
    return '$minutes min';
  }

  @override
  String get sectionPurchase => 'Full version';

  @override
  String get purchasePitch =>
      'Unlock all 12 activities and all 8 story chapters. One purchase, forever. Family Sharing included.';

  @override
  String purchaseButton(String price) {
    return 'Unlock everything — $price';
  }

  @override
  String get purchaseOwned => 'Thank you! Everything is unlocked.';

  @override
  String get allFreeNote => 'Test build: everything is unlocked.';

  @override
  String get purchaseRestore => 'Restore purchases';

  @override
  String get purchaseUnavailable =>
      'The App Store isn\'t available right now. Please try again later.';

  @override
  String get purchasePending => 'Waiting for the App Store…';

  @override
  String get purchaseFailed =>
      'The purchase didn\'t go through. Nothing was charged.';

  @override
  String get sectionProgress => 'What your child has played';

  @override
  String get progressNone => 'Nothing yet.';

  @override
  String progressLine(String name, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count times',
      one: 'once',
    );
    return '$name: played $_temp0';
  }

  @override
  String chaptersDone(int count, int total) {
    return 'Story lights found: $count of $total';
  }

  @override
  String get sectionAbout => 'About';

  @override
  String get privacyTitle => 'Privacy';

  @override
  String get privacyBody =>
      'Yun\'s Lantern collects nothing. No accounts, no analytics, no ads, no tracking, no internet connection except the App Store purchase itself. Progress is stored only on this device.';

  @override
  String get creditsTitle => 'Credits';

  @override
  String get creditsBody =>
      'Chinese text set in Noto Sans SC (SIL Open Font License).';

  @override
  String get devUnlock => 'Developer: unlock everything (debug builds only)';

  @override
  String get errorContent =>
      'Something went wrong loading the app. Please restart it.';
}
