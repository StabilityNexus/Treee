import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tree_planting_protocol/utils/constants/ui/color_constants.dart';
import 'package:tree_planting_protocol/utils/constants/ui/dimensions.dart';

class MembersTab extends StatelessWidget {
  final List<String> organisationOwners;
  final List<String> organisationMembers;
  final bool isOwner;
  final VoidCallback onAddMember;
  final Function(String) onRemoveMember;

  const MembersTab({
    super.key,
    required this.organisationOwners,
    required this.organisationMembers,
    required this.isOwner,
    required this.onAddMember,
    required this.onRemoveMember,
  });

  String _truncateAddress(String address) {
    if (address.length <= 10) return address;
    return '${address.substring(0, 6)}...${address.substring(address.length - 4)}';
  }

  void _copyAddress(BuildContext context, String address) {
    Clipboard.setData(ClipboardData(text: address));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Address copied to clipboard'),
        backgroundColor: getThemeColors(context)['primary'],
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _showRemoveMemberConfirmation(BuildContext context, String address) {
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
              onRemoveMember(address);
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

  Widget _buildMemberTile(
      BuildContext context, String address, bool isMemberOwner) {
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
            onPressed: () => _copyAddress(context, address),
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
              onPressed: () => _showRemoveMemberConfirmation(context, address),
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

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
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
              ...organisationOwners
                  .map((owner) => _buildMemberTile(context, owner, true)),
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
                    onPressed: onAddMember,
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('Add Member'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: getThemeColors(context)['primary'],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(buttonCircularRadius),
                      ),
                      side: const BorderSide(color: Colors.black, width: 1),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            if (organisationMembers.isNotEmpty)
              ...organisationMembers
                  .map((member) => _buildMemberTile(context, member, false))
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
      ),
    );
  }
}
