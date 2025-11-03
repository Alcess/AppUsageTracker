import '../utils/shared_prefs_helper.dart';

enum AppRole { parent, child }

class RoleService {
  static Future<void> setRole(AppRole role) async {
    await SharedPrefsHelper.setString('role', role.toString());
  }

  static Future<AppRole> getRole() async {
    final roleStr =
        await SharedPrefsHelper.getString('role') ?? AppRole.parent.toString();
    return roleStr == AppRole.child.toString() ? AppRole.child : AppRole.parent;
  }
}
