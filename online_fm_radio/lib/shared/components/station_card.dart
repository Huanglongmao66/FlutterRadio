import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:online_fm_radio/core/services/favorites_service.dart';
import 'package:online_fm_radio/core/services/player_service.dart';
import 'package:online_fm_radio/data/models/station.dart';
import 'package:online_fm_radio/shared/components/station_logo.dart';

/// 电台卡片组件：展示电台信息，包含播放/暂停和收藏操作。
///
/// 布局结构：
/// - 左侧：电台 Logo（圆形）
/// - 中间：电台名称、分类标签、国家信息
/// - 右侧：播放/暂停按钮 + 收藏按钮（横向排列）
///
/// 交互功能：
/// - 点击卡片触发 [onTap] 回调（通常跳转到播放页）
/// - 播放按钮：根据当前状态切换播放/暂停
/// - 收藏按钮：切换电台收藏状态
class StationCard extends StatelessWidget {
  /// 电台数据
  final Station station;

  /// 点击卡片时的回调
  final VoidCallback onTap;

  const StationCard({
    super.key,
    required this.station,
    required this.onTap,
  });

  /// 电台名称翻译映射表：将英文/长名称映射为更简洁的中文名称
  static final Map<String, String> _stationNameMap = {
    '中央人民广播电台音乐之声': '音乐之声',
    '中国国际广播电台轻松调频': '轻松调频',
    '北京交通广播': '北京交通广播',
    '上海东方广播电台': '东方广播电台',
    'Classic FM': '经典调频',
    'BBC Radio 1': 'BBC第一电台',
    'BBC Radio 4': 'BBC第四电台',
    'KQED Public Radio': 'KQED公共电台',
    'WNYC': '纽约公共电台',
    'WFUV': '福特汉姆大学电台',
    'KEXP': '西雅图独立电台',
    'Jazz FM': '爵士调频',
    'Deutschlandfunk': '德国之声',
    'WDR 2': '西德第二台',
    'France Inter': '法国国际台',
    'Radio Classique': '古典音乐台',
    'NHK Radio 1': 'NHK第一广播',
    'Tokyo FM': '东京调频',
    'ESPN Radio': 'ESPN体育电台',
    'BBC Radio 5 Live': 'BBC第五电台',
    'Radio Electronica': '电子音乐台',
    'J-Wave': 'J波电台',
    'China Radio International': '中国国际广播电台',
    'Virgin Radio': '维珍电台',
    'MANGORADIO': '芒果电台',
    'Dance Wave!': '舞曲浪潮',
    'REYFM - #original': '雷电台',
    'Radio Paradise Main Mix (EU) 320k AAC': '天堂电台',
    'Classic Vinyl HD': '经典黑胶电台',
  };

