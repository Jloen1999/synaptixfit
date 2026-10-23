/// Rol de la cuenta.
enum UserRole {
  user,
  admin;

  static UserRole fromApi(String? value) =>
      value == 'ADMIN' ? UserRole.admin : UserRole.user;
}
