import 'package:flutter/material.dart';
import 'package:online_fm_radio/data/models/language.dart';
import 'package:online_fm_radio/data/repositories/station_repository.dart';

class LanguageListPage extends StatefulWidget {
  const LanguageListPage({super.key});

  @override
  State<LanguageListPage> createState() => _LanguageListPageState();
}

class _LanguageListPageState extends State<LanguageListPage> {
  final StationRepository _repository = StationRepository();
  List<Language> _languages = [];
  List<Language> _filteredLanguages = [];
  bool _isLoading = true;
  String? _errorMessage;
  String _searchKeyword = '';

  @override
  void initState() {
    super.initState();
    _loadLanguages();
  }

  Future<void> _loadLanguages() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final languages = await _repository.loadLanguages();
      _languages = languages;
      _filterLanguages();
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _filterLanguages() {
    if (_searchKeyword.isEmpty) {
      _filteredLanguages = _languages;
    } else {
      _filteredLanguages = _languages
          .where((l) => l.name.toLowerCase().contains(_searchKeyword.toLowerCase()))
          .toList();
    }
  }

  String _getLanguageDisplayName(String name) {
    const Map<String, String> nameMap = {
      'chinese': '中文',
      'english': '英语',
      'german': '德语',
      'french': '法语',
      'japanese': '日语',
      'spanish': '西班牙语',
      'italian': '意大利语',
      'korean': '韩语',
      'russian': '俄语',
      'portuguese': '葡萄牙语',
      'arabic': '阿拉伯语',
      'hindi': '印地语',
      'dutch': '荷兰语',
      'swedish': '瑞典语',
      'norwegian': '挪威语',
      'danish': '丹麦语',
      'finnish': '芬兰语',
      'polish': '波兰语',
      'turkish': '土耳其语',
      'greek': '希腊语',
    };
    final lower = name.toLowerCase().trim();
    if (nameMap.containsKey(lower)) {
      return '${nameMap[lower]}（$name）';
    }
    return name;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('语言'),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              decoration: InputDecoration(
                hintText: '搜索语言...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey[100],
              ),
              onChanged: (value) {
                setState(() {
                  _searchKeyword = value;
                  _filterLanguages();
                });
              },
            ),
          ),
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('正在加载语言列表...'),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text('加载失败', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(_errorMessage!, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadLanguages,
              child: const Text('重试'),
            ),
          ],
        ),
      );
    }

    if (_filteredLanguages.isEmpty) {
      return const Center(child: Text('没有找到匹配的语言'));
    }

    return ListView.builder(
      itemCount: _filteredLanguages.length,
      itemBuilder: (context, index) {
        final language = _filteredLanguages[index];
        return ListTile(
          leading: CircleAvatar(
            backgroundColor: Theme.of(context).colorScheme.primaryContainer,
            child: Icon(
              Icons.language,
              color: Theme.of(context).colorScheme.onPrimaryContainer,
            ),
          ),
          title: Text(_getLanguageDisplayName(language.name)),
          subtitle: Text('${language.stationCount} 个电台'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            Navigator.pushNamed(
              context,
              '/language_stations',
              arguments: language,
            );
          },
        );
      },
    );
  }
}
