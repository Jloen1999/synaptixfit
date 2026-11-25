/// Estado de carga común a las pantallas del panel de administración.
enum AdminStatus {
  initial,
  loading,
  ready,
  failure;

  bool get isLoading => this == AdminStatus.initial || this == loading;
}
