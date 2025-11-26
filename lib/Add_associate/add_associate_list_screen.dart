import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart'; // ✅ For call functionality
import '/Model/associate_model.dart';
import '/service/associate_list_service.dart';
import '/DirectLogin/DirectLoginPage.dart';

class AssociateListScreen extends StatefulWidget {
  const AssociateListScreen({super.key});

  @override
  State<AssociateListScreen> createState() => _AssociateListScreenState();
}

class _AssociateListScreenState extends State<AssociateListScreen> {
  final AssociateService _service = AssociateService();
  late Future<List<Associate>> _futureAssociates;

  @override
  void initState() {
    super.initState();
    _futureAssociates = _service.fetchAssociates().then((list) {
      list = list.reversed.toList(); // Latest at top
      return list;
    });
  }

  // ✅ Function to launch phone dialer
  void _makeCall(String phoneNumber) async {
    final Uri url = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cannot launch phone dialer')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.yellow,
        title: const Text(
          'Associates',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: FutureBuilder<List<Associate>>(
        future: _futureAssociates,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No associates found'));
          } else {
            final associates = snapshot.data!;
            return ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              itemCount: associates.length,
              itemBuilder: (context, index) {
                final associate = associates[index];
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.amber.shade100,
                      child: Text(
                        _initialsOf(associate.fullName),
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
                      ),
                    ),
                    title: Text(
                      associate.fullName,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(
                      associate.phone,
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => _showAssociateDetail(associate),
                  ),
                );
              },
            );
          }
        },
      ),
    );
  }

  void _showAssociateDetail(Associate associate) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.85,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
          ),
          child: SingleChildScrollView(
            controller: scrollController,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 50,
                  height: 5,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                _associateCard(associate),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Card _associateCard(Associate associate) {
    final profileImage = _profileImageFor(associate.profilePic);
    final projectBadges = _buildProjectBadges(associate);
    final documentBadges = _buildDocumentBadges(associate);
                return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                CircleAvatar(
                  radius: 32,
                  backgroundColor: Colors.grey.shade200,
                  backgroundImage: profileImage,
                  child: profileImage == null
                      ? Text(
                          _initialsOf(associate.fullName),
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        )
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        associate.fullName,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                      ),
                      if (_isNotEmpty(associate.associateId))
                        Text(
                          'ID: ${associate.associateId}',
                          style: const TextStyle(color: Colors.black54),
                        ),
                      Text(
                        associate.status ? 'Status: Active' : 'Status: Inactive',
                        style: TextStyle(
                          color: associate.status ? Colors.green : Colors.red,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            _detailRow(
              label: 'Phone',
              value: associate.phone,
              trailing: IconButton(
                              icon: const Icon(Icons.call, color: Colors.green),
                              onPressed: () => _makeCall(associate.phone),
              ),
            ),
            _detailRow(label: 'Email', value: associate.email),
            _detailRow(label: 'Current Address', value: associate.currentAddress),
            _detailRow(label: 'Permanent Address', value: associate.permanentAddress),
            _detailRow(
              label: 'Location',
              value: _combineLocation(associate),
            ),
            _detailRow(label: 'Aadhaar No', value: associate.aadhaarNo),
            _detailRow(label: 'PAN No', value: associate.panNo),
            _detailRow(label: 'Created On', value: _formatDate(associate.createDate)),
            _detailRow(label: 'Joined On', value: _formatDate(associate.joiningDate)),
            if (documentBadges.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Text(
                'Documents',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: documentBadges,
              ),
            ],
            if (projectBadges.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Text(
                'Projects & Commission',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: projectBadges,
              ),
            ],
          ],
        ),
      ),
    );
  }

  List<Widget> _buildProjectBadges(Associate associate) {
    final List<Widget> badges = [];
    void addBadge(String? name, num? commission) {
      if (!_isNotEmpty(name)) return;
      final formattedCommission =
          commission == null ? '' : ' • ₹${_formatAmount(commission)}';
      badges.add(
        Chip(
          label: Text('$name$formattedCommission'),
          backgroundColor: Colors.yellow.shade100,
        ),
      );
    }

    addBadge(associate.projectName1, associate.commissionProject1);
    addBadge(associate.projectName2, associate.commissionProject2);
    return badges;
  }

  List<Widget> _buildDocumentBadges(Associate associate) {
    final docEntries = <String, String?>{
      'Aadhaar Front': associate.aadharFrontPic,
      'Aadhaar Back': associate.aadhaarBackPic,
      'PAN Card': associate.panPic,
      'Profile Pic': associate.profilePic,
    };
    return docEntries.entries
        .where((entry) => _isNotEmpty(entry.value))
        .map((entry) => InkWell(
              onTap: () => _showImageDialog(entry.key, entry.value!),
              child: Chip(
                label: Text(entry.key),
                backgroundColor: Colors.blue.shade50,
                avatar: const Icon(Icons.image, size: 18, color: Colors.blue),
              ),
            ))
        .toList();
  }

  void _showImageDialog(String title, String imagePath) {
    final imageUrl = _buildImageUrl(imagePath);
    print('🖼️ Showing image dialog for: $title');
    print('📁 Image path from API: $imagePath');
    print('🌐 Constructed URL: $imageUrl');

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: Stack(
          children: [
            Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.8,
                maxWidth: MediaQuery.of(context).size.width * 0.9,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  ),
                  Flexible(
                    child: ClipRRect(
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(16),
                        bottomRight: Radius.circular(16),
                      ),
                      child: _buildImageWithFallback(imageUrl, imagePath),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _buildImageUrl(String? path) {
    if (!_isNotEmpty(path)) return '';
    final cleaned = path!.trim();
    
    // If already a full URL, return as is
    if (cleaned.startsWith('http://') || cleaned.startsWith('https://')) {
      return cleaned;
    }
    
    // API returns paths like "/Uploads/file.jpg" - remove leading slash and prepend base URL
    String normalized = cleaned.startsWith('/') ? cleaned.substring(1) : cleaned;
    
    // If path contains a folder (e.g., "Uploads/file.png" or "Images/file.png")
    // API format: "/Uploads/741b27d7-2463-4af5-a50b-58ee3b06e92a.jpg"
    if (normalized.contains('/')) {
      return 'https://realapp.cheenu.in/$normalized';
    }
    
    // If just a filename without folder, try Uploads first (matches API format)
    return 'https://realapp.cheenu.in/Uploads/$normalized';
  }
  
  Widget _buildImageWithFallback(String primaryUrl, String imagePath) {
    final alternativeUrls = _getAlternativeUrls(imagePath);
    int currentIndex = alternativeUrls.indexOf(primaryUrl);
    if (currentIndex == -1) currentIndex = 0;

    return _tryLoadImage(alternativeUrls, currentIndex);
  }

  Widget _tryLoadImage(List<String> urls, int index) {
    if (index >= urls.length) {
      return _buildErrorWidget(urls.first);
    }

    final url = urls[index];
    return Image.network(
      url,
      fit: BoxFit.contain,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return const Center(
          child: Padding(
            padding: EdgeInsets.all(32.0),
            child: CircularProgressIndicator(),
          ),
        );
      },
      errorBuilder: (context, error, stackTrace) {
        print('❌ Failed to load from: $url');
        // Try next URL if available
        if (index + 1 < urls.length) {
          print('🔄 Trying alternative URL...');
          return _tryLoadImage(urls, index + 1);
        }
        // All URLs failed
        return _buildErrorWidget(urls.first);
      },
    );
  }

  Widget _buildErrorWidget(String attemptedUrl) {
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 8),
            const Text(
              'Failed to load image',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Tried: $attemptedUrl',
                style: const TextStyle(fontSize: 10, color: Colors.grey),
                textAlign: TextAlign.center,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Please check console for details',
              style: TextStyle(fontSize: 10, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  List<String> _getAlternativeUrls(String? path) {
    if (!_isNotEmpty(path)) return [];
    final cleaned = path!.trim();
    if (cleaned.startsWith('http://') || cleaned.startsWith('https://')) {
      return [cleaned];
    }
    
    String normalized = cleaned.startsWith('/') ? cleaned.substring(1) : cleaned;
    
    // If path already contains folder (API format: "/Uploads/file.jpg")
    if (normalized.contains('/')) {
      // Try the exact path first, then try lowercase version as fallback
      return [
        'https://realapp.cheenu.in/$normalized',
        'https://realapp.cheenu.in/${normalized.replaceFirst('Uploads', 'uploads')}',
        'https://realapp.cheenu.in/${normalized.replaceFirst('Images', 'images')}',
      ];
    }
    
    // If just filename, try alternative URLs in order (prioritize Uploads to match API)
    return [
      'https://realapp.cheenu.in/Uploads/$normalized',
      'https://realapp.cheenu.in/uploads/$normalized',
      'https://realapp.cheenu.in/Images/$normalized',
      'https://realapp.cheenu.in/images/$normalized',
    ];
  }

  Widget _detailRow({required String label, required String? value, Widget? trailing}) {
    if (!_isNotEmpty(value)) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(
            child: Text(
              value!,
              style: const TextStyle(color: Colors.black87),
            ),
          ),
          if (trailing != null) trailing,
        ],
      ),
    );
  }

  String _combineLocation(Associate associate) {
    final parts = [
      associate.city,
      associate.state,
      associate.pincode,
    ].where(_isNotEmpty).toList();
    if (parts.isEmpty) return '';
    return parts.join(', ');
  }

  String? _formatDate(String? date) {
    if (!_isNotEmpty(date)) return null;
    try {
      final dt = DateTime.parse(date!);
      final months = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec'
      ];
      final day = dt.day.toString().padLeft(2, '0');
      final month = months[dt.month - 1];
      final year = dt.year;
      final hour = dt.hour.toString().padLeft(2, '0');
      final minute = dt.minute.toString().padLeft(2, '0');
      return '$day $month $year, $hour:$minute';
    } catch (_) {
      return date;
    }
  }

  String _initialsOf(String name) {
    if (name.trim().isEmpty) return 'A';
    final parts = name.trim().split(' ');
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }

  bool _isNotEmpty(String? value) => value != null && value.trim().isNotEmpty;

  ImageProvider? _profileImageFor(String? path) {
    if (!_isNotEmpty(path)) return null;
    final imageUrl = _buildImageUrl(path);
    return NetworkImage(imageUrl);
  }

  String _formatAmount(num value) {
    final withoutTrailingZero = value % 1 == 0 ? value.toStringAsFixed(0) : value.toStringAsFixed(2);
    return withoutTrailingZero;
  }
}