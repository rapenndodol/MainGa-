import 'package:flutter/foundation.dart';
import '../../data/models/library_entry_model.dart';

class LibraryNotifier extends ChangeNotifier {
  LibraryNotifier._();
  static final LibraryNotifier instance = LibraryNotifier._();

  int? lastModifiedGameId;
  String? lastModifiedStatus;
  LibraryEntryModel? lastModifiedEntry;
  bool lastActionWasDelete = false;

  void notifyAdded(LibraryEntryModel entry) {
    lastModifiedGameId = entry.gameId;
    lastModifiedStatus = entry.status;
    lastModifiedEntry = entry;
    lastActionWasDelete = false;
    notifyListeners();
  }

  void notifyUpdated(LibraryEntryModel entry) {
    lastModifiedGameId = entry.gameId;
    lastModifiedStatus = entry.status;
    lastModifiedEntry = entry;
    lastActionWasDelete = false;
    notifyListeners();
  }

  void notifyDeleted(int gameId) {
    lastModifiedGameId = gameId;
    lastModifiedStatus = null;
    lastModifiedEntry = null;
    lastActionWasDelete = true;
    notifyListeners();
  }

  void notifyGeneralChange() {
    notifyListeners();
  }
}
