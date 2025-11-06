class ProfanityWordFilter {
  static final List<String> _profaneWords = [
    "arse",
    "arsehead",
    "arsehole",
    "ass",
    "asshole",
    "bastard",
    "bitch",
    "bloody",
    "bollocks",
    "brotherfucker",
    "bugger",
    "bullshit",
    "child-fucker",
    "christ on a bike",
    "christ on a cracker",
    "cock",
    "cocksucker",
    "crap",
    "cunt",
    "dammit",
    "damn",
    "damned",
    "damn it",
    "dick",
    "dick-head",
    "dickhead",
    "dumb ass",
    "dumb-ass",
    "dumbass",
    "wtf",
    "dyke",
    "faggot",
    "father-fucker",
    "fatherfucker",
    "fuck",
    "fucked",
    "fucker",
    "fucking",
    "god dammit",
    "goddammit",
    "god damn",
    "goddamn",
    "goddamned",
    "goddamnit",
    "godsdamn",
    "holy shit",
    "horseshit",
    "in shit",
    "jackarse",
    "jack-ass",
    "jackass",
    "jesus christ",
    "jesus fuck",
    "jesus harold christ",
    "jesus h. christ",
    "jesus, mary and joseph",
    "jesus wept",
    "kike",
    "mother fucker",
    "mother-fucker",
    "motherfucker",
    "nigga",
    "nigra",
    "stupid",
    "pigfucker",
    "piss",
    "prick",
    "pussy",
    "shit",
    "shit ass",
    "shite",
    "sibling fucker",
    "sisterfuck",
    "sisterfucker",
    "slut",
    "son of a bitch",
    "son of a whore",
    "spastic",
    "sweet jesus",
    "twat",
    "wanker",
  ];

  static Map<String, dynamic> filterText(String message) {
    final originalMessage = message;
    final lowerMessage = originalMessage.toLowerCase();

    final cleanedMessage = lowerMessage.replaceAll(RegExp(r'[^a-z0-9]'), '');
    final List<String> foundProfanity = [];

    String censoredMessage = originalMessage;

    for (final word in _profaneWords) {
      final cleanedWord =
          word.replaceAll(RegExp(r'[^a-z0-9]'), '').toLowerCase();
      final regex = RegExp(cleanedWord);

      // Search for cleaned word in cleaned message
      final matches = regex.allMatches(cleanedMessage);
      if (matches.isNotEmpty) {
        foundProfanity.add(cleanedWord);
      }

      // Also search and censor in original message, even embedded words
      final censorRegex = RegExp(cleanedWord, caseSensitive: false);
      censoredMessage = censoredMessage.replaceAllMapped(censorRegex, (match) {
        return '*' * match.group(0)!.length;
      });
    }

    foundProfanity.sort();

    if (foundProfanity.isNotEmpty) {
      return {
        'isProfane': true,
        'profanityWordContain': foundProfanity,
        'message': 'Inappropriate words detected: ${foundProfanity.join(', ')}',
        'processedText': cleanedMessage,
        'censoredMessage': censoredMessage,
      };
    } else {
      return {
        'isProfane': false,
        'message': 'No inappropriate words detected.',
        'processedText': cleanedMessage,
        'censoredMessage': originalMessage,
      };
    }
  }
}
