import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:tree_planting_protocol/components/transaction_dialog.dart';
import 'package:tree_planting_protocol/providers/wallet_provider.dart';
import 'package:tree_planting_protocol/utils/constants/ui/color_constants.dart';
import 'package:tree_planting_protocol/utils/services/contract_functions/tree_nft_contract/tree_nft_contract_write_functions.dart';
import 'package:tree_planting_protocol/utils/services/storage_service.dart';
import 'package:tree_planting_protocol/widgets/basic_scaffold.dart';

class RegisterUserPage extends StatefulWidget {
  const RegisterUserPage({super.key});

  @override
  State<RegisterUserPage> createState() => _RegisterUserPageState();
}

class _RegisterUserPageState extends State<RegisterUserPage> {
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;
  String? _errorMessage = "";
  String? _profilePhotoHash = "";
  bool _isUploading = false;
  File? _selectedImage;

  final nameController = TextEditingController();

  @override
  void dispose() {
    nameController.dispose();
    super.dispose();
  }

  void _showSuccessDialog(String title, String message,
      {String? transactionHash}) {
    TransactionDialog.showSuccess(
      context,
      title: title,
      message: message,
      transactionHash: transactionHash,
    );
  }

  void _showErrorDialog(String title, String message) {
    TransactionDialog.showError(
      context,
      title: title,
      message: message,
    );
  }

  Future<void> _pickAndUploadImage() async {
    try {
      final XFile? profilePhoto =
          await _picker.pickImage(source: ImageSource.gallery);
      if (profilePhoto == null) return;

      setState(() {
        _isUploading = true;
        _selectedImage = File(profilePhoto.path);
      });

      File imageFile = File(profilePhoto.path);
      String? hash = await uploadToIPFS(imageFile, (isUploading) {
        setState(() {
          _isUploading = isUploading;
        });
      });

      if (hash != null) {
        setState(() {
          _profilePhotoHash = hash;
          _isUploading = false;
        });
      } else {
        setState(() {
          _isUploading = false;
        });
        _showErrorDialog('Upload Failed', 'Failed to upload image to IPFS');
      }
    } catch (e) {
      setState(() {
        _isUploading = false;
      });
      _showErrorDialog(
          'Error', 'Failed to pick or upload image: ${e.toString()}');
    }
  }

  bool _validateFields() {
    if (nameController.text.trim().isEmpty) {
      _showErrorDialog('Validation Error', 'Please enter your name');
      return false;
    }
    if (_profilePhotoHash == null || _profilePhotoHash!.isEmpty) {
      _showErrorDialog(
          'Validation Error', 'Please select and upload a profile photo');
      return false;
    }
    return true;
  }

  Future<void> _registerUser() async {
    if (!_validateFields()) return;

    final WalletProvider walletProvider =
        Provider.of<WalletProvider>(context, listen: false);
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final result = await ContractWriteFunctions.registerUser(
        walletProvider: walletProvider,
        name: nameController.text.trim(),
        profilePhotoHash: _profilePhotoHash.toString(),
      );

      if (result.success) {
        _showSuccessDialog(
          'Registration Successful!',
          'User registered successfully! Welcome to the Tree Planting Protocol!',
          transactionHash: result.transactionHash,
        );
      } else {
        _showErrorDialog('Registration Failed', result.errorMessage!);
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Unexpected error: ${e.toString()}';
      });
      _showErrorDialog('Unexpected Error', e.toString());
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return BaseScaffold(
      title: "Register",
      showBackButton: true,
      isLoading: _isLoading,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            Text(
              "Enter your details! Fellow Tree Planter!!",
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: getThemeColors(context)['primary'],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),
            _buildFormField(
              controller: nameController,
              label: 'Name',
              icon: Icons.person,
              hint: 'Enter your full name',
              maxLines: 1,
              context: context,
            ),

            const SizedBox(height: 30),
            _buildProfilePhotoSection(),
            const SizedBox(height: 40),

            if (_errorMessage != null && _errorMessage!.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  border: Border.all(color: Colors.red.shade200),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline,
                        color: getThemeColors(context)['error']),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style:
                            TextStyle(color: getThemeColors(context)['error']),
                      ),
                    ),
                  ],
                ),
              ),

            // Register Button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isLoading || _isUploading ? null : _registerUser,
                style: ElevatedButton.styleFrom(
                  backgroundColor: getThemeColors(context)['primary'],
                  foregroundColor: getThemeColors(context)['background'],
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 2,
                ),
                child: _isLoading
                    ? SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                              getThemeColors(context)['textPrimary']!),
                        ),
                      )
                    : const Text(
                        'Register',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfilePhotoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFF1CD381),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.camera_alt,
                color: getThemeColors(context)['icon'],
                size: 18,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'Profile Photo',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: getThemeColors(context)['primary'],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: _isUploading ? null : _pickAndUploadImage,
          child: Container(
            height: 200,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: getThemeColors(context)['primaryBorder']!,
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: getThemeColors(context)['primary']!,
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: _buildPhotoContent(),
          ),
        ),
      ],
    );
  }

  Widget _buildPhotoContent() {
    if (_isUploading) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(
                getThemeColors(context)['primary']!),
          ),
          SizedBox(height: 16),
          Text(
            'Uploading to IPFS...',
            style: TextStyle(
              color: getThemeColors(context)['primary']!,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      );
    }

    if (_selectedImage != null) {
      return Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Image.file(
              _selectedImage!,
              height: 200,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
          Positioned(
            top: 8,
            right: 8,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: Colors.black54,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.check,
                color: getThemeColors(context)['icon']!,
                size: 16,
              ),
            ),
          ),
          Positioned(
            bottom: 8,
            left: 8,
            right: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Tap to change photo',
                style: TextStyle(
                  color: getThemeColors(context)['textPrimary'],
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      );
    }

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.add_a_photo_outlined,
          size: 48,
          color: getThemeColors(context)['icon']!,
        ),
        const SizedBox(height: 16),
        Text(
          'Tap to select profile photo',
          style: TextStyle(
            fontSize: 16,
            color: getThemeColors(context)['textPrimary'],
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'This field is required',
          style: TextStyle(
            fontSize: 12,
            color: getThemeColors(context)['textPrimary'],
          ),
        ),
      ],
    );
  }
}

Widget _buildFormField({
  required TextEditingController controller,
  required String label,
  required String hint,
  required IconData icon,
  int maxLines = 1,
  int? minLines,
  required BuildContext context,
}) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: getThemeColors(context)['primary'],
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
              color: getThemeColors(context)['primary']!,
            ),
          ),
        ],
      ),
      const SizedBox(height: 12),
      Container(
        decoration: BoxDecoration(
          color: getThemeColors(context)['background']!,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: getThemeColors(context)['border']!,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: getThemeColors(context)['shadow']!,
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: TextField(
          controller: controller,
          maxLines: maxLines,
          minLines: minLines,
          style: TextStyle(
            fontSize: 16,
            color: getThemeColors(context)['textPrimary']!,
            height: 1.4,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              color: getThemeColors(context)['textSecondary']!,
              fontSize: 14,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.all(20),
            filled: true,
            fillColor: Colors.transparent,
          ),
        ),
      ),
    ],
  );
}
