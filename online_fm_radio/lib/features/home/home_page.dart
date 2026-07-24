import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:online_fm_radio/core/services/country_preference_service.dart';
import 'package:online_fm_radio/core/services/history_service.dart';
import 'package:online_fm_radio/core/ui/app_drawer.dart';
import 'package:online_fm_radio/core/ui/app_top_bar.dart';
import 'package:online_fm_radio/data/models/country.dart';
import 'package:online_fm_radio/data/models/language.dart';
import 'package:online_fm_radio/data/models/station.dart';
import 'package:online_fm_radio/data/repositories/station_repository.dart';
import 'package:online_fm_radio/shared/components/station_card.dart';
import 'package:online_fm_radio/shared/components/station_logo.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  /// 电台数据仓库，负责从远端 API / 本地缓存读取电台列表。
  final StationRepository _repository = StationRepository();

  /// 全量电台缓存（首次加载或远程更新后填充，最多 10000 条）。
  List<Station> _allStations = [];

  /// 当前展示在「推荐」Tab 的电台列表（已按国家筛选）。
  List<Station> _recommendedStations = [];

  /// 国家列表（用于「国家」Tab 展示）。
  List<Country> _countries = [];

  /// 语言列表（用于「语言」Tab 展示）。
  List<Language> _languages = [];

  /// 当前选中的国家名称（来自 CountryPreferenceService，为空表示全部国家）。
  String? _selectedCountry;

  /// 当前排序方式（默认按热门度）
  StationSortMode _sortMode = StationSortMode.votes;

  /// 首次加载数据时的全局 loading 标志。
  bool _isLoading = true;

  /// 仅推荐列表在按国家重新拉取时的 loading 标志（不影响其它 Tab）。
  bool _isLoadingRecommended = false;

  /// 国家偏好服务引用（在 initState 后绑定监听，dispose 时解绑）。
  CountryPreferenceService? _countryService;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
    // 在首帧渲染完成后才能拿到 Provider，此时绑定监听并应用持久化的国家偏好。
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _countryService = context.read<CountryPreferenceService>();
      _countryService!.addListener(_onCountryPreferenceChanged);
      // 应用已持久化的国家偏好（设置页选过的国家会立即生效）。
      _applyCountryFilter(_countryService!.selectedCountry);
    });
  }

  /// 国家偏好变化回调：重新按新国家拉取推荐电台。
  /// 该方法由 CountryPreferenceService 的 notifyListeners 触发。
  void _onCountryPreferenceChanged() {
    _applyCountryFilter(_countryService?.selectedCountry);
  }

  /// 并行加载推荐电台、国家列表、语言列表。
  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      await Future.wait([
        _loadRecommendedStations(),
        _loadCountries(),
        _loadLanguages(),
      ]);
    } catch (e) {
      debugPrint('Failed to load data: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// 加载全量电台缓存，随后应用当前国家筛选。
  Future<void> _loadRecommendedStations() async {
    try {
      _allStations = await _repository.loadStations();
      await _applyCountryFilter(_countryService?.selectedCountry);
    } catch (e) {
      debugPrint('Failed to load recommended stations: $e');
    }
  }

  /// 按国家筛选推荐列表。
  /// - country 为空：使用全量缓存前 50 条；
  /// - country 非空：调用 API 按国家名精确拉取该国家电台（最多 50 条），
  ///   若 API 返回为空则回退到本地缓存中同国家电台，保证不会一直空白。
  Future<void> _applyCountryFilter(String? country) async {
    setState(() {
      _selectedCountry = country;
      _isLoadingRecommended = true;
    });

    try {
      List<Station> stations;
      if (country == null || country.isEmpty) {
        stations = _allStations.take(50).toList();
      } else {
        stations = await _repository.loadByCountryName(country);
        if (stations.isEmpty) {
          stations = _allStations
              .where((s) => s.country == country)
              .take(50)
              .toList();
        }
      }
      if (mounted) {
        setState(() {
          _recommendedStations = stations;
          _isLoadingRecommended = false;
        });
      }
    } catch (e) {
      debugPrint('Failed to apply country filter: $e');
      if (mounted) {
        setState(() {
          _isLoadingRecommended = false;
          _recommendedStations = _allStations.take(50).toList();
        });
      }
    }
  }

  /// 顶部国家筛选按钮 / 设置页选择国家后的统一入口。
  /// 将选择写入 CountryPreferenceService，监听器会自动重新拉取推荐电台。
  void _onCountrySelected(String? country) async {
    final service = context.read<CountryPreferenceService>();
    await service.setCountry(country);
  }

  /// 排序方式变化回调：重新对推荐列表排序
  void _onSortModeChanged(StationSortMode mode) {
    setState(() => _sortMode = mode);
    _applySortMode();
  }

  /// 对推荐列表应用当前排序方式
  void _applySortMode() {
    if (_recommendedStations.isEmpty) return;

    final sorted = List<Station>.from(_recommendedStations);
    switch (_sortMode) {
      case StationSortMode.votes:
        sorted.sort((a, b) => b.votes.compareTo(a.votes));
        break;
      case StationSortMode.name:
        sorted.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
        break;
      case StationSortMode.country:
        sorted.sort((a, b) => a.country.toLowerCase().compareTo(b.country.toLowerCase()));
        break;
      case StationSortMode.newest:
        // 按原始顺序（已按 votes 排序）保持不变
        break;
    }

    setState(() {
      _recommendedStations = sorted;
    });
  }

  Future<void> _loadCountries() async {
    try {
      _countries = await _repository.loadCountries();
    } catch (e) {
      debugPrint('Failed to load countries: $e');
    }
  }

  Future<void> _loadLanguages() async {
    try {
      _languages = await _repository.loadLanguages();
    } catch (e) {
      debugPrint('Failed to load languages: $e');
    }
  }

  @override
  void dispose() {
    _countryService?.removeListener(_onCountryPreferenceChanged);
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const AppDrawer(),
      appBar: AppTopBar(
        title: 'FMradio',
        selectedCountry: _selectedCountry,
        onCountrySelected: _onCountrySelected,
        sortMode: _sortMode,
        onSortModeChanged: _onSortModeChanged,
      ),
      body: Column(
        children: [
          // 选中国家时顶部展示筛选条，点击 × 可清除国家筛选。
          if (_selectedCountry != null)
            Material(
              color: Theme.of(context).colorScheme.primaryContainer,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                child: Row(
                  children: [
                    Icon(
                      Icons.filter_list,
                      size: 16,
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '当前筛选: $_selectedCountry',
                        style: TextStyle(
                          fontSize: 13,
                          color: Theme.of(context).colorScheme.onPrimaryContainer,
                        ),
                      ),
                    ),
                    InkWell(
                      onTap: () => _onCountrySelected(null),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Icon(
                          Icons.close,
                          size: 18,
                          color: Theme.of(context).colorScheme.onPrimaryContainer,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          TabBar(
            controller: _tabController,
            tabs: const [
              Tab(text: '推荐'),
              Tab(text: '国家'),
              Tab(text: '语言'),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildRecommendationTab(),
                _buildCountryList(),
                _buildLanguageList(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 推荐 Tab：顶部横向「最近播放」+ 下方国家筛选后的电台列表。
  Widget _buildRecommendationTab() {
    return Consumer<HistoryService>(
      builder: (context, historyService, _) {
        final recent = historyService.history;
        return Column(
          children: [
            // 仅在有播放记录时展示横向「最近播放」。
            if (recent.isNotEmpty) _buildRecentlyPlayedSection(recent),
            Expanded(child: _buildStationList(_recommendedStations)),
          ],
        );
      },
    );
  }

  /// 横向「最近播放」区域：固定高度，横向滑动展示最近播放过的电台。
  Widget _buildRecentlyPlayedSection(List<Station> recent) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Row(
            children: [
              Icon(
                Icons.history,
                size: 18,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 6),
              Text(
                '最近播放',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 112,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: recent.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              final station = recent[index];
              return _buildRecentStationChip(station);
            },
          ),
        ),
        const Divider(height: 1),
      ],
    );
  }

  /// 最近播放中的单个横向电台卡片：logo + 名称，点击进入播放页。
  Widget _buildRecentStationChip(Station station) {
    return InkWell(
      onTap: () => Navigator.pushNamed(
        context,
        '/player',
        arguments: station,
      ),
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        width: 96,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: StationLogo(
                station: station,
                size: 72,
                borderRadius: 12,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              station.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStationList(List<Station> stations) {
    // 全局加载中（首次进入）。
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    // 按国家重新拉取推荐列表时的局部加载。
    if (_isLoadingRecommended) {
      return const Center(child: CircularProgressIndicator());
    }
    if (stations.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.radio, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(_selectedCountry != null
                ? '$_selectedCountry 暂无电台'
                : '暂无电台'),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: stations.length,
      itemBuilder: (context, index) {
        final station = stations[index];
        return StationCard(
          station: station,
          onTap: () => Navigator.pushNamed(
            context,
            '/player',
            arguments: station,
          ),
        );
      },
    );
  }

  Widget _buildCountryList() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_countries.isEmpty) {
      return const Center(child: Text('暂无国家数据'));
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 4),
      itemCount: _countries.length,
      itemBuilder: (context, index) {
        final country = _countries[index];
        final isSelected = _selectedCountry == country.name;
        // 国旗 emoji：由 ISO 国家码转换得到，无码时回退到文字占位。
        final flag = country.flagEmoji;
        return ListTile(
          leading: CircleAvatar(
            backgroundColor: Theme.of(context).colorScheme.primaryContainer,
            radius: 24,
            child: Text(
              flag.isNotEmpty
                  ? flag
                  : (country.countryCode.isNotEmpty
                      ? country.countryCode.substring(0, 2).toUpperCase()
                      : '?'),
              style: TextStyle(
                fontSize: 22,
                color: Theme.of(context).colorScheme.onPrimaryContainer,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          title: Text(
            country.name,
            style: TextStyle(
              fontSize: 18,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected ? Theme.of(context).colorScheme.primary : null,
            ),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${country.stationCount}',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w500,
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                ),
              ),
              const SizedBox(width: 4),
              const Icon(Icons.chevron_right, size: 20),
            ],
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          onTap: () {
            Navigator.pushNamed(
              context,
              '/country_stations',
              arguments: country,
            );
          },
        );
      },
    );
  }

  static final Map<String, String> _languageNameMap = {
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
    'hungarian': '匈牙利语',
    'czech': '捷克语',
    'slovak': '斯洛伐克语',
    'croatian': '克罗地亚语',
    'serbian': '塞尔维亚语',
    'bulgarian': '保加利亚语',
    'romanian': '罗马尼亚语',
    'ukrainian': '乌克兰语',
    'hebrew': '希伯来语',
    'persian': '波斯语',
    'thai': '泰语',
    'vietnamese': '越南语',
    'indonesian': '印尼语',
    'malay': '马来语',
    'tamil': '泰米尔语',
    'telugu': '泰卢固语',
    'marathi': '马拉地语',
    'bengali': '孟加拉语',
    'punjabi': '旁遮普语',
    'gujarati': '古吉拉特语',
    'kannada': '卡纳达语',
    'malayalam': '马拉雅拉姆语',
    'oriya': '奥里亚语',
    'assamese': '阿萨姆语',
    'nepali': '尼泊尔语',
    'sinhalese': '僧伽罗语',
    'burmese': '缅甸语',
    'khmer': '高棉语',
    'lao': '老挝语',
    'mongolian': '蒙古语',
    'tibetan': '藏语',
    'uyghur': '维吾尔语',
    'kazakh': '哈萨克语',
    'uzbek': '乌兹别克语',
    'tajik': '塔吉克语',
    'kyrgyz': '吉尔吉斯语',
    'turkmen': '土库曼语',
    'azerbaijani': '阿塞拜疆语',
    'georgian': '格鲁吉亚语',
    'armenian': '亚美尼亚语',
    'kurdish': '库尔德语',
    'pashto': '普什图语',
    'balochi': '俾路支语',
    'sindhi': '信德语',
    'saraiki': '萨拉伊基语',
    'balti': '巴尔蒂语',
    'ladakhi': '拉达克语',
    'dogri': '多格里语',
    'kashmiri': '克什米尔语',
    'konkani': '孔卡尼语',
    'santali': '桑塔利语',
    'bodo': '博多语',
    'mizo': '米佐语',
    'kuki': '库基语',
    'manipuri': '曼尼普尔语',
    'naga': '那加语',
    'karbi': '卡比语',
    'garo': '加罗语',
    'tripuri': '特里普拉语',
    'khasi': '卡西语',
    'jangli': '姜格利语',
    'birhor': '比尔霍语',
    'sauria paharia': '索里亚帕哈里亚语',
    'ho': '霍语',
    'mundari': '蒙达里语',
    'oraon': '奥拉翁语',
    'korku': '科尔库语',
    'gondi': '贡迪语',
    'bhil': '比尔语',
    'nihar': '尼哈尔语',
    'kanauji': '卡瑙吉语',
    'bundeli': '本德尔坎德语',
    'chhattisgarhi': '恰蒂斯加尔语',
    'sarguja': '萨古贾语',
    'nimari': '尼玛里语',
    'malwi': '马尔维语',
    'rathi': '拉蒂语',
    'bagheli': '巴盖利语',
    'awadhi': '阿瓦迪语',
    'chaurasia': '乔拉西亚语',
    'braj bhasha': '布拉吉语',
    'khariboli': '哈里波利语',
    'bundelkhandi': '本德尔坎德语',
    'pahari': '帕哈里语',
    'garhwali': '加瓦尔语',
    'kumaoni': '库马奥尼语',
    'bhotiya': '博蒂亚语',
    'sherpa': '夏尔巴语',
    'limbu': '林布语',
    'raute': '劳特语',
    'tharu': '塔鲁语',
    'rajbanshi': '拉杰班希语',
    'maithili': '迈蒂利语',
    'bhojpuri': '博杰普尔语',
    'magahi': '马加希语',
    'orissa': '奥里萨语',
    'sambalpuri': '桑巴普尔语',
    'haryanvi': '哈里亚纳语',
    'rajasthani': '拉贾斯坦语',
  };

  String _getLanguageDisplayName(String name) {
    final lower = name.toLowerCase().trim();
    if (_languageNameMap.containsKey(lower)) {
      return '${_languageNameMap[lower]}（$name）';
    }
    final parts = lower.split(',').map((p) => p.trim()).toList();
    final translatedParts = parts
        .map((p) => _languageNameMap[p] ?? _capitalize(p))
        .toList();
    final englishParts = parts.map((p) => _capitalize(p)).toList();
    return '${translatedParts.join(',')}（${englishParts.join(',')}）';
  }

  Widget _buildLanguageList() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_languages.isEmpty) {
      return const Center(child: Text('暂无语言数据'));
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 4),
      itemCount: _languages.length,
      itemBuilder: (context, index) {
        final language = _languages[index];
        return ListTile(
          title: Text(
            _getLanguageDisplayName(language.name),
            style: const TextStyle(fontSize: 20),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${language.stationCount}',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w500,
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                ),
              ),
              const SizedBox(width: 4),
              const Icon(Icons.chevron_right, size: 20),
            ],
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
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

  String _capitalize(String s) {
    if (s.isEmpty) return s;
    return s[0].toUpperCase() + s.substring(1);
  }
}