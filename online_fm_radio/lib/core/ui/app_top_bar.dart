import 'package:flutter/material.dart';
import 'package:online_fm_radio/core/services/station_update_service.dart';
import 'package:online_fm_radio/data/models/country.dart';
import 'package:online_fm_radio/data/repositories/station_repository.dart';
import 'package:provider/provider.dart';

class AppTopBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final bool showSearch;
  final bool showCountryFilter;
  final bool showDownload;
  final String? selectedCountry;
  final void Function(String?)? onCountrySelected;

  const AppTopBar({
    super.key,
    this.title = '',
    this.showSearch = true,
    this.showCountryFilter = true,
    this.showDownload = true,
    this.selectedCountry,
    this.onCountrySelected,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      leading: Builder(
        builder: (context) {
          return IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
          );
        },
      ),
      title: title.isNotEmpty ? Text(title) : null,
      centerTitle: true,
      actions: [
        if (showSearch)
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => Navigator.pushNamed(context, '/search'),
          ),
        if (showCountryFilter)
          IconButton(
            icon: const Icon(Icons.public),
            onPressed: () => _showCountryPicker(context),
          ),
        if (showDownload)
          Consumer<StationUpdateService>(
            builder: (context, updateService, child) {
              return IconButton(
                icon: updateService.isUpdating
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.download),
                onPressed: updateService.isUpdating
                    ? null
                    : () => updateService.updateAllStations(),
              );
            },
          ),
      ],
    );
  }

  void _showCountryPicker(BuildContext context) async {
    final repository = StationRepository();
    List<Country> countries = [];

    try {
      countries = await repository.loadCountries();
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('加载国家列表失败: $e')),
        );
      }
      return;
    }

    if (!context.mounted) return;

    final result = await showDialog<String?>(
      context: context,
      builder: (context) {
        String searchKeyword = '';
        List<Country> filteredCountries = countries;
        return StatefulBuilder(
          builder: (context, setState) {
            if (searchKeyword.isNotEmpty) {
              filteredCountries = countries
                  .where((c) => c.name.toLowerCase().contains(searchKeyword.toLowerCase()))
                  .toList();
            } else {
              filteredCountries = countries;
            }

            return AlertDialog(
              title: const Text('选择国家/地区'),
              content: SizedBox(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                children: [
                  if (selectedCountry != null || onCountrySelected != null)
                    TextButton.icon(
                      onPressed: () {
                        Navigator.pop(context, '__all__');
                      },
                      icon: const Icon(Icons.public),
                      label: const Text('全部国家'),
                    ),
                  TextField(
                    decoration: const InputDecoration(
                      hintText: '搜索国家...',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    onChanged: (value) {
                      setState(() {
                        searchKeyword = value;
                      });
                    },
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 300,
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: filteredCountries.length,
                      itemBuilder: (context, index) {
                        final country = filteredCountries[index];
                        final isSelected = selectedCountry == country.name;
                        return ListTile(
                          leading: CircleAvatar(
                            radius: 18,
                            backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                            child: Text(
                              country.countryCode.isNotEmpty
                                  ? country.countryCode.substring(0, 2).toUpperCase()
                                  : '?',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.onPrimaryContainer,
                              ),
                            ),
                          ),
                          title: Text(
                            country.name,
                            style: TextStyle(
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              color: isSelected
                                  ? Theme.of(context).colorScheme.primary
                                  : null,
                            ),
                          ),
                          trailing: Text('${country.stationCount}'),
                          onTap: () {
                            Navigator.pop(context, country.name);
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, null),
                  child: const Text('取消'),
                ),
              ],
            );
          },
        );
      },
    );

    if (result != null && onCountrySelected != null) {
      if (result == '__all__') {
        onCountrySelected!(null);
      } else {
        onCountrySelected!(result);
      }
    }
  }
}