import 'dart:convert';
import '../models/media_item.dart';
import 'base_repository.dart';

class MovieRepository extends BaseRepository {
  static const String _moviesEndpoint = '/poster/by/filtres';

  Future<List<MediaItem>> getMovies({
    int page = 0,
    int genreId = 0,
    int countryId = 0,
    FilterType filterType = FilterType.defaultFilter,
  }) async {
    try {
      final url =
          '${baseUrl}$_moviesEndpoint/0/$countryId/${filterType.apiValue}/$page/${apiKey}';
      final jsonData = await executeRequest(url);
      return parseMovies(jsonData);
    } catch (e) {
      throw Exception('Error fetching movies: $e');
    }
  }

  List<MediaItem> parseMovies(String jsonData) {
    final movies = <MediaItem>[];
    final jsonArray = json.decode(jsonData) as List;

    for (var item in jsonArray) {
      try {
        final movieObj = item as Map<String, dynamic>;
        final movie = MediaItem.fromJson(movieObj);
        if (movie.type == 'movie') {
          movies.add(movie);
        }
      } catch (e) {
        continue;
      }
    }

    return movies;
  }
}
