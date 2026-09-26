// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get appTitle => '小云的灯笼';

  @override
  String get grownUps => '家长专区';

  @override
  String get gateTitle => '家长专区';

  @override
  String gateQuestion(String a, String b) {
    return '请输入 $a 乘以 $b 的结果';
  }

  @override
  String get gateClear => '清除';

  @override
  String get gateOk => '确定';

  @override
  String get numberWord2 => '二';

  @override
  String get numberWord3 => '三';

  @override
  String get numberWord4 => '四';

  @override
  String get numberWord5 => '五';

  @override
  String get numberWord6 => '六';

  @override
  String get numberWord7 => '七';

  @override
  String get numberWord8 => '八';

  @override
  String get numberWord9 => '九';

  @override
  String get parentTitle => '家长专区';

  @override
  String get parentBack => '回去玩';

  @override
  String get sectionLanguage => '语言';

  @override
  String get languageAuto => '跟随设备';

  @override
  String get languageEn => 'English';

  @override
  String get languageZh => '中文';

  @override
  String get bookLanguage => '故事朗读';

  @override
  String get bookLanguageApp => '跟随应用语言';

  @override
  String get bookLanguageBoth => '双语（先应用语言）';

  @override
  String get sectionSound => '声音';

  @override
  String get voiceVolume => '语音音量';

  @override
  String get musicVolume => '音乐音量';

  @override
  String get effectsVolume => '音效音量';

  @override
  String get sectionChild => '您的孩子';

  @override
  String get childAge => '孩子的年龄';

  @override
  String childAgeValue(int age) {
    return '$age 岁';
  }

  @override
  String get childAgeHelp => '标记为 4 岁以上的游戏会在孩子满 4 岁后出现。这是为了合适，不是锁定。';

  @override
  String get sectionActivities => '游戏';

  @override
  String get activitiesHelp => '如果孩子觉得某个游戏太难，可以把它隐藏。';

  @override
  String get activityNoGoal => '一个图画和声音的游戏——打开看看它让孩子做什么。';

  @override
  String get sectionBreak => '休息提醒';

  @override
  String get breakHelp => '一轮结束后，小云会建议休息。绝不会打断游戏。';

  @override
  String get breakOff => '关闭';

  @override
  String breakMinutes(int minutes) {
    return '$minutes 分钟';
  }

  @override
  String get sectionPurchase => '完整版';

  @override
  String get purchasePitch => '解锁全部 12 个游戏和 8 个故事章节。一次购买，永久使用。支持家人共享。';

  @override
  String purchaseButton(String price) {
    return '全部解锁 — $price';
  }

  @override
  String get purchaseOwned => '谢谢您！所有内容已解锁。';

  @override
  String get allFreeNote => '测试版：所有内容已解锁。';

  @override
  String get purchaseRestore => '恢复购买';

  @override
  String get purchaseUnavailable => 'App Store 暂时无法使用，请稍后再试。';

  @override
  String get purchasePending => '正在等待 App Store…';

  @override
  String get purchaseFailed => '购买没有完成，没有扣费。';

  @override
  String get sectionProgress => '孩子玩过的游戏';

  @override
  String get progressNone => '还没有玩过。';

  @override
  String progressLine(String name, int count) {
    return '$name：玩了 $count 次';
  }

  @override
  String chaptersDone(int count, int total) {
    return '找到的故事灯光：$count / $total';
  }

  @override
  String get sectionAbout => '关于';

  @override
  String get privacyTitle => '隐私';

  @override
  String get privacyBody =>
      '小云的灯笼不收集任何信息。没有账号、没有统计、没有广告、没有追踪，除 App Store 购买本身外不联网。进度只保存在这台设备上。';

  @override
  String get creditsTitle => '致谢';

  @override
  String get creditsBody => '中文字体使用 Noto Sans SC（SIL 开源字体许可）。';

  @override
  String get devUnlock => '开发者：全部解锁（仅调试版本）';

  @override
  String get errorContent => '加载时出了问题，请重新打开应用。';
}
