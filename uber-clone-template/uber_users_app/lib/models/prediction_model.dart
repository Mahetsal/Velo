class PredictionModel {
  String? place_id;
  String? main_text;
  String? secondary_text;

  PredictionModel({this.place_id, this.main_text, this.secondary_text});

  PredictionModel.fromJson(Map<String, dynamic> json) {
    final isGoogleShape = json.containsKey("structured_formatting");
    if (isGoogleShape) {
      place_id = json["place_id"]?.toString();
      main_text = json["structured_formatting"]["main_text"]?.toString();
      secondary_text = json["structured_formatting"]["secondary_text"]?.toString();
      return;
    }

    final lat = json["lat"]?.toString() ?? "";
    final lon = json["lon"]?.toString() ?? "";
    place_id = "$lat,$lon";
    main_text = (json["name"] ?? json["display_name"] ?? "").toString();
    secondary_text = (json["display_name"] ?? "").toString();
  }
}
