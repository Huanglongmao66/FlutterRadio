import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:online_fm_radio/data/models/station.dart';
import 'package:online_fm_radio/shared/components/station_card.dart';
import 'package:online_fm_radio/features/home/home_page_view_model.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('FM Radio'),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              decoration: InputDecoration(
                hintText: '搜索电台...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey[100],
              ),
              onChanged: (value) {
                Provider.of<HomePageViewModel>(context, listen: false)
                    .setSearchKeyword(value);
              },
            ),
          ),
        ),
      ),
      body: Consumer<HomePageViewModel>(
        builder: (context, viewModel, child) {
          if (viewModel.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          return Column(
            children: [
              _buildCategoryFilter(context, viewModel),
              _buildCountryFilter(context, viewModel),
              Expanded(child: _buildStationList(viewModel)),
            ],
          );
        },
      ),
    );
  }

  Widget _buildCategoryFilter(
      BuildContext context, HomePageViewModel viewModel) {
    return SizedBox(
      height: 50,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        children: [
          _buildFilterChip(
            context,
            '全部',
            viewModel.currentCategory == null,
            () => viewModel.setCategory(null),
          ),
          ...viewModel.categories.map((category) => _buildFilterChip(
                context,
                category,
                viewModel.currentCategory == category,
                () => viewModel.setCategory(category),
              )),
        ],
      ),
    );
  }

  Widget _buildCountryFilter(
      BuildContext context, HomePageViewModel viewModel) {
    return SizedBox(
      height: 50,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        children: [
          _buildFilterChip(
            context,
            '全部地区',
            viewModel.currentCountry == null,
            () => viewModel.setCountry(null),
          ),
          ...viewModel.countries.map((country) => _buildFilterChip(
                context,
                country,
                viewModel.currentCountry == country,
                () => viewModel.setCountry(country),
              )),
        ],
      ),
    );
  }

  Widget _buildFilterChip(
    BuildContext context,
    String label,
    bool isSelected,
    VoidCallback onPressed,
  ) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (_) => onPressed(),
        selectedColor: Theme.of(context).colorScheme.primary,
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : Theme.of(context).colorScheme.onSurface,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }

  Widget _buildStationList(HomePageViewModel viewModel) {
    if (viewModel.filteredStations.isEmpty) {
      return const Center(
        child: Text('没有找到匹配的电台'),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: viewModel.filteredStations.length,
      itemBuilder: (context, index) {
        final station = viewModel.filteredStations[index];
        return StationCard(
          station: station,
          onTap: () => _navigateToPlayer(context, station),
        );
      },
    );
  }

  void _navigateToPlayer(BuildContext context, Station station) {
    Navigator.pushNamed(
      context,
      '/player',
      arguments: station,
    );
  }
}