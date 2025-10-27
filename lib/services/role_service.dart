import 'package:shared_preferences/shared_preferences.dart';

enum AppRole { parent, child }

class RoleService {
  static Future<void> setRole(AppRole role) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString('role', role.toString());
  }

  static Future<AppRole> getRole() async {
    final prefs = await SharedPreferences.getInstance();
    final roleStr = prefs.getString('role') ?? AppRole.parent.toString();
    return roleStr == AppRole.child.toString() ? AppRole.child : AppRole.parent;
  }
}
