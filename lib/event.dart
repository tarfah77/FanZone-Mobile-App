import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

class ScheduledMatchesScreen extends StatefulWidget {
  @override
  _ScheduledMatchesScreenState createState() => _ScheduledMatchesScreenState();
}

class _ScheduledMatchesScreenState extends State<ScheduledMatchesScreen> {
  List<dynamic> saudiMatches = [];
  bool isLoading = true;
  String errorMessage = '';
  String currentDate = '';

  final Map<String, String> _teamImages = {
    'Al-Ahli': 'teams/alahli.png',
    'Al-Hilal': 'teams/alhilal.png',
    'Al-Nassr': 'teams/alnassr.png',
    'Al-Ittihad': 'teams/alIttihad.png',
    'Al-Shabab': 'teams/alshabab.png',
    'Al-Fateh': 'teams/alfateh.png',
    'Al-Taawoun': 'teams/altaawoun.png',
    'Al-Raed': 'teams/alraed.png',
    'Al-Khaleej': 'teams/alkhaleej.png',
    'Al-Wehda': 'teams/alwehda.png',
    'Al-Riyadh': 'teams/alriyadh.png',
    'Al-Ettifaq': 'teams/alettifaq.png',
    'Al-Fayha': 'teams/alfayha.png',
    'Damac': 'teams/Damac.png',
    'Al-Okhdood': 'teams/alokhdood.png',
    'Al-Qadsiah': 'teams/alqadsiah.png',
    'Al-Kholood': 'teams/alkholood.png',
    'Al-Orobah': 'teams/alorobah.png',
  };

  @override
  void initState() {
    super.initState();
    currentDate = DateFormat('EEEE, MMMM d').format(DateTime.now());
    fetchScheduledMatches();
  }

  Future<void> fetchScheduledMatches() async {
    try {
      setState(() {
        isLoading = true;
        errorMessage = '';
      });

     
      final String apiKey = 'YOUR_RAPID_API_KEY_HERE';
      final String date = DateFormat('yyyy-MM-dd').format(DateTime.now());
      final Uri url = Uri.parse(
        'https://sportapi7.p.rapidapi.com/api/v1/sport/football/scheduled-events/$date',
      );

      final response = await http.get(
        url,
        headers: {
          'x-rapidapi-host': 'sportapi7.p.rapidapi.com',
          'x-rapidapi-key': apiKey,
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final events = data['events'] ?? [];

        final filtered =
            events.where((event) {
              final league =
                  event['tournament']?['name']?.toString().toLowerCase() ?? '';
              final tournamentId = event['tournament']?['id']?.toString() ?? '';
              return league.contains('saudi') || tournamentId == '205';
            }).toList();

        setState(() {
          saudiMatches = filtered;
          isLoading = false;
        });
      } else {
        throw Exception('Failed to load matches: ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        isLoading = false;
        errorMessage = 'Error loading matches: ${e.toString()}';
      });
    }
  }

  String formatTimestamp(int timestamp) {
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
    return DateFormat('h:mm a').format(date);
  }

  Widget _buildTeamLogo(String teamName, String networkImageUrl) {
    final localImagePath = _teamImages[teamName];
    return localImagePath != null
        ? Image.asset(
          localImagePath,
          width: 50,
          height: 50,
          errorBuilder:
              (context, error, stackTrace) =>
                  _buildNetworkImage(networkImageUrl),
        )
        : _buildNetworkImage(networkImageUrl);
  }

  Widget _buildNetworkImage(String networkImageUrl) {
    return networkImageUrl.isNotEmpty
        ? Image.network(
          networkImageUrl,
          width: 50,
          height: 50,
          errorBuilder: (context, error, stackTrace) => _buildDefaultIcon(),
        )
        : _buildDefaultIcon();
  }

  Widget _buildDefaultIcon() {
    return const Icon(Icons.sports_soccer, size: 40, color: Colors.blue);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFDAEBFF), Colors.white],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child:
            isLoading
                ? const Center(child: CircularProgressIndicator())
                : errorMessage.isNotEmpty
                ? Center(child: Text(errorMessage))
                : saudiMatches.isEmpty
                ? const Center(child: Text('No matches today'))
                : ListView.builder(
                  itemCount: saudiMatches.length,
                  itemBuilder: (context, index) {
                    final match = saudiMatches[index];
                    final home = match['homeTeam']['name'];
                    final away = match['awayTeam']['name'];
                    final homeLogo = match['homeTeam']['image'] ?? '';
                    final awayLogo = match['awayTeam']['image'] ?? '';
                    final time = match['startTimestamp'];
                    final league =
                        match['tournament']['name'] ?? 'Saudi Pro League';

                    return Card(
                      margin: const EdgeInsets.all(10),
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                        side: BorderSide(color: Colors.blue.shade100, width: 1),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            Text(
                              league,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.green[800],
                              ),
                            ),
                            const SizedBox(height: 10),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                Column(
                                  children: [
                                    _buildTeamLogo(home, homeLogo),
                                    const SizedBox(height: 5),
                                    Text(
                                      home,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                const Text(
                                  'VS',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                    color: Color.fromARGB(255, 93, 6, 0),
                                  ),
                                ),
                                Column(
                                  children: [
                                    _buildTeamLogo(away, awayLogo),
                                    const SizedBox(height: 5),
                                    Text(
                                      away,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.access_time, size: 16),
                                const SizedBox(width: 5),
                                Text(formatTimestamp(time)),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
      ),
    );
  }
}