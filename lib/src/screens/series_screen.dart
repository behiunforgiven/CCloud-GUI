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

  void _checkAndLoadMore() {
    if (!_scrollController.hasClients) return;
    final seriesProvider = Provider.of<SeriesProvider>(context, listen: false);
    if (seriesProvider.isLoading || !seriesProvider.hasMore) return;
    if (_scrollController.position.maxScrollExtent <= 0) {
      seriesProvider.loadSeries();
    }
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

                  // Add error handling similar to movies screen
                  if (seriesProvider.errorMessage.isNotEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('Error: ${seriesProvider.errorMessage}'),
                          const SizedBox(height: 20),
                          ElevatedButton(
                            onPressed: seriesProvider.refreshSeries,
                            child: const Text('تلاش مجدد'),
                          ),
                        ],
                      ),
                    );
                  }

                  return LayoutBuilder(
                    builder: (context, constraints) {
                      WidgetsBinding.instance.addPostFrameCallback(
                        (_) => _checkAndLoadMore(),
                      );
                      // Calculate cross axis count based on available width
                      final cardWidth = 200.0; // Increased card width
                      final spacing = 20.0;
                      final crossAxisCount =
                          ((constraints.maxWidth + spacing) /
                                  (cardWidth + spacing))
                              .floor()
                              .toInt();

                      // Ensure at least 1 column and max 5 columns
                      final count = crossAxisCount.clamp(1, 5);

                      return GridView.builder(
                        controller: _scrollController,
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount:
                              count, // Use dynamic count instead of fixed 5
                          childAspectRatio:
                              0.68, // Adjusted for the new card dimensions
                          crossAxisSpacing: 20,
                          mainAxisSpacing: 20,
                        ),
                        itemCount:
                            seriesProvider.series.length +
                            (seriesProvider.hasMore ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (index == seriesProvider.series.length) {
                            return Center(
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: seriesProvider.isLoading
                                    ? const CircularProgressIndicator()
                                    : ElevatedButton.icon(
                                        onPressed: seriesProvider.loadSeries,
                                        icon: const Icon(Icons.expand_more),
                                        label: Text(
                                          'بارگذاری بیشتر',
                                          style: GoogleFonts.vazirmatn(),
                                        ),
                                      ),
                              ),
                            );
                          }

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
                              // Save series to storage and navigate to single series screen
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
}
