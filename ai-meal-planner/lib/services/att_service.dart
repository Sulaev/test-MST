import 'package:app_tracking_transparency/app_tracking_transparency.dart';

class AttService {
  Future<TrackingStatus> getStatus() {
    return AppTrackingTransparency.trackingAuthorizationStatus;
  }

  Future<TrackingStatus> requestIfNeeded() async {
    final TrackingStatus current = await getStatus();
    if (current != TrackingStatus.notDetermined) {
      return current;
    }
    return AppTrackingTransparency.requestTrackingAuthorization();
  }

  Future<String> getAdvertisingId() async {
    return AppTrackingTransparency.getAdvertisingIdentifier();
  }
}
