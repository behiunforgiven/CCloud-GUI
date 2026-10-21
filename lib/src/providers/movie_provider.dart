import 'package:flutter/material.dart';
import '../models/media_item.dart';
import '../repositories/movie_repository.dart';
import '../utils/storage_utils.dart';

const int _kMinVisibleItems = 10;

class MovieProvider with ChangeNotifier {
  final MovieRepository _movieRepository = MovieRepository();

  List<MediaItem> _movies = [];
  bool _isLoading = false;
  String _errorMessage = '';
  int _currentPage = 0;
  bool _hasMore = true;
  int _selectedGenreId = 0;
  int _selectedCountryId = 0;
  FilterType _selectedFilter = FilterType.defaultFilter;

  List<MediaItem> get movies {
    return _movies
        .where(
          (movie) =>
              _selectedGenreId == 0 ||
              movie.genres.any((genre) => genre.id == _selectedGenreId),
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

  Future<void> loadMovies({bool refresh = false, bool isRetry = false}) async {
    if (_isLoading) return;

    if (refresh) {
      _movies = [];
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
      final int initialVisibleCount = movies.length;

      while (_hasMore && consecutiveEmptyTries < maxConsecutiveEmptyTries) {
        final result = await _movieRepository.getMovies(
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

        final filteredMovies = result.items
            .where((movie) => !containsFarsiOrArabic(movie.title))
            .toList();

        _movies.addAll(filteredMovies);

        final currentVisibleCount = movies.length;
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

  Future<void> refreshMovies() async {
    await loadMovies(refresh: true);
  }

  void selectGenre(int genreId) {
    _selectedGenreId = genreId;
    notifyListeners();

    if (movies.length < _kMinVisibleItems && _hasMore && !_isLoading) {
      loadMovies();
    }
  }

  void selectCountry(int countryId) {
    _selectedCountryId = countryId;
    refreshMovies();
  }

  void selectFilter(FilterType filter) {
    _selectedFilter = filter;
    refreshMovies();
  }

  void resetFilters() {
    _selectedGenreId = 0;
    _selectedCountryId = 0;
    _selectedFilter = FilterType.defaultFilter;
    refreshMovies();
  }
}
