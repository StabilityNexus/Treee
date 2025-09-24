import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tree_planting_protocol/providers/wallet_provider.dart';
import 'package:tree_planting_protocol/utils/constants/ui/color_constants.dart';
import 'package:tree_planting_protocol/utils/constants/ui/dimensions.dart';
import 'package:tree_planting_protocol/utils/logger.dart';
import 'package:tree_planting_protocol/utils/services/contract_functions/organisation_contract/organisation_read_functions.dart';
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

  @override
  void initState() {
    super.initState();
    fetchOrganisationDetails();
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
          _errorMessage = result.errorMessage ?? "Failed to load organisation details";
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
          // Logo
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
          
          // Organisation Name
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
          
          // Address
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
          
          // Status Badges
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (isOwner) _buildStatusBadge("Owner", getThemeColors(context)['primary']!),
              if (isOwner && isMember) const SizedBox(width: 8),
              if (isMember && !isOwner) _buildStatusBadge("Member", getThemeColors(context)['secondary']!),
              if (!isMember && !isOwner) _buildStatusBadge("Visitor", Colors.grey),
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
          
          // Creation Date
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
          // Owners Section
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
          
          // Members Section
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
          const SizedBox(height: 12),
          if (organisationMembers.isNotEmpty)
            ...organisationMembers.map((member) => _buildMemberTile(member, false))
          else
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'No members yet',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMemberTile(String address, bool isOwner) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isOwner 
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
            isOwner ? Icons.admin_panel_settings : Icons.person,
            size: 16,
            color: isOwner 
                ? getThemeColors(context)['primary']
                : getThemeColors(context)['secondary'],
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
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Container(
      padding: const EdgeInsets.all(40),
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
            color: Colors.red.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'Failed to load organisation',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: getThemeColors(context)['error'] ?? Colors.red,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _errorMessage,
            style: TextStyle(
              fontSize: 14,
              color: getThemeColors(context)['error'] ?? Colors.red,
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