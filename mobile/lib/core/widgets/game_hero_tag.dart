import '../../features/games/data/models/game_model.dart';

/// Membuat tag Hero yang stabil untuk cover sebuah game.
///
/// [scope] membedakan sumber kartu (katalog, rekomendasi, game serupa) agar
/// dua kartu game yang sama tidak bertabrakan saat berada di satu layar.
String gameCoverHeroTag(GameModel game, String scope) {
  final int id = game.id > 0 ? game.id : game.rawgId;
  return 'game-cover-$scope-$id';
}
