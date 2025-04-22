import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:compass/pages/player_details_page.dart';

class SteamLoginPage extends StatefulWidget {
  const SteamLoginPage({super.key});

  @override
  _SteamLoginPageState createState() => _SteamLoginPageState();
}

class _SteamLoginPageState extends State<SteamLoginPage> {
  bool _isLoading = true;
  bool _showWebView = false;
  bool _webViewLoading = false;
  String? _steamId;
  Map<String, dynamic>? _playerProfile;
  WebViewController? _controller;
  String? _error;

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedSteamId = prefs.getString('steam_id');

      if (savedSteamId != null) {
        setState(() {
          _steamId = savedSteamId;
          _isLoading = true;
        });
        await _fetchPlayerProfile();
      }
    } catch (e) {
      _handleError('Failed to check login status');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _handleError(String message) {
    setState(() {
      _error = message;
      _isLoading = false;
      _webViewLoading = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<void> _fetchPlayerProfile() async {
    try {
      if (_steamId != null) {
        final response = await http.get(
          Uri.parse('https://api.opendota.com/api/players/${_convertToAccountId(_steamId!)}'),
        ).timeout(
          const Duration(seconds: 10),
          onTimeout: () => throw TimeoutException('Request timed out'),
        );

        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          if (data['profile'] != null) {
            setState(() {
              _playerProfile = data['profile'];
              _error = null;
            });
          } else {
            throw Exception('Invalid profile data');
          }
        } else {
          throw Exception('Failed to fetch profile');
        }
      }
    } catch (e) {
      _handleError('Error fetching profile: ${e.toString()}');
    }
  }

  String _convertToAccountId(String steamId) {
    try {
      return (BigInt.parse(steamId) - BigInt.parse('76561197960265728')).toString();
    } catch (e) {
      throw Exception('Invalid Steam ID format');
    }
  }

  void _initWebView() {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            setState(() => _webViewLoading = true);
            debugPrint('Page started loading: $url');
          },
          onPageFinished: (String url) {
            setState(() => _webViewLoading = false);
            debugPrint('Page finished loading: $url');
          },
          onNavigationRequest: (NavigationRequest request) {
            debugPrint('Navigation request to: ${request.url}');
            if (request.url.contains('openid/id/')) {
              try {
                final steamId = _extractSteamIdFromUrl(request.url);
                _handleSteamLogin(steamId);
              } catch (e) {
                _handleError('Failed to extract Steam ID');
              }
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
          onWebResourceError: (WebResourceError error) {
            debugPrint('WebView error: ${error.description}');
            _handleError('WebView error: ${error.description}');
          },
        ),
      );

    final steamLoginUrl = Uri(
      scheme: 'https',
      host: 'steamcommunity.com',
      path: '/openid/login',
      queryParameters: {
        'openid.ns': 'http://specs.openid.net/auth/2.0',
        'openid.mode': 'checkid_setup',
        'openid.identity': 'http://specs.openid.net/auth/2.0/identifier_select',
        'openid.claimed_id': 'http://specs.openid.net/auth/2.0/identifier_select',
        'openid.return_to': 'https://steamcommunity.com/openid/id/',
        'openid.realm': 'https://steamcommunity.com',
      },
    ).toString();

    _controller!.loadRequest(Uri.parse(steamLoginUrl));
  }

  String _extractSteamIdFromUrl(String url) {
    final uri = Uri.parse(url);
    final claimedId = uri.queryParameters['openid.claimed_id'] ?? '';

    if (claimedId.isNotEmpty) {
      final RegExp steamIdRegex = RegExp(r'id/(\d+)');
      final match = steamIdRegex.firstMatch(claimedId);
      if (match != null && match.groupCount > 0) {
        return match.group(1)!;
      }
    }
    throw Exception('Steam ID not found in URL');
  }

  Future<void> _handleSteamLogin(String steamId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('steam_id', steamId);

      setState(() {
        _steamId = steamId;
        _showWebView = false;
        _isLoading = true;
      });

      await _fetchPlayerProfile();

      if (mounted && _playerProfile != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Steam login successful!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      _handleError('Login failed: ${e.toString()}');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loginWithSteam() async {
    setState(() {
      _showWebView = true;
      _error = null;
    });
    _initWebView();
  }

  Future<void> _logout() async {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: isDarkMode ? const Color.fromRGBO(20, 20, 20, 1) : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          title: Text(
            'Confirm Logout',
            style: TextStyle(
              color: isDarkMode ? Colors.white : Colors.black,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          content: Text(
            'Are you sure you want to log out?',
            style: TextStyle(
              color: isDarkMode ? Colors.grey[400] : Colors.grey[800],
              fontSize: 16,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(false); // User cancels logout
              },
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: isDarkMode ? Colors.grey[400] : Colors.grey[800],
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(true); // User confirms logout
              },
              child: Text(
                'Logout',
                style: TextStyle(
                  color: Colors.redAccent,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );

    if (shouldLogout == true) {
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('steam_id');

        setState(() {
          _steamId = null;
          _playerProfile = null;
          _error = null;
        });
      } catch (e) {
        _handleError('Logout failed: ${e.toString()}');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    if (_isLoading) {
      return Scaffold(
        backgroundColor: isDarkMode ? const Color.fromRGBO(10, 10, 10, 1) : Colors.white,
        body: Center(
          child: CircularProgressIndicator(
            color: isDarkMode ? Colors.white : Colors.black,
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: isDarkMode ? const Color.fromRGBO(10, 10, 10, 1) : Colors.white,
      body: Stack(
        children: [
          if (_showWebView && _controller != null)
            Column(
              children: [
                const SizedBox(height: 40),
                Expanded(
                  child: Stack(
                    children: [
                      WebViewWidget(controller: _controller!),
                      if (_webViewLoading)
                        Container(
                          color: Colors.black.withOpacity(0.1),
                          child: const Center(

                          ),
                        ),
                    ],
                  ),
                ),
              ],
            )
          else if (_steamId == null)
            _buildLoginPrompt(isDarkMode)
          else
            PlayerDetailsPage(
              accountId: _convertToAccountId(_steamId!),
              playerName: _playerProfile?['personaname'] ?? 'Unknown',
              avatarUrl: _playerProfile?['avatarfull'] ?? '',
              showAppBar: false,
              onLogout: _logout,
            ),

          if (_error != null)
            Positioned(
              top: 40,
              left: 20,
              right: 20,
              child: Material(
                elevation: 4,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.red.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: Colors.red),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _error!,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.red),
                        onPressed: () => setState(() => _error = null),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildLoginPrompt(bool isDarkMode) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SvgPicture.asset(
              'lib/icons/steam-brands-solid.svg',
              width: 80,
              height: 80,
              color: isDarkMode ? Colors.white : Colors.black,
            ),
            const SizedBox(height: 24),
            Text(
              'Connect with Steam',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: isDarkMode ? Colors.white : Colors.black,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Sign in with your Steam account to view your Dota 2 statistics',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 16,
                color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _loginWithSteam,
              style: ElevatedButton.styleFrom(
                backgroundColor: isDarkMode ? Colors.grey[800] : Colors.grey[200],
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SvgPicture.asset(
                    'lib/icons/steam-brands-solid.svg',
                    width: 24,
                    height: 24,
                    color: isDarkMode ? Colors.white : Colors.black,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Login with Steam',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 16,
                      color: isDarkMode ? Colors.white : Colors.black,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfilePage(bool isDarkMode) {
    if (_playerProfile == null) {
      return Center(
        child: CircularProgressIndicator(
          color: isDarkMode ? Colors.white : Colors.black,
        ),
      );
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 50,
            backgroundImage: NetworkImage(_playerProfile!['avatarfull']),
            backgroundColor: Colors.grey[300],
          ),
          const SizedBox(height: 16),
          Text(
            _playerProfile!['personaname'],
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: isDarkMode ? Colors.white : Colors.black,
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: () {
              final accountId = _convertToAccountId(_steamId!);
              Navigator.push( // Changed from pushReplacement to push
                context,
                MaterialPageRoute(
                  builder: (context) => PlayerDetailsPage(
                    accountId: accountId,
                    playerName: _playerProfile!['personaname'],
                    avatarUrl: _playerProfile!['avatarfull'],
                    showAppBar: true, // Add AppBar for this navigation path
                  ),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: isDarkMode ? Colors.grey[800] : Colors.grey[200],
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            ),
            child: Text(
              'View Statistics',
              style: TextStyle(
                fontFamily: 'Inter',
                color: isDarkMode ? Colors.white : Colors.black,
              ),
            ),
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: _logout,
            child: Text(
              'Logout',
              style: TextStyle(
                fontFamily: 'Inter',
                color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
              ),
            ),
          ),
        ],
      ),
    );
  }
}