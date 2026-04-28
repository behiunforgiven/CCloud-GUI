import 'package:flutter/material.dart';
import '../models/media_item.dart';
import '../repositories/movie_repository.dart';
import '../utils/storage_utils.dart';

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
  int get selectedGenreId => _selectedGenreId;
  int get selectedCountryId => _selectedCountryId;
  FilterType get selectedFilter => _selectedFilter;

  Future<void> loadMovies({bool refresh = false}) async {
    if (_isLoading) return;

    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      if (refresh) {
        _movies = [];
        _currentPage = 0;
        _hasMore = true;
      }

      if (!_hasMore) {
        _isLoading = false;
        notifyListeners();
        return;
      }

      final newMovies = await _movieRepository.getMovies(
        page: _currentPage,
        genreId: 0,
        countryId: _selectedCountryId,
        filterType: _selectedFilter,
      );

      final filteredMovies = newMovies
          .where((movie) => !containsFarsiOrArabic(movie.title))
          .toList();

      if (newMovies.isEmpty) {
        _hasMore = false;
      } else {
        _movies.addAll(filteredMovies);
        _currentPage++;

        if (movies.isEmpty && _hasMore) {
          _isLoading = false;
          notifyListeners();
          await loadMovies();
          return;
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

    if (movies.isEmpty && _hasMore && !_isLoading) {
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
