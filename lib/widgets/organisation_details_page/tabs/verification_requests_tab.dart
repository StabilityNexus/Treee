import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tree_planting_protocol/providers/wallet_provider.dart';
import 'package:tree_planting_protocol/utils/constants/ui/color_constants.dart';
import 'package:tree_planting_protocol/utils/logger.dart';
import 'package:tree_planting_protocol/utils/services/contract_functions/organisation_contract/organisation_read_functions.dart';

class VerificationRequestsTab extends StatefulWidget {
  final String organisationAddress;

  const VerificationRequestsTab({
    super.key,
    required this.organisationAddress,
  });

  @override
  State<VerificationRequestsTab> createState() =>
      _VerificationRequestsTabState();
}

class _VerificationRequestsTabState extends State<VerificationRequestsTab>
    with SingleTickerProviderStateMixin {
  late TabController _statusTabController;
  final Map<int, List<Map<String, dynamic>>> _requestsByStatus = {
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
    _loadAllRequests();
  }

  @override
  void dispose() {
    _statusTabController.dispose();
    super.dispose();
  }

  Future<void> _loadAllRequests() async {
    for (int status = 0; status <= 2; status++) {
      await _loadRequestsByStatus(status);
    }
  }

  Future<void> _loadRequestsByStatus(int status) async {
    setState(() {
      _isLoading[status] = true;
      _errorMessages[status] = '';
    });

    try {
      final walletProvider =
          Provider.of<WalletProvider>(context, listen: false);
      final result = await OrganisationContractReadFunctions
          .getVerificationRequestsByStatus(
        walletProvider: walletProvider,
        organisationContractAddress: widget.organisationAddress,
        status: status,
        offset: 0,
        limit: 50,
      );

      if (result.success && result.data != null) {
        setState(() {
          _requestsByStatus[status] =
              List<Map<String, dynamic>>.from(result.data['requests'] ?? []);
        });
      } else {
        setState(() {
          _errorMessages[status] =
              result.errorMessage ?? 'Failed to load verification requests';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessages[status] = 'Error loading verification requests: $e';
      });
      logger.e('Error loading verification requests for status $status: $e');
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

  String _formatDate(int timestamp) {
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
    return "${date.day}/${date.month}/${date.year}";
  }

  Widget _buildRequestCard(Map<String, dynamic> request) {
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
                  color: _getStatusColor(request['status']),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'ID: ${request['id']}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const Spacer(),
              Icon(
                Icons.verified_user,
                size: 16,
                color: getThemeColors(context)['primary'],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            request['description'] ?? 'No description',
            style: TextStyle(
              fontSize: 14,
              color: getThemeColors(context)['textPrimary'],
              fontWeight: FontWeight.w500,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                Icons.person,
                size: 16,
                color: getThemeColors(context)['secondary'],
              ),
              const SizedBox(width: 4),
              Text(
                'Member: ${_truncateAddress(request['initialMember'])}',
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
                Icons.calendar_today,
                size: 16,
                color: getThemeColors(context)['secondary'],
              ),
              const SizedBox(width: 4),
              Text(
                'Date: ${_formatDate(request['timestamp'])}',
                style: TextStyle(
                  fontSize: 12,
                  color: getThemeColors(context)['textPrimary'],
                ),
              ),
            ],
          ),
          if (request['treeNftId'] != null && request['treeNftId'] > 0) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  Icons.nature,
                  size: 16,
                  color: getThemeColors(context)['primary'],
                ),
                const SizedBox(width: 4),
                Text(
                  'Tree NFT ID: ${request['treeNftId']}',
                  style: TextStyle(
                    fontSize: 12,
                    color: getThemeColors(context)['textPrimary'],
                    fontWeight: FontWeight.w500,
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
                'Loading ${_getStatusText(status).toLowerCase()} requests...',
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
              'Error loading requests',
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
              onPressed: () => _loadRequestsByStatus(status),
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

    final requests = _requestsByStatus[status]!;
    if (requests.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(40),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.verified_user_outlined,
                size: 48,
                color: getThemeColors(context)['secondary'],
              ),
              const SizedBox(height: 16),
              Text(
                'No ${_getStatusText(status).toLowerCase()} requests',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: getThemeColors(context)['textPrimary'],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'No verification requests found with ${_getStatusText(status).toLowerCase()} status.',
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
      itemCount: requests.length,
      itemBuilder: (context, index) {
        return _buildRequestCard(requests[index]);
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
                  text: 'Pending (${_requestsByStatus[0]?.length ?? 0})',
                ),
                Tab(
                  icon: Icon(Icons.check_circle, size: 16),
                  text: 'Approved (${_requestsByStatus[1]?.length ?? 0})',
                ),
                Tab(
                  icon: Icon(Icons.cancel, size: 16),
                  text: 'Rejected (${_requestsByStatus[2]?.length ?? 0})',
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
