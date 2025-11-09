import 'dart:math';

class StringUtils {
  static final _rnd = Random();

  /// Generates a random string of specified length
  /// 
  /// Parameters:
  /// - [length]: The length of the string to generate (default: 10)
  /// - [includeNumbers]: Whether to include numbers in the string (default: true)
  /// - [includeUppercase]: Whether to include uppercase letters (default: true)
  /// - [includeLowercase]: Whether to include lowercase letters (default: true)
  /// - [includeSpecial]: Whether to include special characters (default: false)
  /// 
  /// Returns a randomly generated string based on the specified parameters
  static String generateRandomString({
    int length = 10,
    bool includeNumbers = true,
    bool includeUppercase = true,
    bool includeLowercase = true,
    bool includeSpecial = false,
  }) {
    var chars = '';
    
    if (includeLowercase) chars += 'abcdefghijklmnopqrstuvwxyz';
    if (includeUppercase) chars += 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
    if (includeNumbers) chars += '0123456789';
    if (includeSpecial) chars += '!@#\$%^&*()_+-=[]{}|;:,.<>?';

    if (chars.isEmpty) {
      chars = 'abcdefghijklmnopqrstuvwxyz'; // Default to lowercase if nothing selected
    }

    return String.fromCharCodes(
      Iterable.generate(
        length,
        (_) => chars.codeUnitAt(_rnd.nextInt(chars.length)),
      ),
    );
  }

  /// Generates a random username with optional prefix and suffix
  /// 
  /// Parameters:
  /// - [prefix]: Optional prefix for the username
  /// - [suffix]: Optional suffix for the username
  /// - [length]: Length of the random part (default: 6)
  /// 
  /// Returns a username in the format: prefix + random + suffix
  static String generateUsername({
    String prefix = '',
    String suffix = '',
    int length = 6,
  }) {
    final randomPart = generateRandomString(
      length: length,
      includeSpecial: false,
      includeUppercase: false,
    );
    return '$prefix$randomPart$suffix';
  }

  /// Generates a memorable string by combining random words
  /// 
  /// Parameters:
  /// - [wordCount]: Number of words to combine (default: 2)
  /// - [separator]: Character to use between words (default: '')
  /// 
  /// Returns a memorable string like "BlueElephant" or "HappyCloud"
  static String generateMemorable({
    int wordCount = 2,
    String separator = '',
  }) {
    final adjectives = [
      'Happy', 'Brave', 'Bright', 'Swift', 'Cool',
      'Wild', 'Calm', 'Smart', 'Blue', 'Red',
    ];
    
    final nouns = [
      'Wolf', 'Eagle', 'River', 'Cloud', 'Star',
      'Moon', 'Tree', 'Mountain', 'Ocean', 'Sun',
    ];

    final words = <String>[];
    
    // Add adjectives for all but the last word
    for (var i = 0; i < wordCount - 1; i++) {
      words.add(adjectives[_rnd.nextInt(adjectives.length)]);
    }
    
    // Add noun as the last word
    words.add(nouns[_rnd.nextInt(nouns.length)]);

    return words.join(separator);
  }
}