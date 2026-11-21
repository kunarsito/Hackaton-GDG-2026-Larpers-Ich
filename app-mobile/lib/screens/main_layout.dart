import 'dart:async';
import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';
import '../services/api_service.dart';
import '../services/social_api.dart';
import 'library_screen.dart';
import 'practice_screen.dart';
import 'challenge_detail_screen.dart';
import 'community_screen.dart';
import 'jobs_screen.dart';
import 'messages_screen.dart';
import 'profile_screen.dart';
import 'talent_screen.dart';

class MainLayout extends StatefulWidget {
  /// Cierra la sesión y vuelve al login (lo maneja AuthGate en main.dart).
  final VoidCallback? onLogout;

  const MainLayout({super.key, this.onLogout});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  final ApiService _apiService = ApiService();
  int _currentIndex = 0;

  // Variables de estado para interconectar el Happy Path
  String? _prefilledCommunityTitle;
  String? _prefilledCommunityCode;
  String? _activeChallengeId;

  // RF-16: insignia de mensajes no leídos (polling, sin WebSockets)
  int _unread = 0;
  Timer? _unreadTimer;

  @override
  void initState() {
    super.initState();
    _apiService.userVersion.addListener(_onUserChanged);
    _apiService.refreshCurrentUser();
    _pollUnread();
    _unreadTimer = Timer.periodic(const Duration(seconds: 30), (_) => _pollUnread());
  }

  @override
  void dispose() {
    _unreadTimer?.cancel();
    _apiService.userVersion.removeListener(_onUserChanged);
    super.dispose();
  }

  void _onUserChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _pollUnread() async {
    if (_apiService.isOfflineMode || !_apiService.hasSession) return;
    try {
      final count = await _apiService.getUnreadCount();
      if (mounted && count != _unread) setState(() => _unread = count);
    } catch (_) {}
  }

