import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';
import '../services/api_service.dart';
import 'library_screen.dart';
import 'practice_screen.dart';
import 'challenge_detail_screen.dart';
import 'community_screen.dart';
import 'jobs_screen.dart';

class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

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
            title: Row(
              children: [
                const Text(
                  '> FARO_DEV // CAMPUS',
                  style: TextStyle(
                    fontFamily: AppTheme.monoFont,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: AppTheme.phosphorGreen,
                    letterSpacing: 1.1,
                  ),
                ),
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
            ),
            actions: [
              // Chip en vivo de Karma Técnico
              Container(
                margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
                    const SizedBox(width: 6),
                    Text(
                      '[KARMA: ${user.karmaPoints}]',
                      style: const TextStyle(
                        fontFamily: AppTheme.monoFont,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.solderGold,
                        letterSpacing: 0.6,
                      ),
                    ),
                  ],
                ),
              ),
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
                  ],
                ),
        );
      },
    );
  }
}
