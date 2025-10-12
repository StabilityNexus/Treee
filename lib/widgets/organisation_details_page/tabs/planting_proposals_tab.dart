import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tree_planting_protocol/providers/wallet_provider.dart';
import 'package:tree_planting_protocol/utils/constants/ui/color_constants.dart';
import 'package:tree_planting_protocol/utils/logger.dart';
import 'package:tree_planting_protocol/utils/services/contract_functions/organisation_contract/organisation_read_functions.dart';

class PlantingProposalsTab extends StatefulWidget {
  final String organisationAddress;

  const PlantingProposalsTab({
    super.key,
    required this.organisationAddress,
  });

  @override
  State<PlantingProposalsTab> createState() => _PlantingProposalsTabState();
}

class _PlantingProposalsTabState extends State<PlantingProposalsTab>
    with SingleTickerProviderStateMixin {
  late TabController _statusTabController;
  final Map<int, List<Map<String, dynamic>>> _proposalsByStatus = {
    0: [], // Pending
    1: [], // Approved
    2: [], // Rejected
  };
  final Map<int, bool> _isLoading = {0: false, 1: false, 2: false};
  final Map<int, String> _errorMessages = {0: '', 1: '', 2: ''};

  @override
  void initState() {
    super.initState();
    _statusTabController = TabController(length: 3, vsync: this);
    _loadAllProposals();
  }

  @override
  void dispose() {
    _statusTabController.dispose();
    super.dispose();
  }

  Future<void> _loadAllProposals() async {
    for (int status = 0; status <= 2; status++) {
      await _loadProposalsByStatus(status);
    }
  }

  Future<void> _loadProposalsByStatus(int status) async {
    setState(() {
      _isLoading[status] = true;
      _errorMessages[status] = '';
    });

    try {
      final walletProvider =
          Provider.of<WalletProvider>(context, listen: false);
      final result = await OrganisationContractReadFunctions
          .getTreePlantingProposalsByStatus(
        walletProvider: walletProvider,
        organisationContractAddress: widget.organisationAddress,
        status: status,
        offset: 0,
        limit: 50,
      );

      if (result.success && result.data != null) {
        setState(() {
          _proposalsByStatus[status] =
              List<Map<String, dynamic>>.from(result.data['proposals'] ?? []);
        });
      } else {
        setState(() {
          _errorMessages[status] =
              result.errorMessage ?? 'Failed to load tree planting proposals';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessages[status] = 'Error loading tree planting proposals: $e';
      });
      logger.e('Error loading tree planting proposals for status $status: $e');
    } finally {
      setState(() {
        _isLoading[status] = false;
      });
    }
  }

  String _getStatusText(int status) {
    switch (status) {
      case 0:
        return 'Pending';
      case 1:
        return 'Approved';
      case 2:
        return 'Rejected';
      default:
        return 'Unknown';
    }
  }

  Color _getStatusColor(int status) {
    switch (status) {
      case 0:
        return Colors.orange;
      case 1:
        return Colors.green;
      case 2:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _truncateAddress(String address) {
    if (address.length <= 10) return address;
    return '${address.substring(0, 6)}...${address.substring(address.length - 4)}';
  }

  double _convertCoordinate(int coordinate) {
    // Convert from fixed-point representation to decimal degrees
    return coordinate / 1000000.0;
  }

  Widget _buildProposalCard(Map<String, dynamic> proposal) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: getThemeColors(context)['background'],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: getThemeColors(context)['border']!,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: getThemeColors(context)['shadow']!.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getStatusColor(proposal['status']),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'ID: ${proposal['id']}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: getThemeColors(context)['primary'],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${proposal['numberOfTrees']} trees',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            proposal['species'] ?? 'Unknown Species',
            style: TextStyle(
              fontSize: 16,
              color: getThemeColors(context)['textPrimary'],
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                Icons.location_on,
                size: 16,
                color: getThemeColors(context)['secondary'],
              ),
              const SizedBox(width: 4),
              Text(
                'Lat: ${_convertCoordinate(proposal['latitude']).toStringAsFixed(6)}, '
                'Lng: ${_convertCoordinate(proposal['longitude']).toStringAsFixed(6)}',
                style: TextStyle(
                  fontSize: 12,
                  color: getThemeColors(context)['textPrimary'],
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(
                Icons.person,
                size: 16,
                color: getThemeColors(context)['secondary'],
              ),
              const SizedBox(width: 4),
              Text(
                'Initiator: ${_truncateAddress(proposal['initiator'])}',
                style: TextStyle(
                  fontSize: 12,
                  color: getThemeColors(context)['textPrimary'],
                ),
              ),
            ],
          ),
          if (proposal['geoHash'] != null &&
              proposal['geoHash'].isNotEmpty) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  Icons.map,
                  size: 16,
                  color: getThemeColors(context)['primary'],
                ),
                const SizedBox(width: 4),
                Text(
                  'GeoHash: ${proposal['geoHash']}',
                  style: TextStyle(
                    fontSize: 12,
                    color: getThemeColors(context)['textPrimary'],
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            ),
          ],
          if (proposal['photos'] != null &&
              (proposal['photos'] as List).isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.photo_library,
                  size: 16,
                  color: getThemeColors(context)['primary'],
                ),
                const SizedBox(width: 4),
                Text(
                  '${(proposal['photos'] as List).length} photos',
                  style: TextStyle(
                    fontSize: 12,
                    color: getThemeColors(context)['textPrimary'],
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatusTabContent(int status) {
    if (_isLoading[status]!) {
      return Container(
        padding: const EdgeInsets.all(40),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(
                  getThemeColors(context)['primary']!,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Loading ${_getStatusText(status).toLowerCase()} proposals...',
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

    if (_errorMessages[status]!.isNotEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: getThemeColors(context)['error'],
            ),
            const SizedBox(height: 16),
            Text(
              'Error loading proposals',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: getThemeColors(context)['error'],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessages[status]!,
              style: TextStyle(
                fontSize: 14,
                color: getThemeColors(context)['error'],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _loadProposalsByStatus(status),
              style: ElevatedButton.styleFrom(
                backgroundColor: getThemeColors(context)['primary'],
                foregroundColor: Colors.white,
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    final proposals = _proposalsByStatus[status]!;
    if (proposals.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(40),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.nature_outlined,
                size: 48,
                color: getThemeColors(context)['secondary'],
              ),
              const SizedBox(height: 16),
              Text(
                'No ${_getStatusText(status).toLowerCase()} proposals',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: getThemeColors(context)['textPrimary'],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'No tree planting proposals found with ${_getStatusText(status).toLowerCase()} status.',
                style: TextStyle(
                  fontSize: 14,
                  color: getThemeColors(context)['textPrimary'],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: proposals.length,
      itemBuilder: (context, index) {
        return _buildProposalCard(proposals[index]);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            decoration: BoxDecoration(
              color: getThemeColors(context)['background'],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: getThemeColors(context)['border']!,
                width: 1,
              ),
            ),
            child: TabBar(
              controller: _statusTabController,
              labelColor: Colors.white,
              unselectedLabelColor: getThemeColors(context)['textPrimary'],
              indicatorSize: TabBarIndicatorSize.tab,
              indicator: BoxDecoration(
                color: getThemeColors(context)['primary'],
                borderRadius: BorderRadius.circular(12),
              ),
              dividerColor: Colors.transparent,
              tabs: [
                Tab(
                  icon: Icon(Icons.pending, size: 16),
                  text: 'Pending (${_proposalsByStatus[0]?.length ?? 0})',
                ),
                Tab(
                  icon: Icon(Icons.check_circle, size: 16),
                  text: 'Approved (${_proposalsByStatus[1]?.length ?? 0})',
                ),
                Tab(
                  icon: Icon(Icons.cancel, size: 16),
                  text: 'Rejected (${_proposalsByStatus[2]?.length ?? 0})',
                ),
              ],
            ),
          ),
          SizedBox(
            height: 500, // Fixed height for the TabBarView
            child: TabBarView(
              controller: _statusTabController,
              children: [
                _buildStatusTabContent(0), // Pending
                _buildStatusTabContent(1), // Approved
                _buildStatusTabContent(2), // Rejected
              ],
            ),
          ),
        ],
      ),
    );
  }
}
