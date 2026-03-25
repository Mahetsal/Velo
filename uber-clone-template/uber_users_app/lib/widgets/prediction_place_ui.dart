import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uber_users_app/appInfo/app_info.dart';
import 'package:uber_users_app/models/address_models.dart';
import 'package:uber_users_app/models/prediction_model.dart';
import 'package:uber_users_app/widgets/loading_dialog.dart';

class PredictionPlaceUI extends StatefulWidget {
  final PredictionModel predictedPlaceData;

  const PredictionPlaceUI({super.key, required this.predictedPlaceData});

  @override
  State<PredictionPlaceUI> createState() => _PredictionPlaceUIState();
}

class _PredictionPlaceUIState extends State<PredictionPlaceUI> {
  fetchClickedPlaceDetails(String placeId) async {
    // Show loading dialog
    showDialog(
      barrierDismissible: false,
      context: context,
      builder: (BuildContext context) =>
          const LoadingDialog(messageText: "Getting details..."),
    );

    final pieces = placeId.split(",");
    if (pieces.length != 2) {
      Navigator.pop(context);
      return;
    }
    final lat = double.tryParse(pieces[0]);
    final lon = double.tryParse(pieces[1]);
    Navigator.pop(context);
    if (lat == null || lon == null) {
      return;
    }
    AddressModel dropOffLocation = AddressModel();
    dropOffLocation.placeName = widget.predictedPlaceData.secondaryText ??
        widget.predictedPlaceData.mainText ??
        "Selected destination";
    dropOffLocation.latitudePosition = lat;
    dropOffLocation.longitudePosition = lon;
    dropOffLocation.placeID = placeId;
    Provider.of<AppInfoClass>(context, listen: false)
        .updateDropOffLocation(dropOffLocation);
    Navigator.pop(context, "placeSelected");
  }

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () {
        fetchClickedPlaceDetails(
            widget.predictedPlaceData.placeId.toString());
      },
      style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(0))),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(
                Icons.share_location,
                color: Colors.grey,
              ),
              const SizedBox(
                width: 15,
              ),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Text(
                      widget.predictedPlaceData.mainText.toString(),
                      overflow: TextOverflow.ellipsis,
                      style:
                          const TextStyle(fontSize: 16, color: Colors.black87),
                    ),
                    const SizedBox(
                      height: 3,
                    ),
                    Text(
                      widget.predictedPlaceData.secondaryText.toString(),
                      overflow: TextOverflow.ellipsis,
                      style:
                          const TextStyle(fontSize: 13, color: Colors.black54),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
