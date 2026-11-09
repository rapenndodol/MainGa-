import 'package:flutter/foundation.dart';
import '../../data/models/wishlist_item_model.dart';

class WishlistNotifier extends ChangeNotifier {
  WishlistNotifier._();
  static final WishlistNotifier instance = WishlistNotifier._();

  int? lastModifiedGameId;
  int? lastModifiedWishlistId;
  WishlistItemModel? lastModifiedItem;
  bool lastActionWasDelete = false;
  bool? lastModifiedActive;

  void notifyAdded(WishlistItemModel item) {
    lastModifiedGameId = item.gameId;
    lastModifiedWishlistId = item.id;
    lastModifiedItem = item;
    lastModifiedActive = item.aktif;
    lastActionWasDelete = false;
    notifyListeners();
  }

  void notifyUpdated(WishlistItemModel item) {
    lastModifiedGameId = item.gameId;
    lastModifiedWishlistId = item.id;
    lastModifiedItem = item;
    lastModifiedActive = item.aktif;
    lastActionWasDelete = false;
    notifyListeners();
  }

  void notifyDeleted(int wishlistId, {int? gameId}) {
    lastModifiedWishlistId = wishlistId;
    lastModifiedGameId = gameId;
    lastModifiedItem = null;
    lastModifiedActive = null;
    lastActionWasDelete = true;
    notifyListeners();
  }

  void notifyToggled(int wishlistId, bool aktif, {int? gameId}) {
    lastModifiedWishlistId = wishlistId;
    lastModifiedGameId = gameId;
    lastModifiedActive = aktif;
    if (lastModifiedItem != null && lastModifiedItem!.id == wishlistId) {
      lastModifiedItem = lastModifiedItem!.copyWith(aktif: aktif);
    }
    lastActionWasDelete = false;
    notifyListeners();
  }

  void notifyGeneralChange() {
    notifyListeners();
  }
}
