import 'package:flutter/material.dart';
import 'package:persistent_bottom_nav_bar/persistent_bottom_nav_bar.dart';
import 'package:x_video_downloader/downloads.dart';
import 'package:x_video_downloader/main.dart';
import 'package:x_video_downloader/settings.dart';

class BottomNavBar extends StatelessWidget {
  BottomNavBar({super.key});

  final PersistentTabController _controller = PersistentTabController(initialIndex: 0);

  @override
  Widget build(BuildContext context) {
    return PersistentTabView(
      context,
      controller: _controller,
      screens: const [
        Home(),
        Downloads(),
        Settings()
      ],
      items: [
        PersistentBottomNavBarItem(
          icon: const Icon(
            Icons.home_max_rounded
          ),
          title: ("Home"),
        ),
        PersistentBottomNavBarItem(
          icon: const Icon(
            Icons.download_outlined
          ),
          title: ("Downloads"),
        ),
        PersistentBottomNavBarItem(
          icon: const Icon(
            Icons.settings_outlined
          ),
          title: ("Settings"),
        )
      ],
      handleAndroidBackButtonPress: true, // Default is true.
      resizeToAvoidBottomInset: true, // This needs to be true if you want to move up the screen on a non-scrollable screen when keyboard appears. Default is true.
      stateManagement: true, // Default is true.
      hideNavigationBarWhenKeyboardAppears: true,
      popBehaviorOnSelectedNavBarItemPress: PopBehavior.all,
      padding: const EdgeInsets.only(top: 8),
      backgroundColor: Colors.grey.shade900,
      isVisible: true,
      animationSettings: const NavBarAnimationSettings(
        navBarItemAnimation: ItemAnimationSettings(
          // Navigation Bar's items animation properties.
          duration: Duration(milliseconds: 400),
          curve: Curves.ease,
        ),
        screenTransitionAnimation: ScreenTransitionAnimationSettings(
          // Screen transition animation on change of selected tab.
          animateTabTransition: true,
          duration: Duration(milliseconds: 200),
          screenTransitionAnimationType: ScreenTransitionAnimationType.fadeIn,
        ),
      ),
      confineToSafeArea: true,
      navBarHeight: kBottomNavigationBarHeight,
      navBarStyle: NavBarStyle.style9, // Choose the nav bar style with this property
    );
  }
}
