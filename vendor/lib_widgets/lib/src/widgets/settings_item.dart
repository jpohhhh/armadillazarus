import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Widget that displays a single settings item.
class SettingsItem extends StatelessWidget {
  /// The network to be shown.
  final String iconUrl;

  /// The label of the settings item
  final String label;

  /// Information about the settings item displayed below it
  final String details;

  /// Whether the item is in an error state or not
  final bool isError;

  /// Callback to run when the network is tapped
  final VoidCallback onTap;

  /// Scaling factor to render widget
  final double scale;

  /// Builds a new access point.
  const SettingsItem({
    required this.iconUrl,
    required this.label,
    this.details,
    this.isError = false,
    this.scale,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return new InkWell(
        onTap: onTap,
        child: new Container(
            height: 64.0 * scale,
            width: 480.0 * scale,
            child: new Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[_buildLogo(), _buildText()],
            )));
  }

  Widget _buildLogo() {
    return new Container(
        padding: new EdgeInsets.only(
          right: 16.0 * scale,
        ),
        child: new Image.asset(
          iconUrl,
          height: 48.0 * scale,
          width: 48.0 * scale,
        ));
  }

  Widget _buildText() {
    final Text text = new Text(label, style: _textStyle(scale));

    if (details == null) {
      return text;
    }

    return new Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        text,
        new Text(details, style: _textStyle(scale, isError: isError))
      ],
    );
  }
}

TextStyle _textStyle(double scale, {bool isError = false}) => new TextStyle(
      color: isError ? Colors.grey[900] : Colors.redAccent,
      fontSize: 24.0 * scale,
      fontWeight: FontWeight.w200,
    );
