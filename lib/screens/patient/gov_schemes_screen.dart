import 'package:flutter/material.dart';
import 'package:medivault_ai/models/gov_scheme.dart';
import 'package:medivault_ai/services/gov_scheme_ai_service.dart';
import 'package:url_launcher/url_launcher.dart';

class GovSchemesScreen extends StatefulWidget {
  const GovSchemesScreen({super.key});

  @override
  State<GovSchemesScreen> createState() => _GovSchemesScreenState();
}

class _GovSchemesScreenState extends State<GovSchemesScreen> {
  late Future<List<GovScheme>> _schemesFuture;
  final GovSchemeAIService _schemeService = GovSchemeAIService();

  @override
  void initState() {
    super.initState();
    _schemesFuture = _schemeService.fetchGovernmentMedicalSchemes();
  }

  Future<void> _refreshSchemes() async {
    setState(() {
      _schemesFuture = _schemeService.fetchGovernmentMedicalSchemes();
    });
  }

  Future<void> _launchURL(String url) async {
    final Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Could not launch URL')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Government Health Schemes'),
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: _refreshSchemes,
        child: FutureBuilder<List<GovScheme>>(
          future: _schemesFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Failed to load schemes'),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _refreshSchemes,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              );
            } else if (snapshot.hasData) {
              final schemes = snapshot.data!;
              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: schemes.length,
                itemBuilder: (context, index) {
                  final scheme = schemes[index];
                  return _buildSchemeCard(scheme);
                },
              );
            } else {
              return const Center(child: Text('No schemes available'));
            }
          },
        ),
      ),
    );
  }

  Widget _buildSchemeCard(GovScheme scheme) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 3,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with gradient background
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).colorScheme.primary,
                  Theme.of(context).colorScheme.primary.withAlpha(180),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  scheme.title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Text(
                  scheme.description,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.white70,
                    height: 1.4,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          // Content
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Eligibility
                _buildDetailSection(
                  '👥 Eligibility',
                  scheme.eligibility.isNotEmpty
                      ? scheme.eligibility
                      : 'Check official website for details',
                ),
                const SizedBox(height: 16),
                // Benefits
                _buildDetailSection(
                  '✨ Benefits',
                  scheme.benefits.isNotEmpty
                      ? scheme.benefits
                      : 'Multiple health and insurance benefits',
                ),
                const SizedBox(height: 16),
                // Coverage
                _buildDetailSection(
                  '🏥 Coverage',
                  scheme.coverage.isNotEmpty
                      ? scheme.coverage
                      : 'Comprehensive medical coverage',
                ),
              ],
            ),
          ),
          // Action button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _launchURL(scheme.websiteUrl),
                icon: const Icon(Icons.open_in_browser),
                label: const Text('View Details & Apply'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildDetailSection(String title, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          content,
          style: const TextStyle(fontSize: 13, height: 1.5, color: Colors.grey),
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}
