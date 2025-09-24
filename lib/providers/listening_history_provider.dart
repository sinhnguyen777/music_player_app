import 'package:flutter/material.dart';

import '../models/listening_history.dart';
import '../models/track.dart';
import '../services/listening_history_service.dart';

class ListeningHistoryProvider with ChangeNotifier {
  final ListeningHistoryService _service = ListeningHistoryService();

  List<ListeningHistory> _history = [];
  Map<String, dynamic> _stats = {};
  List<Map<String, dynamic>> _topTracks = [];
  bool _isLoading = false;
  String? _error;

  // Getters
  List<ListeningHistory> get history => _history;
  Map<String, dynamic> get stats => _stats;
  List<Map<String, dynamic>> get topTracks => _topTracks;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Add listening history
  Future<bool> addListeningHistory(
    Track track, {
    required int playDuration,
    required double playPercentage,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final success = await _service.addListeningHistory(
        track,
        playDuration: playDuration,
        playPercentage: playPercentage,
        metadata: metadata,
      );

      if (success) {
        // Thêm vào đầu danh sách history local để UI cập nhật ngay
        final newHistory = ListeningHistory(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          userFirebaseUid: '', // Sẽ được cập nhật từ Firestore
          trackId: track.id,
          trackTitle: track.title,
          trackArtist: track.artist,
          trackArtworkUrl: track.artworkUrl,
          trackDuration: track.duration,
          listenedAt: DateTime.now(),
          playDuration: playDuration,
          playPercentage: playPercentage,
          source: track.source ?? 'unknown',
          metadata: metadata,
        );

        _history.insert(0, newHistory);
        notifyListeners();
      }

      return success;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Load listening history
  Future<void> loadHistory({int limit = 50}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _history = await _service.getUserListeningHistory(limit: limit);
    } catch (e) {
      _error = e.toString();
      _history = [];
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Load more history (pagination)
  Future<void> loadMoreHistory() async {
    if (_history.isEmpty) return;

    try {
      // Note: Để đơn giản, chúng ta sẽ không implement pagination phức tạp
      // Chỉ load thêm history
      final moreHistory = await _service.getUserListeningHistory(limit: 20);

      // Lọc bỏ những item đã có
      final newItems = moreHistory
          .where((item) => !_history.any((existing) => existing.id == item.id))
          .toList();

      if (newItems.isNotEmpty) {
        _history.addAll(newItems);
        notifyListeners();
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  /// Load statistics
  Future<void> loadStats({int days = 30}) async {
    try {
      _stats = await _service.getListeningStats(days: days);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  /// Load top tracks
  Future<void> loadTopTracks({int limit = 10, int days = 30}) async {
    try {
      _topTracks = await _service.getTopTracks(limit: limit, days: days);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  /// Load all data
  Future<void> loadAll() async {
    await Future.wait([loadHistory(), loadStats(), loadTopTracks()]);
  }

  /// Refresh data
  Future<void> refresh() async {
    await loadAll();
  }

  /// Delete old history
  Future<bool> cleanOldHistory({int keepDays = 90}) async {
    try {
      final success = await _service.cleanOldHistory(keepDays: keepDays);
      if (success) {
        await loadHistory(); // Reload after cleaning
      }
      return success;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Get history by date
  Future<List<ListeningHistory>> getHistoryByDate(DateTime date) async {
    try {
      return await _service.getHistoryByDate(date);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return [];
    }
  }

  /// Format listening time
  String formatListeningTime(int seconds) {
    if (seconds < 60) {
      return '${seconds}s';
    } else if (seconds < 3600) {
      final minutes = seconds ~/ 60;
      final remainingSeconds = seconds % 60;
      return remainingSeconds > 0
          ? '${minutes}m ${remainingSeconds}s'
          : '${minutes}m';
    } else {
      final hours = seconds ~/ 3600;
      final minutes = (seconds % 3600) ~/ 60;
      return minutes > 0 ? '${hours}h ${minutes}m' : '${hours}h';
    }
  }

  /// Format total listening time from stats
  String formatTotalListeningTime() {
    final totalSeconds = _stats['totalDuration'] as int? ?? 0;
    return formatListeningTime(totalSeconds);
  }

  /// Get recent tracks (unique tracks)
  List<ListeningHistory> getRecentUniqueTracks({int limit = 10}) {
    final Set<String> seenTrackIds = {};
    final List<ListeningHistory> uniqueTracks = [];

    for (final history in _history) {
      if (!seenTrackIds.contains(history.trackId)) {
        seenTrackIds.add(history.trackId);
        uniqueTracks.add(history);
        if (uniqueTracks.length >= limit) break;
      }
    }

    return uniqueTracks;
  }

  /// Clear cache
  void clearCache() {
    _history.clear();
    _stats.clear();
    _topTracks.clear();
    _error = null;
    notifyListeners();
  }
}
