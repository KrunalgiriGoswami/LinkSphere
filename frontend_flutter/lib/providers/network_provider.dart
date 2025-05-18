import 'package:flutter/foundation.dart';
import '../services/api_service.dart';

class NetworkProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  List<Map<String, dynamic>>? _connections;
  List<Map<String, dynamic>>? _suggestions;
  String? _error;
  bool _isLoading = false;

  List<Map<String, dynamic>>? get connections =>
      _connections ?? _dummyConnections;
  List<Map<String, dynamic>>? get suggestions =>
      _suggestions ?? _dummySuggestions;
  String? get error => _error;
  bool get isLoading => _isLoading;

  // Dummy data for development and fallback
  final List<Map<String, dynamic>> _dummyConnections = [
    {
      'id': 1,
      'username': 'John Doe',
      'headline': 'Software Engineer at Google',
      'profilePicture': null,
      'connectedUserId': 1
    },
    {
      'id': 2,
      'username': 'Jane Smith',
      'headline': 'Product Manager at Apple',
      'profilePicture': null,
      'connectedUserId': 2
    },
    {
      'id': 3,
      'username': 'Mike Johnson',
      'headline': 'UI/UX Designer',
      'profilePicture': null,
      'connectedUserId': 3
    }
  ];

  final List<Map<String, dynamic>> _dummySuggestions = [
    {
      'id': 4,
      'username': 'Sarah Wilson',
      'headline': 'Frontend Developer at Amazon',
      'profilePicture': null,
      'connectedUserId': 4
    },
    {
      'id': 5,
      'username': 'David Brown',
      'headline': 'Backend Engineer at Microsoft',
      'profilePicture': null,
      'connectedUserId': 5
    },
    {
      'id': 6,
      'username': 'Emily Davis',
      'headline': 'Mobile Developer',
      'profilePicture': null,
      'connectedUserId': 6
    },
    {
      'id': 7,
      'username': 'Alex Turner',
      'headline': 'Full Stack Developer',
      'profilePicture': null,
      'connectedUserId': 7
    }
  ];

  Future<void> fetchConnections() async {
    if (_isLoading) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _apiService.getConnections();
      if (result.isNotEmpty) {
        _connections = result;
      } else {
        _connections = _dummyConnections;
      }
      _error = null;
    } catch (e) {
      print('Error fetching connections: $e');
      _error = null;
      _connections = _dummyConnections;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchSuggestions() async {
    if (_isLoading) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _apiService.getConnectionSuggestions();
      if (result.isNotEmpty) {
        _suggestions = result;
      } else {
        _suggestions = _dummySuggestions;
      }
      _error = null;
    } catch (e) {
      print('Error fetching suggestions: $e');
      _error = null;
      _suggestions = _dummySuggestions;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> connect(int connectedUserId) async {
    try {
      await _apiService.connect(connectedUserId);
      // After successful connection, refresh both lists
      await fetchConnections();
      await fetchSuggestions();
    } catch (e) {
      print('Error connecting: $e');
      // For demo purposes, simulate successful connection with dummy data
      final userToConnect = _dummySuggestions.firstWhere(
        (s) => s['connectedUserId'] == connectedUserId,
        orElse: () => _suggestions!.firstWhere(
          (s) => s['connectedUserId'] == connectedUserId,
        ),
      );

      _connections = [..._connections ?? [], userToConnect];
      _suggestions = (_suggestions ?? _dummySuggestions)
          .where((s) => s['connectedUserId'] != connectedUserId)
          .toList();
      notifyListeners();
    }
  }

  Future<void> disconnect(int connectedUserId) async {
    try {
      await _apiService.disconnect(connectedUserId);
      // After successful disconnection, refresh both lists
      await fetchConnections();
      await fetchSuggestions();
    } catch (e) {
      print('Error disconnecting: $e');
      // For demo purposes, simulate successful disconnection with dummy data
      final disconnectedUser = (_connections ?? _dummyConnections)
          .firstWhere((c) => c['connectedUserId'] == connectedUserId);

      _connections = (_connections ?? _dummyConnections)
          .where((c) => c['connectedUserId'] != connectedUserId)
          .toList();
      _suggestions = [..._suggestions ?? [], disconnectedUser];
      notifyListeners();
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  void reset() {
    _connections = null;
    _suggestions = null;
    _error = null;
    _isLoading = false;
    notifyListeners();
  }
}
