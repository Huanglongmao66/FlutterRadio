import 'package:cached_network_image/cached_network_image.dart';
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
    // 在首帧渲染完成后才能拿到 Provider，此时绑定监听并加载数据。
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _countryService = context.read<CountryPreferenceService>();
      _countryService!.addListener(_onCountryPreferenceChanged);
      // 先加载数据，加载完成后根据国家偏好筛选。
      _loadData();
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
        _loadCountries(),
        _loadLanguages(),
      ]);
      // 先加载全量电台缓存。
      _allStations = await _repository.loadStations();
    } catch (e) {
      debugPrint('Failed to load data: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
        // 数据加载完成后应用国家筛选（此时 _countryService 已初始化）。
        _applyCountryFilter(_countryService?.selectedCountry);
      }
    }
  }

  /// 按国家筛选推荐列表。
  /// - country 为空：使用全量缓存前 50 条；
  /// - country 非空：调用 API 按国家名精确拉取该国家电台（最多 50 条），
  ///   若 API 返回为空则回退到本地缓存中同国家电台，保证不会一直空白。
  Future<void> _applyCountryFilter(String? country) async {
    if (!mounted) return;
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
        title: 'Fradoi',
        selectedCountry: _selectedCountry,
        onCountrySelected: _onCountrySelected,
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
              child: CachedNetworkImage(
                imageUrl: station.logo,
                width: 72,
                height: 72,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  width: 72,
                  height: 72,
                  color: Theme.of(context).colorScheme.primaryContainer,
                  child: Icon(
                    Icons.radio,
                    size: 28,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                ),
                errorWidget: (context, url, error) => Container(
                  width: 72,
                  height: 72,
                  color: Theme.of(context).colorScheme.primaryContainer,
                  child: Icon(
                    Icons.radio,
                    size: 28,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                ),
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
            _capitalize(language.name),
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