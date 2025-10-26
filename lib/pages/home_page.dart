import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:home_launcher_app/services/launch_permissions.dart';
import 'package:installed_apps/app_info.dart';
import 'package:installed_apps/installed_apps.dart';
import 'installed_apps_list_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String enteredCode = "";
  final String secretCode = "12345";
  List<AppInfo> installedApps = [];

  bool? isDefaultLauncher;

  @override
  void initState() {
    checkLauncherStatus();
    super.initState();
    Future.delayed(const Duration(seconds: 2), getAllInstalledApps);
  }

  Future<void> getAllInstalledApps() async {
    List<AppInfo> apps = await InstalledApps.getInstalledApps(
      excludeSystemApps: false,
      excludeNonLaunchableApps: true,
      withIcon: true,
    );
    setState(() {
      installedApps = apps;
    });
  }

  void checkLauncherStatus() async {
    bool status = await LauncherPermission.isDefaultLauncher();
    setState(() {
      isDefaultLauncher = status;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: KeyboardListener(
        focusNode: FocusNode()..requestFocus(), // Request focus to capture keys
        autofocus: true,
        onKeyEvent: (KeyEvent event) {
          if (event is KeyDownEvent) {
            // Only listen to key down events
            final key = event.logicalKey.keyLabel;

            // Check if it's a number
            if (RegExp(r'^[0-9]$').hasMatch(key)) {
              enteredCode += key;

              // Check if code matches
              if (enteredCode.endsWith(secretCode)) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => InstalledAppsListPage(installedApps: installedApps,),
                  ),
                );
                enteredCode = ""; // reset after success
              }
            } else {
              // If any other key pressed, reset
              enteredCode = "";
            }
          }
        },
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              margin: EdgeInsets.only(bottom: 20),
              child: ElevatedButton(
                onPressed: () async {
                  bool isDefault = await LauncherPermission.isDefaultLauncher();
                  if (!isDefault) {
                    await LauncherPermission.requestSetDefaultLauncher();
                    // Check status again after a delay
                    Future.delayed(Duration(seconds: 2), () async {
                      bool newStatus =
                          await LauncherPermission.isDefaultLauncher();
                      setState(() {
                        isDefaultLauncher = newStatus;
                      });
                      if (newStatus) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('App is now default launcher!'),
                            backgroundColor: Colors.green,
                            duration: Duration(milliseconds: 500),
                          ),
                        );
                      }
                    });
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('App is already default launcher'),
                        backgroundColor: Colors.blue,
                        duration: Duration(milliseconds: 500),
                      ),
                    );
                  }
                },
                child: Text(
                  "Set as Default Launcher",
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => InstalledAppsListPage(installedApps: installedApps,),
                  ),
                );
              },
              child: Text("Go to App List"),
            ),
            const Center(child: Text("You are home screen 🤩")),
          ],
        ),
      ),
    );
  }
}
