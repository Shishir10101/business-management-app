import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/utils/nepali_validators.dart';
import '../../../../core/widgets/nepal_address_fields.dart';
import '../providers/business_providers.dart';
import '../../data/repositories/business_repository_impl.dart';
import '../../../../l10n/app_localizations.dart';

/// Business setup / creation flow. Shown to authenticated users who have no
/// business yet (see router redirect), and reachable any time from the
/// business switcher to create an additional business.
class BusinessSetupPage extends ConsumerStatefulWidget {
  const BusinessSetupPage({super.key});

  @override
  ConsumerState<BusinessSetupPage> createState() => _BusinessSetupPageState();
}

class _BusinessSetupPageState extends ConsumerState<BusinessSetupPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _typeController = TextEditingController();
  final _panController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _addressController = TextEditingController();
  final _wardController = TextEditingController();

  /// Province/district/municipality, chosen through the cascading widget.
  NepalAddress _address = const NepalAddress();

  bool _submitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    _typeController.dispose();
    _panController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _wardController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _submitting = true);
    try {
      final repository = ref.read(businessRepositoryProvider);
      final business = await repository.createBusiness(
        name: _nameController.text.trim(),
        type: _emptyToNull(_typeController.text),
        panNumber: _emptyToNull(_panController.text),
        phoneNumber: _emptyToNull(_phoneController.text),
        email: _emptyToNull(_emailController.text),
        addressLine: _emptyToNull(_addressController.text),
        city: _address.municipality,
        district: _address.district,
        province: _address.province,
        wardNumber: _emptyToNull(_wardController.text),
      );

      // Make it the active business and refresh the business list.
      await repository.switchBusiness(business.id);
      ref.invalidate(myBusinessesProvider);

      if (!mounted) return;
      context.go('/');
    } catch (e) {
      if (!mounted) return;
      final l10n = AppLocalizations.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.couldNotCreateBusiness('$e'))),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  static String? _emptyToNull(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.createBusiness)),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  l10n.businessSetupTitle,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 4),
                Text(
                  l10n.businessSetupSubtitle,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: l10n.businessNameRequired,
                    prefixIcon: Icon(Icons.store_outlined),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return l10n.businessNameIsRequired;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _typeController,
                  decoration: InputDecoration(
                    labelText: l10n.businessType,
                    prefixIcon: Icon(Icons.category_outlined),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _panController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: l10n.panNumber,
                    prefixIcon: Icon(Icons.badge_outlined),
                  ),
                  validator: (value) {
                    final text = value?.trim() ?? '';
                    if (text.isNotEmpty && text.length != 9) {
                      return l10n.panMustBe9DigitNumber;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    labelText: l10n.phoneNumberPlaceholder,
                    prefixIcon: Icon(Icons.phone_outlined),
                  ),
                  validator: (value) => isValidNepaliPhone(value)
                      ? null
                      : l10n.phoneInvalidNepali,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: l10n.businessEmail,
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                  validator: (value) {
                    final text = value?.trim() ?? '';
                    if (text.isNotEmpty &&
                        !RegExp(r'^[\w.-]+@[\w.-]+\.\w+$').hasMatch(text)) {
                      return l10n.emailInvalid;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _addressController,
                  decoration: InputDecoration(
                    labelText: l10n.address,
                    prefixIcon: Icon(Icons.location_on_outlined),
                  ),
                ),
                const SizedBox(height: 16),
                NepalAddressFields(
                  onChanged: (value) => _address = value,
                  initialProvince: _address.province,
                  initialDistrict: _address.district,
                  initialMunicipality: _address.municipality,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _wardController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: l10n.wardNumber,
                    prefixIcon: Icon(Icons.tag),
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _submitting ? null : _submit,
                  child: _submitting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(l10n.createBusiness),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
