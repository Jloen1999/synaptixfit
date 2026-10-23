/// Filtro temporal del muro.
enum FeedPeriod {
  all('ALL'),
  today('TODAY'),
  week('WEEK'),
  month('MONTH');

  const FeedPeriod(this.apiValue);

  final String apiValue;
}
