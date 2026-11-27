/// Oyun sesleri kullanıcı isteğiyle kaldırıldı (kulak tırmalıyordu).
/// Çağrılar bozulmasın diye boş bir arayüz kalır.
class Sfx {
  static bool enabled = false;
  static Future<void> init() async {}
  static void pause(bool v) {}
  static void crowd(String kind) {}
}
