import 'package:flutter/material.dart';

/// Class which stores constants like the default padding etc
///
/// TODO: Could also be dynamically generated based on device data like screen size dpi etc
class AppConstants {
  static const double nodeWidth = 120.0;
  static const double nodeHeight = 50.0;
  static const double nodeLineWidth = 2.0;
  static const double nodeBorderRadius = 8.0;
  static const double nodeFontSize = 16;
  static const double nodeBadeSize = 26;

  static const TextStyle nodeTextStyle = TextStyle(
      fontWeight: FontWeight.bold,
      fontSize: AppConstants.nodeFontSize,
      color: Colors.black,
      decoration: TextDecoration.none);

  /// padding above and beneath the nodes
  static const double verticalNodePadding = 20.0;
  static const double endPadding = nodeBadeSize/2;

  static const double canvasWidth = nodeWidth * 0.9;
  static const double connectionLineWidth = nodeLineWidth;
  static const double interNodeDistance =
      AppConstants.verticalNodePadding * 2 + AppConstants.nodeHeight;
  // just for better readability
  static const double paddedNodeHeight = interNodeDistance;
  static const double paddedNodeCenter = paddedNodeHeight/2;

  /// its just the height after which the first bezier curve ends
  static double interConnectionDistance(int numberChildren, double height) =>
      height / (2 * numberChildren);

  static double subTreeHeight(int leafsInSubTree) =>
      (AppConstants.nodeHeight + 2 * AppConstants.verticalNodePadding) * leafsInSubTree;
}
