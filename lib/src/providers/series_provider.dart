import 'package:flutter/material.dart';
import '../models/media_item.dart';
import '../repositories/series_repository.dart';
import '../utils/storage_utils.dart';

const int _kMinVisibleItems = 10;

class SeriesProvider with ChangeNotifier {
  final SeriesRepository _seriesRepository = SeriesRepository();

  List<MediaItem> _series = [];
  bool _isLoading = false;
  String _errorMessage = '';
  int _currentPage = 0;
  bool _hasMore = true;
  int _selectedGenreId = 0;
  int _selectedCountryId = 0;
  FilterType _selectedFilter = FilterType.defaultFilter;

  List<MediaItem> get series {
    return _series
        .where(
          (item) =>
              (_selectedGenreId == 0 ||
                  item.genres.any((genre) => genre.id == _selectedGenreId)) &&
              (_selectedCountryId == 0 ||
                  item.countries.isEmpty ||
                  item.countries.any(
                    (country) => country.id == _selectedCountryId,
                  )),
        )
        .toList();
  }

  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;
  bool get hasMore => _hasMore;
  int get currentPage => _currentPage;
  int get selectedGenreId => _selectedGenreId;
  int get selectedCountryId => _selectedCountryId;
  FilterType get selectedFilter => _selectedFilter;

  Future<void> loadSeries({bool refresh = false, bool isRetry = false}) async {
    if (_isLoading) return;

    if (refresh) {
      _series = [];
      _currentPage = 0;
      _hasMore = true;
      _errorMessage = '';
    } else if (isRetry) {
      _hasMore = true;
      _errorMessage = '';
    }

    if (!_hasMore) {
      return;
    }

    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      int consecutiveEmptyTries = 0;
      const int maxConsecutiveEmptyTries = 10;
      final int initialVisibleCount = series.length;

      while (_hasMore && consecutiveEmptyTries < maxConsecutiveEmptyTries) {
        final result = await _seriesRepository.getSeries(
          page: _currentPage,
          genreId: 0,
          countryId: _selectedCountryId,
          filterType: _selectedFilter,
        );

        _currentPage++;

        if (result.isApiEmpty) {
          consecutiveEmptyTries++;
          if (consecutiveEmptyTries >= maxConsecutiveEmptyTries) {
            _hasMore = false;
            break;
          }
          continue;
        }

        // Filter out series with Farsi/Arabic titles
        final filteredSeries = result.items
            .where((item) => !containsFarsiOrArabic(item.title))
            .toList();

        _series.addAll(filteredSeries);

        final currentVisibleCount = series.length;
        final newItemsAdded = currentVisibleCount - initialVisibleCount;

        if (newItemsAdded > 0) {
          if (initialVisibleCount > 0 ||
              currentVisibleCount >= _kMinVisibleItems ||
              newItemsAdded >= 5) {
            break;
          }
          consecutiveEmptyTries = 0;
        } else {
          consecutiveEmptyTries++;
          if (consecutiveEmptyTries >= maxConsecutiveEmptyTries) {
            _hasMore = false;
            break;
          }
        }
      }
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refreshSeries() async {
    await loadSeries(refresh: true);
  }

  void selectGenre(int genreId) {
    _selectedGenreId = genreId;
    notifyListeners();

    if (series.length < _kMinVisibleItems && _hasMore && !_isLoading) {
      loadSeries();
    }
  }

  void selectCountry(int countryId) {
    _selectedCountryId = countryId;
    refreshSeries();
  }

  void selectFilter(FilterType filter) {
    _selectedFilter = filter;
    refreshSeries();
  }

  void resetFilters() {
    _selectedGenreId = 0;
    _selectedCountryId = 0;
    _selectedFilter = FilterType.defaultFilter;
    refreshSeries();
  }
}
