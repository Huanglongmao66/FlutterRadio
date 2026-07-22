import 'package:flutter/material.dart';
import 'package:online_fm_radio/core/services/station_update_service.dart';
import 'package:provider/provider.dart';

class AppTopBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final bool showSearch;
  final bool showCountryFilter;
  final bool showDownload;

  const AppTopBar({
    super.key,
    this.title = '',
    this.showSearch = true,
    this.showCountryFilter = true,
    this.showDownload = true,
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
            onPressed: () => Navigator.pushNamed(context, '/countries'),
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
}
