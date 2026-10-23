/// Listado de amistades: amigos, solicitudes recibidas/enviadas o bloqueados.
enum FriendshipListKind {
  friends('FRIENDS'),
  received('RECEIVED'),
  sent('SENT'),
  blocked('BLOCKED');

  const FriendshipListKind(this.apiValue);

  final String apiValue;
}
