import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:tree_planting_protocol/providers/wallet_provider.dart';
import 'package:tree_planting_protocol/utils/constants/ui/color_constants.dart';
import 'package:tree_planting_protocol/utils/constants/ui/dimensions.dart';
import 'package:tree_planting_protocol/utils/logger.dart';
import 'package:tree_planting_protocol/utils/services/contract_functions/organisation_factory_contract.dart/organisation_factory_contract_read_functions.dart';
import 'package:tree_planting_protocol/widgets/basic_scaffold.dart';

class OrganisationsPage extends StatefulWidget {
  const OrganisationsPage({super.key});

  @override
  State<OrganisationsPage> createState() => _OrganisationsPageState();
}

class _OrganisationsPageState extends State<OrganisationsPage> {
  final GlobalKey<_UserOrganisationsWidgetState> _organisationsKey =
      GlobalKey();

  @override
  Widget build(BuildContext context) {
    final walletProvider = Provider.of<WalletProvider>(context);
    return BaseScaffold(
      title: 'Organisations',
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  onPressed: () {
                    _organisationsKey.currentState?.fetchUserOrganisations();
                  },
                  icon: const Icon(Icons.refresh),
                  style: IconButton.styleFrom(
                    backgroundColor: getThemeColors(context)['primary'],
                    foregroundColor: getThemeColors(context)['secondary'],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(buttonCircularRadius),
                    ),
                    padding: const EdgeInsets.all(12),
                    elevation: 4,
                    side: const BorderSide(color: Colors.black, width: 2),
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      elevation: 4,
                      backgroundColor: getThemeColors(context)['primary'],
                      foregroundColor: getThemeColors(context)['secondary'],
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(buttonCircularRadius),
                      ),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      side: const BorderSide(color: Colors.black, width: 2),
                    ),
                    onPressed: () {
                      context.push('/create-organisation');
                    },
                    child: const Text('Create Organisation')),
              ],
            ),
            const SizedBox(height: 20),
            UserOrganisationsWidget(
                key: _organisationsKey,
                userAddress: walletProvider.userAddress.toString()),
          ],
        ),
      ),
    );
  }
}

class UserOrganisationsWidget extends StatefulWidget {
  final String userAddress;
  const UserOrganisationsWidget({super.key, required this.userAddress});

  @override
  State<UserOrganisationsWidget> createState() =>
      _UserOrganisationsWidgetState();
}

class _UserOrganisationsWidgetState extends State<UserOrganisationsWidget> {
  List<String> userOrganisations = [];
  bool _isLoading = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    fetchUserOrganisations();
  }

  Future<void> fetchUserOrganisations() async {
    if (_isLoading) return;
    setState(() {
      _isLoading = true;
      _errorMessage = '';
      userOrganisations.clear();
    });
    try {
      final walletProvider =
          Provider.of<WalletProvider>(context, listen: false);
      final result = await ContractReadFunctions.getOrganisationsByUser(
          walletProvider: walletProvider);
      if (result.success && result.data != null) {
        final data = result.data as Map<String, dynamic>;
        final organisations = data['organisations'] as List<dynamic>;
        setState(() {
          userOrganisations = organisations.map((e) => e.toString()).toList();
        });
      } else {
        setState(() {
          _errorMessage = result.errorMessage ?? 'Unknown error occurred';
        });
      }
      logger.d("User organisations fetched:");
      logger.d(userOrganisations);
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        userOrganisations.isNotEmpty
            ? _buildUserOrganisationsList(context)
            : const Text('No organisations found for this user.'),
        if (_isLoading) const CircularProgressIndicator(),
        if (_errorMessage.isNotEmpty) Text(_errorMessage),
      ],
    );
  }

  Widget _buildUserOrganisationsList(BuildContext context) {
    return ListView.builder(
      shrinkWrap: true,
      itemCount: userOrganisations.length,
      itemBuilder: (context, index) {
        return _buildUserOrganisationCard(context, userOrganisations[index]);
      },
    );
  }

  Widget _buildUserOrganisationCard(
      BuildContext context, String organisationAddress) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () {
        context.push('/organisations/$organisationAddress');
      },
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        elevation: 8,
        shadowColor: Colors.black,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: getThemeColors(context)['border']!,
            width: 2,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            organisationAddress,
            style: TextStyle(
              color: getThemeColors(context)['textPrimary'],
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}
