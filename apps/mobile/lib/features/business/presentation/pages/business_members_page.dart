import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/business_entity.dart';
import '../providers/business_providers.dart';
import '../../data/repositories/business_repository_impl.dart';
import '../../../../l10n/app_localizations.dart';

/// Staff management: list members, invite by email, change roles, remove.
/// Only Owners and Admins can manage (the API enforces this too).
class BusinessMembersPage extends ConsumerWidget {
  final int businessId;

  const BusinessMembersPage({super.key, required this.businessId});

  Future<void> _invite(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final emailController = TextEditingController();
    var role = l10n.roleViewer;

    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(l10n.inviteMember),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: l10n.emailMustHaveAccount,
                  prefixIcon: Icon(Icons.email_outlined),
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: role,
                decoration: InputDecoration(labelText: l10n.role),
                items: kAssignableRoles
                    .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                    .toList(),
                onChanged: (value) => setState(() => role = value ?? 'Viewer'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(l10n.cancel),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(l10n.invite),
            ),
          ],
        ),
      ),
    );

    if (result != true) return;
    final email = emailController.text.trim();
    if (email.isEmpty) return;

    try {
      await ref
          .read(businessRepositoryProvider)
          .inviteMember(businessId, email: email, role: role);
      ref.invalidate(businessMembersProvider(businessId));
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.inviteFailed('$e'))),
        );
      }
    }
  }

  Future<void> _changeRole(
    BuildContext context,
    WidgetRef ref,
    BusinessMemberEntity member,
  ) async {
    final l10n = AppLocalizations.of(context);
    var role = member.role;

    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(l10n.changeRoleFor(member.fullName)),
          content: DropdownButtonFormField<String>(
            value: role,
            decoration: InputDecoration(labelText: l10n.role),
            items: kAssignableRoles
                .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                .toList(),
            onChanged: (value) => setState(() => role = value ?? member.role),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(l10n.cancel),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(l10n.save),
            ),
          ],
        ),
      ),
    );

    if (result != true || role == member.role) return;

    try {
      await ref
          .read(businessRepositoryProvider)
          .updateMemberRole(businessId, member.id, role: role);
      ref.invalidate(businessMembersProvider(businessId));
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.couldNotChangeRole('$e'))),
        );
      }
    }
  }

  Future<void> _remove(
    BuildContext context,
    WidgetRef ref,
    BusinessMemberEntity member,
  ) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.removeMember(member.fullName)),
        content: Text(l10n.removeMemberWarning),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.remove),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await ref
          .read(businessRepositoryProvider)
          .removeMember(businessId, member.id);
      ref.invalidate(businessMembersProvider(businessId));
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.couldNotRemoveMember('$e'))),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);

    final membersAsync = ref.watch(businessMembersProvider(businessId));
    final canManage =
        ref.watch(businessDetailProvider(businessId)).valueOrNull?.isManager ??
            false;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.staff)),
      floatingActionButton: canManage
          ? FloatingActionButton.extended(
              onPressed: () => _invite(context, ref),
              icon: const Icon(Icons.person_add_outlined),
              label: Text(l10n.invite),
            )
          : null,
      body: membersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48),
                const SizedBox(height: 12),
                Text(l10n.couldNotLoad('$error'),
                    textAlign: TextAlign.center),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: () =>
                      ref.invalidate(businessMembersProvider(businessId)),
                  child: Text(l10n.retry),
                ),
              ],
            ),
          ),
        ),
        data: (members) {
          if (members.isEmpty) {
            return Center(child: Text(l10n.noStaffMembersYet));
          }

          return ListView.builder(
            itemCount: members.length,
            itemBuilder: (context, index) {
              final member = members[index];
              return Card(
                child: ListTile(
                  leading: CircleAvatar(
                    child: Text(member.fullName.substring(0, 1).toUpperCase()),
                  ),
                  title: Text(member.fullName),
                  subtitle: Text(l10n.emailAndRole('${member.email}', '${member.role}')),
                  isThreeLine: true,
                  trailing: canManage
                      ? PopupMenuButton<String>(
                          onSelected: (value) {
                            switch (value) {
                              case 'role':
                                _changeRole(context, ref, member);
                              case 'remove':
                                _remove(context, ref, member);
                            }
                          },
                          itemBuilder: (context) => [
                            PopupMenuItem(
                                value: 'role', child: Text(l10n.changeRole)),
                            PopupMenuItem(
                                value: 'remove', child: Text(l10n.remove)),
                          ],
                        )
                      : null,
                ),
              );
            },
          );
        },
      ),
    );
  }
}
