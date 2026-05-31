import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';

class NoInternetWidget extends StatefulWidget {
  const NoInternetWidget({Key? key}) : super(key: key);

  @override
  _NoInternetWidgetState createState() => _NoInternetWidgetState();
}

class _NoInternetWidgetState extends State<NoInternetWidget> {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<ConnectivityResult>>(
        stream: Connectivity().onConnectivityChanged,
        builder: (context, snapshot) {
          final results = snapshot.data;
          final isDisconnected = results == null ||
              results.isEmpty ||
              results.contains(ConnectivityResult.none);

          return isDisconnected
              ? Container(
                  width: double.infinity,
                  color: Colors.redAccent,
                  child: const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text(
                      " Cannot connect to Aeober servers",
                      style: TextStyle(
                          color: Colors.black, fontWeight: FontWeight.bold),
                    ),
                  ),
                )
              : const SizedBox();
        });
  }
}
