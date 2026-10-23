/// Sexo declarado en el perfil físico.
enum Sex {
  male('MALE'),
  female('FEMALE'),
  nonBinary('NON_BINARY'),
  preferNotToSay('PREFER_NOT_TO_SAY');

  const Sex(this.apiValue);

  final String apiValue;

  static Sex? fromApi(String? value) {
    for (final v in values) {
      if (v.apiValue == value) return v;
    }
    return null;
  }
}
