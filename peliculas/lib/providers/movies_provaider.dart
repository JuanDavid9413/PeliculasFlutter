import 'dart:async';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:peliculas/helpers/debouncer.dart';
import 'package:peliculas/models/models.dart';
import 'package:peliculas/models/now_playing_response.dart';
import 'package:peliculas/models/searchMovieResponse.dart';

class MoviesProvider extends ChangeNotifier {
  String _baseUrl = 'api.themoviedb.org';
  String _apiKey = 'bb0f3fb4571da6b3561c5ba362216bc8';
  String _language = 'es-ES';

  List<Movie> onDisplayMovies = [];
  List<Movie> popularMovies = [];
  Map<int, List<Cast>> moviesCast = {};
  int _popularPage = 0;
  final debouncer = Debouncer(duration: Duration(milliseconds: 500));
  // ignore: close_sinks
  final StreamController<List<Movie>> _suggestionStreamController =
      new StreamController.broadcast();

  Stream<List<Movie>> get suggestionStream =>
      this._suggestionStreamController.stream;

  MoviesProvider() {
    this.getOnDisplayMovies();
    this.getPopularMovies();
  }

  Future<String> _getJsonData(String endpoint, [int page = 1]) async {
    final url = Uri.https(_baseUrl, endpoint,
        {'api_key': _apiKey, 'language': _language, 'page': '$page'});

    final response = await http.get(url);
    return response.body;
  }

  getOnDisplayMovies() async {
    final jsonData = await _getJsonData('3/movie/now_playing');
    final nowPlayingResponse = NowPlayingResponse.fromJson(jsonData);
    onDisplayMovies = nowPlayingResponse.results;

    notifyListeners();
  }

  getPopularMovies() async {
    _popularPage++;
    final jsonData = await _getJsonData('3/movie/popular', _popularPage);
    final popularResponse = PopularResponse.fromJson(jsonData);
    popularMovies = [...popularMovies, ...popularResponse.results];

    notifyListeners();
  }

  Future<List<Cast>> getCastMovie(int idMovie) async {
    if (moviesCast.containsKey(idMovie)) return moviesCast[idMovie]!;
    final jsonData = await _getJsonData('3/movie/$idMovie/credits');
    final castResponse = CastResponse.fromJson(jsonData);
    moviesCast[idMovie] = castResponse.cast;
    return castResponse.cast;
  }

  Future<List<Movie>> searchMovie(String query) async {
    final url = Uri.https(
      _baseUrl,
      '3/search/movie',
      {'api_key': _apiKey, 'language': _language, 'query': query},
    );

    final jsonData = await http.get(url);
    final searchMovieResponse = SearchMovieResponse.fromJson(jsonData.body);
    return searchMovieResponse.results;
  }

  void getSuggestionByQuery(String searchTeem) {
    debouncer.value = '';
    debouncer.onValue = (value) async {
      final results = await this.searchMovie(searchTeem);
      this._suggestionStreamController.add(results);
    };
  }
}
