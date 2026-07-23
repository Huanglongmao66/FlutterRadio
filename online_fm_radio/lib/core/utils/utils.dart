import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';

/// 格式化时长为 HH:MM:SS 或 MM:SS 格式
///
/// [duration] - 要格式化的时长
///
/// 超过1小时显示 HH:MM:SS，否则显示 MM:SS
String formatDuration(Duration duration) {
  if (duration.inSeconds <= 0) {
    return '00:00';
  }

  final hours = duration.inHours;
  final minutes = duration.inMinutes.remainder(60);
  final seconds = duration.inSeconds.remainder(60);

  if (hours > 0) {
    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
}

/// 格式化定时关闭时长为可读字符串
///
/// [duration] - 定时时长，为空或零返回 'Off'
///
/// 超过60分钟显示 'X h Y min' 或 'X h'，否则显示 'X min'
String formatSleepTimer(Duration? duration) {
  if (duration == null || duration.inSeconds <= 0) {
    return 'Off';
  }

  final minutes = duration.inMinutes;

  if (minutes >= 60) {
    final hours = minutes ~/ 60;
    final remainingMinutes = minutes % 60;
    if (remainingMinutes > 0) {
      return '$hours h $remainingMinutes min';
    }
    return '$hours h';
  }

  return '$minutes min';
}

/// 格式化时间为 HH:MM 格式
///
/// [time] - 要格式化的时间
String formatTime(DateTime time) {
  return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
}

/// 格式化日期时间为 YYYY-MM-DD HH:MM 格式
///
/// [dateTime] - 要格式化的日期时间
String formatDateTime(DateTime dateTime) {
  return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')} ${formatTime(dateTime)}';
}

/// 截断字符串到指定长度，超出部分用省略号代替
///
/// [str] - 原始字符串
/// [maxLength] - 最大长度
String truncateString(String str, int maxLength) {
  if (str.length <= maxLength) {
    return str;
  }
  return '${str.substring(0, maxLength)}...';
}

/// 首字母大写，其余字母小写
///
/// [str] - 原始字符串
String capitalize(String str) {
  if (str.isEmpty) return str;
  return str[0].toUpperCase() + str.substring(1).toLowerCase();
}

/// 每个单词首字母大写
///
/// [str] - 原始字符串
String capitalizeEachWord(String str) {
  if (str.isEmpty) return str;
  return str.split(' ').map(capitalize).join(' ');
}

/// 移除字符串中的特殊字符（保留字母、数字和空格）
///
/// [str] - 原始字符串
String removeSpecialCharacters(String str) {
  return str.replaceAll(RegExp(r'[^\w\s]'), '');
}

/// 清理文件名中的非法字符，替换为下划线
///
/// [fileName] - 原始文件名
String sanitizeFileName(String fileName) {
  return fileName.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
}

/// 验证 URL 是否有效
///
/// [url] - 要验证的 URL
bool isValidUrl(String url) {
  try {
    Uri.parse(url);
    return true;
  } catch (_) {
    return false;
  }
}

/// 验证邮箱格式是否有效
///
/// [email] - 要验证的邮箱地址
bool isValidEmail(String email) {
  final regex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
  return regex.hasMatch(email);
}

/// 生成唯一 ID（基于时间戳）
///
/// 返回格式：{毫秒时间戳}_{微秒时间戳取模}
String generateId() {
  return '${DateTime.now().millisecondsSinceEpoch}_${DateTime.now().microsecondsSinceEpoch % 1000000}';
}

/// 根据出生日期计算年龄
///
/// [birthDate] - 出生日期
int calculateAge(DateTime birthDate) {
  final now = DateTime.now();
  int age = now.year - birthDate.year;
  if (now.month < birthDate.month ||
      (now.month == birthDate.month && now.day < birthDate.day)) {
    age--;
  }
  return age;
}

/// 计算百分比（0.0 ~ 100.0）
///
/// [current] - 当前值
/// [total] - 总值，为零时返回 0.0
double calculatePercentage(int current, int total) {
  if (total == 0) return 0.0;
  return (current / total) * 100;
}

/// 格式化文件大小（B/KB/MB/GB）
///
/// [bytes] - 文件字节数
String formatFileSize(int bytes) {
  if (bytes < 1024) return '$bytes B';
  if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(2)} KB';
  if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
  return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
}

