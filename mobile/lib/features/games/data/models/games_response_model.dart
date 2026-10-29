import 'game_model.dart';

class GamesResponseModel {
  final bool success;
  final String message;
  final List<GameModel> games;
  final int currentPage;
  final int lastPage;
  final int total;

  const GamesResponseModel({
    required this.success,
    required this.message,
    required this.games,
    required this.currentPage,
    required this.lastPage,
    required this.total,
  });

  factory GamesResponseModel.fromJson(Map<String, dynamic> json) {
    final bool success = json['success'] == true;
    final String message = (json['message'] ?? '').toString();

    List<GameModel> games = [];
    int currentPage = 1;
    int lastPage = 1;
    int total = 0;

    if (json['data'] is Map<String, dynamic>) {
      final data = json['data'] as Map<String, dynamic>;
      if (data['games'] is List) {
        games = (data['games'] as List)
            .map((item) => GameModel.fromJson(item as Map<String, dynamic>))
            .toList();
      }

      if (data['pagination'] is Map<String, dynamic>) {
        final pag = data['pagination'] as Map<String, dynamic>;
        currentPage = pag['current_page'] is int ? pag['current_page'] as int : 1;
        lastPage = pag['last_page'] is int ? pag['last_page'] as int : 1;
        total = pag['total'] is int ? pag['total'] as int : games.length;
      }
    }

    return GamesResponseModel(
      success: success,
      message: message,
      games: games,
      currentPage: currentPage,
      lastPage: lastPage,
      total: total,
    );
  }
}
