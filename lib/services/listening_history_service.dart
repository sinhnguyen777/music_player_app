import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/listening_history.dart';
import '../models/track.dart';

class ListeningHistoryService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final String _collection = 'listening_history';

  /// Thêm lịch sử nghe nhạc
  Future<bool> addListeningHistory(
    Track track, {
    required int playDuration, // Thời gian nghe thực tế (giây)
    required double playPercentage, // Phần trăm nghe (0.0 - 1.0)
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        print('❌ User chưa đăng nhập');
        return false;
      }

      // Chỉ lưu lịch sử nếu nghe ít nhất 30 giây hoặc 30% bài hát
      if (playDuration < 30 && playPercentage < 0.3) {
        print('⏭️ Không lưu lịch sử: nghe quá ngắn');
        return false;
      }

      print('📝 Đang lưu lịch sử nghe nhạc: ${track.title} - ${track.artist}');

      final history = ListeningHistory(
        id: '', // Firestore sẽ tự tạo ID
        userFirebaseUid: user.uid,
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

      await _firestore.collection(_collection).add(history.toFirestore());
      print('✅ Saved listening history successfully');
      return true;
    } catch (e) {
      print('❌ Error loading history: $e');
      return false;
    }
  }

  /// Get user's listening history (simplified to avoid complex index)
  Future<List<ListeningHistory>> getUserListeningHistory({
    int limit = 50,
    DocumentSnapshot? lastDocument,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        print('❌ User chưa đăng nhập');
        return [];
      }

      print('🔍 Loading listening history...');

      // Chỉ query với where clause, không dùng orderBy để tránh composite index
      final snapshot = await _firestore
          .collection(_collection)
          .where('userFirebaseUid', isEqualTo: user.uid)
          .limit(limit)
          .get();

      final histories = snapshot.docs
          .map((doc) => ListeningHistory.fromFirestoreMap(doc.data(), doc.id))
          .toList();

      // Sắp xếp theo thời gian trong memory
      histories.sort((a, b) => b.listenedAt.compareTo(a.listenedAt));

      print('✅ Tải được ${histories.length} lịch sử');
      return histories;
    } catch (e) {
      print('❌ Error loading history: $e');
      return [];
    }
  }

  /// Lấy lịch sử nghe nhạc theo ngày
  Future<List<ListeningHistory>> getHistoryByDate(DateTime date) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return [];

      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      final snapshot = await _firestore
          .collection(_collection)
          .where('userFirebaseUid', isEqualTo: user.uid)
          .where(
            'listenedAt',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay),
          )
          .where('listenedAt', isLessThan: Timestamp.fromDate(endOfDay))
          .orderBy('listenedAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => ListeningHistory.fromFirestoreMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      print('❌ Error loading history by date: $e');
      return [];
    }
  }

  /// Lấy top bài hát được nghe nhiều nhất
  Future<List<Map<String, dynamic>>> getTopTracks({
    int limit = 10,
    int days = 30, // Trong vòng 30 ngày gần đây
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return [];

      final startDate = DateTime.now().subtract(Duration(days: days));

      final snapshot = await _firestore
          .collection(_collection)
          .where('userFirebaseUid', isEqualTo: user.uid)
          .where(
            'listenedAt',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startDate),
          )
          .get();

      // Đếm số lần nghe mỗi bài hát
      final Map<String, Map<String, dynamic>> trackCounts = {};

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final trackId = data['trackId'] as String;

        if (trackCounts.containsKey(trackId)) {
          trackCounts[trackId]!['count'] += 1;
          trackCounts[trackId]!['totalDuration'] += data['playDuration'] ?? 0;
        } else {
          trackCounts[trackId] = {
            'trackId': trackId,
            'trackTitle': data['trackTitle'],
            'trackArtist': data['trackArtist'],
            'trackArtworkUrl': data['trackArtworkUrl'],
            'count': 1,
            'totalDuration': data['playDuration'] ?? 0,
          };
        }
      }

      // Sắp xếp theo số lần nghe
      final sortedTracks = trackCounts.values.toList()
        ..sort((a, b) => (b['count'] as int).compareTo(a['count'] as int));

      return sortedTracks.take(limit).toList();
    } catch (e) {
      print('❌ Error getting top tracks: $e');
      return [];
    }
  }

  /// Lấy thống kê nghe nhạc
  Future<Map<String, dynamic>> getListeningStats({int days = 30}) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return {};

      final startDate = DateTime.now().subtract(Duration(days: days));

      final snapshot = await _firestore
          .collection(_collection)
          .where('userFirebaseUid', isEqualTo: user.uid)
          .where(
            'listenedAt',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startDate),
          )
          .get();

      int totalTracks = snapshot.docs.length;
      int totalDuration = 0;
      Set<String> uniqueArtists = {};
      Map<String, int> genreCounts = {};

      for (final doc in snapshot.docs) {
        final data = doc.data();
        totalDuration += (data['playDuration'] ?? 0) as int;
        uniqueArtists.add(data['trackArtist'] ?? '');

        // Có thể thêm genre từ metadata nếu có
        final metadata = data['metadata'] as Map<String, dynamic>?;
        if (metadata != null && metadata['genres'] != null) {
          final genres = List<String>.from(metadata['genres']);
          for (final genre in genres) {
            genreCounts[genre] = (genreCounts[genre] ?? 0) + 1;
          }
        }
      }

      return {
        'totalTracks': totalTracks,
        'totalDuration': totalDuration, // Tổng thời gian nghe (giây)
        'uniqueArtists': uniqueArtists.length,
        'averagePerDay': (totalTracks / days).round(),
        'topGenres': genreCounts.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value)),
      };
    } catch (e) {
      print('❌ Error getting statistics: $e');
      return {};
    }
  }

  /// Xóa lịch sử cũ (older than specified days)
  Future<bool> cleanOldHistory({int keepDays = 90}) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      final cutoffDate = DateTime.now().subtract(Duration(days: keepDays));

      final snapshot = await _firestore
          .collection(_collection)
          .where('userFirebaseUid', isEqualTo: user.uid)
          .where('listenedAt', isLessThan: Timestamp.fromDate(cutoffDate))
          .get();

      // Xóa theo batch để tránh timeout
      final batch = _firestore.batch();
      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
      print('✅ Đã xóa ${snapshot.docs.length} lịch sử cũ');
      return true;
    } catch (e) {
      print('❌ Error deleting old history: $e');
      return false;
    }
  }

  /// Stream lịch sử real-time
  Stream<List<ListeningHistory>> getHistoryStream({int limit = 20}) {
    final user = _auth.currentUser;
    if (user == null) {
      return Stream.value([]);
    }

    return _firestore
        .collection(_collection)
        .where('userFirebaseUid', isEqualTo: user.uid)
        .orderBy('listenedAt', descending: true)
        .limit(limit)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(
                (doc) => ListeningHistory.fromFirestoreMap(doc.data(), doc.id),
              )
              .toList(),
        );
  }
}
