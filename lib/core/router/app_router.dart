import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../app/scaffold_with_nav_bar.dart';
import '../../features/home/presentation/home_page.dart';
import '../../features/memories/presentation/memories_history_page.dart';
import '../../features/memories/presentation/memory_detail_page.dart';
import '../../features/ask/presentation/ask_page.dart';
import '../../features/profile/presentation/profile_page.dart';
import '../../features/capture/presentation/capture_page.dart';
import '../../features/understand/presentation/memory_review_page.dart';
import '../../features/remember/presentation/memory_saved_page.dart';
import '../../features/context/presentation/context_bridge_page.dart';
import '../../features/actions/presentation/action_approval_page.dart';
import '../../features/outcomes/presentation/outcome_record_page.dart';
import '../../features/reminders/presentation/reminders_page.dart';
import '../../features/memory/domain/memory_candidate.dart';
import '../../features/memory/domain/memory_models.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _homeNavigatorKey = GlobalKey<NavigatorState>();
final _historyNavigatorKey = GlobalKey<NavigatorState>();
final _askNavigatorKey = GlobalKey<NavigatorState>();
final _profileNavigatorKey = GlobalKey<NavigatorState>();

final GoRouter appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/',
  routes: [
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        return ScaffoldWithNavBar(navigationShell: navigationShell);
      },
      branches: [
        StatefulShellBranch(
          navigatorKey: _homeNavigatorKey,
          routes: [
            GoRoute(
              path: '/',
              builder: (context, state) => const HomePage(),
            ),
          ],
        ),
        StatefulShellBranch(
          navigatorKey: _historyNavigatorKey,
          routes: [
            GoRoute(
              path: '/history',
              builder: (context, state) => const MemoriesHistoryPage(),
            ),
          ],
        ),
        StatefulShellBranch(
          navigatorKey: _askNavigatorKey,
          routes: [
            GoRoute(
              path: '/ask',
              builder: (context, state) => const AskPage(),
            ),
          ],
        ),
        StatefulShellBranch(
          navigatorKey: _profileNavigatorKey,
          routes: [
            GoRoute(
              path: '/profile',
              builder: (context, state) => const ProfilePage(),
            ),
          ],
        ),
      ],
    ),
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/capture',
      builder: (context, state) => const CapturePage(),
    ),
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/understand',
      builder: (context, state) => MemoryReviewPage(
        candidate: state.extra! as MemoryCandidate,
      ),
    ),
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/remember',
      builder: (context, state) => MemorySavedPage(
        memory: state.extra! as MemoryModel,
      ),
    ),
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/memory-detail',
      builder: (context, state) => MemoryDetailPage(
        memory: state.extra! as MemoryModel,
      ),
    ),
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/reminders',
      builder: (context, state) => const RemindersPage(),
    ),
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/context-bridge',
      builder: (context, state) {
        final statement = state.extra as String? ?? 'My AC isn''t working.';
        return ContextBridgePage(statement: statement);
      },
    ),
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/action-approval',
      builder: (context, state) => ActionApprovalPage(
        proposal: state.extra! as ActionProposal,
      ),
    ),
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/record-outcome',
      builder: (context, state) {
        final thingName = state.extra as String? ?? 'AC';
        return OutcomeRecordPage(thingName: thingName);
      },
    ),
  ],
);