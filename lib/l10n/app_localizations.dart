import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('zh'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Yun\'s Lantern'**
  String get appTitle;

  /// No description provided for @grownUps.
  ///
  /// In en, this message translates to:
  /// **'For grown-ups'**
  String get grownUps;

  /// No description provided for @gateTitle.
  ///
  /// In en, this message translates to:
  /// **'For grown-ups'**
  String get gateTitle;

  /// No description provided for @gateQuestion.
  ///
  /// In en, this message translates to:
  /// **'Enter the result of {a} times {b}'**
  String gateQuestion(String a, String b);

  /// No description provided for @gateClear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get gateClear;

  /// No description provided for @gateOk.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get gateOk;

  /// No description provided for @numberWord2.
  ///
  /// In en, this message translates to:
  /// **'two'**
  String get numberWord2;

  /// No description provided for @numberWord3.
  ///
  /// In en, this message translates to:
  /// **'three'**
  String get numberWord3;

  /// No description provided for @numberWord4.
  ///
  /// In en, this message translates to:
  /// **'four'**
  String get numberWord4;

  /// No description provided for @numberWord5.
  ///
  /// In en, this message translates to:
  /// **'five'**
  String get numberWord5;

  /// No description provided for @numberWord6.
  ///
  /// In en, this message translates to:
  /// **'six'**
  String get numberWord6;

  /// No description provided for @numberWord7.
  ///
  /// In en, this message translates to:
  /// **'seven'**
  String get numberWord7;

  /// No description provided for @numberWord8.
  ///
  /// In en, this message translates to:
  /// **'eight'**
  String get numberWord8;

  /// No description provided for @numberWord9.
  ///
  /// In en, this message translates to:
  /// **'nine'**
  String get numberWord9;

  /// No description provided for @parentTitle.
  ///
  /// In en, this message translates to:
  /// **'Parent area'**
  String get parentTitle;

  /// No description provided for @parentBack.
  ///
  /// In en, this message translates to:
  /// **'Back to play'**
  String get parentBack;

  /// No description provided for @sectionLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get sectionLanguage;

  /// No description provided for @languageAuto.
  ///
  /// In en, this message translates to:
  /// **'Match device'**
  String get languageAuto;

  /// No description provided for @languageEn.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEn;

  /// No description provided for @languageZh.
  ///
  /// In en, this message translates to:
  /// **'中文'**
  String get languageZh;

  /// No description provided for @bookLanguage.
  ///
  /// In en, this message translates to:
  /// **'Story narration'**
  String get bookLanguage;

  /// No description provided for @bookLanguageApp.
  ///
  /// In en, this message translates to:
  /// **'Same as the app'**
  String get bookLanguageApp;

  /// No description provided for @bookLanguageBoth.
  ///
  /// In en, this message translates to:
  /// **'Both languages (app language first)'**
  String get bookLanguageBoth;

  /// No description provided for @sectionSound.
  ///
  /// In en, this message translates to:
  /// **'Sound'**
  String get sectionSound;

  /// No description provided for @voiceVolume.
  ///
  /// In en, this message translates to:
  /// **'Voice volume'**
  String get voiceVolume;

  /// No description provided for @musicVolume.
  ///
  /// In en, this message translates to:
  /// **'Music volume'**
  String get musicVolume;

  /// No description provided for @effectsVolume.
  ///
  /// In en, this message translates to:
  /// **'Sound effects volume'**
  String get effectsVolume;

  /// No description provided for @sectionChild.
  ///
  /// In en, this message translates to:
  /// **'Your child'**
  String get sectionChild;

  /// No description provided for @childAge.
  ///
  /// In en, this message translates to:
  /// **'Child\'s age'**
  String get childAge;

  /// No description provided for @childAgeValue.
  ///
  /// In en, this message translates to:
  /// **'{age} years'**
  String childAgeValue(int age);

  /// No description provided for @childAgeHelp.
  ///
  /// In en, this message translates to:
  /// **'Activities marked 4+ appear once your child is 4. This is about fit, not a lock.'**
  String get childAgeHelp;

  /// No description provided for @sectionActivities.
  ///
  /// In en, this message translates to:
  /// **'Activities'**
  String get sectionActivities;

  /// No description provided for @activitiesHelp.
  ///
  /// In en, this message translates to:
  /// **'Hide any activity your child finds frustrating.'**
  String get activitiesHelp;

  /// No description provided for @activityNoGoal.
  ///
  /// In en, this message translates to:
  /// **'A picture-and-sound game — open it to see what it asks.'**
  String get activityNoGoal;

  /// No description provided for @sectionBreak.
  ///
  /// In en, this message translates to:
  /// **'Break reminder'**
  String get sectionBreak;

  /// No description provided for @breakHelp.
  ///
  /// In en, this message translates to:
  /// **'Yun suggests a break after a round ends. It never interrupts a game.'**
  String get breakHelp;

  /// No description provided for @breakOff.
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get breakOff;

  /// No description provided for @breakMinutes.
  ///
  /// In en, this message translates to:
  /// **'{minutes} min'**
  String breakMinutes(int minutes);

  /// No description provided for @sectionPurchase.
  ///
  /// In en, this message translates to:
  /// **'Full version'**
  String get sectionPurchase;

  /// No description provided for @purchasePitch.
  ///
  /// In en, this message translates to:
  /// **'Unlock all 12 activities and all 8 story chapters. One purchase, forever. Family Sharing included.'**
  String get purchasePitch;

  /// No description provided for @purchaseButton.
  ///
  /// In en, this message translates to:
  /// **'Unlock everything — {price}'**
  String purchaseButton(String price);

  /// No description provided for @purchaseOwned.
  ///
  /// In en, this message translates to:
  /// **'Thank you! Everything is unlocked.'**
  String get purchaseOwned;

  /// No description provided for @allFreeNote.
  ///
  /// In en, this message translates to:
  /// **'Test build: everything is unlocked.'**
  String get allFreeNote;

  /// No description provided for @purchaseRestore.
  ///
  /// In en, this message translates to:
  /// **'Restore purchases'**
  String get purchaseRestore;

  /// No description provided for @purchaseUnavailable.
  ///
  /// In en, this message translates to:
  /// **'The App Store isn\'t available right now. Please try again later.'**
  String get purchaseUnavailable;

  /// No description provided for @purchasePending.
  ///
  /// In en, this message translates to:
  /// **'Waiting for the App Store…'**
  String get purchasePending;

  /// No description provided for @purchaseFailed.
  ///
  /// In en, this message translates to:
  /// **'The purchase didn\'t go through. Nothing was charged.'**
  String get purchaseFailed;

  /// No description provided for @sectionProgress.
  ///
  /// In en, this message translates to:
  /// **'What your child has played'**
  String get sectionProgress;

  /// No description provided for @progressNone.
  ///
  /// In en, this message translates to:
  /// **'Nothing yet.'**
  String get progressNone;

  /// No description provided for @progressLine.
  ///
  /// In en, this message translates to:
  /// **'{name}: played {count, plural, =1{once} other{{count} times}}'**
  String progressLine(String name, int count);

  /// No description provided for @chaptersDone.
  ///
  /// In en, this message translates to:
  /// **'Story lights found: {count} of {total}'**
  String chaptersDone(int count, int total);

  /// No description provided for @sectionAbout.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get sectionAbout;

  /// No description provided for @privacyTitle.
  ///
  /// In en, this message translates to:
  /// **'Privacy'**
  String get privacyTitle;

  /// No description provided for @privacyBody.
  ///
  /// In en, this message translates to:
  /// **'Yun\'s Lantern collects nothing. No accounts, no analytics, no ads, no tracking, no internet connection except the App Store purchase itself. Progress is stored only on this device.'**
  String get privacyBody;

  /// No description provided for @creditsTitle.
  ///
  /// In en, this message translates to:
  /// **'Credits'**
  String get creditsTitle;

  /// No description provided for @creditsBody.
  ///
  /// In en, this message translates to:
  /// **'Chinese text set in Noto Sans SC (SIL Open Font License).'**
  String get creditsBody;

  /// No description provided for @devUnlock.
  ///
  /// In en, this message translates to:
  /// **'Developer: unlock everything (debug builds only)'**
  String get devUnlock;

  /// No description provided for @errorContent.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong loading the app. Please restart it.'**
  String get errorContent;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
