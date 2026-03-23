import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mitabl_user/helper/route_arguement.dart';
import 'package:mitabl_user/widgets/design_tokens.dart';
import 'package:mitabl_user/widgets/glass_app_bar.dart';
import 'package:mitabl_user/widgets/mitabl_button.dart';
import 'package:mitabl_user/widgets/mitabl_card.dart';
import 'package:mitabl_user/widgets/mitabl_text_field.dart';

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
  final TextEditingController _certificateNumberController =
      TextEditingController();

  @override
  void dispose() {
    _certificateNumberController.dispose();
    super.dispose();
  }

  Future<void> _pickFiles() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
    );

    if (result != null && result.files.isNotEmpty) {
      setState(() {
        for (final file in result.files) {
          // Reject files larger than 10 MB
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
      appBar: const GlassAppBar(title: Text('Kitchen Certification')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(
          horizontal: MitablSpacing.pagePadding,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),

            // ── Step indicator ──
            const Text(
              'Step 3 of 3',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: MitablColors.onSurfaceVariant,
                fontFamily: 'Nunito',
              ),
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: MitablRadius.pillBorder,
              child: LinearProgressIndicator(
                value: 1.0,
                color: MitablColors.accent,
                backgroundColor:
                    MitablColors.outlineVariant.withValues(alpha: 0.3),
                minHeight: 6,
              ),
            ),
            const SizedBox(height: 24),

            // ── Heading ──
            Text(
              'Kitchen Certification',
              style: GoogleFonts.nunito(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: MitablColors.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Complete your kitchen compliance checklist and upload required documents.',
              style: TextStyle(
                fontSize: 14,
                color: MitablColors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),

            // ── Required Checklist ──
            MitablCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Required Checklist',
                    style: GoogleFonts.nunito(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: MitablColors.onSurface,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ..._checklist.entries.map(
                    (entry) => ChecklistItemTile(
                      title: entry.key,
                      value: entry.value,
                      onChanged: (val) {
                        setState(() {
                          _checklist[entry.key] = val ?? false;
                        });
                      },
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: MitablSpacing.listItem),

            // ── Upload Documents ──
            MitablCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Upload Documents',
                    style: GoogleFonts.nunito(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: MitablColors.onSurface,
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Dashed-border upload area
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 28),
                    decoration: BoxDecoration(
                      borderRadius: MitablRadius.cardBorder,
                      border: Border.all(
                        color: MitablColors.outlineVariant,
                        width: 1.5,
                        strokeAlign: BorderSide.strokeAlignInside,
                      ),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.cloud_upload_outlined,
                          size: 40,
                          color: MitablColors.onSurfaceVariant
                              .withValues(alpha: 0.5),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Drop your certifications here',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: MitablColors.onSurface,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Supported formats: PDF, JPG, PNG  •  Max 10MB',
                          style: TextStyle(
                            fontSize: 12,
                            color: MitablColors.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: 160,
                          child: MitablButton(
                            label: 'Browse Files',
                            variant: MitablButtonVariant.outline,
                            fullWidth: false,
                            onPressed: _pickFiles,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Uploaded file list
                  if (_uploadedFiles.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    ..._uploadedFiles.asMap().entries.map(
                      (entry) {
                        final index = entry.key;
                        final file = entry.value;
                        return UploadedFileTile(
                          fileName: file.name,
                          fileSize: _formatFileSize(file.size),
                          onDelete: () {
                            setState(() {
                              _uploadedFiles.removeAt(index);
                            });
                          },
                        );
                      },
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: MitablSpacing.listItem),

            // ── Certificate Number ──
            MitablTextField(
              label: 'Certificate Number',
              hint: 'Enter your certificate number',
              controller: _certificateNumberController,
            ),
            const SizedBox(height: 32),

            // ── Complete Setup ──
            MitablButton(
              label: 'Complete Setup',
              variant: MitablButtonVariant.primary,
              fullWidth: true,
              onPressed: () {
                Navigator.of(context).pushNamedAndRemoveUntil(
                  '/DashboardCook',
                  (route) => false,
                );
              },
            ),
            const SizedBox(height: MitablSpacing.breathe),
          ],
        ),
      ),
    );
  }
}
