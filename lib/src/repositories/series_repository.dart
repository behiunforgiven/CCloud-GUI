import 'dart:convert';
import '../models/media_item.dart';
import 'base_repository.dart';

class SeriesRepository extends BaseRepository {
  static const String _seriesEndpoint = '/poster/by/filtres';

  Future<List<MediaItem>> getSeries({
    int page = 0,
    int genreId = 0,
    int countryId = 0,
    FilterType filterType = FilterType.defaultFilter,
  }) async {
    try {
      final url =
          '$baseUrl$_seriesEndpoint/0/$countryId/${filterType.apiValue}/$page/$apiKey';
      final jsonData = await executeRequest(url);
      return parseSeries(jsonData);
    } catch (e) {
      throw Exception('Error fetching series: $e');
    }
  }

  List<MediaItem> parseSeries(String jsonData) {
    final seriesList = <MediaItem>[];
    final jsonArray = json.decode(jsonData) as List;

    for (var item in jsonArray) {
      try {
        final seriesObj = item as Map<String, dynamic>;
        final series = MediaItem.fromJson(seriesObj);
        if (series.type == 'serie') {
          seriesList.add(series);
        }
      } catch (e) {
        // Skip items that fail to parse
        continue;
      }
    }

    return seriesList;
  }
}
