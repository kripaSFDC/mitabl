import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:mitabl_user/helper/route_arguement.dart';
import 'package:mitabl_user/widgets/design_tokens.dart';

import '../element/checklist_item_tile.dart';
import '../element/uploaded_file_tile.dart';

class KitchenCertificationPage extends StatefulWidget {
  const KitchenCertificationPage({super.key});

  static Route<void> route({RouteArguments? routeArguments}) {
    return MaterialPageRoute<void>(
      builder: (_) => const KitchenCertificationPage(),
    );
  }

  @override
  State<KitchenCertificationPage> createState() =>
      _KitchenCertificationPageState();
}

class _KitchenCertificationPageState extends State<KitchenCertificationPage> {
  final Map<String, bool> _checklist = {
    'Health & Safety Registration': false,
    'Tax Residency': false,
    'Food Building Certificate': false,
    'Insurance': false,
    'Product Certificate Labelling': false,
  };

  final List<PlatformFile> _uploadedFiles = [];

  Future<void> _pickFiles() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
    );

    if (result != null && result.files.isNotEmpty) {
      setState(() {
        for (final file in result.files) {
          if ((file.size) <= 10 * 1024 * 1024) {
            _uploadedFiles.add(file);
          }
        }
      });
    }
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MitablColors.surface,
      body: Column(
        children: [
          // TopAppBar
          SafeArea(
            bottom: false,
            child: Container(
              height: 64,
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () {
                      if (Navigator.of(context).canPop()) {
                        Navigator.of(context).pop();
                      } else {
                        Navigator.of(context).pushNamedAndRemoveUntil('/HomePage', (r) => false);
                      }
                    },
                    icon: const Icon(Icons.arrow_back,
                        color: MitablColors.primary),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'mitabl',
                    style: TextStyle(
                      fontFamily: 'Nunito',
                      fontWeight: FontWeight.w800,
                      fontSize: 24,
                      color: MitablColors.primary,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Scrollable content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),

                  // Hero header
                  const Text(
                    'Kitchen Certification',
                    style: TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      color: MitablColors.onSurface,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Upload your safety compliance documents to verify your kitchen atelier. Our team will review your submission within 48 hours.',
                    style: TextStyle(
                      fontSize: 16,
                      color: MitablColors.onSurfaceVariant,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Upload Zone
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        vertical: 48, horizontal: 24),
                    decoration: BoxDecoration(
                      color: MitablColors.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(32),
                      border: Border.all(
                        color: MitablColors.outlineVariant,
                        width: 2,
                        strokeAlign: BorderSide.strokeAlignInside,
                      ),
                    ),
                    child: Column(
                      children: [
                        // Upload icon circle
                        Container(
                          width: 80,
                          height: 80,
                          decoration: const BoxDecoration(
                            color: Color(0xFFFFEDD5),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.cloud_upload_outlined,
                            size: 36,
                            color: MitablColors.primary,
                          ),
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          'Drop your certifications here',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: MitablColors.onSurface,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const SizedBox(
                          width: 280,
                          child: Text(
                            'Supports PDF, JPG, and PNG up to 10MB. Ensure text is legible for faster verification.',
                            style: TextStyle(
                              fontSize: 14,
                              color: MitablColors.onSurfaceVariant,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(height: 32),
                        SizedBox(
                          height: 52,
                          child: ElevatedButton(
                            onPressed: _pickFiles,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: MitablColors.primary,
                              foregroundColor: MitablColors.onPrimary,
                              shape: const RoundedRectangleBorder(
                                borderRadius: MitablRadius.pillBorder,
                              ),
                              elevation: 4,
                              shadowColor:
                                  MitablColors.primary.withValues(alpha: 0.20),
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 32),
                            ),
                            child: const Text(
                              'Browse Files',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Status grid - show checklist items as status cards
                  ..._checklist.entries.map((entry) {
                    return ChecklistItemTile(
                      title: entry.key,
                      value: entry.value,
                      onChanged: (val) {
                        setState(() {
                          _checklist[entry.key] = val ?? false;
                        });
                      },
                    );
                  }),
                  const SizedBox(height: 24),

                  // Required Checklist card
                  Container(
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(32),
                    ),
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Required Checklist',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: MitablColors.onSurface,
                          ),
                        ),
                        SizedBox(height: 24),
                        _ChecklistRow(
                          title: 'Business Registration (ABN/GST)',
                          subtitle:
                              'Proof of registered entity in your region.',
                          isComplete: true,
                        ),
                        SizedBox(height: 16),
                        _ChecklistRow(
                          title: 'Food Safety Certificate',
                          subtitle:
                              'Certification of completed Level 2 safety training.',
                          isComplete: true,
                        ),
                        SizedBox(height: 16),
                        _ChecklistRow(
                          title: 'Public Liability Insurance',
                          subtitle:
                              'Minimum coverage of \$10M recommended.',
                          isComplete: false,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Uploaded Files section
                  Container(
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: MitablColors.surfaceContainerLowest,
                      borderRadius: BorderRadius.circular(32),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Uploaded Files',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: MitablColors.onSurface,
                          ),
                        ),
                        const SizedBox(height: 24),
                        // Show uploaded files or static examples
                        if (_uploadedFiles.isNotEmpty)
                          ..._uploadedFiles.asMap().entries.map((entry) {
                            final index = entry.key;
                            final file = entry.value;
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: UploadedFileTile(
                                fileName: file.name,
                                fileSize: _formatFileSize(file.size),
                                onDelete: () {
                                  setState(() {
                                    _uploadedFiles.removeAt(index);
                                  });
                                },
                              ),
                            );
                          })
                        else ...[
                          const _UploadedFileRow(
                            icon: Icons.picture_as_pdf,
                            name: 'health_cert_2024.pdf',
                            detail: '2.4 MB',
                          ),
                          const SizedBox(height: 12),
                          const _UploadedFileRow(
                            icon: Icons.image_outlined,
                            name: 'gst_reg_document.jpg',
                            detail: '1.1 MB',
                          ),
                        ],
                        const SizedBox(height: 24),
                        // View All History button
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: TextButton(
                            onPressed: () {},
                            style: TextButton.styleFrom(
                              foregroundColor: MitablColors.primary,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: const Text(
                              'View All History',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Complete Setup button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: MitablColors.primaryGradient,
                        borderRadius: MitablRadius.pillBorder,
                        boxShadow: [
                          BoxShadow(
                            color:
                                MitablColors.primary.withValues(alpha: 0.20),
                            blurRadius: 16,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: MitablRadius.pillBorder,
                          onTap: () {
                            Navigator.of(context).pushNamedAndRemoveUntil(
                              '/DashboardCook',
                              (route) => false,
                            );
                          },
                          child: const Center(
                            child: Text(
                              'Complete Setup',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: MitablColors.onPrimary,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 48),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A single checklist row matching the HTML design.
class _ChecklistRow extends StatelessWidget {
  const _ChecklistRow({
    required this.title,
    required this.subtitle,
    required this.isComplete,
  });

  final String title;
  final String subtitle;
  final bool isComplete;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(4),
          margin: const EdgeInsets.only(top: 4),
          decoration: BoxDecoration(
            color: isComplete
                ? MitablColors.secondaryContainer
                : const Color(0xFFF8FAFC),
            shape: BoxShape.circle,
          ),
          child: Icon(
            isComplete ? Icons.check : Icons.circle_outlined,
            size: 14,
            color: isComplete
                ? MitablColors.onSecondaryContainer
                : MitablColors.onSurfaceVariant,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                  color: MitablColors.onSurface,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 13,
                  color: MitablColors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// A row showing an uploaded file with icon, name, and size.
class _UploadedFileRow extends StatelessWidget {
  const _UploadedFileRow({
    required this.icon,
    required this.name,
    required this.detail,
  });

  final IconData icon;
  final String name;
  final String detail;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: MitablColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: MitablColors.onSurfaceVariant,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: MitablColors.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  detail,
                  style: const TextStyle(
                    fontSize: 12,
                    color: MitablColors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () {},
            icon: const Icon(
              Icons.more_vert,
              color: MitablColors.onSurfaceVariant,
              size: 20,
            ),
          ),
        ],
      ),
    );
  }
}
