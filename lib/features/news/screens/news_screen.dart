import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:cadre_upsc/features/news/services/news_service.dart';
import 'package:cadre_upsc/features/news/services/news_ingestion_service.dart';

class NewsScreen extends StatefulWidget {
  const NewsScreen({super.key});

  @override
  State<NewsScreen> createState() => _NewsScreenState();
}

class _NewsScreenState extends State<NewsScreen> {
  String _selectedCategory = 'All';
  final List<String> _categories = ['All', 'National', 'Polity', 'Economy', 'International', 'Sci-Tech', 'Environment'];

  String _formatTimestamp(Timestamp? timestamp) {
    if (timestamp == null) return "Just Now";
    final now = DateTime.now();
    final date = timestamp.toDate();
    final diff = now.difference(date);

    if (diff.inDays == 0) return "Today";
    if (diff.inDays == 1) return "Yesterday";
    return "${date.day}/${date.month}/${date.year}";
  }

  Future<void> _launchUrl(BuildContext context, String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Could not open link.")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final newsService = NewsService();

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        title: const Text("CURRENT AFFAIRS", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.blueAccent),
            onPressed: () async {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Refreshing news feed...")));
              await NewsIngestionService().fetchAndIngestRSS();
            },
          )
        ],
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: newsService.getDailyBriefStream(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
             return Center(child: Text("Error: ${snapshot.error}", style: const TextStyle(color: Colors.redAccent)));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator(color: Colors.amber));
          }

          var newsList = snapshot.data!;

          // Filter logic
          if (_selectedCategory != 'All') {
            newsList = newsList.where((news) {
              final tags = news['tags'] as List<dynamic>? ?? [];
              final headline = (news['headline']?.toString() ?? '').toLowerCase();
              final summary = (news['summary']?.toString() ?? '').toLowerCase();
              final primaryTag = tags.isNotEmpty ? tags.first.toString().toLowerCase() : '';
              
              // Broad synonym matching to catch AI variations
              List<String> keywords = [];
              switch (_selectedCategory) {
                case 'National':
                  keywords = ['national', 'india', 'state', 'domestic', 'country'];
                  break;
                case 'Polity':
                  keywords = ['polity', 'law', 'supreme court', 'governance', 'parliament', 'constitution', 'bill', 'act', 'election'];
                  break;
                case 'Economy':
                  keywords = ['economy', 'rbi', 'finance', 'budget', 'gdp', 'market', 'trade', 'tax'];
                  break;
                case 'International':
                  keywords = ['international', 'world', 'global', 'foreign', 'un', 'diplomacy', 'israel', 'us', 'war'];
                  break;
                case 'Sci-Tech':
                  keywords = ['sci-tech', 'science', 'technology', 'space', 'isro', 'ai', 'cyber', 'health', 'digital'];
                  break;
                case 'Environment':
                  keywords = ['environment', 'climate', 'pollution', 'wildlife', 'conservation', 'energy', 'water'];
                  break;
                default:
                  keywords = [_selectedCategory.toLowerCase()];
              }

              // 1. Check if the AI's primary tag matches any synonym
              if (keywords.any((word) => primaryTag.contains(word))) {
                return true;
              }
              
              // 2. Fallback: Check if any synonym exists in headline/summary
              if (keywords.any((word) => headline.contains(word) || summary.contains(word))) {
                return true;
              }
              
              return false;
            }).toList();
          }

          if (newsList.isEmpty && _selectedCategory == 'All') {
            // Show seed articles so new users are never greeted by a blank screen
            final seedArticles = [
              {
                'headline': 'Budget 2025-26: Key Highlights for UPSC Aspirants',
                'summary': '• Rs 1.5 lakh crore allocated for education sector — highest ever.\n• New Unified Pension Scheme (UPS) replaces NPS for government employees.\n• Infrastructure outlay raised to Rs 11.11 lakh crore, focus on rural connectivity.',
                'fullArticle': 'The Union Budget 2025-26 focuses heavily on education and infrastructure. A record Rs 1.5 lakh crore has been allocated to the education sector. In addition, the New Unified Pension Scheme (UPS) has been introduced to replace the existing NPS for government employees, ensuring better retirement security. Infrastructure has also seen its outlay raised to Rs 11.11 lakh crore, with a significant part marked for improving rural connectivity.',
                'timestamp': null,
                'sourceUrl': '',
              },
              {
                'headline': 'India Ranks 111th on Global Hunger Index 2024',
                'summary': '• India falls behind neighbours Nepal (68th) and Bangladesh (84th).\n• Wasting prevalence at 18.7% — highest in the world.\n• Government disputes methodology; cites POSHAN 2.0 and PDS reforms.',
                'fullArticle': 'India has been ranked 111th out of 125 countries in the Global Hunger Index (GHI) 2024, lagging behind regional neighbours such as Nepal (68th) and Bangladesh (84th). The report highlights that India’s child wasting prevalence stands at 18.7%, the highest globally. However, the Indian government has strongly disputed the methodology of the index, asserting that it is flawed and does not reflect the positive impact of robust interventions like POSHAN 2.0 and structural reforms in the Public Distribution System (PDS).',
                'timestamp': null,
                'sourceUrl': '',
              },
              {
                'headline': 'ISRO Successfully Tests Gaganyaan Crew Module',
                'summary': '• Crew Escape System abort test conducted successfully over Bay of Bengal.\n• India\'s first crewed spaceflight mission targeted for 2025.\n• Gaganyaan is a Class-III GS Paper topic under Science & Technology.',
                'fullArticle': 'The Indian Space Research Organisation (ISRO) successfully accomplished the first uncrewed flight test (TV-D1) for the Gaganyaan mission. The test validated the Crew Escape System (CES) off the coast of Sriharikota over the Bay of Bengal, successfully ejecting and safely recovering the simulated module. This paves the way for India’s ambitious maiden human spaceflight mission, highly anticipated to launch in 2025.',
                'timestamp': null,
                'sourceUrl': '',
              },
            ];
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline, color: Colors.amber, size: 14),
                      const SizedBox(width: 6),
                       const Text('Sample articles — Tap refresh for live news', style: TextStyle(color: Colors.amber, fontSize: 11)),
                      const Spacer(),
                      TextButton(
                        onPressed: () async {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Refreshing news feed...")));
                          await NewsIngestionService().fetchAndIngestRSS();
                        },
                         child: const Text('REFRESH', style: TextStyle(color: Colors.blueAccent, fontSize: 11)),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: seedArticles.length,
                    itemBuilder: (context, index) =>
                        _buildNewsCard(context, seedArticles[index]),
                  ),
                ),
              ],
            );
          }

          return Column(
            children: [
              _buildFilterBar(),
              if (newsList.isEmpty)
                 Expanded(
                   child: Center(
                     child: Column(
                       mainAxisAlignment: MainAxisAlignment.center,
                       children: [
                         Icon(Icons.satellite_alt, color: Colors.blueAccent.withValues(alpha: 0.3), size: 64),
                         const SizedBox(height: 16),
                         Text("NO INTEL AVAILABLE", style: TextStyle(color: Colors.white54, fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                       ],
                     ),
                   ),
                 ),
              if (newsList.isNotEmpty)
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: () async {
                      await NewsIngestionService().fetchAndIngestRSS();
                    },
                    color: Colors.amber,
                    backgroundColor: const Color(0xFF1E293B),
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: newsList.length,
                      itemBuilder: (context, index) {
                        final news = newsList[index];
                        return _buildNewsCard(context, news);
                      },
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildFilterBar() {
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final category = _categories[index];
          final isSelected = _selectedCategory == category;
          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: ChoiceChip(
              label: Text(category, style: TextStyle(fontSize: 12, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
              selected: isSelected,
              selectedColor: Colors.blueAccent.withValues(alpha: 0.3),
              backgroundColor: Colors.transparent,
              labelStyle: TextStyle(color: isSelected ? Colors.cyanAccent : Colors.white54),
              side: BorderSide(color: isSelected ? Colors.cyanAccent : Colors.white24),
              onSelected: (selected) {
                if (selected) {
                  setState(() {
                    _selectedCategory = category;
                  });
                }
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildNewsCard(BuildContext context, Map<String, dynamic> news) {
    final sourceUrl = news['sourceUrl']?.toString() ?? '';
    final hasLink = sourceUrl.isNotEmpty;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: hasLink ? Colors.blueAccent.withValues(alpha: 0.3) : Colors.white10),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          splashColor: Colors.blueAccent.withValues(alpha: 0.1),
          highlightColor: Colors.blueAccent.withValues(alpha: 0.05),
          onTap: () => _showArticleDetails(context, news),
          child: ListTile(
          contentPadding: const EdgeInsets.all(16),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.blueAccent.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      _getPrimaryTag(news),
                      style: TextStyle(color: Colors.blueAccent.shade100, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ),
                  Text(
                    _formatTimestamp(news['timestamp']),
                    style: const TextStyle(color: Colors.white38, fontSize: 12),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                news['headline'] ?? 'Untitled Report',
                style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  news['summary'] ?? '',
                  style: const TextStyle(color: Colors.white70, height: 1.4),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                if (hasLink)
                  Padding(
                    padding: const EdgeInsets.only(top: 12.0),
                    child: Row(
                      children: [
                        const Icon(Icons.open_in_new, size: 14, color: Colors.amber),
                        const SizedBox(width: 4),
                        Text(
                          "READ SOURCE",
                          style: TextStyle(color: Colors.amber.shade400, fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

  String _getPrimaryTag(Map<String, dynamic> news) {
    final tags = news['tags'] as List<dynamic>?;
    if (tags != null && tags.isNotEmpty) {
      return tags.first.toString().toUpperCase();
    }
    return "CURRENT AFFAIRS";
  }

  void _showArticleDetails(BuildContext context, Map<String, dynamic> news) {
    final sourceUrl = news['sourceUrl']?.toString() ?? '';
    final hasLink = sourceUrl.isNotEmpty;

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      barrierColor: Colors.black.withValues(alpha: 0.4),
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, animation, secondaryAnimation) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Center(
            child: Container(
              width: MediaQuery.of(context).size.width * 0.9,
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.8,
              ),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B).withValues(alpha: 0.85),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white10),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.5),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Flexible(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.blueAccent.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              _getPrimaryTag(news),
                              style: TextStyle(
                                color: Colors.blueAccent.shade100,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.white54),
                          onPressed: () => Navigator.of(context).pop(),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      news['headline'] ?? 'Untitled Report',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _formatTimestamp(news['timestamp']),
                      style: const TextStyle(color: Colors.white38, fontSize: 13),
                    ),
                    const SizedBox(height: 20),
                    Flexible(
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        child: Text(
                          news['fullArticle'] ?? news['summary'] ?? '',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 15,
                            height: 1.6,
                          ),
                        ),
                      ),
                    ),
                    if (hasLink) ...[
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            _launchUrl(context, sourceUrl);
                          },
                          icon: const Icon(Icons.open_in_new, size: 18, color: Colors.white),
                          label: const Text(
                            "READ FULL ARTICLE ON WEB",
                            style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1, color: Colors.white),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blueAccent.shade400,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ]
                  ],
                ),
              ),
            ),
          ),
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: animation,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.95, end: 1.0).animate(
              CurvedAnimation(
                parent: animation,
                curve: Curves.easeOutCubic,
              ),
            ),
            child: child,
          ),
        );
      },
    );
  }
}

