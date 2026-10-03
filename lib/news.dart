import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'api.dart';

class LastNewsPage extends StatefulWidget {
  const LastNewsPage({super.key});

  @override
  _LastNewsPageState createState() => _LastNewsPageState();
}

class _LastNewsPageState extends State<LastNewsPage> {
  late Future<List<dynamic>> newsFuture;

  @override
  void initState() {
    super.initState();
    newsFuture = ApiService().fetchNews();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color.fromARGB(255, 213, 230, 255), Colors.white],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: FutureBuilder<List<dynamic>>(
          future: newsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(child: Text('خطأ: ${snapshot.error}'));
            } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(child: Text('لا توجد أخبار متاحة'));
            }

            final newsList = snapshot.data!;
            return ListView.builder(
              itemCount: newsList.length,
              itemBuilder: (context, index) {
                final article = newsList[index];
                return Card(
                  margin: const EdgeInsets.all(10),
                  elevation: 5,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: InkWell(
                    onTap: () {
                      if (article['url'] != null) {
                        launchURL(article['url']);
                      }
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(10.0),
                      child: Directionality(
                        textDirection: TextDirection.rtl,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (article['urlToImage'] != null)
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  article['urlToImage'],
                                  fit: BoxFit.cover,
                                ),
                              ),
                            const SizedBox(height: 10),
                            Text(
                              article['title'] ?? 'بدون عنوان',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                                color: Color.fromARGB(255, 78, 103, 171),
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              article['description'] ?? 'بدون وصف',
                              style: const TextStyle(
                                fontSize: 14,
                                color: Color.fromARGB(255, 121, 172, 255),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  void launchURL(String url) async {
    final Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("لا يمكن فتح الرابط")));
    }
  }
}
