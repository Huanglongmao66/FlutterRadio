import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:online_fm_radio/data/models/station.dart';

/// 导入导出服务类
///
/// 支持从文件导入电台列表和将电台列表导出到文件。
/// 支持的格式：
/// - M3U：标准播放列表格式
/// - M3U8：UTF-8 编码的 M3U 格式（支持更多元数据）
/// - JSON：结构化数据格式
class ImportExportService {
  /// 创建导入导出服务实例
  const ImportExportService();

  /// 从文件导入电台列表
  ///
  /// 使用文件选择器选择文件，根据文件扩展名自动选择解析方式。
  /// 支持 m3u、m3u8 和 json 格式。
  Future<List<Station>> importFromFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['m3u', 'm3u8', 'json'],
    );

    if (result == null || result.files.isEmpty) {
      return [];
    }

    final file = File(result.files.first.path!);
    final fileName = result.files.first.name.toLowerCase();
    final content = await file.readAsString();

    if (fileName.endsWith('.m3u') || fileName.endsWith('.m3u8')) {
      return _parseM3U(content);
    } else if (fileName.endsWith('.json')) {
      return _parseJson(content);
    }

    return [];
  }

  /// 将电台列表导出到文件
  ///
  /// [stations] - 要导出的电台列表
  /// [format] - 导出格式：'m3u'、'm3u8' 或 'json'
  ///
  /// 根据指定格式生成内容并保存到文件
  Future<void> exportToFile(List<Station> stations, String format) async {
    final String content;
    final String extension;

    if (format == 'm3u') {
      content = _generateM3U(stations);
      extension = 'm3u';
    } else if (format == 'm3u8') {
      content = _generateM3U8(stations);
      extension = 'm3u8';
    } else {
      content = _generateJson(stations);
      extension = 'json';
    }

    final result = await FilePicker.platform.saveFile(
      dialogTitle: '导出电台列表',
      fileName: 'radio_stations.$extension',
      allowedExtensions: [extension],
    );

    if (result != null) {
      final file = File(result);
      await file.writeAsString(content);
    }
  }

  /// 解析 M3U/M3U8 文件内容
  ///
  /// M3U 格式说明：
  /// - #EXTM3U：文件头标识
  /// - #EXTINF:-1,name：电台信息行
  /// - url：流媒体地址行
  List<Station> _parseM3U(String content) {
    final stations = <Station>[];
    final lines = content.split('\n');

    String? name;
    String? url;

    for (final line in lines) {
      final trimmed = line.trim();

      if (trimmed.isEmpty || trimmed.startsWith('#EXTM3U')) {
        continue;
      }

      if (trimmed.startsWith('#EXTINF:')) {
        final match = RegExp(r'#EXTINF:[-\d]+(?:,\s*(.+))?').firstMatch(trimmed);
        if (match != null) {
          name = match.group(1)?.trim() ?? 'Unknown';
        }
      } else if (trimmed.isNotEmpty && !trimmed.startsWith('#')) {
        url = trimmed;
        if (name != null && url.isNotEmpty) {
          stations.add(
            Station(
              id: url.hashCode.toString(),
              name: name,
              streamUrl: url,
              country: '',
              countryCode: '',
              language: '',
              category: 'Imported',
              logo: '',
              description: '',
            ),
          );
          name = null;
          url = null;
        }
      }
    }

    return stations;
  }

  /// 解析 JSON 文件内容
  ///
  /// JSON 格式需为 Station 对象的数组
  List<Station> _parseJson(String content) {
    try {
      final jsonData = jsonDecode(content) as List<dynamic>;
      return jsonData
          .map((item) => Station.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  /// 生成 M3U 格式内容
  String _generateM3U(List<Station> stations) {
    final buffer = StringBuffer();
    buffer.writeln('#EXTM3U');

    for (final station in stations) {
      buffer.writeln('#EXTINF:-1,${station.name}');
      buffer.writeln(station.streamUrl);
    }

    return buffer.toString();
  }

  /// 生成 M3U8 格式内容
  ///
  /// 比标准 M3U 增加了分类和国家信息
  String _generateM3U8(List<Station> stations) {
    final buffer = StringBuffer();
    buffer.writeln('#EXTM3U');

    for (final station in stations) {
      buffer.writeln('#EXTINF:-1 group-title="${station.category}",${station.name}');
      buffer.writeln('#EXTGRP:${station.country}');
      buffer.writeln(station.streamUrl);
    }

    return buffer.toString();
  }

  /// 生成 JSON 格式内容
  String _generateJson(List<Station> stations) {
    final jsonList = stations.map((s) => s.toJson()).toList();
    return jsonEncode(jsonList);
  }
}