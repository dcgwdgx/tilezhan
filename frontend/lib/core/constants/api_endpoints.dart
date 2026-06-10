/// API endpoint constants.
/// Values are placeholders until backend is deployed.

class ApiEndpoints {
  static const baseUrl = 'https://api.tilezhan.app/v1';

  // Auth
  static const register = '$baseUrl/auth/register';
  static const login = '$baseUrl/auth/login';

  // User
  static const profile = '$baseUrl/user/profile';
  static const progress = '$baseUrl/user/progress';

  // Puzzles
  static const daily = '$baseUrl/puzzles/daily';
  static const flashcards = '$baseUrl/puzzles/flashcards';
  static const nanikiru = '$baseUrl/puzzles/nanikiru';
  static const evaluate = '$baseUrl/puzzles/evaluate';

  // SRS
  static const srsSync = '$baseUrl/srs/sync';
  static const srsReport = '$baseUrl/srs/report';

  // IAP
  static const products = '$baseUrl/products';
  static const subscription = '$baseUrl/subscription';
}
