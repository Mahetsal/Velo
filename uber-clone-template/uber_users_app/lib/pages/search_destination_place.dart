import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:uber_users_app/appInfo/app_info.dart';
import 'package:uber_users_app/main.dart';
import 'package:uber_users_app/methods/common_methods.dart';
import 'package:uber_users_app/models/address_models.dart';
import 'package:uber_users_app/models/prediction_model.dart';
import 'package:uber_users_app/theme/app_theme.dart';
import 'package:uber_users_app/global/global_var.dart';
import 'package:uber_users_app/observability/analytics_service.dart';
import 'package:uber_users_app/l10n/l10n_ext.dart';

class SearchDestinationPlace extends StatefulWidget {
  final bool editPickup;
  const SearchDestinationPlace({super.key, this.editPickup = false});
  const SearchDestinationPlace.forPickup({super.key}) : editPickup = true;
  const SearchDestinationPlace.forDropOff({super.key}) : editPickup = false;

  @override
  State<SearchDestinationPlace> createState() => _SearchDestinationPlaceState();
}

class _SearchDestinationPlaceState extends State<SearchDestinationPlace> {
  TextEditingController pickUpTextEditingController = TextEditingController();
  TextEditingController destinationTextEditingController =
      TextEditingController();

  late bool _isEditingPickup;
  List<PredictionModel> dropOffPredictionsPlacesList = [];
  Timer? _debounce;
  String _lastQuery = "";