  /// 国家名称翻译映射表：将英文国家名映射为中文国家名
  static final Map<String, String> _countryMap = {
    'china': '中国',
    'chinese': '中国',
    'germany': '德国',
    'german': '德国',
    'hungary': '匈牙利',
    'the united states of america': '美国',
    'united states': '美国',
    'usa': '美国',
    'america': '美国',
    'california': '美国',
    'england': '英国',
    'uk': '英国',
    'great britain': '英国',
    'france': '法国',
    'french': '法国',
    'japan': '日本',
    'japanese': '日本',
    'italy': '意大利',
    'italian': '意大利',
    'spain': '西班牙',
    'spanish': '西班牙',
    'russia': '俄罗斯',
    'russian': '俄罗斯',
    'canada': '加拿大',
    'australia': '澳大利亚',
    'brazil': '巴西',
    'mexico': '墨西哥',
    'india': '印度',
    'indonesia': '印度尼西亚',
    'philippines': '菲律宾',
    'malaysia': '马来西亚',
    'singapore': '新加坡',
    'thailand': '泰国',
    'vietnam': '越南',
    'south korea': '韩国',
    'korea': '韩国',
    'portugal': '葡萄牙',
    'netherlands': '荷兰',
    'belgium': '比利时',
    'switzerland': '瑞士',
    'austria': '奥地利',
    'poland': '波兰',
    'sweden': '瑞典',
    'norway': '挪威',
    'denmark': '丹麦',
    'finland': '芬兰',
    'iceland': '冰岛',
    'ireland': '爱尔兰',
    'scotland': '英国',
    'wales': '英国',
    'northern ireland': '英国',
    'turkey': '土耳其',
    'greece': '希腊',
    'cyprus': '塞浦路斯',
    'israel': '以色列',
    'egypt': '埃及',
    'south africa': '南非',
    'nigeria': '尼日利亚',
    'kenya': '肯尼亚',
    'ghana': '加纳',
    'morocco': '摩洛哥',
    'saudi arabia': '沙特阿拉伯',
    'uae': '阿联酋',
    'qatar': '卡塔尔',
    'kuwait': '科威特',
    'iran': '伊朗',
    'iraq': '伊拉克',
    'pakistan': '巴基斯坦',
    'bangladesh': '孟加拉国',
    'sri lanka': '斯里兰卡',
    'nepal': '尼泊尔',
    'bhutan': '不丹',
    'maldives': '马尔代夫',
    'myanmar': '缅甸',
    'laos': '老挝',
    'cambodia': '柬埔寨',
    'new zealand': '新西兰',
    'papua new guinea': '巴布亚新几内亚',
    'fiji': '斐济',
    'samoa': '萨摩亚',
    'tonga': '汤加',
    'haiti': '海地',
    'dominican republic': '多米尼加',
    'cuba': '古巴',
    'puerto rico': '波多黎各',
    'guatemala': '危地马拉',
    'honduras': '洪都拉斯',
    'el salvador': '萨尔瓦多',
    'nicaragua': '尼加拉瓜',
    'costa rica': '哥斯达黎加',
    'panama': '巴拿马',
    'colombia': '哥伦比亚',
    'venezuela': '委内瑞拉',
    'ecuador': '厄瓜多尔',
    'peru': '秘鲁',
    'chile': '智利',
    'argentina': '阿根廷',
    'uruguay': '乌拉圭',
    'paraguay': '巴拉圭',
    'bolivia': '玻利维亚',
    'guinea': '几内亚',
    'sierra leone': '塞拉利昂',
    'liberia': '利比里亚',
    'ivory coast': '科特迪瓦',
    'togo': '多哥',
    'benin': '贝宁',
    'niger': '尼日尔',
    'cameroon': '喀麦隆',
    'chad': '乍得',
    'central african republic': '中非',
    'gabon': '加蓬',
    'congo': '刚果',
    'democratic republic of the congo': '刚果(金)',
    'angola': '安哥拉',
    'zambia': '赞比亚',
    'malawi': '马拉维',
    'mozambique': '莫桑比克',
    'zimbabwe': '津巴布韦',
    'botswana': '博茨瓦纳',
    'namibia': '纳米比亚',
    'lesotho': '莱索托',
    'swaziland': '斯威士兰',
    'madagascar': '马达加斯加',
    'mauritius': '毛里求斯',
    'seychelles': '塞舌尔',
    'comoros': '科摩罗',
    'sudan': '苏丹',
    'south sudan': '南苏丹',
    'ethiopia': '埃塞俄比亚',
    'eritrea': '厄立特里亚',
    'djibouti': '吉布提',
    'somalia': '索马里',
    'uganda': '乌干达',
    'tanzania': '坦桑尼亚',
    'rwanda': '卢旺达',
    'burundi': '布隆迪',
    'eswatini': '斯威士兰',
  };

