class Session {
  static const String baseUrl = "https://honkaistarretail-repo.vercel.app/";
  
  static String token = "";
  static String username = "";
  static String role = "";
  static List<String> orderHistory = [];

  static void clearSession() {
    token = "";
    username = "";
    role = "";
    orderHistory.clear();
  }
}