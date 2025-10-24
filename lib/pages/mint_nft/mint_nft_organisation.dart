import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:tree_planting_protocol/providers/mint_nft_provider.dart';
import 'package:tree_planting_protocol/providers/wallet_provider.dart';
import 'package:tree_planting_protocol/utils/constants/route_constants.dart';
import 'package:tree_planting_protocol/utils/constants/ui/color_constants.dart';
import 'package:tree_planting_protocol/utils/constants/ui/dimensions.dart';
import 'package:tree_planting_protocol/utils/logger.dart';
import 'package:tree_planting_protocol/utils/services/contract_functions/organisation_factory_contract.dart/organisation_factory_contract_read_functions.dart';
import 'package:tree_planting_protocol/widgets/basic_scaffold.dart';

class MintNftOrganisationPage extends StatefulWidget {
  const MintNftOrganisationPage({super.key});

  @override
  State<MintNftOrganisationPage> createState() =>
      _MintNftOrganisationPageState();
}

class _MintNftOrganisationPageState extends State<MintNftOrganisationPage> {
  List<String> _userOrganisations = [];
  String? _selectedOrganisation;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadUserOrganisations();
  }

  Future<void> _loadUserOrganisations() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final walletProvider =
          Provider.of<WalletProvider>(context, listen: false);

      final result = await ContractReadFunctions.getOrganisationsByUser(
        walletProvider: walletProvider,
      );

      if (result.success && result.data != null) {
        final data = result.data as Map<String, dynamic>;
        final organisations = data['organisations'] as List<dynamic>;

        setState(() {
          _userOrganisations = organisations.map((e) => e.toString()).toList();
          _isLoading = false;
        });

        logger.d("User organisations loaded: $_userOrganisations");
      } else {
        setState(() {
          _errorMessage = result.errorMessage ?? 'Failed to load organisations';
          _isLoading = false;
        });
      }
    } catch (e) {
      logger.e("Error loading organisations: $e");
      setState(() {
        _errorMessage = 'Error loading organisations: $e';
        _isLoading = false;
      });
    }
  }

  void _submitOrganisation() {
    if (_selectedOrganisation == null || _selectedOrganisation!.isEmpty) {
      _showCustomSnackBar(
        "Please select an organisation",
        isError: true,
      );
      return;
    }
    Provider.of<MintNftProvider>(context, listen: false)
        .setOrganisationAddress(_selectedOrganisation!);

    _showCustomSnackBar("Organisation selected successfully!");
    context.push(RouteConstants.mintNftImagesPath);
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
        backgroundColor:
            isError ? Colors.red.shade400 : getThemeColors(context)['primary'],
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
      title: "Select Organisation",
      showBackButton: true,
      isLoading: _isLoading,
      body: _isLoading
          ? _buildLoadingState()
          : _errorMessage != null
              ? _buildErrorState()
              : _userOrganisations.isEmpty
                  ? _buildEmptyState()
                  : SingleChildScrollView(
                      padding: EdgeInsets.symmetric(
                        horizontal: screenWidth * 0.05,
                        vertical: 20,
                      ),
                      child: Column(
                        children: [
                          _buildFormSection(screenWidth, context),
                          const SizedBox(height: 32),
                        ],
                      ),
                    ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(
                getThemeColors(context)['primary']!),
          ),
          const SizedBox(height: 16),
          Text(
            'Loading your organisations...',
            style: TextStyle(
              fontSize: 16,
              color: getThemeColors(context)['textPrimary'],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: getThemeColors(context)['error'],
            ),
            const SizedBox(height: 16),
            Text(
              'Failed to Load Organisations',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: getThemeColors(context)['textPrimary'],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage ?? 'Unknown error occurred',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: getThemeColors(context)['textPrimary'],
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadUserOrganisations,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: getThemeColors(context)['primary'],
                foregroundColor: getThemeColors(context)['textSecondary'],
                elevation: 4,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(buttonCircularRadius),
                  side: const BorderSide(color: Colors.black, width: 2),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: getThemeColors(context)['secondary']!,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.black, width: 3),
              ),
              child: Icon(
                Icons.business_outlined,
                size: 64,
                color: getThemeColors(context)['textPrimary'],
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No Organisations Found',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: getThemeColors(context)['textPrimary'],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'You are not a member of any organisations yet. You can mint individually or create/join an organisation.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: getThemeColors(context)['textPrimary'],
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),
            // Mint Individually button (primary action)
            Material(
              elevation: 4,
              borderRadius: BorderRadius.circular(buttonCircularRadius),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    logger.i("=== MINT INDIVIDUALLY FROM EMPTY STATE ===");
                    logger.i("Clearing organisation address to empty string");
                    Provider.of<MintNftProvider>(context, listen: false)
                        .setOrganisationAddress("");
                    final address =
                        Provider.of<MintNftProvider>(context, listen: false)
                            .organisationAddress;
                    logger.i("Organisation address after clearing: '$address'");
                    logger.i("Address length: ${address.length}");
                    context.push(RouteConstants.mintNftImagesPath);
                  },
                  icon: Icon(Icons.person,
                      size: 20, color: getThemeColors(context)['textPrimary']),
                  label: Text(
                    'Mint Individually',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: getThemeColors(context)['textPrimary'],
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: getThemeColors(context)['primary'],
                    foregroundColor: getThemeColors(context)['textPrimary'],
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(buttonCircularRadius),
                      side: const BorderSide(color: Colors.black, width: 2),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Divider(height: 32),
            Text(
              'Or manage organisations',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: getThemeColors(context)['textPrimary'],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  child: Material(
                    elevation: 4,
                    borderRadius: BorderRadius.circular(buttonCircularRadius),
                    child: OutlinedButton.icon(
                      onPressed: () {
                        context.push('/create-organisation');
                      },
                      icon: Icon(Icons.add,
                          size: 20,
                          color: getThemeColors(context)['textPrimary']),
                      label: Text(
                        'Create',
                        style: TextStyle(
                          color: getThemeColors(context)['textPrimary'],
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: getThemeColors(context)['textPrimary'],
                        backgroundColor: getThemeColors(context)['secondary'],
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 12),
                        side: BorderSide(
                          color: Colors.black,
                          width: 2,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(buttonCircularRadius),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Material(
                    elevation: 4,
                    borderRadius: BorderRadius.circular(buttonCircularRadius),
                    child: OutlinedButton.icon(
                      onPressed: () {
                        context.push('/organisations');
                      },
                      icon: Icon(Icons.search,
                          size: 20,
                          color: getThemeColors(context)['textPrimary']),
                      label: Text(
                        'View All',
                        style: TextStyle(
                          color: getThemeColors(context)['textPrimary'],
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: getThemeColors(context)['textPrimary'],
                        backgroundColor: getThemeColors(context)['secondary'],
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 12),
                        side: BorderSide(
                          color: Colors.black,
                          width: 2,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(buttonCircularRadius),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFormSection(double screenWidth, BuildContext context) {
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
            offset: const Offset(0, 4),
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
                    Icons.business,
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
                        'Choose Organisation',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: getThemeColors(context)['textSecondary'],
                        ),
                      ),
                      Text(
                        'Select organisation or mint individually',
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
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: getThemeColors(context)['secondary'],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: getThemeColors(context)['border']!,
                      width: 2,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: getThemeColors(context)['textPrimary'],
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Minting on behalf of an organisation will create a proposal that needs approval from organisation members',
                          style: TextStyle(
                            color: getThemeColors(context)['textPrimary'],
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Your Organisations',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: getThemeColors(context)['textPrimary'],
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  decoration: BoxDecoration(
                    color: getThemeColors(context)['background'],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: getThemeColors(context)['border']!,
                      width: 2,
                    ),
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedOrganisation,
                      hint: Text(
                        'Select an organisation',
                        style: TextStyle(
                          color: getThemeColors(context)['textPrimary']!,
                          fontSize: 14,
                        ),
                      ),
                      isExpanded: true,
                      icon: Icon(
                        Icons.arrow_drop_down,
                        color: getThemeColors(context)['primary'],
                        size: 30,
                      ),
                      style: TextStyle(
                        fontSize: 14,
                        color: getThemeColors(context)['textPrimary'],
                      ),
                      items: _userOrganisations.map((String organisation) {
                        return DropdownMenuItem<String>(
                          value: organisation,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  '${organisation.substring(0, 6)}...${organisation.substring(organisation.length - 4)}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  organisation,
                                  style: TextStyle(
                                    fontSize: 10,
                                    color:
                                        getThemeColors(context)['textPrimary']!,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        setState(() {
                          _selectedOrganisation = newValue;
                        });
                      },
                    ),
                  ),
                ),
                if (_selectedOrganisation != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: getThemeColors(context)['primary']!,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: getThemeColors(context)['border']!,
                        width: 2,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.check_circle,
                          color: getThemeColors(context)['primary'],
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Selected Organisation:',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _selectedOrganisation!,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'monospace',
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 32),
                Column(
                  children: [
                    Material(
                      elevation: 4,
                      borderRadius: BorderRadius.circular(buttonCircularRadius),
                      child: SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () {
                            // Clear organization address and skip to images
                            logger
                                .i("=== MINT INDIVIDUALLY BUTTON CLICKED ===");
                            logger.i(
                                "Clearing organisation address to empty string");
                            Provider.of<MintNftProvider>(context, listen: false)
                                .setOrganisationAddress("");
                            final address = Provider.of<MintNftProvider>(
                                    context,
                                    listen: false)
                                .organisationAddress;
                            logger.i(
                                "Organisation address after clearing: '$address'");
                            logger.i("Address length: ${address.length}");
                            context.push(RouteConstants.mintNftImagesPath);
                          },
                          icon: const Icon(Icons.person, size: 20),
                          label: const Text('Mint Individually'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor:
                                getThemeColors(context)['textPrimary'],
                            backgroundColor:
                                getThemeColors(context)['secondary'],
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(
                                vertical: 16, horizontal: 24),
                            side: BorderSide(
                              color: getThemeColors(context)['border']!,
                              width: 2,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(buttonCircularRadius),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Material(
                      elevation: 4,
                      borderRadius: BorderRadius.circular(buttonCircularRadius),
                      child: SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _submitOrganisation,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: getThemeColors(context)['primary'],
                            foregroundColor:
                                getThemeColors(context)['textSecondary'],
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(buttonCircularRadius),
                              side: const BorderSide(
                                  color: Colors.black, width: 2),
                            ),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Continue',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              SizedBox(width: 8),
                              Icon(Icons.arrow_forward, size: 20),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
