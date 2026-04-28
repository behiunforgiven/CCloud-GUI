import 'package:flutter/material.dart';
import '../models/country.dart';
import '../models/poster.dart';
import '../models/media_item.dart';
import '../repositories/countries_repository.dart';

class CountriesProvider with ChangeNotifier {
  final CountriesRepository _repository = CountriesRepository();

  List<CountryModel> _countries = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<CountryModel> get countries => _countries;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> loadCountries() async {
    if (_isLoading) return;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _countries = await _repository.getCountries();
    } catch (e) {
      _errorMessage = e.toString();
      _countries = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}

class CountryMediaProvider with ChangeNotifier {
  final CountriesRepository _repository = CountriesRepository();

  List<Poster> _mediaItems = [];
  bool _isLoading = false;
  String? _errorMessage;
  FilterType _currentFilter = FilterType.defaultFilter;
  int _currentPage = 0;
  bool _hasMore = true;
  int _selectedCountryId = 0;

  List<Poster> get mediaItems => _mediaItems;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  FilterType get currentFilter => _currentFilter;
  bool get hasMore => _hasMore;

  Future<void> loadMediaByCountry(
    int countryId, {
    FilterType? filterType,
    bool refresh = false,
  }) async {
    if (_isLoading) return;

    _isLoading = true;
    _errorMessage = null;
    if (filterType != null) {
      _currentFilter = filterType;
    }

    if (refresh) {
      _mediaItems = [];
      _currentPage = 0;
      _hasMore = true;
    }

    _selectedCountryId = countryId;
    notifyListeners();

    try {
      if (!_hasMore) {
        _isLoading = false;
        notifyListeners();
        return;
      }

      final newItems = await _repository.getPostersByCountry(
        countryId,
        page: _currentPage,
        filterType: _currentFilter,
      );

      if (newItems.isEmpty) {
        _hasMore = false;
      } else {
        _mediaItems.addAll(newItems);
        _currentPage++;
      }
    } catch (e) {
      _errorMessage = e.toString();
      if (_mediaItems.isEmpty) {
        _mediaItems = [];
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadMore() async {
    if (_selectedCountryId == 0) return;
    await loadMediaByCountry(_selectedCountryId, filterType: _currentFilter);
  }
}
