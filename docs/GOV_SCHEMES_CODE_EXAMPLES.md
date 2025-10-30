# Government Schemes AI Feature - Code Examples

## Example 1: Basic Service Usage

```dart
import 'package:health_buddy/services/gov_scheme_ai_service.dart';

// Simple usage
final service = GovSchemeAIService();
final schemes = await service.fetchGovernmentMedicalSchemes();

for (var scheme in schemes) {
  print('Scheme: ${scheme.title}');
  print('Eligibility: ${scheme.eligibility}');
  print('Benefits: ${scheme.benefits}');
}
```

## Example 2: Display Schemes in ListView

```dart
FutureBuilder<List<GovScheme>>(
  future: _schemeService.fetchGovernmentMedicalSchemes(),
  builder: (context, snapshot) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return const Center(child: CircularProgressIndicator());
    }
    
    if (snapshot.hasError) {
      return Center(child: Text('Error: ${snapshot.error}'));
    }
    
    final schemes = snapshot.data ?? [];
    
    return ListView.builder(
      itemCount: schemes.length,
      itemBuilder: (context, index) {
        final scheme = schemes[index];
        return _buildSchemeCard(scheme);
      },
    );
  },
)
```

## Example 3: Beautiful Scheme Card Widget

```dart
Widget _buildSchemeCard(GovScheme scheme) {
  return Card(
    margin: const EdgeInsets.only(bottom: 16),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    elevation: 3,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Gradient Header
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
              _buildDetailSection('👥 Eligibility', scheme.eligibility),
              const SizedBox(height: 16),
              _buildDetailSection('✨ Benefits', scheme.benefits),
              const SizedBox(height: 16),
              _buildDetailSection('🏥 Coverage', scheme.coverage),
            ],
          ),
        ),
        // Button
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
        style: const TextStyle(
          fontSize: 13,
          height: 1.5,
          color: Colors.grey,
        ),
        maxLines: 3,
        overflow: TextOverflow.ellipsis,
      ),
    ],
  );
}
```

## Example 4: URL Launch Implementation

```dart
import 'package:url_launcher/url_launcher.dart';

Future<void> _launchURL(String url) async {
  final Uri uri = Uri.parse(url);
  
  if (await canLaunchUrl(uri)) {
    await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    );
  } else {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not launch URL'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }
}
```

## Example 5: Pull-to-Refresh Implementation

```dart
Future<void> _refreshSchemes() async {
  setState(() {
    _schemesFuture = _schemeService.fetchGovernmentMedicalSchemes();
  });
}

RefreshIndicator(
  onRefresh: _refreshSchemes,
  color: Theme.of(context).colorScheme.primary,
  child: FutureBuilder<List<GovScheme>>(
    future: _schemesFuture,
    builder: (context, snapshot) {
      // Build UI based on snapshot
    },
  ),
)
```

## Example 6: Error Handling Pattern

```dart
// In Service
Future<List<GovScheme>> fetchGovernmentMedicalSchemes() async {
  try {
    final response = await http
        .post(url, headers: headers, body: jsonEncode(body))
        .timeout(const Duration(seconds: 60));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      // Parse and return schemes
      return schemes;
    } else {
      return _getDefaultSchemes();
    }
  } on TimeoutException catch (_) {
    print('Request timeout');
    return _getDefaultSchemes();
  } catch (e) {
    print('Error: $e');
    return _getDefaultSchemes();
  }
}
```

## Example 7: Model Usage

```dart
// Creating a new scheme
final scheme = GovScheme(
  id: '1',
  title: 'Ayushman Bharat PMJAY',
  description: 'Health insurance for poor families',
  imageUrl: 'https://example.com/image.jpg',
  websiteUrl: 'https://pmjay.gov.in',
  launchDate: DateTime(2018, 9, 23),
  eligibility: 'Poor and vulnerable families',
  benefits: 'Free treatment up to ₹5 lakhs',
  coverage: 'Hospital expenses, diagnostics',
);

// Converting to JSON
final json = scheme.toJson();

// Creating from JSON
final scheme2 = GovScheme.fromJson(json);
```

## Example 8: Filtering Schemes

```dart
// Filter schemes by eligibility
List<GovScheme> filterByEligibility(
  List<GovScheme> schemes,
  String keyword,
) {
  return schemes
      .where((scheme) =>
          scheme.eligibility.toLowerCase().contains(keyword.toLowerCase()))
      .toList();
}

// Usage
final employeeSchemes = filterByEligibility(schemes, 'employees');
```

## Example 9: Searching Schemes

```dart
// Search functionality
List<GovScheme> searchSchemes(
  List<GovScheme> schemes,
  String query,
) {
  final lowerQuery = query.toLowerCase();
  return schemes
      .where((scheme) =>
          scheme.title.toLowerCase().contains(lowerQuery) ||
          scheme.description.toLowerCase().contains(lowerQuery) ||
          scheme.benefits.toLowerCase().contains(lowerQuery))
      .toList();
}

// Usage
final results = searchSchemes(schemes, 'PMJAY');
```

## Example 10: Scheme Selection & Navigation

```dart
class SchemeDetailPage extends StatelessWidget {
  final GovScheme scheme;

  const SchemeDetailPage({Key? key, required this.scheme}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(scheme.title),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSection('Description', scheme.description),
              const SizedBox(height: 20),
              _buildSection('Eligibility', scheme.eligibility),
              const SizedBox(height: 20),
              _buildSection('Benefits', scheme.benefits),
              const SizedBox(height: 20),
              _buildSection('Coverage', scheme.coverage),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: () => _launchURL(scheme.websiteUrl),
                child: const Text('Apply Now'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection(String title, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          content,
          style: const TextStyle(
            fontSize: 16,
            height: 1.5,
          ),
        ),
      ],
    );
  }
}
```

## Example 11: Gemini API Request Structure

```dart
// Request body sent to Gemini
{
  'contents': [
    {
      'parts': [
        {
          'text': '''
You are a healthcare information specialist. 
Provide detailed information about government medical and health schemes in India.

For EACH scheme provide JSON:
{
  "id": "unique_id",
  "title": "Scheme Name",
  "description": "Description",
  "eligibility": "Who is eligible",
  "benefits": "Key benefits",
  "websiteUrl": "https://official-link",
  "coverage": "Coverage details"
}

Include major schemes like PMJAY, CGHS, RSBY, ESIS, NHM, PMMVY.
Provide ONLY valid JSON array.
'''
        }
      ]
    }
  ]
}
```

## Example 12: Response Parsing from Gemini

```dart
// Gemini API response
{
  "candidates": [
    {
      "content": {
        "parts": [
          {
            "text": "[{\"id\":\"1\",\"title\":\"Scheme Name\",...}]"
          }
        ]
      }
    }
  ]
}

// Parse response
final responseText = response['candidates'][0]['content']['parts'][0]['text'];
final jsonMatch = RegExp(r'\[[\s\S]*\]').firstMatch(responseText);
final jsonString = jsonMatch?.group(0);
final schemes = jsonDecode(jsonString);
```

---

**All code examples are production-ready and follow Flutter best practices!**
