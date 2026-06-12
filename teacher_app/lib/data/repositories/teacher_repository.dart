import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/api_client.dart';
import '../models/critical_risk.dart';
import '../models/growth_observation.dart';
import '../models/school_class_models.dart';
import '../models/teacher_models.dart';

class TeacherRepository {
  TeacherRepository(this._dio);
  final Dio _dio;

  Future<SchoolClassList> listSchoolClasses() async {
    return unwrap(
      _dio.get('/api/v1/auth/classes'),
      (data) => SchoolClassList.fromJson(data as Map<String, dynamic>),
    );
  }

  Future<AuthToken> register({
    required String username,
    required String nickname,
    required String password,
    required String registrationSecret,
    required String className,
  }) async {
    return unwrap(
      _dio.post('/api/v1/auth/teacher-register', data: {
        'username': username,
        'nickname': nickname,
        'password': password,
        'registration_secret': registrationSecret,
        'class_name': className,
      }),
      (data) => AuthToken.fromJson(data as Map<String, dynamic>),
    );
  }

  Future<TeacherProfile> fetchTeacherProfile() async {
    return unwrap(
      _dio.get('/api/v1/auth/teacher/me'),
      (data) => TeacherProfile.fromJson(data as Map<String, dynamic>),
    );
  }

  Future<AuthToken> login({required String username, required String password}) async {
    return unwrap(
      _dio.post('/api/v1/auth/teacher-login', data: {
        'username': username,
        'password': password,
      }),
      (data) => AuthToken.fromJson(data as Map<String, dynamic>),
    );
  }

  Future<List<TeacherMoodReport>> listMoodReports(String reportDate) async {
    return unwrap(
      _dio.get('/api/v1/teacher/mood-reports/today', queryParameters: {'report_date': reportDate}),
      (data) => (data as List<dynamic>)
          .map((e) => TeacherMoodReport.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Future<TeacherMoodReport> getMoodReport(String studentId, String reportDate) async {
    return unwrap(
      _dio.get(
        '/api/v1/teacher/mood-reports/today/$studentId',
        queryParameters: {'report_date': reportDate},
      ),
      (data) => TeacherMoodReport.fromJson(data as Map<String, dynamic>),
    );
  }

  Future<List<GrowthFocusItem>> listGrowthFocusInRange({
    required String dateFrom,
    required String dateTo,
    bool includeFollowed = true,
  }) async {
    return unwrap(
      _dio.get(
        '/api/v1/teacher/alerts',
        queryParameters: {
          'date_from': dateFrom,
          'date_to': dateTo,
          'include_followed': includeFollowed,
        },
      ),
      (data) => (data as List<dynamic>)
          .map((e) => GrowthFocusItem.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Future<GrowthArchive> getGrowthArchive(String studentId, {int days = 7}) async {
    return unwrap(
      _dio.get(
        '/api/v1/teacher/students/$studentId/growth-archive',
        queryParameters: {'days': days},
      ),
      (data) => GrowthArchive.fromJson(data as Map<String, dynamic>),
    );
  }

  Future<void> markGrowthFollowed(String focusId) async {
    await unwrap(
      _dio.post('/api/v1/teacher/alerts/$focusId/ack'),
      (_) => null,
    );
  }

  Future<void> unmarkGrowthFollowed(String focusId) async {
    await unwrap(
      _dio.post('/api/v1/teacher/alerts/$focusId/unack'),
      (_) => null,
    );
  }

  Future<void> dismissGrowthFocus(String focusId) async {
    await unwrap(
      _dio.delete('/api/v1/teacher/alerts/$focusId'),
      (_) => null,
    );
  }

  Future<TeacherFollowUp> createFollowUp({
    required String studentId,
    required String action,
    String? note,
  }) async {
    return unwrap(
      _dio.post(
        '/api/v1/teacher/students/$studentId/follow-ups',
        data: {'action': action, 'note': note},
      ),
      (data) => TeacherFollowUp.fromJson(data as Map<String, dynamic>),
    );
  }

  Future<void> dismissRiskExposure({
    required String studentId,
    required String momentId,
  }) async {
    await unwrap(
      _dio.post('/api/v1/teacher/students/$studentId/risk-exposures/$momentId/dismiss'),
      (_) => null,
    );
  }

  Future<List<CriticalRiskSignal>> listCriticalRiskSignals({
    required String dateFrom,
    required String dateTo,
    bool includeFollowed = true,
  }) async {
    return unwrap(
      _dio.get(
        '/api/v1/teacher/risk-signals',
        queryParameters: {
          'date_from': dateFrom,
          'date_to': dateTo,
          'include_followed': includeFollowed,
        },
      ),
      (data) => (data as List<dynamic>)
          .map((e) => CriticalRiskSignal.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Future<int> pendingCriticalRiskCount({
    required String dateFrom,
    required String dateTo,
  }) async {
    return unwrap(
      _dio.get(
        '/api/v1/teacher/risk-signals/pending-count',
        queryParameters: {'date_from': dateFrom, 'date_to': dateTo},
      ),
      (data) => (data as num).toInt(),
    );
  }

  Future<void> markCriticalRiskFollowed({
    required String momentId,
    String? note,
  }) async {
    await unwrap(
      _dio.post(
        '/api/v1/teacher/risk-signals/$momentId/follow',
        data: {'note': note},
      ),
      (_) => null,
    );
  }

  Future<void> reactivateCriticalRisk(String momentId) async {
    await unwrap(
      _dio.post('/api/v1/teacher/risk-signals/$momentId/reactivate'),
      (_) => null,
    );
  }

  Future<CriticalRiskDetail> getCriticalRiskDetail(String momentId) async {
    return unwrap(
      _dio.get('/api/v1/teacher/risk-signals/$momentId'),
      (data) => CriticalRiskDetail.fromJson(data as Map<String, dynamic>),
    );
  }

  @Deprecated('Use listGrowthFocusInRange')
  Future<List<TeacherAlert>> listAlertsInRange({
    required String dateFrom,
    required String dateTo,
    bool includeAcked = true,
  }) async {
    return unwrap(
      _dio.get(
        '/api/v1/teacher/alerts',
        queryParameters: {
          'date_from': dateFrom,
          'date_to': dateTo,
          'include_acked': includeAcked,
        },
      ),
      (data) => (data as List<dynamic>)
          .map((e) => TeacherAlert.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Future<void> ackAlert(String alertId) => markGrowthFollowed(alertId);

  Future<void> dismissAlert(String alertId) => dismissGrowthFocus(alertId);
}

final teacherRepositoryProvider = Provider<TeacherRepository>((ref) {
  return TeacherRepository(ref.watch(dioProvider));
});