  static const List<_RecommendedPlace> _recommended = [
    _RecommendedPlace(
      titleKey: "recAbdaliTitle",
      subtitleKey: "recAbdaliSubtitle",
      lat: 31.9622,
      lng: 35.9066,
    ),
    _RecommendedPlace(
      titleKey: "recAirportTitle",
      subtitleKey: "recAirportSubtitle",
      lat: 31.7226,
      lng: 35.9932,
    ),
    _RecommendedPlace(
      titleKey: "recRainbowTitle",
      subtitleKey: "recRainbowSubtitle",
      lat: 31.9497,
      lng: 35.9303,
    ),
    _RecommendedPlace(
      titleKey: "recCityMallTitle",
      subtitleKey: "recCityMallSubtitle",
      lat: 31.9787,
      lng: 35.8316,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _isEditingPickup = widget.editPickup;
    final appInfo = Provider.of<AppInfoClass>(context, listen: false);
    pickUpTextEditingController.text =
        appInfo.pickUpLocation?.humanReadableAddress ?? "";
    destinationTextEditingController.text =
        appInfo.dropOffLocation?.humanReadableAddress ?? "";
  }

  @override
  void dispose() {
    _debounce?.cancel();
    pickUpTextEditingController.dispose();
    destinationTextEditingController.dispose();
    super.dispose();
  }

  void searchLocation(String locationName) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 280), () async {
      final q = locationName.trim();
      if (q.length <= 1) {
        if (!mounted) return;
        setState(() => dropOffPredictionsPlacesList = []);
        return;
      }
      if (q == _lastQuery) return;
      _lastQuery = q;

      final query = Uri.encodeComponent(q);
      final lang = Localizations.localeOf(context).languageCode == "ar"
          ? "ar"
          : "en";
      final apiPlacesUrl =
          "https://nominatim.openstreetmap.org/search?q=$query&format=jsonv2&limit=8&addressdetails=1&countrycodes=jo&accept-language=$lang";

      final responseFromPlacesAPI =
          await CommonMethods.sendRequestToAPI(apiPlacesUrl);

      if (!mounted) return;
      if (responseFromPlacesAPI == "error") {
        setState(() => dropOffPredictionsPlacesList = []);
        return;
      }

      if (responseFromPlacesAPI is List) {
        final predictionsList = responseFromPlacesAPI
            .map((eachPlacePrediction) =>
                PredictionModel.fromJson(eachPlacePrediction))
            .toList();
        setState(() => dropOffPredictionsPlacesList = predictionsList);
      }
    });
  }

  Future<void> _setLocationFromPrediction(PredictionModel prediction) async {
    final pieces = (prediction.placeId ?? "").split(",");
    if (pieces.length != 2) return;
    final lat = double.tryParse(pieces[0]);
    final lon = double.tryParse(pieces[1]);
    if (lat == null || lon == null) return;
    final address = AddressModel(
      placeName: prediction.secondaryText ?? prediction.mainText ?? "Selected",
      humanReadableAddress:
          prediction.secondaryText ?? prediction.mainText ?? "Selected",
      latitudePosition: lat,
      longitudePosition: lon,
      placeID: prediction.placeId,
    );
    final appInfo = Provider.of<AppInfoClass>(context, listen: false);
    if (_isEditingPickup) {
      appInfo.updatePickUpLocation(address);
    } else {
      appInfo.updateDropOffLocation(address);
    }
    if (!mounted) return;
    unawaited(AnalyticsService.logDestinationSelected());
    Navigator.pop(context, "placeSelected");
  }

  Future<void> _openMapPicker() async {
    final appInfo = Provider.of<AppInfoClass>(context, listen: false);
    final start = _isEditingPickup
        ? appInfo.pickUpLocation
        : appInfo.dropOffLocation;
    final initial = LatLng(
      start?.latitudePosition ?? initialMapCenter.latitude,
      start?.longitudePosition ?? initialMapCenter.longitude,
    );

    final AddressModel? chosen = await Navigator.push<AddressModel?>(
      context,
      MaterialPageRoute(
        builder: (_) => _MapPickerPage(
          initialTarget: initial,
          title: _isEditingPickup
              ? context.l10n.selectPickupOnMap
              : context.l10n.selectDropoffOnMap,
        ),
      ),
    );
    if (chosen == null || !mounted) return;
    if (_isEditingPickup) {
      appInfo.updatePickUpLocation(chosen);
      pickUpTextEditingController.text = chosen.humanReadableAddress ?? "";
    } else {
      appInfo.updateDropOffLocation(chosen);
      destinationTextEditingController.text = chosen.humanReadableAddress ?? "";
    }
    setState(() => dropOffPredictionsPlacesList = []);
    if (!mounted) return;
    unawaited(AnalyticsService.logDestinationSelected());
    Navigator.pop(context, "placeSelected");
  }

  Future<void> _applyRecommended(_RecommendedPlace p) async {
    final t = p.title(context);
    final s = p.subtitle(context);
    final address = AddressModel(
      placeName: t,
      humanReadableAddress: "$t • $s",
      latitudePosition: p.lat,
      longitudePosition: p.lng,
      placeID: "${p.lat},${p.lng}",
    );
    final appInfo = Provider.of<AppInfoClass>(context, listen: false);
    if (_isEditingPickup) {
      appInfo.updatePickUpLocation(address);
      pickUpTextEditingController.text = address.humanReadableAddress ?? "";
    } else {
      appInfo.updateDropOffLocation(address);
      destinationTextEditingController.text = address.humanReadableAddress ?? "";
    }
    if (!mounted) return;
    unawaited(AnalyticsService.logDestinationSelected());
    Navigator.pop(context, "placeSelected");
  }

  @override
  Widget build(BuildContext context) {
    mq = MediaQuery.sizeOf(context);
    return SafeArea(
      child: Scaffold(
        body: CustomScrollView(
          slivers: [
            SliverAppBar(
              pinned: true,
              elevation: 0,
              scrolledUnderElevation: 0,
              backgroundColor: Theme.of(context).colorScheme.surface.withOpacity(0.92),
              surfaceTintColor: Colors.transparent,
              leading: Padding(
                padding: const EdgeInsetsDirectional.only(start: 8),
                child: IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back_rounded),
                ),
              ),
              title: const Text("Choose Pickup & Dropoff"),
              actions: [
                IconButton(
                  tooltip: context.l10n.pickFromMap,
                  onPressed: _openMapPicker,
                  icon: const Icon(Icons.map_outlined),
                ),
                Padding(
                  padding: const EdgeInsetsDirectional.only(end: 14),
                  child: Center(
                    child: Text(
                      "Velo Jordan",
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w900,
                            fontStyle: FontStyle.italic,
                            color: AppTheme.accent,
                          ),
                    ),
                  ),
                ),
              ],
            ),
            SliverPadding(
              padding: const EdgeInsetsDirectional.fromSTEB(16, 16, 16, 12),
              sliver: SliverToBoxAdapter(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Column(
                    children: [
                      Stack(
                        children: [
                          Positioned.fill(
                            child: Align(
                              alignment: AlignmentDirectional.centerEnd,
                              child: Container(
                                margin: const EdgeInsetsDirectional.only(end: 30, top: 18, bottom: 18),
                                width: 2,
                                decoration: BoxDecoration(
                                  color: AppTheme.ghostOutline.withOpacity(0.45),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                              ),
                            ),
                          ),
                          Column(
                            children: [
                              _SearchFieldRow(
                                label: context.l10n.pickupLocation,
                                controller: pickUpTextEditingController,
                                icon: Icons.my_location_rounded,
                                iconBg: AppTheme.accent.withOpacity(0.10),
                                iconColor: AppTheme.accent,
                                onChanged: (value) {
                                  _isEditingPickup = true;
                                  searchLocation(value);
                                },
                              ),
                              const SizedBox(height: 12),
                              _SearchFieldRow(
                                label: context.l10n.whereTo,
                                controller: destinationTextEditingController,
                                icon: Icons.location_on_rounded,
                                iconBg: AppTheme.accent,
                                iconColor: Colors.white,
                                autofocus: true,
                                onChanged: (value) {
                                  _isEditingPickup = false;
                                  searchLocation(value);
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      SizedBox(
                        height: 44,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          children: [
                            ChoiceChip(
                              label: Text(context.l10n.editPickup),
                              selected: _isEditingPickup,
                              onSelected: (_) => setState(() => _isEditingPickup = true),
                            ),
                            const SizedBox(width: 10),
                            ChoiceChip(
                              label: Text(context.l10n.editDropoff),
                              selected: !_isEditingPickup,
                              onSelected: (_) => setState(() => _isEditingPickup = false),
                            ),
                            const SizedBox(width: 10),
                            ActionChip(
                              avatar: const Icon(Icons.map_outlined, size: 18),
                              label: Text(context.l10n.selectFromMap),
                              onPressed: _openMapPicker,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsetsDirectional.fromSTEB(16, 6, 16, 8),
              sliver: SliverToBoxAdapter(
                child: Row(
                  children: [
                    Text(
                      context.l10n.recommendedDestinations,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.4,
                            color: AppTheme.onSurfaceMuted,
                          ),
                    ),
                  ],
                ),
              ),
            ),
            if (dropOffPredictionsPlacesList.isEmpty)
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
                sliver: SliverList.separated(
                  itemCount: _recommended.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final p = _recommended[index];
                    return _PredictionCard(
                      icon: _isEditingPickup
                          ? Icons.my_location_rounded
                          : Icons.location_on_rounded,
                      title: p.title(context),
                      subtitle: p.subtitle(context),
                      onTap: () => _applyRecommended(p),
                    );
                  },
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                sliver: SliverList.separated(
                  itemCount: dropOffPredictionsPlacesList.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final prediction = dropOffPredictionsPlacesList[index];
                    return _PredictionCard(
                      icon: _isEditingPickup
                          ? Icons.my_location_rounded
                          : Icons.location_on_rounded,
                      title: prediction.mainText ?? "",
                      subtitle: prediction.secondaryText ?? "",
                      onTap: () => _setLocationFromPrediction(prediction),
                    );
                  },
                ),
              ),
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
          ],
        ),
      ),
    );
  }
}

class _SearchFieldRow extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final ValueChanged<String> onChanged;
  final bool autofocus;

  const _SearchFieldRow({
    required this.label,
    required this.controller,
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.onChanged,
    this.autofocus = false,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isPrimary = label == "Where to?";
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isPrimary ? cs.surfaceContainerLowest : cs.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(18),
        boxShadow: isPrimary
            ? [
                BoxShadow(
                  color: AppTheme.accent.withOpacity(0.10),
                  blurRadius: 28,
                  offset: const Offset(0, 12),
                ),
              ]
            : null,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.2,
                        color: isPrimary ? AppTheme.accent : AppTheme.onSurfaceMuted,
                      ),
                ),
                const SizedBox(height: 2),
                TextField(
                  controller: controller,
                  autofocus: autofocus,
                  onChanged: onChanged,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: isPrimary ? FontWeight.w900 : FontWeight.w700,
                        color: AppTheme.onSurface,
                      ),
                  decoration: const InputDecoration(
                    isDense: true,
                    filled: false,
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                    hintText: "",
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Icon(icon, color: iconColor),
          ),
        ],
      ),
    );
  }
}

class _PredictionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _PredictionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: cs.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: cs.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, color: AppTheme.accent),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w900,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppTheme.onSurfaceMuted,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right_rounded, color: Color(0xFFCBD5E1)),
            ],
          ),
        ),
      ),
    );
  }
}