  /// 分类标签翻译映射表：将英文分类名映射为中文分类名
  static final Map<String, String> _categoryMap = {
    '流行': '流行',
    'pop': '流行',
    'music': '音乐',
    'classic': '古典',
    'classical': '古典',
    'jazz': '爵士',
    'rock': '摇滚',
    'news': '新闻',
    'talk': '谈话',
    'sports': '体育',
    'electronic': '电子',
    'dance': '舞曲',
    'house': '浩室',
    'trance': '迷幻',
    'club': '俱乐部',
    '#original': '原创',
    '1930': '怀旧',
    'alternative': '另类',
    'ambient': '氛围',
    'blues': '蓝调',
    'country': '乡村',
    'folk': '民谣',
    'heavy metal': '重金属',
    'hip hop': '嘻哈',
    'rap': '说唱',
    'indie': '独立',
    'latin': '拉丁',
    'reggae': '雷鬼',
    'r&b': '节奏布鲁斯',
    'soul': '灵魂',
    'world': '世界音乐',
    'religious': '宗教',
    'christian': '基督教',
    'islamic': '伊斯兰',
    'hindu': '印度教',
    'buddhist': '佛教',
    'business': '商业',
    'finance': '金融',
    'weather': '天气',
    'traffic': '交通',
    'education': '教育',
    'kids': '儿童',
    'oldies': '老歌',
    'retro': '复古',
    '70s': '70年代',
    '80s': '80年代',
    '90s': '90年代',
    '00s': '00年代',
    '2000s': '2000年代',
    '2010s': '2010年代',
    '2020s': '2020年代',
    'christmas': '圣诞',
    'holiday': '节日',
    'party': '派对',
    'chill': '放松',
    'sleep': '助眠',
    'study': '学习',
    'work': '工作',
    'gym': '健身',
    'running': '跑步',
    'yoga': '瑜伽',
    'meditation': '冥想',
    'cafe': '咖啡馆',
    'restaurant': '餐厅',
    'hotel': '酒店',
    'mall': '商场',
    'airport': '机场',
    'train': '火车',
    'car': '车载',
    'travel': '旅行',
    'nature': '自然',
    'ocean': '海洋',
    'forest': '森林',
    'rain': '雨声',
    'fire': '火焰',
    'thunder': '雷声',
    'white noise': '白噪音',
    'podcast': '播客',
    'radio drama': '广播剧',
    'storytelling': '故事',
    'comedy': '喜剧',
    'humor': '幽默',
    'games': '游戏',
    'gaming': '游戏',
    'esports': '电竞',
    'movie': '电影',
    'tv': '电视',
    'celebrity': '名人',
    'interview': '访谈',
    'live': '直播',
    'concert': '演唱会',
    'festival': '音乐节',
    'awards': '颁奖典礼',
    'talk show': '脱口秀',
    'news talk': '新闻谈话',
    'sports talk': '体育谈话',
    'political': '政治',
    'current affairs': '时事',
    'debate': '辩论',
    'commentary': '评论',
    'opinion': '观点',
    'call in': '热线',
    'request': '点歌',
    'dedication': '点播',
    'love songs': '情歌',
    'ballads': '民谣',
    'instrumental': '器乐',
    'acoustic': '原声',
    'live music': '现场音乐',
    'session': '演出',
    'jam': '即兴',
    'covers': '翻唱',
    'remix': '混音',
    'remixes': '混音',
    'dubstep': '回响贝斯',
    'drum and bass': '鼓打贝斯',
    'techno': '铁克诺',
    'minimal': '极简',
    'progressive': '前卫',
    'deep house': '深度浩室',
    'tropical house': '热带浩室',
    'future bass': '未来贝斯',
    'chillwave': '冷潮',
    'synthwave': '合成波',
    'vaporwave': '蒸汽波',
    'lo-fi': '低保真',
    'lofi': '低保真',
    'chillhop': '冷嘻哈',
    'jazz hop': '爵士嘻哈',
    'trip hop': '神游嘻哈',
    'downtempo': '慢板',
    'experimental': '实验',
    'noise': '噪音',
    'industrial': '工业',
    'punk': '朋克',
    'post-punk': '后朋克',
    'new wave': '新浪潮',
    'goth': '哥特',
    'emo': '情绪',
    'screamo': '嘶吼',
    'metalcore': '金属核',
    'death metal': '死亡金属',
    'black metal': '黑金属',
    'thrash metal': '鞭挞金属',
    'power metal': '力量金属',
    'progressive metal': '前卫金属',
    'nu metal': '新金属',
    'grunge': '垃圾摇滚',
    'garage': '车库',
    'surf': '冲浪',
    'psych rock': '迷幻摇滚',
    'psychedelic': '迷幻',
    'space rock': '太空摇滚',
    'shoegaze': '盯鞋',
    'dream pop': '梦幻流行',
    'indie pop': '独立流行',
    'synth pop': '合成器流行',
    'disco': '迪斯科',
    'funk': '放克',
    'salsa': '萨尔萨',
    'merengue': '梅伦格',
    'bachata': '巴恰塔',
    'reggaeton': '雷鬼顿',
    'cumbia': '昆比亚',
    'tango': '探戈',
    'bossanova': '巴萨诺瓦',
    'bossa nova': '巴萨诺瓦',
    'mpb': '巴西流行',
    'samba': '桑巴',
    'pagode': '帕戈德',
    'forró': '弗罗罗',
    'axe': '阿克斯',
    'k-pop': '韩流',
    'j-pop': '日流行',
    'c-pop': '华语流行',
    'mandopop': '华语流行',
    'cantopop': '粤语流行',
    'taiwanese': '台语',
    'hokkien': '闽南语',
    'teochew': '潮州话',
    'hakka': '客家话',
    'chinese classical': '中国古典',
    'traditional': '传统',
    'folk music': '民间音乐',
    'world music': '世界音乐',
    'celtic': '凯尔特',
    'irish': '爱尔兰',
    'scottish': '苏格兰',
    'welsh': '威尔士',
    'breton': '布列塔尼',
    'galician': '加利西亚',
    'asturian': '阿斯图里亚斯',
    'basque': '巴斯克',
    'catalan': '加泰罗尼亚',
    'andalusian': '安达卢西亚',
    'flamenco': '弗拉门戈',
    'rumba': '伦巴',
    'sardinian': '撒丁岛',
    'sicilian': '西西里',
    'neapolitan': '那不勒斯',
    'venetian': '威尼斯',
    'florentine': '佛罗伦萨',
    'romanian': '罗马尼亚',
    'bulgarian': '保加利亚',
    'serbian': '塞尔维亚',
    'croatian': '克罗地亚',
    'slovenian': '斯洛文尼亚',
    'macedonian': '马其顿',
    'albanian': '阿尔巴尼亚',
    'greek': '希腊',
    'turkish': '土耳其',
    'arabic': '阿拉伯',
    'persian': '波斯',
    'kurdish': '库尔德',
    'armenian': '亚美尼亚',
    'georgian': '格鲁吉亚',
    'azerbaijani': '阿塞拜疆',
  };

