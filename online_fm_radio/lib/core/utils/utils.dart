import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';

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

String formatTime(DateTime time) {
  return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
}

String formatDateTime(DateTime dateTime) {
  return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')} ${formatTime(dateTime)}';
}

String truncateString(String str, int maxLength) {
  if (str.length <= maxLength) {
    return str;
  }
  return '${str.substring(0, maxLength)}...';
}

String capitalize(String str) {
  if (str.isEmpty) return str;
  return str[0].toUpperCase() + str.substring(1).toLowerCase();
}

String capitalizeEachWord(String str) {
  if (str.isEmpty) return str;
  return str.split(' ').map(capitalize).join(' ');
}

String removeSpecialCharacters(String str) {
  return str.replaceAll(RegExp(r'[^\w\s]'), '');
}

String sanitizeFileName(String fileName) {
  return fileName.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
}

bool isValidUrl(String url) {
  try {
    Uri.parse(url);
    return true;
  } catch (_) {
    return false;
  }
}

bool isValidEmail(String email) {
  final regex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
  return regex.hasMatch(email);
}

String generateId() {
  return '${DateTime.now().millisecondsSinceEpoch}_${DateTime.now().microsecondsSinceEpoch % 1000000}';
}

int calculateAge(DateTime birthDate) {
  final now = DateTime.now();
  int age = now.year - birthDate.year;
  if (now.month < birthDate.month ||
      (now.month == birthDate.month && now.day < birthDate.day)) {
    age--;
  }
  return age;
}

double calculatePercentage(int current, int total) {
  if (total == 0) return 0.0;
  return (current / total) * 100;
}

String formatFileSize(int bytes) {
  if (bytes < 1024) return '$bytes B';
  if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(2)} KB';
  if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
  return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
}

String formatNumber(int number) {
  if (number >= 1000000) {
    return '${(number / 1000000).toStringAsFixed(1)}M';
  }
  if (number >= 1000) {
    return '${(number / 1000).toStringAsFixed(1)}K';
  }
  return number.toString();
}

Color hexToColor(String hexString) {
  final buffer = StringBuffer();
  if (hexString.length == 6 || hexString.length == 7) buffer.write('ff');
  buffer.write(hexString.replaceFirst('#', ''));
  return Color(int.parse(buffer.toString(), radix: 16));
}

String colorToHex(Color color) {
  return '#${color.value.toRadixString(16).padLeft(8, '0').substring(2)}';
}

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

List<T> removeDuplicates<T>(List<T> list) {
  return list.toSet().toList();
}

List<T> sortBy<T>(List<T> list, Comparable Function(T) keySelector) {
  return List.from(list)..sort((a, b) => keySelector(a).compareTo(keySelector(b)));
}

List<T> sortByDescending<T>(List<T> list, Comparable Function(T) keySelector) {
  return List.from(list)..sort((a, b) => keySelector(b).compareTo(keySelector(a)));
}

T? find<T>(List<T> list, bool Function(T) test) {
  for (final item in list) {
    if (test(item)) return item;
  }
  return null;
}

int indexOf<T>(List<T> list, bool Function(T) test) {
  for (int i = 0; i < list.length; i++) {
    if (test(list[i])) return i;
  }
  return -1;
}

List<T> filter<T>(List<T> list, bool Function(T) test) {
  return list.where(test).toList();
}

List<R> map<T, R>(List<T> list, R Function(T) transform) {
  return list.map(transform).toList();
}

E reduce<E>(List<E> list, E Function(E, E) combine) {
  if (list.isEmpty) throw ArgumentError('Cannot reduce empty list');
  var value = list.first;
  for (int i = 1; i < list.length; i++) {
    value = combine(value, list[i]);
  }
  return value;
}

bool any<T>(List<T> list, bool Function(T) test) {
  for (final item in list) {
    if (test(item)) return true;
  }
  return false;
}

bool all<T>(List<T> list, bool Function(T) test) {
  for (final item in list) {
    if (!test(item)) return false;
  }
  return true;
}

int count<T>(List<T> list, bool Function(T) test) {
  int count = 0;
  for (final item in list) {
    if (test(item)) count++;
  }
  return count;
}
