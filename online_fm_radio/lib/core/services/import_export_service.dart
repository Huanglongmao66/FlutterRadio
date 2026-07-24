import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:online_fm_radio/data/models/station.dart';

/// 导出筛选条件配置
///
/// 用于开发者调试功能中自定义导出电台数据。
/// 支持按数量、国家、标签、语言组合筛选。
class ExportFilter {
  /// 导出数量上限（默认 100）
  final int limit;

  /// 国家代码（如 CN、US），为空表示不筛选
  final String? countryCode;

  /// 国家名称（如 China），为空表示不筛选
  final String? countryName;

  /// 标签（如 pop、jazz），为空表示不筛选
  final String? tag;

  /// 语言（如 English、Chinese），为空表示不筛选
  final String? language;

  /// 是否仅导出可用电台（隐藏损坏的）
  final bool hideBroken;

  /// 创建导出筛选条件
  const ExportFilter({
    this.limit = 100,
    this.countryCode,
    this.countryName,
    this.tag,
    this.language,
    this.hideBroken = true,
  });

  /// 是否有筛选条件
  bool get hasFilter =>
      countryCode != null ||
      countryName != null ||
      tag != null ||
      language != null;

  /// 生成描述文本
  String get description {
    final parts = <String>['数量: $limit'];
    if (countryCode != null && countryCode!.isNotEmpty) {
      parts.add('国家码: $countryCode');
    }
    if (countryName != null && countryName!.isNotEmpty) {
      parts.add('国家: $countryName');
    }
    if (tag != null && tag!.isNotEmpty) {
      parts.add('标签: $tag');
    }
    if (language != null && language!.isNotEmpty) {
      parts.add('语言: $language');
    }
    return parts.join(' | ');
  }
}

/// 导入导出服务类
///
/// 支持从文件导入电台列表和将电台列表导出到文件。
/// 支持的格式：
/// - M3U：标准播放列表格式
/// - M3U8：UTF-8 编码的 M3U 格式（支持更多元数据）
/// - JSON：结构化数据格式
///
/// 开发者调试功能：
/// - 一键导出全部缓存电台
/// - 按筛选条件（数量/国家/标签/语言）从远程 API 获取并导出
class ImportExportService {
  /// radio-browser.info API 服务器地址
  static const String _apiServer = 'http://de1.api.radio-browser.info/json';

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

    final bytes = utf8.encode(content);
    final result = await FilePicker.platform.saveFile(
      dialogTitle: '导出电台列表',
      fileName: 'radio_stations.$extension',
      allowedExtensions: [extension],
      bytes: bytes,
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

  // ===== 开发者调试功能 =====

  /// 从远程 API 按筛选条件获取电台数据
  ///
  /// [filter] - 导出筛选条件（数量/国家/标签/语言）
  /// [onProgress] - 进度回调，参数为已获取数量
  ///
  /// 返回符合筛选条件的电台列表。支持组合筛选（如同时指定国家和标签）。
  Future<List<Station>> fetchStationsByFilter(
    ExportFilter filter, {
    void Function(int fetched)? onProgress,
  }) async {
    final dio = Dio(BaseOptions(
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 30),
      baseUrl: _apiServer,
      headers: {
        'Accept': 'application/json',
        'Accept-Encoding': 'gzip, deflate',
      },
    ));

    try {
      // 构建查询参数
      final queryParams = <String, dynamic>{
        'limit': filter.limit,
        'order': 'votes',
        'reverse': 'true',
        'hidebroken': filter.hideBroken.toString(),
      };

      // 添加筛选条件
      if (filter.countryCode != null && filter.countryCode!.isNotEmpty) {
        queryParams['countrycode'] = filter.countryCode;
      }
      if (filter.countryName != null && filter.countryName!.isNotEmpty) {
        queryParams['country'] = filter.countryName;
      }
      if (filter.tag != null && filter.tag!.isNotEmpty) {
        queryParams['tag'] = filter.tag;
      }
      if (filter.language != null && filter.language!.isNotEmpty) {
        queryParams['language'] = filter.language;
      }

      final response = await dio.get('/stations', queryParameters: queryParams);
      final List<dynamic> jsonData = response.data as List<dynamic>;

      final stations = jsonData
          .map((json) => Station.fromRadioBrowserJson(json as Map<String, dynamic>))
          .where((station) => station.streamUrl.isNotEmpty)
          .toList();

      onProgress?.call(stations.length);
      return stations;
    } catch (e) {
      throw Exception('获取远程电台失败: $e');
    } finally {
      dio.close();
    }
  }

  /// 从远程获取并导出电台数据
  ///
  /// [filter] - 导出筛选条件
  /// [format] - 导出格式：'m3u'、'm3u8' 或 'json'
  /// [onProgress] - 进度回调
  ///
  /// 先从远程 API 获取符合筛选条件的电台，再导出到文件。
  Future<int> exportFromRemote(
    ExportFilter filter,
    String format, {
    void Function(int fetched)? onProgress,
  }) async {
    final stations = await fetchStationsByFilter(filter, onProgress: onProgress);

    if (stations.isEmpty) {
      throw Exception('未找到符合条件的电台');
    }

    // 生成文件名（包含筛选条件信息）
    final fileName = _generateFileName(filter, format);
    final content = _generateContent(stations, format);
    final bytes = utf8.encode(content);

    final result = await FilePicker.platform.saveFile(
      dialogTitle: '导出电台数据',
      fileName: fileName,
      allowedExtensions: [format],
      bytes: bytes,
    );

    if (result != null) {
      final file = File(result);
      await file.writeAsString(content);
    }

    return stations.length;
  }

  /// 根据筛选条件生成文件名
  String _generateFileName(ExportFilter filter, String format) {
    final parts = <String>['stations'];
    if (filter.countryCode != null && filter.countryCode!.isNotEmpty) {
      parts.add(filter.countryCode!.toLowerCase());
    }
    if (filter.tag != null && filter.tag!.isNotEmpty) {
      parts.add(filter.tag!.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '_'));
    }
    if (filter.language != null && filter.language!.isNotEmpty) {
      parts.add(filter.language!.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '_'));
    }
    parts.add('${filter.limit}');
    return '${parts.join('_')}.$format';
  }

  /// 根据格式生成内容
  String _generateContent(List<Station> stations, String format) {
    switch (format) {
      case 'm3u':
        return _generateM3U(stations);
      case 'm3u8':
        return _generateM3U8(stations);
      default:
        return _generateJson(stations);
    }
  }

  /// 一键导出全部缓存电台
  ///
  /// [stations] - 缓存的电台列表
  /// [format] - 导出格式
  Future<int> exportAllCached(List<Station> stations, String format) async {
    if (stations.isEmpty) {
      throw Exception('缓存为空，请先更新电台数据');
    }

    final content = _generateContent(stations, format);
    final timestamp = DateTime.now().toIso8601String().split('T')[0];
    final fileName = 'all_stations_${stations.length}_$timestamp.$format';
    final bytes = utf8.encode(content);

    final result = await FilePicker.platform.saveFile(
      dialogTitle: '一键导出全部缓存电台',
      fileName: fileName,
      allowedExtensions: [format],
      bytes: bytes,
    );

    if (result != null) {
      final file = File(result);
      await file.writeAsString(content);
    }

    return stations.length;
  }
}