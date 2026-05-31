import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_webservice/places.dart';

class PredictionItemView extends StatelessWidget {
  final Prediction prediction;

  const PredictionItemView({Key? key, required this.prediction}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text(
          prediction.description ?? "",
        ),
        trailing: const Icon(Icons.arrow_forward),
      ),
    );
  }
}
