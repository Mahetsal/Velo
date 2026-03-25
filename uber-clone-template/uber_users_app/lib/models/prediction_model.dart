class PredictionModel {
  String? placeId;
  String? mainText;
  String? secondaryText;

  PredictionModel({this.placeId, this.mainText, this.secondaryText});

  PredictionModel.fromJson(Map<String, dynamic> json) {
    final isGoogleShape = json.containsKey("structured_formatting");
    if (isGoogleShape) {
      placeId = json["place_id"]?.toString();
      mainText = json["structured_formatting"]["main_text"]?.toString();
      secondaryText =
          json["structured_formatting"]["secondary_text"]?.toString();
      return;
    }

    final lat = json["lat"]?.toString() ?? "";
    final lon = json["lon"]?.toString() ?? "";
    placeId = "$lat,$lon";
    mainText = (json["name"] ?? json["display_name"] ?? "").toString();
    secondaryText = (json["display_name"] ?? "").toString();
  }
}
