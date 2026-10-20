import 'package:flutter/material.dart';

import '../data/nepal_geography.dart';
import '../../l10n/app_localizations.dart';

/// The selected Nepal address parts, as plain strings ready for the API.
class NepalAddress {
  const NepalAddress({this.province, this.district, this.municipality});

  final String? province;
  final String? district;
  final String? municipality;
}

/// Cascading Nepal address fields: Province → District → Municipality.
///
/// The geography comes from `nepal_geography.dart` (all 7 provinces, all 77
/// districts, well-known municipalities per district). Picking a province
/// resets the district; picking a district resets the municipality. A district
/// with no curated municipality list degrades to a free-text field rather
/// than forcing a wrong pick — the table does not claim all 753 local units.
///
/// The municipality is what the API calls `city`, the district what it calls
/// `district`, and the province is derived from the district when needed.
class NepalAddressFields extends StatefulWidget {
  const NepalAddressFields({
    super.key,
    required this.onChanged,
    this.initialProvince,
    this.initialDistrict,
    this.initialMunicipality,
    this.enabled = true,
  });

  final ValueChanged<NepalAddress> onChanged;

  /// Seed values for edit mode. A lone district without a province is
  /// resolved through [provinceOf], so editing an old party still shows the
  /// right province preselected.
  final String? initialProvince;
  final String? initialDistrict;
  final String? initialMunicipality;
  final bool enabled;

  @override
  State<NepalAddressFields> createState() => _NepalAddressFieldsState();
}

class _NepalAddressFieldsState extends State<NepalAddressFields> {
  String? _province;
  String? _district;
  String? _municipality;
  final _municipalityController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _district = widget.initialDistrict;
    _province = widget.initialProvince ?? provinceOf(_district ?? '');
    _municipality = widget.initialMunicipality;
    _municipalityController.text = _municipality ?? '';
  }

  @override
  void dispose() {
    _municipalityController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant NepalAddressFields oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Edit forms load the party/business asynchronously, so the seed values
    // arrive after the first build. Adopt them once — but never overwrite a
    // pick the user has already made.
    final seedsArrived =
        (widget.initialDistrict ?? '') != (oldWidget.initialDistrict ?? '') ||
        (widget.initialMunicipality ?? '') !=
            (oldWidget.initialMunicipality ?? '');
    if (seedsArrived && _district == null && _municipality == null) {
      setState(() {
        _district = widget.initialDistrict;
        _province = widget.initialProvince ?? provinceOf(_district ?? '');
        _municipality = widget.initialMunicipality;
        _municipalityController.text = _municipality ?? '';
      });
    }
  }

  void _emit() {
    widget.onChanged(NepalAddress(
      province: _province,
      district: _district,
      municipality: _municipality,
    ));
  }

  void _onProvinceChanged(String? value) {
    setState(() {
      _province = value;
      _district = null;
      _municipality = null;
      _municipalityController.clear();
    });
    _emit();
  }

  void _onDistrictChanged(String? value) {
    setState(() {
      _district = value;
      _municipality = null;
      _municipalityController.clear();
    });
    _emit();
  }

  void _onMunicipalityChanged(String? value) {
    setState(() => _municipality = value);
    _emit();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final districts = districtsOf(_province ?? '');
    final municipalities = municipalitiesOf(_district ?? '');
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DropdownButtonFormField<String?>(
          value: _province,
          decoration: InputDecoration(
            labelText: l10n.province,
            prefixIcon: const Icon(Icons.public),
          ),
          hint: Text(l10n.selectProvinceHint),
          items: [
            for (final province in nepalProvinces)
              DropdownMenuItem(
                value: province.name,
                child: Text(province.name),
              ),
          ],
          onChanged: widget.enabled ? _onProvinceChanged : null,
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<String?>(
          value: _district,
          decoration: InputDecoration(
            labelText: l10n.district,
            prefixIcon: const Icon(Icons.map_outlined),
          ),
          hint: Text(l10n.selectDistrictHint),
          items: [
            for (final district in districts)
              DropdownMenuItem(
                value: district.name,
                child: Text(district.name),
              ),
          ],
          onChanged: widget.enabled && districts.isNotEmpty
              ? _onDistrictChanged
              : null,
        ),
        const SizedBox(height: 16),
        if (municipalities.isNotEmpty)
          DropdownButtonFormField<String?>(
            value: _municipality,
            decoration: InputDecoration(
              labelText: l10n.municipality,
              prefixIcon: const Icon(Icons.location_city_outlined),
            ),
            hint: Text(l10n.selectMunicipalityHint),
            isExpanded: true,
            items: [
              for (final municipality in municipalities)
                DropdownMenuItem(
                  value: municipality,
                  child: Text(
                    municipality,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
            ],
            onChanged: widget.enabled ? _onMunicipalityChanged : null,
          )
        else
          TextFormField(
            controller: _municipalityController,
            enabled: widget.enabled,
            decoration: InputDecoration(
              labelText: l10n.municipality,
              prefixIcon: const Icon(Icons.location_city_outlined),
              helperText: l10n.municipalityFreeTextHint,
              helperMaxLines: 2,
            ),
            onChanged: (value) {
              _municipality = value.trim().isEmpty ? null : value.trim();
              _emit();
            },
          ),
      ],
    );
  }
}
