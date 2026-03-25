import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uber_users_app/appInfo/app_info.dart';
import 'package:uber_users_app/main.dart';
import 'package:uber_users_app/methods/common_methods.dart';
import 'package:uber_users_app/models/address_models.dart';
import 'package:uber_users_app/models/prediction_model.dart';

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

  @override
  void initState() {
    super.initState();
    _isEditingPickup = widget.editPickup;
  }

  searchLocation(String locationName) async {
    if (locationName.length > 1) {
      final query = Uri.encodeComponent(locationName);
      final apiPlacesUrl =
          "https://nominatim.openstreetmap.org/search?q=$query&format=jsonv2&limit=8&addressdetails=1&countrycodes=jo&accept-language=en";

      var responseFromPlacesAPI =
          await CommonMethods.sendRequestToAPI(apiPlacesUrl);

      if (responseFromPlacesAPI == "error") {
        return;
      }

      if (responseFromPlacesAPI is List) {
        var predictionsResultsInJson = responseFromPlacesAPI;
        var predictionsList = (predictionsResultsInJson as List)
            .map(
              (eachPlacePrediction) => 
                  PredictionModel.fromJson(eachPlacePrediction),
            )
            .toList();

        // Check if the widget is still mounted before calling setState
        if (mounted) {
          setState(() {
            dropOffPredictionsPlacesList = predictionsList;
          });
        }
      }
    }
  }

  Future<void> _setLocationFromPrediction(PredictionModel prediction) async {
    final pieces = (prediction.place_id ?? "").split(",");
    if (pieces.length != 2) return;
    final lat = double.tryParse(pieces[0]);
    final lon = double.tryParse(pieces[1]);
    if (lat == null || lon == null) return;
    final address = AddressModel(
      placeName: prediction.secondary_text ?? prediction.main_text ?? "Selected",
      humanReadableAddress:
          prediction.secondary_text ?? prediction.main_text ?? "Selected",
      latitudePosition: lat,
      longitudePosition: lon,
      placeID: prediction.place_id,
    );
    final appInfo = Provider.of<AppInfoClass>(context, listen: false);
    if (_isEditingPickup) {
      appInfo.updatePickUpLocation(address);
    } else {
      appInfo.updateDropOffLocation(address);
    }
    if (!mounted) return;
    Navigator.pop(context, "placeSelected");
  }

  @override
  Widget build(BuildContext context) {
    final appInfo = Provider.of<AppInfoClass>(context, listen: false);
    final userAddress = appInfo.pickUpLocation?.humanReadableAddress ?? '';
    final dropAddress = appInfo.dropOffLocation?.humanReadableAddress ?? '';

    pickUpTextEditingController.text = userAddress;
    if (destinationTextEditingController.text.isEmpty) {
      destinationTextEditingController.text = dropAddress;
    }
    mq = MediaQuery.sizeOf(context);
    return SafeArea(
      child: Scaffold(
        backgroundColor: const Color(0xFFF8F8F8),
        body: SingleChildScrollView(
          child: Column(
            children: [
              Card(
                elevation: 5,
                color: Colors.white,
                child: Container(
                  //height: mq.height * 0.25,
                  decoration: const BoxDecoration(
                    //color: Colors.black12,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 5.0,
                        spreadRadius: 0.5,
                        offset: Offset(0.7, 0.7),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.only(
                        left: 24, top: 20, right: 24, bottom: 30),
                    child: Column(
                      children: [
                        const SizedBox(
                          height: 6,
                        ),
                        Stack(
                          children: [
                            GestureDetector(
                              onTap: () {
                                Navigator.pop(context);
                              },
                              child: const Icon(
                                Icons.arrow_back,
                                color: const Color(0xFF121212),
                              ),
                            ),
                            const Center(
                              child: Text(
                                "Choose Pickup & Dropoff",
                                style: TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                            )
                          ],
                        ),
                        const SizedBox(
                          height: 18,
                        ),
                        Row(
                          children: [
                            Image.asset(
                              "assets/images/initial.png",
                              height: 16,
                              width: 16,
                            ),
                            const SizedBox(
                              width: 18,
                            ),
                            Expanded(
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.white60,
                                  borderRadius: BorderRadius.circular(5),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(3),
                                  child: TextField(
                                    controller: pickUpTextEditingController,
                                    onChanged: (value) {
                                      _isEditingPickup = true;
                                      searchLocation(value);
                                    },
                                    style: const TextStyle(color: Color(0xFF121212)),
                                    decoration: const InputDecoration(
                                      hintText: "Pickup Address",
                                      fillColor: Color(0xFFF3F4F6),
                                      filled: true,
                                      border: InputBorder.none,
                                      isDense: true,
                                      contentPadding: EdgeInsets.only(
                                          left: 11, top: 9, bottom: 9),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(
                          height: 11,
                        ),
                        Row(
                          children: [
                            Image.asset(
                              "assets/images/final.png",
                              height: 16,
                              width: 16,
                            ),
                            const SizedBox(
                              width: 18,
                            ),
                            Expanded(
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.white60,
                                  borderRadius: BorderRadius.circular(5),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(3),
                                  child: TextField(
                                    controller: destinationTextEditingController,
                                    onChanged: (value) {
                                      _isEditingPickup = false;
                                      searchLocation(value);
                                    },
                                    style: const TextStyle(color: Color(0xFF121212)),
                                    decoration: const InputDecoration(
                                      hintText: "Destination Address",
                                      fillColor: Color(0xFFF3F4F6),
                                      filled: true,
                                      border: InputBorder.none,
                                      isDense: true,
                                      contentPadding: EdgeInsets.only(
                                          left: 11, top: 9, bottom: 9),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Expanded(
                              child: ChoiceChip(
                                label: const Text("Edit Pickup"),
                                selected: _isEditingPickup,
                                onSelected: (_) {
                                  setState(() => _isEditingPickup = true);
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: ChoiceChip(
                                label: const Text("Edit Dropoff"),
                                selected: !_isEditingPickup,
                                onSelected: (_) {
                                  setState(() => _isEditingPickup = false);
                                },
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              //diplay the prediction results
              (dropOffPredictionsPlacesList.isNotEmpty)
                  ? Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: 5,
                        horizontal: 5,
                      ),
                      child: ListView.separated(
                        padding: EdgeInsets.all(0),
                        
                        
                        itemBuilder: (context, index) {
                          final prediction = dropOffPredictionsPlacesList[index];
                          return Card(
                            elevation: 3,
                            child: ListTile(
                              onTap: () => _setLocationFromPrediction(prediction),
                              leading: Icon(
                                _isEditingPickup
                                    ? Icons.my_location
                                    : Icons.location_on,
                              ),
                              title: Text(
                                prediction.main_text ?? "",
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              subtitle: Text(
                                prediction.secondary_text ?? "",
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          );
                        },
                        separatorBuilder: (BuildContext context, int index) =>
                            const SizedBox(
                          height: 10,
                        ),
                        itemCount: dropOffPredictionsPlacesList.length,
                        shrinkWrap: true,
                        physics: const ClampingScrollPhysics(),
                      ),
                    )
                  : Container(),
            ],
          ),
        ),
      ),
    );
  }
}
