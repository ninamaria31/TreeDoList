/// Class which stores constants like the default padding etc
///
/// TODO: Could also be dynamically generated based on device data like screen size dpi etc
class AppConstants {
  static const double nodeWidth = 125.0;
  static const double nodeHeight = 50.0;
  static const double nodeLineWidth = 2.0;
  static const double nodeBorderRadius = 8.0;
  static const double nodeFontSize = 16;

  /// padding above and beneath the nodes
  static const double verticalNodePadding = 20.0;
  static const double canvasWidth = nodeWidth;
  static const double connectionLineWidth = nodeLineWidth;

  static const double interNodeDistance =
      AppConstants.verticalNodePadding * 2 + AppConstants.nodeHeight;

  /// its just the height after which the first bezier curve ends
  static double interConnectionDistance(int numberChildren, double height) =>
      height / (2 * numberChildren);

  static double subTreeHeight(int leafsInSubTree) =>
      (AppConstants.nodeHeight + 2 * AppConstants.verticalNodePadding) * leafsInSubTree;
}