  /// 获取翻译后的电台名称
  ///
  /// 如果电台名称在 [_stationNameMap] 中有映射，则返回映射值；
  /// 否则返回原始名称
  String get _translatedName {
    return _stationNameMap[station.name] ?? station.name;
  }

  /// 翻译国家名称为中文
  ///
  /// 优先精确匹配，其次模糊匹配（国家名称包含关键词）
  String _translateCountry(String country) {
    final lower = country.toLowerCase().trim();
    if (_countryMap.containsKey(lower)) {
      return _countryMap[lower]!;
    }
    for (final key in _countryMap.keys) {
      if (lower.contains(key)) {
        return _countryMap[key]!;
      }
    }
    return country;
  }

  /// 翻译分类标签为中文
  ///
  /// 优先精确匹配，其次模糊匹配（分类名称包含关键词）
  String _translateCategory(String category) {
    final lower = category.toLowerCase().trim();
    if (_categoryMap.containsKey(lower)) {
      return _categoryMap[lower]!;
    }
    for (final key in _categoryMap.keys) {
      if (lower.contains(key)) {
        return _categoryMap[key]!;
      }
    }
    return category;
  }

  @override
  Widget build(BuildContext context) {
    final favoritesService = Provider.of<FavoritesService>(context);
    final playerService = Provider.of<PlayerService>(context);
    final isFavorite = favoritesService.isFavorite(station);
    final isCurrent = playerService.currentStation?.id == station.id;
    final isPlaying = isCurrent && playerService.isPlaying;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isCurrent
            ? BorderSide(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
                width: 1.5,
              )
            : BorderSide.none,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              StationLogo(
                station: station,
                size: 64,
                borderRadius: 10,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            _translatedName,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: isCurrent
                                  ? Theme.of(context).colorScheme.primary
                                  : Theme.of(context).textTheme.bodyLarge?.color,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 4),
                        if (station.flagEmoji.isNotEmpty)
                          Text(
                            station.flagEmoji,
                            style: const TextStyle(fontSize: 14),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.label,
                            size: 12, color: Colors.grey.shade500),
                        const SizedBox(width: 3),
                        Expanded(
                          child: Text(
                            _translateCategory(station.category.isEmpty
                                ? 'Other'
                                : station.category),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _translateCountry(station.country),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 4),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 40,
                    height: 40,
                    child: IconButton(
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () {
                        if (isCurrent) {
                          if (isPlaying) {
                            playerService.pause();
                          } else {
                            playerService.resume();
                          }
                        } else {
                          playerService.play(station);
                        }
                      },
                      icon: Icon(
                        isPlaying ? Icons.pause_circle_filled : Icons.play_circle_fill,
                        size: 36,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 40,
                    height: 40,
                    child: IconButton(
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () =>
                          favoritesService.toggleFavorite(station),
                      icon: Icon(
                        isFavorite ? Icons.favorite : Icons.favorite_border,
                        color: isFavorite ? Colors.red : Colors.grey,
                        size: 24,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}