class _RecommendedPlace {
  final String titleKey;
  final String subtitleKey;
  final double lat;
  final double lng;
  const _RecommendedPlace({
    required this.titleKey,
    required this.subtitleKey,
    required this.lat,
    required this.lng,
  });

  String title(BuildContext context) {
    switch (titleKey) {
      case "recAbdaliTitle":
        return context.l10n.recAbdaliTitle;
      case "recAirportTitle":
        return context.l10n.recAirportTitle;
      case "recRainbowTitle":
        return context.l10n.recRainbowTitle;
      case "recCityMallTitle":
        return context.l10n.recCityMallTitle;
      default:
        return "";
    }
  }

  String subtitle(BuildContext context) {
    switch (subtitleKey) {
      case "recAbdaliSubtitle":
        return context.l10n.recAbdaliSubtitle;
      case "recAirportSubtitle":
        return context.l10n.recAirportSubtitle;
      case "recRainbowSubtitle":
        return context.l10n.recRainbowSubtitle;
      case "recCityMallSubtitle":
        return context.l10n.recCityMallSubtitle;
      default:
        return "";
    }
  }
}

class _MapPickerPage extends StatefulWidget {
  final LatLng initialTarget;
  final String title;
  const _MapPickerPage({
    required this.initialTarget,
    required this.title,
  });

