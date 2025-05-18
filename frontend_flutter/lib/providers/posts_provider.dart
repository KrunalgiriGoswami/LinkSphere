import 'package:flutter/foundation.dart';
import '../services/api_service.dart';
import 'package:share_plus/share_plus.dart';

class PostsProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  List<Map<String, dynamic>>? _posts;
  String? _error;
  bool _isLoading = false;
  int _retryCount = 0;
  static const int maxRetries = 3;
  Map<int, bool> _likedPosts = {}; // Track liked posts
  int? _currentUserId; // Store current user ID

  List<Map<String, dynamic>>? get posts => _posts;
  String? get error => _error;
  bool get isLoading => _isLoading;
  Map<int, bool> get likedPosts => _likedPosts;
  int? get currentUserId => _currentUserId;

  Future<void> fetchPosts() async {
    if (_isLoading) return; // Prevent multiple simultaneous fetches

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _posts = await _apiService.getPosts();

      // Fetch current user ID if not already fetched
      if (_currentUserId == null) {
        try {
          _currentUserId = await _apiService.getCurrentUserId();
        } catch (e) {
          print('Could not fetch current user ID: $e');
        }
      }

      // Check which posts are liked by the current user
      if (_posts != null) {
        for (var post in _posts!) {
          try {
            int postId = post['id'];
            bool isLiked = await _apiService.checkIfLiked(postId);
            _likedPosts[postId] = isLiked;
          } catch (e) {
            print('Error checking if post is liked: $e');
          }
        }
      }

      _error = null;
      _retryCount = 0; // Reset retry count on successful fetch
    } catch (e) {
      _error = e.toString();
      _posts = null;

      // Implement retry logic
      if (_retryCount < maxRetries) {
        _retryCount++;
        await Future.delayed(Duration(seconds: 2)); // Wait before retrying
        return fetchPosts(); // Retry the fetch
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> likePost(int postId) async {
    try {
      // If already liked, unlike the post
      if (_likedPosts[postId] == true) {
        await _apiService.unlikePost(postId);
        _likedPosts[postId] = false;
      } else {
        await _apiService.likePost(postId);
        _likedPosts[postId] = true;
      }

      // Update the post in the list
      if (_posts != null) {
        for (var post in _posts!) {
          if (post['id'] == postId) {
            int currentLikes = post['likesCount'] ?? 0;
            post['likesCount'] = _likedPosts[postId] == true
                ? currentLikes + 1
                : (currentLikes > 0 ? currentLikes - 1 : 0);
            break;
          }
        }
      }

      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> savePost(int postId) async {
    try {
      await _apiService.savePost(postId);
      await fetchPosts(); // Refresh posts after saving
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> addComment(int postId, String comment) async {
    try {
      await _apiService.addComment(postId, comment);
      await fetchPosts(); // Refresh posts after commenting
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> deletePost(int postId) async {
    try {
      await _apiService.deletePost(postId);

      // Remove the post from the list
      if (_posts != null) {
        _posts!.removeWhere((post) => post['id'] == postId);
      }

      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> sharePost(int postId, String description) async {
    try {
      await Share.share(
        'Check out this post: $description',
        subject: 'Shared from LinkSphere',
      );
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  bool isPostOwnedByCurrentUser(int postUserId) {
    return _currentUserId != null && _currentUserId == postUserId;
  }

  // Clear error state
  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Reset provider state
  void reset() {
    _posts = null;
    _error = null;
    _isLoading = false;
    _retryCount = 0;
    _likedPosts = {};
    notifyListeners();
  }

  Future<void> searchPosts(String query) async {
    if (_isLoading) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _posts = await _apiService.searchPosts(query);

      // Check which posts are liked by the current user
      if (_posts != null) {
        for (var post in _posts!) {
          try {
            int postId = post['id'];
            bool isLiked = await _apiService.checkIfLiked(postId);
            _likedPosts[postId] = isLiked;
          } catch (e) {
            print('Error checking if post is liked: $e');
          }
        }
      }

      _error = null;
    } catch (e) {
      _error = e.toString();
      _posts = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
