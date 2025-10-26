import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:tree_planting_protocol/providers/mint_nft_provider.dart';
import 'package:tree_planting_protocol/utils/constants/route_constants.dart';
import 'package:tree_planting_protocol/utils/constants/ui/color_constants.dart';
import 'package:tree_planting_protocol/utils/constants/tree_species_constants.dart';
import 'package:tree_planting_protocol/widgets/basic_scaffold.dart';

class MintNftDetailsPage extends StatefulWidget {
  const MintNftDetailsPage({super.key});

  @override
  State<MintNftDetailsPage> createState() => _MintNftCoordinatesPageState();
}

class _MintNftCoordinatesPageState extends State<MintNftDetailsPage> {
  final descriptionController = TextEditingController();
  String? selectedSpecies;
  int numberOfTrees = 1;

  void submitDetails() {
    final description = descriptionController.text;

    if (description.isEmpty ||
        selectedSpecies == null ||
        selectedSpecies!.isEmpty) {
      _showCustomSnackBar(
        "Please enter description and select a tree species.",
        isError: true,
      );
      return;
    }

    if (numberOfTrees <= 0) {
      _showCustomSnackBar(
        "Please select at least 1 tree.",
        isError: true,
      );
      return;
    }

    Provider.of<MintNftProvider>(context, listen: false)
        .setDescription(description);
    Provider.of<MintNftProvider>(context, listen: false)
        .setSpecies(selectedSpecies!);
    Provider.of<MintNftProvider>(context, listen: false)
        .setNumberOfTrees(numberOfTrees);

    _showCustomSnackBar("Details submitted successfully!");

    // Navigate to organization selection page
    context.push(RouteConstants.mintNftOrganisationPath);
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
      title: "NFT Details",
      showBackButton: true,
      onBackPressed: () => context.pop(),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          horizontal: screenWidth * 0.05,
          vertical: 20,
        ),
        child: Column(
          children: [
            _buildFormSection(screenWidth),
            const SizedBox(height: 32),
            // _buildPreviewSection(),
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
        color: getThemeColors(context)['background'],
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: getThemeColors(context)['border']!,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: getThemeColors(context)['shadow']!,
            blurRadius: 10,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: getThemeColors(context)['primary'],
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(22),
                topRight: Radius.circular(22),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: getThemeColors(context)['background'],
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: getThemeColors(context)['border']!,
                      width: 2,
                    ),
                  ),
                  child: Icon(
                    Icons.edit_note,
                    color: getThemeColors(context)['primary'],
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'NFT Details',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: getThemeColors(context)['textSecondary'],
                        ),
                      ),
                      Text(
                        'Tell us about your tree',
                        style: TextStyle(
                          fontSize: 14,
                          color: getThemeColors(context)['textSecondary']!,
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
                _buildSpeciesDropdown(),
                const SizedBox(height: 20),
                _buildNumberOfTreesPicker(),
                const SizedBox(height: 20),
                _buildFormField(
                  controller: descriptionController,
                  label: 'Description',
                  hint: 'Describe your tree planting experience...',
                  icon: Icons.description,
                  maxLines: 5,
                  minLines: 3,
                ),
                const SizedBox(height: 32),
                Material(
                  elevation: 4,
                  borderRadius: BorderRadius.circular(16),
                  child: SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: submitDetails,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: getThemeColors(context)['primary'],
                        foregroundColor:
                            getThemeColors(context)['textSecondary'],
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: const BorderSide(color: Colors.black, width: 2),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Continue',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: getThemeColors(context)['textSecondary'],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            Icons.arrow_forward,
                            size: 20,
                            color: getThemeColors(context)['textSecondary'],
                          ),
                        ],
                      ),
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

  Widget _buildFormField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    int maxLines = 1,
    int? minLines,
    TextInputType keyboardType = TextInputType.text,
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
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1CD381),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: getThemeColors(context)['background'],
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
            keyboardType: keyboardType,
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

  Widget _buildSpeciesDropdown() {
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
                Icons.eco,
                color: getThemeColors(context)['icon'],
                size: 18,
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              'Tree Species',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1CD381),
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
              color: const Color(0xFFFAEB96),
              width: 2,
            ),
          ),
          child: DropdownButtonFormField<String>(
            value: selectedSpecies,
            decoration: InputDecoration(
              hintText: 'Select tree species...',
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
            style: TextStyle(
              fontSize: 16,
              color: getThemeColors(context)['textPrimary'],
              height: 1.4,
            ),
            items: TreeSpeciesConstants.getAllSpecies().map((String species) {
              return DropdownMenuItem<String>(
                value: species,
                child: Text(species),
              );
            }).toList(),
            onChanged: (String? newValue) {
              setState(() {
                selectedSpecies = newValue;
              });
            },
          ),
        ),
      ],
    );
  }

  Widget _buildNumberOfTreesPicker() {
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
                Icons.format_list_numbered,
                color: getThemeColors(context)['icon'],
                size: 18,
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              'Number of Trees',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1CD381),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          height: 120,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: const Color(0xFFFAEB96),
              width: 2,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Decrease button
              Container(
                margin: const EdgeInsets.all(8),
                child: ElevatedButton(
                  onPressed: () {
                    if (numberOfTrees > 1) {
                      setState(() {
                        numberOfTrees--;
                      });
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: getThemeColors(context)['primary'],
                    shape: const CircleBorder(),
                    padding: const EdgeInsets.all(12),
                  ),
                  child: const Icon(
                    Icons.remove,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),

              // Number display
              Expanded(
                flex: 2,
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: getThemeColors(context)['background'],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: getThemeColors(context)['primary']!,
                      width: 2,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '$numberOfTrees',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: getThemeColors(context)['primary'],
                        ),
                      ),
                      Text(
                        numberOfTrees == 1 ? 'Tree' : 'Trees',
                        style: TextStyle(
                          fontSize: 14,
                          color: getThemeColors(context)['textPrimary'],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Increase button
              Container(
                margin: const EdgeInsets.all(8),
                child: ElevatedButton(
                  onPressed: () {
                    if (numberOfTrees < 100) {
                      // Set a reasonable max limit
                      setState(() {
                        numberOfTrees++;
                      });
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: getThemeColors(context)['primary'],
                    shape: const CircleBorder(),
                    padding: const EdgeInsets.all(12),
                  ),
                  child: const Icon(
                    Icons.add,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    descriptionController.dispose();
    super.dispose();
  }
}
