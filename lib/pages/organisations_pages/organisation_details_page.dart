import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tree_planting_protocol/components/transaction_dialog.dart';
import 'package:tree_planting_protocol/providers/wallet_provider.dart';
import 'package:tree_planting_protocol/utils/constants/ui/color_constants.dart';
import 'package:tree_planting_protocol/utils/constants/ui/dimensions.dart';
import 'package:tree_planting_protocol/utils/logger.dart';
import 'package:tree_planting_protocol/utils/services/contract_functions/organisation_contract/organisation_read_functions.dart';
import 'package:tree_planting_protocol/utils/services/contract_functions/organisation_contract/organisation_write_functions.dart';
import 'package:tree_planting_protocol/widgets/basic_scaffold.dart';
import 'package:tree_planting_protocol/widgets/image_loader_widget.dart';
import 'package:tree_planting_protocol/widgets/organisation_details_page/tabs/tabs.dart';

class OrganisationDetailsPage extends StatefulWidget {
  final String organisationAddress;

  const OrganisationDetailsPage({super.key, required this.organisationAddress});

  @override
  State<OrganisationDetailsPage> createState() =>
      _OrganisationDetailsPageState();
}

class _OrganisationDetailsPageState extends State<OrganisationDetailsPage>
    with SingleTickerProviderStateMixin {
  String organisationName = "";
  String organisationDescription = "";
  String organisationLogoHash = "";
  List<String> organisationOwners = [];
  List<String> organisationMembers = [];
  int timeOfCreation = 0;
  bool isMember = false;
  bool isOwner = false;
  bool _isLoading = false;
  String _errorMessage = "";
  final TextEditingController _addMemberController = TextEditingController();

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    fetchOrganisationDetails();
  }

  @override
  void dispose() {
    _addMemberController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> fetchOrganisationDetails() async {
    setState(() {
      _isLoading = true;
      _errorMessage = "";
    });

    final walletProvider = Provider.of<WalletProvider>(context, listen: false);
    try {
      final result =
          await OrganisationContractReadFunctions.getOrganisationsByUser(
        walletProvider: walletProvider,
        organisationContractAddress: widget.organisationAddress,
      );

      logger.d("Organisation details fetch result: ${result.data}");

      if (result.success) {
        final data = result.data;
        setState(() {
          isMember = data['isMember'];
          isOwner = data['isOwner'];
          organisationName = data['organisationName'];
          organisationDescription = data['organisationDescription'];
          organisationLogoHash = data['organisationLogoHash'];
          organisationOwners = List<String>.from(data['owners'] ?? []);
          organisationMembers = List<String>.from(data['members'] ?? []);
          timeOfCreation = data['timeOfCreation'] ?? 0;
        });
      } else {
        setState(() {
          _errorMessage =
              result.errorMessage ?? "Failed to load organisation details";
        });
        logger.e("Error fetching organisation details: ${result.errorMessage}");
      }
    } catch (e) {
      setState(() {
        _errorMessage = "Error loading organisation details: $e";
      });
      logger.e("Error fetching organisation details: $e");
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> addMember(String address) async {
    setState(() {
      _isLoading = true;
      _errorMessage = "";
    });

    final walletProvider = Provider.of<WalletProvider>(context, listen: false);
    try {
      final result = await OrganisationContractWriteFunctions.addMember(
        walletProvider: walletProvider,
        organisationContractAddress: widget.organisationAddress,
        userAddress: address,
      );

      if (result.success) {
        // ignore: use_build_context_synchronously
        TransactionDialog.showSuccess(
          context,
          title: 'Member Added!',
          message:
              'The member has been successfully added to the organisation.',
          transactionHash: result.transactionHash,
        );
      } else {
        // ignore: use_build_context_synchronously
        TransactionDialog.showError(
          context,
          title: 'Failed to Add Member',
          message: result.errorMessage ?? 'An unknown error occurred',
        );
        setState(() {
          _errorMessage = result.errorMessage ?? "Failed to add member";
        });
        logger.e("Error adding member: ${result.errorMessage}");
      }
    } catch (e) {
      setState(() {
        _errorMessage = "Error adding member: $e";
      });
      logger.e("Error adding member: $e");
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> removeMember(String address) async {
    setState(() {
      _isLoading = true;
      _errorMessage = "";
    });

    final walletProvider = Provider.of<WalletProvider>(context, listen: false);
    try {
      final result = await OrganisationContractWriteFunctions.removeMember(
        walletProvider: walletProvider,
        organisationContractAddress: widget.organisationAddress,
        userAddress: address,
      );

      if (result.success) {
        // ignore: use_build_context_synchronously
        TransactionDialog.showSuccess(
          context,
          title: 'Member Removed!',
          message:
              'The member has been successfully removed from the organisation.',
          transactionHash: result.transactionHash,
        );
      } else {
        // ignore: use_build_context_synchronously
        TransactionDialog.showError(
          context,
          title: 'Failed to Remove Member',
          message: result.errorMessage ?? 'An unknown error occurred',
        );
        setState(() {
          _errorMessage = result.errorMessage ?? "Failed to add member";
        });
        logger.e("Error adding member: ${result.errorMessage}");
      }
    } catch (e) {
      setState(() {
        _errorMessage = "Error adding member: $e";
      });
      logger.e("Error adding member: $e");
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showAddMemberModal() {
    _addMemberController.clear();
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: getThemeColors(context)['background'],
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(buttonCircularRadius),
          side: BorderSide(
            color: getThemeColors(context)['border']!,
            width: buttonborderWidth,
          ),
        ),
        child: Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Add Member',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: getThemeColors(context)['textPrimary'],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Icon(
                      Icons.close,
                      color: getThemeColors(context)['textPrimary'],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                'Enter the wallet address of the new member:',
                style: TextStyle(
                  fontSize: 14,
                  color: getThemeColors(context)['textPrimary'],
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _addMemberController,
                style: TextStyle(
                  color: getThemeColors(context)['textPrimary'],
                  fontFamily: 'monospace',
                ),
                decoration: InputDecoration(
                  hintText: '0x...',
                  hintStyle: TextStyle(
                    color: getThemeColors(context)['textPrimary'],
                  ),
                  filled: true,
                  fillColor: getThemeColors(context)['secondary'],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                      color: getThemeColors(context)['border']!,
                      width: 1,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                      color: getThemeColors(context)['border']!,
                      width: 1,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                      color: getThemeColors(context)['primary']!,
                      width: 2,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          getThemeColors(context)['secondaryBackground'],
                      foregroundColor: getThemeColors(context)['textPrimary'],
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(buttonCircularRadius),
                      ),
                      side: BorderSide(
                        color: getThemeColors(context)['border']!,
                        width: buttonborderWidth,
                      ),
                    ),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: () {
                      final address = _addMemberController.text.trim();
                      if (address.isNotEmpty) {
                        Navigator.of(context).pop();
                        addMember(address.toString());
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: getThemeColors(context)['primary'],
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(buttonCircularRadius),
                      ),
                      side: const BorderSide(color: Colors.black, width: 2),
                    ),
                    child: const Text('Add Member'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _truncateAddress(String address) {
    if (address.length <= 10) return address;
    return '${address.substring(0, 6)}...${address.substring(address.length - 4)}';
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: getThemeColors(context)['background'],
        borderRadius: BorderRadius.circular(buttonCircularRadius),
        border: Border.all(
          color: getThemeColors(context)['border']!,
          width: buttonborderWidth,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TabBar(
        controller: _tabController,
        labelColor: Colors.white,
        unselectedLabelColor: getThemeColors(context)['textPrimary'],
        indicatorSize: TabBarIndicatorSize.tab,
        indicator: BoxDecoration(
          color: getThemeColors(context)['primary'],
          borderRadius: BorderRadius.circular(buttonCircularRadius),
          border: Border.all(color: Colors.black, width: 2),
        ),
        dividerColor: Colors.transparent,
        tabs: const [
          Tab(
            icon: Icon(Icons.info_outline),
            text: 'Info',
          ),
          Tab(
            icon: Icon(Icons.group),
            text: 'Members',
          ),
          Tab(
            icon: Icon(Icons.verified_user),
            text: 'Verifications',
          ),
          Tab(
            icon: Icon(Icons.nature),
            text: 'Proposals',
          ),
        ],
      ),
    );
  }

  Widget _buildOrganisationHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.black, width: 3),
              boxShadow: [
                BoxShadow(
                  color: Colors.black,
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: organisationLogoHash.isNotEmpty
                ? CircularImageLoaderWidget(
                    imageUrl: organisationLogoHash,
                    radius: 60,
                    errorWidget: Container(
                      color: getThemeColors(context)['primary'],
                      child: const Icon(
                        Icons.business,
                        size: 40,
                        color: Colors.white,
                      ),
                    ),
                  )
                : Container(
                    color: getThemeColors(context)['primary'],
                    child: const Icon(
                        Icons.business,
                        size: 40,
                        color: Colors.white,
                      ),
                    ),
          ),
          const SizedBox(height: 16),
          Text(
            organisationName.isNotEmpty ? organisationName : 'Organisation',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: getThemeColors(context)['secondary'],
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: getThemeColors(context)['border']!,
                width: 1,
              ),
            ),
            child: Text(
              _truncateAddress(widget.organisationAddress),
              style: TextStyle(
                fontSize: 14,
                color: getThemeColors(context)['textPrimary'],
                fontFamily: 'monospace',
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (isOwner)
                _buildStatusBadge("Owner", getThemeColors(context)['primary']!),
              if (isOwner && isMember) const SizedBox(width: 8),
              if (isMember && !isOwner)
                _buildStatusBadge(
                    "Member", getThemeColors(context)['secondary']!),
              if (!isMember && !isOwner)
                _buildStatusBadge("Visitor", Colors.grey),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.black, width: 2),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Container(
      padding: const EdgeInsets.all(40),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(
                  getThemeColors(context)['primary']!),
            ),
            const SizedBox(height: 16),
            Text(
              'Loading organisation details...',
              style: TextStyle(
                fontSize: 16,
                color: getThemeColors(context)['primary'],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Container(
      padding: const EdgeInsets.all(20),
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
            'Failed to load organisation',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: getThemeColors(context)['error'],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _errorMessage,
            style: TextStyle(
              fontSize: 14,
              color: getThemeColors(context)['error'],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: fetchOrganisationDetails,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
            style: ElevatedButton.styleFrom(
              backgroundColor: getThemeColors(context)['primary'],
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(buttonCircularRadius),
              ),
              side: const BorderSide(color: Colors.black, width: 2),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BaseScaffold(
      title: organisationName.isNotEmpty
          ? organisationName
          : "Organisation Details",
      showBackButton: true,
      isLoading: _isLoading,
      showReloadButton: true,
      onReload: fetchOrganisationDetails,
      body: _isLoading
          ? _buildLoadingState()
          : _errorMessage.isNotEmpty
              ? _buildErrorState()
              : Column(
                  children: [
                    _buildOrganisationHeader(),
                    const SizedBox(height: 16),
                    _buildTabBar(),
                    Expanded(
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          InfoTab(
                            organisationDescription: organisationDescription,
                            timeOfCreation: timeOfCreation,
                          ),
                          MembersTab(
                            organisationOwners: organisationOwners,
                            organisationMembers: organisationMembers,
                            isOwner: isOwner,
                            onAddMember: _showAddMemberModal,
                            onRemoveMember: removeMember,
                          ),
                          VerificationRequestsTab(
                            organisationAddress: widget.organisationAddress,
                          ),
                          PlantingProposalsTab(
                            organisationAddress: widget.organisationAddress,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
    );
  }
}
