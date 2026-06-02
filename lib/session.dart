class Session {
  static const String baseUrl = "http://localhost:3000/api";
  
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