/// Qué apuntes compartidos se piden: todos los que puedo ver, los de mis
/// amigos o los que cualquier usuario puede ver (comunidad).
enum SharedNotesScope {
  all('ALL'),
  friends('FRIENDS'),
  community('PUBLIC');

  const SharedNotesScope(this.apiValue);

  final String apiValue;
}
