import 'package:allmah_admin/router/app_router.dart';
import 'package:flutter/material.dart';
import 'package:auto_route/auto_route.dart';
import '../widgets/sidebar.dart';

@RoutePage()
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return AutoTabsRouter(
      routes: const [
        DashboardRoute(),
        CategoriesRoute(),
        QuestionsRoute(),
        UsersRoute(),
        GamesRoute(),
        PaymentsRoute(),
        SettingsRoute(),
      ],
      builder: (context, child) {
        final tabsRouter = AutoTabsRouter.of(context);

        return Scaffold(
          body: Row(
            children: [
              Sidebar(
                currentPage: _getCurrentPageName(tabsRouter.activeIndex),
                onPageChange: (page) {
                  tabsRouter.setActiveIndex(_getIndexForPage(page));
                },
              ),
              Expanded(child: child),
            ],
          ),
        );
      },
      transitionBuilder: (context, child, animation) {
        return FadeTransition(opacity: animation, child: child);
      },
    );
  }

  String _getCurrentPageName(int index) {
    switch (index) {
      case 0:
        return 'dashboard';
      case 1:
        return 'categories';
      case 2:
        return 'questions';
      case 3:
        return 'users';
      case 4:
        return 'games';
      case 5:
        return 'payments';
      case 6:
        return 'settings';
      default:
        return 'dashboard';
    }
  }

  int _getIndexForPage(String page) {
    switch (page) {
      case 'dashboard':
        return 0;
      case 'categories':
        return 1;
      case 'questions':
        return 2;
      case 'users':
        return 3;
      case 'games':
        return 4;
      case 'payments':
        return 5;
      case 'settings':
        return 6;
      default:
        return 0;
    }
  }
}
