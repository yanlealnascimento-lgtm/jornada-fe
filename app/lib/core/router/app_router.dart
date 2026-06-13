import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/onboarding/splash_screen.dart';
import '../../features/onboarding/welcome_screen.dart';
import '../../features/onboarding/denomination_screen.dart';
import '../../features/onboarding/daily_goal_screen.dart';
import '../../features/onboarding/register_screen.dart';
import '../../features/onboarding/screens/onboarding_screen.dart';
import '../../features/onboarding/screens/pf_celebration_screen.dart';
import '../../features/onboarding/screens/streak_screen.dart';
import '../../features/onboarding/screens/create_account_prompt_screen.dart';
import '../../features/home/home_screen.dart';
import '../../features/lesson/lesson_screen.dart';
import '../../features/lesson/screens/lesson_stage_screen.dart';
import '../../features/lesson/screens/lesson_complete_screen.dart';
import '../../features/leagues/leagues_screen.dart';
import '../../features/profile/profile_screen.dart';
import '../../features/profile/character_gallery_screen.dart';
import '../../features/profile/edit_profile_screen.dart';
import '../../features/store/store_screen.dart';
import '../../features/streak/streak_screen.dart';
import '../../features/streak/streak_celebration_screen.dart';
import '../../features/energy/energy_screen.dart';
import '../../features/settings/settings_screen.dart';
import '../../features/auth/login_screen.dart';
import '../../features/missions/missions_screen.dart';
import '../../features/study/screens/study_list_screen.dart';
import '../../features/study/screens/study_detail_screen.dart';
import '../../features/study/screens/study_lesson_screen.dart';
import '../../shared/widgets/jf_bottom_nav.dart';

