/// Compatibility shim retained during migration to GenAPI-only flow.
class FreepikService {
  FreepikService._();

  static final FreepikService instance = FreepikService._();

  Future<String?> findCoverUrl({required String query}) async {
    return null;
  }
}