  @override
  State<_MapPickerPage> createState() => _MapPickerPageState();
}

class _MapPickerPageState extends State<_MapPickerPage> {
  // ignore: unused_field
  GoogleMapController? _controller;
  LatLng _target = const LatLng(31.9539, 35.9106);
  bool _saving = false;
  String _label = "";

  @override
  void initState() {
    super.initState();
    _target = widget.initialTarget;
    _reverseGeocode(_target);
  }

  Future<void> _reverseGeocode(LatLng p) async {
    final url =
        "https://nominatim.openstreetmap.org/reverse?lat=${p.latitude}&lon=${p.longitude}&format=jsonv2&accept-language=en";
    final resp = await CommonMethods.sendRequestToAPI(url);
    if (!mounted) return;
    if (resp == "error") {
      setState(() => _label = "${p.latitude.toStringAsFixed(5)}, ${p.longitude.toStringAsFixed(5)}");
      return;
    }
    final display = (resp["display_name"] ?? "").toString();
    setState(() => _label = display.isEmpty ? "${p.latitude.toStringAsFixed(5)}, ${p.longitude.toStringAsFixed(5)}" : display);
  }

  Future<void> _confirm() async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      final addr = AddressModel(
        placeName: _label.isEmpty ? "Selected" : _label,
        humanReadableAddress: _label.isEmpty ? "Selected" : _label,
        latitudePosition: _target.latitude,
        longitudePosition: _target.longitude,
        placeID: "${_target.latitude},${_target.longitude}",
      );
      if (!mounted) return;
      Navigator.pop(context, addr);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          TextButton(
            onPressed: _saving ? null : _confirm,
            child: Text(_saving ? context.l10n.savingEllipsis : context.l10n.done),
          ),
        ],
      ),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(target: _target, zoom: 16),
            onMapCreated: (c) => _controller = c,
            onCameraMove: (pos) => _target = pos.target,
            onCameraIdle: () => _reverseGeocode(_target),
            markers: {
              Marker(
                markerId: const MarkerId("picked"),
                position: _target,
              ),
            },
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 16,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface.withOpacity(0.92),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                _label.isEmpty ? "${_target.latitude}, ${_target.longitude}" : _label,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
