import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../widgets/media_card.dart';
import '../widgets/genre_selector.dart';
import '../screens/single_series_screen.dart';
import '../providers/series_provider.dart';
import '../providers/genre_provider.dart';
import '../providers/countries_provider.dart';
import '../models/media_item.dart';
import '../utils/storage_utils.dart';

class SeriesScreen extends StatefulWidget {
  const SeriesScreen({super.key});

  @override
  State<SeriesScreen> createState() => _SeriesScreenState();
}

class _SeriesScreenState extends State<SeriesScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final seriesProvider = Provider.of<SeriesProvider>(
        context,
        listen: false,
      );
      final countriesProvider = Provider.of<CountriesProvider>(
        context,
        listen: false,
      );

      if (countriesProvider.countries.isEmpty) {
        countriesProvider.loadCountries();
      }

      if (seriesProvider.series.isEmpty) {
        seriesProvider.loadSeries();
      }
    });

    _scrollController.addListener(_scrollListener);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    super.dispose();
  }


  void _scrollListener() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      final seriesProvider = Provider.of<SeriesProvider>(
        context,
        listen: false,
      );
      if (!seriesProvider.isLoading && seriesProvider.hasMore) {
        seriesProvider.loadSeries();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'سریال‌ها',
              style: GoogleFonts.vazirmatn(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            // Filter and sort options
            Wrap(
              spacing: 12,
              runSpacing: 12,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                // Genre filter button
                Consumer<GenreProvider>(
                  builder: (context, genreProvider, child) {
                    return ElevatedButton(
                      onPressed: () {
                        final seriesProvider = Provider.of<SeriesProvider>(
                          context,
                          listen: false,
                        );

                        showModalBottomSheet(
                          context: context,
                          builder: (context) => GenreSelector(
                            onGenreSelected: seriesProvider.selectGenre,
                          ),
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.vertical(
                              top: Radius.circular(20),
                            ),
                          ),
                        );
                      },
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            genreProvider.selectedGenre?.title ?? 'ژانرها',
                            style: GoogleFonts.vazirmatn(),
                          ),
                          const Icon(Icons.arrow_drop_down),
                        ],
                      ),
                    );
                  },
                ),
                // Country filter dropdown
                Consumer2<CountriesProvider, SeriesProvider>(
                  builder: (context, countriesProvider, seriesProvider, child) {
                    return DropdownButton<int>(
                      value: seriesProvider.selectedCountryId,
                      items: [
                        const DropdownMenuItem<int>(
                          value: 0,
                          child: Text('همه کشورها'),
                        ),
                        ...countriesProvider.countries.map(
                          (country) => DropdownMenuItem<int>(
                            value: country.id,
                            child: Text(country.title),
                          ),
                        ),
                      ],
                      onChanged: (value) {
                        if (value == null) return;
                        seriesProvider.selectCountry(value);
                      },
                    );
                  },
                ),
                // Sort filter dropdown
                Consumer<SeriesProvider>(
                  builder: (context, seriesProvider, child) {
                    return DropdownButton<FilterType>(
                      value: seriesProvider.selectedFilter,
                      items: const [
                        DropdownMenuItem(
                          value: FilterType.defaultFilter,
                          child: Text('پیشفرض'),
                        ),
                        DropdownMenuItem(
                          value: FilterType.byYear,
                          child: Text('بر اساس سال'),
                        ),
                        DropdownMenuItem(
                          value: FilterType.byImdb,
                          child: Text('بر اساس IMDB'),
                        ),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          seriesProvider.selectFilter(value);
                        }
                      },
                    );
                  },
                ),
                // Refresh button
                IconButton(
                  icon: const Icon(Icons.refresh),
                  tooltip: 'تازه‌سازی از ابتدا',
                  onPressed: () {
                    final seriesProvider = Provider.of<SeriesProvider>(
                      context,
                      listen: false,
                    );
                    seriesProvider.refreshSeries();
                  },
                ),
              ],
            ),
            const SizedBox(height: 20),
            // Series grid
            Expanded(
              child: Consumer<SeriesProvider>(
                builder: (context, seriesProvider, child) {
                  if (seriesProvider.isLoading &&
                      seriesProvider.series.isEmpty) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (seriesProvider.errorMessage.isNotEmpty &&
                      seriesProvider.series.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('Error: ${seriesProvider.errorMessage}'),
                          const SizedBox(height: 20),
                          Wrap(
                            spacing: 12,
                            children: [
                              ElevatedButton(
                                onPressed: seriesProvider.refreshSeries,
                                child: const Text('تلاش مجدد'),
                              ),
                              ElevatedButton.icon(
                                onPressed: () => seriesProvider.loadSeries(isRetry: true),
                                icon: const Icon(Icons.download_rounded),
                                label: const Text('بارگذاری صفحات بعدی'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  }

                  if (seriesProvider.series.isEmpty && !seriesProvider.isLoading) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.tv_off_outlined,
                            size: 64,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'سریالی در این بخش یافت نشد',
                            style: GoogleFonts.vazirmatn(
                              fontSize: 18,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 16),
                          Wrap(
                            spacing: 12,
                            children: [
                              ElevatedButton.icon(
                                onPressed: () => seriesProvider.loadSeries(isRetry: true),
                                icon: const Icon(Icons.download_rounded),
                                label: Text(
                                  'تلاش برای بارگذاری موارد بعدی',
                                  style: GoogleFonts.vazirmatn(),
                                ),
                              ),
                              OutlinedButton.icon(
                                onPressed: seriesProvider.refreshSeries,
                                icon: const Icon(Icons.refresh),
                                label: Text(
                                  'تازه‌سازی از ابتدا',
                                  style: GoogleFonts.vazirmatn(),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  }

                  return LayoutBuilder(
                    builder: (context, constraints) {
                      // Calculate cross axis count based on available width
                      final cardWidth = 200.0;
                      final spacing = 20.0;
                      final crossAxisCount =
                          ((constraints.maxWidth + spacing) /
                                  (cardWidth + spacing))
                              .floor()
                              .toInt();

                      // Ensure at least 1 column and max 5 columns
                      final count = crossAxisCount.clamp(1, 5);

                      return CustomScrollView(
                        controller: _scrollController,
                        slivers: [
                          SliverGrid(
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: count,
                              childAspectRatio: 0.68,
                              crossAxisSpacing: 20,
                              mainAxisSpacing: 20,
                            ),
                            delegate: SliverChildBuilderDelegate(
                              (context, index) {
                                final series = seriesProvider.series[index];
                                return MediaCard(
                                  mediaItem: MediaItem(
                                    id: series.id,
                                    type: series.type,
                                    title: series.title,
                                    description: series.description,
                                    year: series.year,
                                    imdb: series.imdb,
                                    rating: series.rating,
                                    duration: series.duration,
                                    image: series.image,
                                    cover: series.cover,
                                    genres: series.genres
                                        .map((g) => Genre(id: g.id, title: g.title))
                                        .toList(),
                                    sources: [],
                                    countries: series.countries
                                        .map(
                                          (c) => Country(
                                            id: c.id,
                                            title: c.title,
                                            image: c.image,
                                          ),
                                        )
                                        .toList(),
                                  ),
                                  onTap: () async {
                                    await StorageUtils.saveSeries(series);
                                    if (context.mounted) {
                                      Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              SingleSeriesScreen(series: series),
                                        ),
                                      );
                                    }
                                  },
                                );
                              },
                              childCount: seriesProvider.series.length,
                            ),
                          ),
                          SliverToBoxAdapter(
                            child: _buildFooter(context, seriesProvider),
                          ),
                        ],
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFooter(BuildContext context, SeriesProvider provider) {
    if (provider.isLoading) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 28.0),
        child: Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2.5),
              ),
              const SizedBox(width: 14),
              Text(
                'در حال بارگذاری موارد بیشتر...',
                style: GoogleFonts.vazirmatn(fontSize: 14),
              ),
            ],
          ),
        ),
      );
    }

    if (provider.errorMessage.isNotEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 24.0),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'خطا در بارگذاری موارد بعدی: ${provider.errorMessage}',
                style: GoogleFonts.vazirmatn(color: Colors.redAccent, fontSize: 13),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: () => provider.loadSeries(isRetry: true),
                icon: const Icon(Icons.refresh_rounded),
                label: Text(
                  'تلاش مجدد برای بارگذاری موارد بعدی',
                  style: GoogleFonts.vazirmatn(),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 28.0),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ElevatedButton.icon(
              onPressed: () => provider.loadSeries(isRetry: true),
              icon: Icon(
                provider.hasMore ? Icons.expand_more_rounded : Icons.refresh_rounded,
              ),
              label: Text(
                provider.hasMore
                    ? 'بیشتر'
                    : 'تلاش مجدد',
                style: GoogleFonts.vazirmatn(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            if (!provider.hasMore) ...[
              const SizedBox(height: 8),
              Text(
                'به انتهای موارد فعلی رسیدید. با دکمه بالا می‌توانید صفحات بعدی را مجدداً بررسی کنید.',
                style: GoogleFonts.vazirmatn(
                  fontSize: 12,
                  color: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.color
                      ?.withValues(alpha: 0.7),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