final routerProvider = Provider<GoRouter>((ref) {
  // MVP: sem redirecionamento por autenticação — ativar em produção
  // final userAsync = ref.watch(currentUserProvider);

  return GoRouter(
    initialLocation: '/splash',
    redirect: (context, state) {
      // MVP: sem redirecionamento de auth complexo
      return null;
    },
    routes: [
      // Auth
      GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),

      // Onboarding
      GoRoute(path: '/splash', builder: (_, __) => const SplashScreen()),
      GoRoute(path: '/onboarding/welcome', builder: (_, __) => const WelcomeScreen()),
      GoRoute(path: '/onboarding/denomination', builder: (_, __) => const DenominationScreen()),
      GoRoute(path: '/onboarding/daily-goal', builder: (_, __) => const DailyGoalScreen()),
      GoRoute(path: '/onboarding/register', builder: (_, __) => const RegisterScreen()),
      GoRoute(path: '/onboarding', builder: (_, __) => const OnboardingScreen()),
      GoRoute(
        path: '/onboarding/pf-celebration',
        builder: (context, state) {
          final pf = int.tryParse(state.uri.queryParameters['pf'] ?? '') ?? 10;
          return PfCelebrationScreen(pfEarned: pf);
        },
      ),
      GoRoute(path: '/onboarding/streak', builder: (_, __) => const StreakOnboardingScreen()),
      GoRoute(path: '/onboarding/create-account', builder: (_, __) => const CreateAccountPromptScreen()),

      // App principal com shell route (bottom nav)
      ShellRoute(
        builder: (context, state, child) => MainScaffold(child: child),
        routes: [
          GoRoute(path: '/home', builder: (_, __) => const HomeScreen()),
          GoRoute(path: '/missions', builder: (_, __) => const MissionsScreen()), // legacy route
          GoRoute(path: '/achievements', builder: (_, __) => const MissionsScreen()), // conquistas (reuses missions screen temporarily)
          GoRoute(path: '/leagues', builder: (_, __) => const LeaguesScreen()),
          GoRoute(path: '/news', builder: (_, __) => const _PlaceholderScreen(title: 'Novidades', icon: Icons.newspaper_rounded, subtitle: 'Atualizações do JourneyFaith')),
          GoRoute(path: '/premium', builder: (_, __) => const _PlaceholderScreen(title: 'Premium', icon: Icons.workspace_premium_rounded, subtitle: 'Desbloqueie conteúdo exclusivo')),
          GoRoute(path: '/profile', builder: (_, __) => const ProfileScreen()),
          GoRoute(path: '/profile/characters', builder: (_, __) => const CharacterGalleryScreen()),
          GoRoute(path: '/profile/edit', builder: (_, __) => const EditProfileScreen()),
          GoRoute(path: '/studies', builder: (_, __) => const StudyListScreen()),
          GoRoute(path: '/store', builder: (_, __) => const StoreScreen()),
          GoRoute(path: '/settings', builder: (_, __) => const SettingsScreen()),
        ],
      ),

      // Licao fora do ShellRoute — sem bottom nav durante o exercicio
      GoRoute(
        path: '/lesson/:lessonId',
        builder: (context, state) {
          final lessonId = state.pathParameters['lessonId'] ?? '';
          return LessonScreen(lessonId: lessonId);
        },
      ),

      // Stage-based lesson route
      GoRoute(
        path: '/lesson/:lessonId/stage/:stageIndex',
        builder: (context, state) {
          final lessonId = state.pathParameters['lessonId'] ?? '';
          final stageIndex = int.tryParse(state.pathParameters['stageIndex'] ?? '0') ?? 0;
          final stagesTotal = int.tryParse(state.uri.queryParameters['stagesTotal'] ?? '1') ?? 1;
          final isReview = state.uri.queryParameters['review'] == '1';
          return LessonStageScreen(
            lessonId: lessonId,
            stageIndex: stageIndex,
            stagesTotal: stagesTotal,
            isReview: isReview,
          );
        },
      ),

      // Lesson/stage complete celebration screen
      GoRoute(
        path: '/lesson-complete',
        builder: (context, state) {
          final q = state.uri.queryParameters;
          return LessonCompleteScreen(
            pfEarned: int.tryParse(q['pf'] ?? q['xp'] ?? '0') ?? 0,
            errorCount: int.tryParse(q['errors'] ?? '0') ?? 0,
            lessonId: q['lessonId'] ?? '',
            accuracyPercent: int.tryParse(q['accuracy'] ?? '100') ?? 100,
            elapsedSeconds: int.tryParse(q['elapsed'] ?? '0') ?? 0,
            isLastStage: q['isLastStage'] == '1',
          );
        },
      ),

      // Ofensiva (Streak) screen — fora do ShellRoute (modal-style)
      GoRoute(path: '/streak', builder: (_, __) => const StreakScreen()),

      // Streak celebration — shown after completing a lesson
      GoRoute(path: '/streak-celebration', builder: (_, __) => const StreakCelebrationScreen()),

      // Energy screen — fora do ShellRoute (modal-style)
      GoRoute(path: '/energy', builder: (_, __) => const EnergyScreen()),

      // Estudos Biblicos — fora do ShellRoute
      GoRoute(
        path: '/study/:slug',
        builder: (context, state) {
          final slug = state.pathParameters['slug'] ?? '';
          return StudyDetailScreen(slug: slug);
        },
      ),
      GoRoute(
        path: '/study/:slug/lesson/:lessonIndex',
        builder: (context, state) {
          final slug = state.pathParameters['slug'] ?? '';
          final lessonIndex = int.tryParse(state.pathParameters['lessonIndex'] ?? '0') ?? 0;
          return StudyLessonScreen(slug: slug, lessonIndex: lessonIndex);
        },
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Text('Rota não encontrada: ${state.uri}'),
      ),
    ),
  );
});

class MainScaffold extends ConsumerStatefulWidget {
  final Widget child;

  const MainScaffold({super.key, required this.child});

  @override
  ConsumerState<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends ConsumerState<MainScaffold> {
  int _currentIndex = 0;

  static const List<String> _routes = [
    '/home',
    '/achievements',
    '/leagues',
    '/news',
    '/store',
    '/profile',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: widget.child,
      bottomNavigationBar: JFBottomNav(
        currentIndex: _currentIndex,
        onTabSelected: (index) {
          setState(() => _currentIndex = index);
          context.go(_routes[index]);
        },
      ),
    );
  }
}

class _PlaceholderScreen extends StatelessWidget {
  final String title;
  final IconData icon;
  final String subtitle;

  const _PlaceholderScreen({
    required this.title,
    required this.icon,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF131F24) : const Color(0xFFF0F7FF),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 64, color: const Color(0xFF4A90E2)),
            const SizedBox(height: 16),
            Text(title, style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: isDark ? const Color(0xFFEEF2F7) : const Color(0xFF1A2E4A))),
            const SizedBox(height: 8),
            Text(subtitle, style: TextStyle(fontSize: 14, color: isDark ? const Color(0xFF8BA0AE) : const Color(0xFF6B7280))),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text('Em breve', style: TextStyle(fontSize: 13, color: Color(0xFFF59E0B), fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ),
    );
  }
}