  Future<void> _openMessages() async {
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => const MessagesScreen()));
    _pollUnread();
  }

  void _openRanking() {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const TalentScreen()));
  }

  void _navigateToTab(int index, {String? challengeId}) {
    setState(() {
      _currentIndex = index;
      if (challengeId != null) {
        _activeChallengeId = challengeId;
      }
    });
  }

  void _navigateToCommunityFromChallenge(String title, String code) {
    setState(() {
      _prefilledCommunityTitle = title;
      _prefilledCommunityCode = code;
      _currentIndex = 2; // Ir al foro
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = _apiService.currentUser;

    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isDesktop = constraints.maxWidth >= 600;
        final bool isMobile = !isDesktop;

        final screens = [
          LibraryScreen(
            onNavigateToTab: (tab, {challengeId}) {
              _navigateToTab(tab, challengeId: challengeId);
            },
          ),
          _activeChallengeId != null
              ? ChallengeDetailScreen(
                  key: ValueKey(_activeChallengeId),
                  challengeId: _activeChallengeId!,
                  onNavigateToCommunity: (title, code) {
                    _navigateToCommunityFromChallenge(title, code);
                  },
                )
              : PracticeScreen(
                  onOpenChallenge: (chId) {
                    setState(() => _activeChallengeId = chId);
                  },
                  onNavigateToCommunity: (title, code) {
                    _navigateToCommunityFromChallenge(title, code);
                  },
                ),
          CommunityScreen(
            key: ValueKey('$_prefilledCommunityTitle-$_prefilledCommunityCode'),
            initialPrefilledTitle: _prefilledCommunityTitle,
            initialPrefilledCode: _prefilledCommunityCode,
          ),
          const JobsScreen(),
          const ProfileScreen(embedded: true),
        ];

        return Scaffold(
          appBar: AppBar(
            leadingWidth: 40,
            leading: _currentIndex == 1 && _activeChallengeId != null
                ? IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new, size: 16),
                    onPressed: () {
                      setState(() => _activeChallengeId = null);
                    },
                  )
                : const Padding(
                    padding: EdgeInsets.only(left: 14),
                    child: Icon(Icons.memory_rounded, color: AppTheme.phosphorGreen),
                  ),
            title: LayoutBuilder(
              builder: (context, constraints) {
                final isCompact = isMobile || constraints.maxWidth < 180;
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        isCompact ? '> FARO_DEV' : '> FARO_DEV // CAMPUS',
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                        style: const TextStyle(
                          fontFamily: AppTheme.monoFont,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: AppTheme.phosphorGreen,
                          letterSpacing: 1.1,
                        ),
                      ),
                    ),
                    if (!isCompact) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppTheme.darkSilicon,
                          borderRadius: BorderRadius.circular(3),
                          border: Border.all(color: AppTheme.circuitTrace),
                        ),
                        child: const Text(
                          'REV 1.0',
                          style: TextStyle(
                            fontFamily: AppTheme.monoFont,
                            fontSize: 9,
                            color: AppTheme.greenishGray,
                          ),
                        ),
                      ),
                    ],
                  ],
                );
              },
            ),
            actions: [
              // RF-16: mensajes privados con insignia de no leídos
              IconButton(
                tooltip: 'Mensajes',
                onPressed: _openMessages,
                icon: Badge(
                  isLabelVisible: _unread > 0,
                  label: Text('$_unread'),
                  backgroundColor: AppTheme.alertRed,
                  child: const Icon(Icons.chat_bubble_outline_rounded, color: AppTheme.phosphorGreen),
                ),
              ),
              // Chip en vivo de Karma Técnico (toca para ver el ranking)
              InkWell(
                onTap: _openRanking,
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.darkSilicon,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppTheme.solderGold, width: 1),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: AppTheme.solderGold,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        isMobile ? '${user.karmaPoints}K' : '[KARMA: ${user.karmaPoints}]',
                        style: const TextStyle(
                          fontFamily: AppTheme.monoFont,
                          fontSize: 10.5,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.solderGold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Menú de cuenta: perfil, ranking y cerrar sesión
              PopupMenuButton<String>(
                tooltip: 'Cuenta',
                icon: const Icon(Icons.account_circle_outlined, color: AppTheme.phosphorGreen),
                color: AppTheme.darkSilicon,
                onSelected: (value) {
                  switch (value) {
                    case 'profile':
                      setState(() {
                        _currentIndex = 4;
                        _activeChallengeId = null;
                      });
                    case 'ranking':
                      _openRanking();
                    case 'messages':
                      _openMessages();
                    case 'logout':
                      widget.onLogout?.call();
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem<String>(
                    enabled: false,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user.name,
                          style: const TextStyle(
                            color: AppTheme.boneWhite,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (user.university.isNotEmpty)
                          Text(
                            user.university,
                            style: const TextStyle(color: AppTheme.greenishGray, fontSize: 12),
                          ),
                        if (_apiService.isOfflineMode)
                          const Text(
                            'Modo demo sin conexión',
                            style: TextStyle(color: AppTheme.solderGold, fontSize: 12),
                          ),
                      ],
                    ),
                  ),
                  const PopupMenuDivider(),
                  const PopupMenuItem<String>(
                    value: 'profile',
                    child: Row(
                      children: [
                        Icon(Icons.person_outline, size: 18, color: AppTheme.phosphorGreen),
                        SizedBox(width: 10),
                        Text('Mi perfil', style: TextStyle(color: AppTheme.boneWhite)),
                      ],
                    ),
                  ),
                  const PopupMenuItem<String>(
                    value: 'messages',
                    child: Row(
                      children: [
                        Icon(Icons.chat_bubble_outline_rounded, size: 18, color: AppTheme.phosphorGreen),
                        SizedBox(width: 10),
                        Text('Mensajes', style: TextStyle(color: AppTheme.boneWhite)),
                      ],
                    ),
                  ),
                  const PopupMenuItem<String>(
                    value: 'ranking',
                    child: Row(
                      children: [
                        Icon(Icons.leaderboard_outlined, size: 18, color: AppTheme.solderGold),
                        SizedBox(width: 10),
                        Text('Ranking y talento', style: TextStyle(color: AppTheme.boneWhite)),
                      ],
                    ),
                  ),
                  const PopupMenuDivider(),
                  const PopupMenuItem<String>(
                    value: 'logout',
                    child: Row(
                      children: [
                        Icon(Icons.logout, size: 18, color: AppTheme.alertRed),
                        SizedBox(width: 10),
                        Text('Cerrar sesión', style: TextStyle(color: AppTheme.boneWhite)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 6),
            ],
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(1),
              child: Container(
                color: AppTheme.circuitTrace,
                height: 1,
              ),
            ),
          ),
          body: isDesktop
              ? Row(
                  children: [
                    // Modo Escritorio / Web (>= 600px): NavigationRail lateral
                    NavigationRail(
                      selectedIndex: _currentIndex,
                      onDestinationSelected: (idx) {
                        setState(() {
                          _currentIndex = idx;
                          if (idx != 1) {
                            _activeChallengeId = null;
                          }
                        });
                      },
                      labelType: NavigationRailLabelType.all,
                      destinations: const [
                        NavigationRailDestination(
                          icon: Icon(Icons.auto_stories_outlined),
                          selectedIcon: Icon(Icons.auto_stories),
                          label: Text('BIBLIOTECA'),
                        ),
                        NavigationRailDestination(
                          icon: Icon(Icons.code_rounded),
                          selectedIcon: Icon(Icons.code),
                          label: Text('PRÁCTICA'),
                        ),
                        NavigationRailDestination(
                          icon: Icon(Icons.forum_outlined),
                          selectedIcon: Icon(Icons.forum),
                          label: Text('COMUNIDAD'),
                        ),
                        NavigationRailDestination(
                          icon: Icon(Icons.work_outline_rounded),
                          selectedIcon: Icon(Icons.work),
                          label: Text('EMPLEOS'),
                        ),
                        NavigationRailDestination(
                          icon: Icon(Icons.person_outline_rounded),
                          selectedIcon: Icon(Icons.person),
                          label: Text('PERFIL'),
                        ),
                      ],
                    ),
                    const VerticalDivider(width: 1, color: AppTheme.circuitTrace),
                    Expanded(child: screens[_currentIndex]),
                  ],
                )
              : screens[_currentIndex],

          // Modo Móvil (< 600px): NavigationBar inferior
          bottomNavigationBar: isDesktop
              ? null
              : NavigationBar(
                  selectedIndex: _currentIndex,
                  onDestinationSelected: (idx) {
                    setState(() {
                      _currentIndex = idx;
                      if (idx != 1) {
                        _activeChallengeId = null;
                      }
                    });
                  },
                  destinations: const [
                    NavigationDestination(
                      icon: Icon(Icons.auto_stories_outlined),
                      selectedIcon: Icon(Icons.auto_stories),
                      label: 'BIBLIOTECA',
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.code_rounded),
                      selectedIcon: Icon(Icons.code),
                      label: 'PRÁCTICA',
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.forum_outlined),
                      selectedIcon: Icon(Icons.forum),
                      label: 'COMUNIDAD',
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.work_outline_rounded),
                      selectedIcon: Icon(Icons.work),
                      label: 'EMPLEOS',
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.person_outline_rounded),
                      selectedIcon: Icon(Icons.person),
                      label: 'PERFIL',
                    ),
                  ],
                ),
        );
      },
    );
  }
}
