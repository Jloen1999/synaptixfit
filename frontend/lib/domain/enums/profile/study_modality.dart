/// Modalidad de estudio.
enum StudyModality {
  inPerson('IN_PERSON'),
  hybrid('HYBRID'),
  online('ONLINE');

  const StudyModality(this.apiValue);

  final String apiValue;

  static StudyModality? fromApi(String? value) {
    for (final v in values) {
      if (v.apiValue == value) return v;
    }
    return null;
  }
}
