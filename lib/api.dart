import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as html;

class ApiService {
  static const String newsBaseUrl = "https://newsapi.org/v2/everything";
  
  static const String apiKey = "YOUR_NEWS_API_KEY_HERE"; 

  static const String matchesUrl = "https://grintahub.com/events?tag=52"; 

  Future<List<dynamic>> fetchNews() async {
    final url = "$newsBaseUrl?q=الدوري%20السعودي&apiKey=$apiKey";
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['articles'];
    } else {
      throw Exception("Failed to bring News");
    }
  }

  Future<List<String>> fetchMatches() async {
    final response = await http.get(Uri.parse(matchesUrl));

    if (response.statusCode == 200) {
      var document = html.parse(response.body);

      var matchElements = document.querySelectorAll(".event-card");

      List<String> matches = [];
      for (var match in matchElements) {
        var matchInfo = match.text.trim();
        matches.add(matchInfo);
      }

      if (matches.isEmpty) {
        throw Exception("There are no matches");
      }

      return matches;
    } else {
      throw Exception("Failed to bring matches");
    }
  }
}