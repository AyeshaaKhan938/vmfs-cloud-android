import '../../core/network/api_client.dart';
import '../../core/storage/token_storage.dart';
import '../../models/auth_user.dart';
import '../../models/dashboard.dart';
import '../../models/machine.dart';
import '../../models/order.dart';
import '../../models/product.dart';
import '../../models/reports.dart';
import '../../models/support_ticket.dart';

class VmfsRepository {
  VmfsRepository({
    ApiClient? apiClient,
    TokenStorage? tokenStorage,
  })  : _api = apiClient ?? ApiClient(),
        _tokenStorage = tokenStorage ?? TokenStorage();

  final ApiClient _api;
  final TokenStorage _tokenStorage;

  Future<AuthUser> login({required String email, required String password}) async {
    final data = await _api.post('/auth/login', body: {
      'email': email,
      'password': password,
    });

    final token = data['token'] as String?;
    if (token == null || token.isEmpty) {
      throw Exception('Login failed — no token returned.');
    }

    await _tokenStorage.saveToken(token);

    return AuthUser.fromJson(data['user'] as Map<String, dynamic>);
  }

  Future<void> logout() async {
    try {
      await _api.post('/auth/logout');
    } finally {
      await _tokenStorage.clearToken();
    }
  }

  Future<AuthUser?> restoreSession() async {
    final token = await _tokenStorage.readToken();
    if (token == null || token.isEmpty) {
      return null;
    }

    try {
      final data = await _api.get('/auth/me');
      return AuthUser.fromJson(data['user'] as Map<String, dynamic>);
    } catch (_) {
      await _tokenStorage.clearToken();
      return null;
    }
  }

  Future<DashboardStats> fetchDashboard() async {
    final data = await _api.get('/dashboard');
    return DashboardStats.fromJson(data);
  }

  Future<List<MachineSummary>> fetchMachines({String? search}) async {
    final data = await _api.get('/machines', query: {
      if (search != null && search.isNotEmpty) 'search': search,
    });
    final list = data['machines'] as List<dynamic>? ?? [];
    return list.map((e) => MachineSummary.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<MachineDetail> fetchMachine(int id) async {
    final data = await _api.get('/machines/$id');
    return MachineDetail.fromJson(data);
  }

  Future<List<ProductSummary>> fetchProducts({String? search}) async {
    final data = await _api.get('/products', query: {
      if (search != null && search.isNotEmpty) 'search': search,
    });
    final list = data['products'] as List<dynamic>? ?? [];
    return list.map((e) => ProductSummary.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<ProductDetail> fetchProduct(int id) async {
    final data = await _api.get('/products/$id');
    return ProductDetail.fromJson(data);
  }

  Future<List<OrderSummary>> fetchOrders() async {
    final data = await _api.get('/orders');
    final list = data['orders'] as List<dynamic>? ?? [];
    return list.map((e) => OrderSummary.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<OrderDetail> fetchOrder(int id) async {
    final data = await _api.get('/orders/$id');
    return OrderDetail.fromJson(data);
  }

  Future<List<SupportTicketSummary>> fetchSupportTickets() async {
    final data = await _api.get('/support-tickets');
    final list = data['tickets'] as List<dynamic>? ?? [];
    return list.map((e) => SupportTicketSummary.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<SupportTicketDetail> fetchSupportTicket(int id) async {
    final data = await _api.get('/support-tickets/$id');
    return SupportTicketDetail.fromJson(data);
  }

  Future<SupportTicketSummary> createSupportTicket({
    required int machineId,
    required String issueDescription,
    String priority = 'normal',
  }) async {
    final data = await _api.post('/support-tickets', body: {
      'machine_id': machineId,
      'issue_description': issueDescription,
      'priority': priority,
    });
    return SupportTicketSummary.fromJson(data['ticket'] as Map<String, dynamic>);
  }

  Future<SupportTicketMessage> sendSupportMessage({
    required int ticketId,
    required String body,
  }) async {
    final data = await _api.post('/support-tickets/$ticketId/messages', body: {'body': body});
    return SupportTicketMessage.fromJson(data['message'] as Map<String, dynamic>);
  }

  Future<Map<String, dynamic>> fetchWallet() async {
    return _api.get('/wallet');
  }

  Future<List<Map<String, dynamic>>> fetchRechargeRecords() async {
    final data = await _api.get('/wallet/recharge-records');
    return (data['records'] as List<dynamic>? ?? [])
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
  }

  Future<ReportsSummary> fetchReportsSummary({String period = '30d'}) async {
    final data = await _api.get('/reports/summary', query: {'period': period});
    return ReportsSummary.fromJson(data);
  }

  Future<List<Map<String, dynamic>>> fetchAdvertisements() async {
    final data = await _api.get('/advertisements');
    return _mapList(data['advertisements']);
  }

  Future<List<Map<String, dynamic>>> fetchAdvertisementGroups() async {
    final data = await _api.get('/advertisement-groups');
    return _mapList(data['groups']);
  }

  Future<List<Map<String, dynamic>>> fetchAdvertisementTags() async {
    final data = await _api.get('/advertisement-tags');
    return _mapList(data['tags']);
  }

  Future<List<Map<String, dynamic>>> fetchCoupons() async {
    final data = await _api.get('/coupons');
    return _mapList(data['coupons']);
  }

  Future<List<Map<String, dynamic>>> fetchLotteries() async {
    final data = await _api.get('/lotteries');
    return _mapList(data['lotteries']);
  }

  Future<List<Map<String, dynamic>>> fetchTeamMembers() async {
    final data = await _api.get('/team-members');
    return _mapList(data['members']);
  }

  Future<List<Map<String, dynamic>>> fetchMachineGroups() async {
    final data = await _api.get('/machine-groups');
    return _mapList(data['groups']);
  }

  Future<List<Map<String, dynamic>>> fetchMachineAlarms() async {
    final data = await _api.get('/machine-alarms');
    return _mapList(data['alarms']);
  }

  Future<List<Map<String, dynamic>>> fetchMachineMap() async {
    final data = await _api.get('/machines-map');
    return _mapList(data['machines']);
  }

  Future<List<Map<String, dynamic>>> fetchProductCategories() async {
    final data = await _api.get('/product-categories');
    return _mapList(data['categories']);
  }

  Future<List<Map<String, dynamic>>> fetchProductTags() async {
    final data = await _api.get('/product-tags');
    return _mapList(data['tags']);
  }

  Future<List<Map<String, dynamic>>> fetchProductTypes() async {
    final data = await _api.get('/product-types');
    return _mapList(data['types']);
  }

  List<Map<String, dynamic>> _mapList(dynamic value) {
    return (value as List<dynamic>? ?? []).map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }
}
