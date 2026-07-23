import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:online_fm_radio/data/models/station.dart';

class ImportExportService {
  const ImportExportService();

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

  String _generateM3U(List<Station> stations) {
    final buffer = StringBuffer();
    buffer.writeln('#EXTM3U');

    for (final station in stations) {
      buffer.writeln('#EXTINF:-1,${station.name}');
      buffer.writeln(station.streamUrl);
    }

    return buffer.toString();
  }

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

  String _generateJson(List<Station> stations) {
    final jsonList = stations.map((s) => s.toJson()).toList();
    return jsonEncode(jsonList);
  }
}