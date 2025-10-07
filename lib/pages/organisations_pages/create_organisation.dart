import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:tree_planting_protocol/providers/wallet_provider.dart';
import 'package:tree_planting_protocol/utils/constants/ui/color_constants.dart';
import 'package:tree_planting_protocol/utils/services/contract_functions/organisation_factory_contract.dart/organisation_factory_contract_write_functions.dart';
import 'package:tree_planting_protocol/utils/services/ipfs_services.dart'; // Add this import for your IPFS function
import 'package:tree_planting_protocol/widgets/basic_scaffold.dart';

class CreateOrganisationPage extends StatefulWidget {
  const CreateOrganisationPage({super.key});

  @override
  State<CreateOrganisationPage> createState() => _CreateOrganisationPageState();
}

class _CreateOrganisationPageState extends State<CreateOrganisationPage> {
  final descriptionController = TextEditingController();
  final nameController = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  File? _selectedImage;
  bool _isUploading = false;
  String? _uploadedImageHash;

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
          _uploadedImageHash = null;
        });
      }
    } catch (e) {
      _showCustomSnackBar(
        "Error selecting image: $e",
        isError: true,
      );
    }
  }

  Future<void> _uploadImageToIPFS() async {
    if (_selectedImage == null) return;

    try {
      final hash = await uploadToIPFS(_selectedImage!, (uploading) {
        setState(() {
          _isUploading = uploading;
        });
      });

      if (hash != null) {
        setState(() {
          _uploadedImageHash = hash;
        });
        _showCustomSnackBar("Image uploaded successfully!");
      } else {
        _showCustomSnackBar("Failed to upload image", isError: true);
      }
    } catch (e) {
      _showCustomSnackBar(
        "Error uploading image: $e",
        isError: true,
      );
    }
  }

  Future<void> submitDetails() async {
    final description = descriptionController.text;
    final name = nameController.text;

    if (description.isEmpty || name.isEmpty) {
      _showCustomSnackBar(
        "Enter all the details",
        isError: true,
      );
      return;
    }

    // If image is selected but not uploaded, upload it first
    if (_selectedImage != null && _uploadedImageHash == null) {
      await _uploadImageToIPFS();
      if (_uploadedImageHash == null) {
        _showCustomSnackBar(
          "Please wait for image upload to complete or remove the image",
          isError: true,
        );
        return;
      }
    }

    try {
      final walletProvider =
          // ignore: use_build_context_synchronously
          Provider.of<WalletProvider>(context, listen: false);
      // ignore: unused_local_variable
      final result =
          await OrganisationFactoryContractWriteFunctions.createOrganisation(
              walletProvider: walletProvider,
              name: name,
              description: description,
              organisationPhotoHash: _uploadedImageHash ?? "");
      _showCustomSnackBar("Organisation details submitted successfully!");
    } catch (e) {
      _showCustomSnackBar(
        "Error submitting organisation details: $e",
        isError: true,
      );
      return;
    }
    // ignore: use_build_context_synchronously
    context.push('/organisations');
  }

  void _showCustomSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.check_circle_outline,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: isError
            ? getThemeColors(context)['secondaryButton']
            : getThemeColors(context)['primaryButton'],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return BaseScaffold(
      title: "Organisation Details",
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => context.pop(),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          horizontal: screenWidth * 0.05,
          vertical: 20,
        ),
        child: Column(
          children: [
            _buildFormSection(screenWidth),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildFormSection(double screenWidth) {
    return Container(
      width: double.infinity,
      constraints: BoxConstraints(maxWidth: screenWidth * 0.92),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: getThemeColors(context)['background'],
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    Icons.edit_note,
                    color: getThemeColors(context)['icon'],
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Organisation Details',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: getThemeColors(context)['textPrimary'],
                        ),
                      ),
                      Text(
                        'Tell us about your organisation',
                        style: TextStyle(
                          fontSize: 14,
                          color: getThemeColors(context)['textPrimary'],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildFormField(
                  controller: nameController,
                  label: 'Organisation Name',
                  hint: 'e.g., Green Earth, Tree Lovers...',
                  icon: Icons.eco,
                  maxLines: 1,
                ),
                const SizedBox(height: 20),
                _buildFormField(
                  controller: descriptionController,
                  label: 'Description',
                  hint: 'Describe your organisation...',
                  icon: Icons.description,
                  maxLines: 5,
                  minLines: 3,
                ),
                const SizedBox(height: 20),
                _buildImageUploadSection(),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isUploading ? null : submitDetails,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: getThemeColors(context)['primary'],
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      shadowColor: primaryGreenColor,
                    ),
                    child: _isUploading
                        ? Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              const Text(
                                'Uploading...',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text(
                                'Continue',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: getThemeColors(context)['primary'],
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Icon(
                                  Icons.arrow_forward,
                                  size: 18,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageUploadSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.image,
                color: getThemeColors(context)['icon'],
                size: 18,
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              'Organisation Logo',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1CD381),
              ),
            ),
            const Text(
              ' (Optional)',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: Colors.grey,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: const Color(0xFFFAEB96),
              width: 2,
            ),
          ),
          child: _selectedImage == null
              ? InkWell(
                  onTap: _pickImage,
                  borderRadius: BorderRadius.circular(16),
                  child: SizedBox(
                    height: 120,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.cloud_upload_outlined,
                          size: 40,
                          color: getThemeColors(context)['icon'],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Tap to upload logo',
                          style: TextStyle(
                            fontSize: 16,
                            color: getThemeColors(context)['textPrimary'],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          'PNG, JPG up to 10MB',
                          style: TextStyle(
                            fontSize: 12,
                            color: getThemeColors(context)['textSecondary'],
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : Column(
                  children: [
                    Container(
                      height: 200,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.file(
                          _selectedImage!,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextButton.icon(
                            onPressed: _pickImage,
                            icon: const Icon(Icons.edit, size: 16),
                            label: const Text('Change'),
                            style: TextButton.styleFrom(
                              foregroundColor:
                                  getThemeColors(context)['primary'],
                            ),
                          ),
                        ),
                        if (_uploadedImageHash == null) ...[
                          const SizedBox(width: 8),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed:
                                  _isUploading ? null : _uploadImageToIPFS,
                              icon: _isUploading
                                  ? SizedBox(
                                      height: 16,
                                      width: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                          Colors.white,
                                        ),
                                      ),
                                    )
                                  : const Icon(Icons.cloud_upload, size: 16),
                              label: Text(
                                  _isUploading ? 'Uploading...' : 'Upload'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    getThemeColors(context)['primary'],
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                          ),
                        ] else ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: getThemeColors(context)['primary'],
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.green, width: 1),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.check_circle,
                                  color: getThemeColors(context)['icon'],
                                  size: 16,
                                ),
                                const SizedBox(width: 4),
                                const Text(
                                  'Uploaded',
                                  style: TextStyle(
                                    color: Colors.green,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        const SizedBox(width: 8),
                        IconButton(
                          onPressed: () {
                            setState(() {
                              _selectedImage = null;
                              _uploadedImageHash = null;
                            });
                          },
                          icon: const Icon(Icons.delete_outline),
                          style: IconButton.styleFrom(
                            foregroundColor: getThemeColors(context)['error'],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
        ),
      ],
    );
  }

  Widget _buildFormField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    int maxLines = 1,
    int? minLines,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: getThemeColors(context)['icon'],
                size: 18,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: getThemeColors(context)['primary'],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: getThemeColors(context)['border']!,
              width: 2,
            ),
          ),
          child: TextField(
            controller: controller,
            maxLines: maxLines,
            minLines: minLines,
            style: TextStyle(
              fontSize: 16,
              color: getThemeColors(context)['textPrimary'],
              height: 1.4,
            ),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(
                color: getThemeColors(context)['background'],
                fontSize: 14,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.all(20),
              filled: true,
              fillColor: getThemeColors(context)['background'],
            ),
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    descriptionController.dispose();
    nameController.dispose();
    super.dispose();
  }
}
