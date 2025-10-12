import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:tree_planting_protocol/providers/wallet_provider.dart';
import 'package:tree_planting_protocol/utils/constants/ui/color_constants.dart';
import 'package:tree_planting_protocol/utils/constants/ui/dimensions.dart';
import 'package:tree_planting_protocol/utils/logger.dart';
import 'package:tree_planting_protocol/utils/services/contract_functions/organisation_contract/organisation_read_functions.dart';
import 'package:tree_planting_protocol/utils/services/contract_functions/organisation_contract/organisation_write_functions.dart';
import 'package:tree_planting_protocol/widgets/basic_scaffold.dart';


class OrganisationDetailsPage extends StatefulWidget {
  final String organisationAddress;

  const OrganisationDetailsPage({super.key, required this.organisationAddress});

  @override
  State<OrganisationDetailsPage> createState() =>
      _OrganisationDetailsPageState();
}

class _OrganisationDetailsPageState extends State<OrganisationDetailsPage> {
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

  @override
  void initState() {
    super.initState();
    fetchOrganisationDetails();
  }

  @override
  void dispose() {
    _addMemberController.dispose();
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Transaction sent successfully'),
            // ignore: use_build_context_synchronously
            backgroundColor: getThemeColors(context)['primary'],
          ),
        );
      } else {
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Transaction sent successfully'),
            // ignore: use_build_context_synchronously
            backgroundColor: getThemeColors(context)['primary'],
          ),
        );
      } else {
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

  void _copyAddress(String address) {
    Clipboard.setData(ClipboardData(text: address));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Address copied to clipboard'),
        backgroundColor: getThemeColors(context)['primary'],
        duration: Duration(seconds: 2),
      ),
    );
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

  void _showRemoveMemberConfirmation(String address) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: getThemeColors(context)['background'],
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(buttonCircularRadius),
          side: BorderSide(
            color: getThemeColors(context)['border']!,
            width: buttonborderWidth,
          ),
        ),
        title: Text(
          'Remove Member',
          style: TextStyle(
            color: getThemeColors(context)['textPrimary'],
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          'Are you sure you want to remove this member?\n\n${_truncateAddress(address)}',
          style: TextStyle(
            color: getThemeColors(context)['textPrimary'],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: getThemeColors(context)['textPrimary'],
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              removeMember(address);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: getThemeColors(context)['error'],
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(buttonCircularRadius),
              ),
            ),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }

  String _formatDate(int timestamp) {
    if (timestamp == 0) return "Unknown";
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
    return "${date.day}/${date.month}/${date.year}";
  }

  String _truncateAddress(String address) {
    if (address.length <= 10) return address;
    return '${address.substring(0, 6)}...${address.substring(address.length - 4)}';
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
            child: ClipOval(
              child: organisationLogoHash.isNotEmpty
                  ? Image.network(
                      organisationLogoHash,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: getThemeColors(context)['primary'],
                          child: const Icon(
                            Icons.business,
                            size: 40,
                            color: Colors.white,
                          ),
                        );
                      },
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Container(
                          color: getThemeColors(context)['secondary'],
                          child: const CircularProgressIndicator(
                            color: Colors.black,
                          ),
                        );
                      },
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

  Widget _buildInfoSection() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'About',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: getThemeColors(context)['textPrimary'],
            ),
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: getThemeColors(context)['secondary'],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: getThemeColors(context)['border']!,
                width: 1,
              ),
            ),
            child: Text(
              organisationDescription.isNotEmpty
                  ? organisationDescription
                  : 'No description available',
              style: TextStyle(
                fontSize: 14,
                color: getThemeColors(context)['textPrimary'],
                height: 1.4,
              ),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Icon(
                Icons.calendar_today,
                size: 20,
                color: getThemeColors(context)['primary'],
              ),
              const SizedBox(width: 8),
              Text(
                'Created: ${_formatDate(timeOfCreation)}',
                style: TextStyle(
                  fontSize: 14,
                  color: getThemeColors(context)['textPrimary'],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMembersSection() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (organisationOwners.isNotEmpty) ...[
            Row(
              children: [
                Icon(
                  Icons.admin_panel_settings,
                  size: 20,
                  color: getThemeColors(context)['primary'],
                ),
                const SizedBox(width: 8),
                Text(
                  'Owners (${organisationOwners.length})',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: getThemeColors(context)['textPrimary'],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...organisationOwners.map((owner) => _buildMemberTile(owner, true)),
            const SizedBox(height: 20),
          ],
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.group,
                    size: 20,
                    color: getThemeColors(context)['secondary'],
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Members (${organisationMembers.length})',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: getThemeColors(context)['textPrimary'],
                    ),
                  ),
                ],
              ),
              if (isOwner)
                ElevatedButton.icon(
                  onPressed: _showAddMemberModal,
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Add Member'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: getThemeColors(context)['primary'],
                    foregroundColor: Colors.white,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(buttonCircularRadius),
                    ),
                    side: const BorderSide(color: Colors.black, width: 1),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (organisationMembers.isNotEmpty)
            ...organisationMembers
                .map((member) => _buildMemberTile(member, false))
          else
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: getThemeColors(context)['secondaryBackground'],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: getThemeColors(context)['border']!,
                  width: 1,
                ),
              ),
              child: Text(
                'No members yet',
                style: TextStyle(
                  color: getThemeColors(context)['textPrimary'],
                  fontSize: 14,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMemberTile(String address, bool isMemberOwner) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isMemberOwner
            ? getThemeColors(context)['primary']
            : getThemeColors(context)['secondary'],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: getThemeColors(context)['border']!,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            isMemberOwner ? Icons.admin_panel_settings : Icons.person,
            size: 16,
            color: isMemberOwner
                ? getThemeColors(context)['primary']
                : getThemeColors(context)['textPrimary'],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _truncateAddress(address),
              style: TextStyle(
                fontSize: 14,
                color: getThemeColors(context)['textPrimary'],
                fontFamily: 'monospace',
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: () => _copyAddress(address),
            icon: Icon(
              Icons.copy,
              size: 16,
              color: getThemeColors(context)['textPrimary'],
            ),
            tooltip: 'Copy address',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(
              minWidth: 32,
              minHeight: 32,
            ),
          ),
          if (isOwner && !isMemberOwner) ...[
            const SizedBox(width: 4),
            IconButton(
              onPressed: () => _showRemoveMemberConfirmation(address),
              icon: Icon(
                Icons.remove_circle,
                size: 16,
                color: getThemeColors(context)['error'],
              ),
              tooltip: 'Remove member',
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(
                minWidth: 32,
                minHeight: 32,
              ),
            ),
          ],
        ],
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
      actions: [
        IconButton(
          onPressed: _isLoading ? null : fetchOrganisationDetails,
          icon: _isLoading
              ? SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                        getThemeColors(context)['primary']!),
                  ),
                )
              : const Icon(Icons.refresh),
          tooltip: 'Reload',
        ),
      ],
      body: _isLoading
          ? _buildLoadingState()
          : _errorMessage.isNotEmpty
              ? _buildErrorState()
              : SingleChildScrollView(
                  child: Column(
                    children: [
                      _buildOrganisationHeader(),
                      _buildInfoSection(),
                      _buildMembersSection(),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
    );
  }
}