/// 格式化数字（K/M 单位）
///
/// [number] - 原始数字
String formatNumber(int number) {
  if (number >= 1000000) {
    return '${(number / 1000000).toStringAsFixed(1)}M';
  }
  if (number >= 1000) {
    return '${(number / 1000).toStringAsFixed(1)}K';
  }
  return number.toString();
}

/// 将十六进制颜色字符串转换为 Color 对象
///
/// [hexString] - 十六进制颜色字符串，支持带或不带 #
Color hexToColor(String hexString) {
  final buffer = StringBuffer();
  if (hexString.length == 6 || hexString.length == 7) buffer.write('ff');
  buffer.write(hexString.replaceFirst('#', ''));
  return Color(int.parse(buffer.toString(), radix: 16));
}

/// 将 Color 对象转换为十六进制颜色字符串
///
/// [color] - Color 对象
String colorToHex(Color color) {
  return '#${color.value.toRadixString(16).padLeft(8, '0').substring(2)}';
}

/// 将 Image Widget 转换为 Uint8List（PNG 格式）
///
/// [image] - Image Widget
/// [width] - 可选，目标宽度
/// [height] - 可选，目标高度
Future<Uint8List?> imageToBytes(Image image, {int? width, int? height}) async {
  final completer = Completer<Uint8List?>();
  image.image
      .resolve(const ImageConfiguration())
      .addListener(ImageStreamListener((info, _) async {
    final ui.Image uiImage = info.image;
    final byteData = await uiImage.toByteData(format: ui.ImageByteFormat.png);
    completer.complete(byteData?.buffer.asUint8List());
  }));
  return completer.future;
}

/// 移除列表中的重复元素
///
/// [list] - 原始列表
List<T> removeDuplicates<T>(List<T> list) {
  return list.toSet().toList();
}

/// 按指定键升序排序列表
///
/// [list] - 原始列表
/// [keySelector] - 键选择器函数
List<T> sortBy<T>(List<T> list, Comparable Function(T) keySelector) {
  return List.from(list)..sort((a, b) => keySelector(a).compareTo(keySelector(b)));
}

/// 按指定键降序排序列表
///
/// [list] - 原始列表
/// [keySelector] - 键选择器函数
List<T> sortByDescending<T>(List<T> list, Comparable Function(T) keySelector) {
  return List.from(list)..sort((a, b) => keySelector(b).compareTo(keySelector(a)));
}

/// 在列表中查找第一个满足条件的元素
///
/// [list] - 原始列表
/// [test] - 测试函数
T? find<T>(List<T> list, bool Function(T) test) {
  for (final item in list) {
    if (test(item)) return item;
  }
  return null;
}

/// 在列表中查找第一个满足条件的元素索引
///
/// [list] - 原始列表
/// [test] - 测试函数
/// 返回索引，未找到返回 -1
int indexOf<T>(List<T> list, bool Function(T) test) {
  for (int i = 0; i < list.length; i++) {
    if (test(list[i])) return i;
  }
  return -1;
}

/// 过滤列表中满足条件的元素
///
/// [list] - 原始列表
/// [test] - 测试函数
List<T> filter<T>(List<T> list, bool Function(T) test) {
  return list.where(test).toList();
}

/// 转换列表中的每个元素
///
/// [list] - 原始列表
/// [transform] - 转换函数
List<R> map<T, R>(List<T> list, R Function(T) transform) {
  return list.map(transform).toList();
}

/// 将列表元素累积合并为单个值
///
/// [list] - 原始列表
/// [combine] - 合并函数
/// 列表为空时抛出 ArgumentError
E reduce<E>(List<E> list, E Function(E, E) combine) {
  if (list.isEmpty) throw ArgumentError('Cannot reduce empty list');
  var value = list.first;
  for (int i = 1; i < list.length; i++) {
    value = combine(value, list[i]);
  }
  return value;
}

/// 判断列表中是否有任意元素满足条件
///
/// [list] - 原始列表
/// [test] - 测试函数
bool any<T>(List<T> list, bool Function(T) test) {
  for (final item in list) {
    if (test(item)) return true;
  }
  return false;
}

/// 判断列表中是否所有元素都满足条件
///
/// [list] - 原始列表
/// [test] - 测试函数
bool all<T>(List<T> list, bool Function(T) test) {
  for (final item in list) {
    if (!test(item)) return false;
  }
  return true;
}

/// 统计列表中满足条件的元素数量
///
/// [list] - 原始列表
/// [test] - 测试函数
int count<T>(List<T> list, bool Function(T) test) {
  int count = 0;
  for (final item in list) {
    if (test(item)) count++;
  }
  return count;
}
