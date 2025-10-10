import 'package:flutter/material.dart';
import 'package:health_buddy/models/gov_scheme.dart';
import 'package:health_buddy/services/gov_scheme_service.dart';
import 'package:url_launcher/url_launcher.dart';

class GovSchemesScreen extends StatefulWidget {
  const GovSchemesScreen({super.key});

  @override
  State<GovSchemesScreen> createState() => _GovSchemesScreenState();
}

class _GovSchemesScreenState extends State<GovSchemesScreen> {
  late Future<List<GovScheme>> _schemesFuture;
  final GovSchemeService _schemeService = GovSchemeService();

  @override
  void initState() {
    super.initState();
    _schemesFuture = _schemeService.fetchMedicalInsuranceSchemes();
  }

  Future<void> _refreshSchemes() async {
    setState(() {
      _schemesFuture = _schemeService.fetchMedicalInsuranceSchemes();
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: InkWell(
        onTap: () => _launchURL(scheme.websiteUrl),
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with title and launch date
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    scheme.title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Launched: ${scheme.launchDate.day}/${scheme.launchDate.month}/${scheme.launchDate.year}',
                    style: const TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                ],
              ),
            ),
            // Description
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                scheme.description,
                style: const TextStyle(fontSize: 16),
              ),
            ),
            const SizedBox(height: 16),
            // Action button
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  ElevatedButton.icon(
                    onPressed: () => _launchURL(scheme.websiteUrl),
                    icon: const Icon(Icons.open_in_browser),
                    label: const Text('View Details'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
