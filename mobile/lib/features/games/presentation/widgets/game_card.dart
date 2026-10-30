import 'package:flutter/material.dart';
import '../../../../core/widgets/app_game_card.dart';
import '../../data/models/game_model.dart';

/// GameCard yang mendelegasikan ke AppGameCard terpusat.
class GameCard extends StatelessWidget {
  final GameModel game;
  final VoidCallback? onTap;

  const GameCard({
    super.key,
    required this.game,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AppGameCard(game: game, onTap: onTap);
  }
}
