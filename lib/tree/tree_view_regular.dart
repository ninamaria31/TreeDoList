import 'dart:async';

import 'package:flutter/material.dart';
import 'package:tree_do/tree/tree_callbacks.dart';
import 'package:tree_do/tree/tree_vis_elements.dart';
import 'tree.dart';
import 'package:snap_scroll_physics/snap_scroll_physics.dart';
import '../app_constants.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'connection_layer.dart';
import '../services/nose_mode_service.dart';
import '../settings/settings.dart';
TimerService timerService = TimerService(noseModeDuration);
var remaining_nose_mode_duration;
final noseModeAllowed = ValueNotifier<bool>(true);

class TreeViewRegular extends StatefulWidget {
  final Tree todoTree;

  const TreeViewRegular({super.key, required this.todoTree});

  @override
  TreeViewRegularState createState() =>
      TreeViewRegularState();
}

// the TreeCallbacks provides the callback for tap, longpress, etc
class TreeViewRegularState extends State<TreeViewRegular> with TreeCallbacks<TreeViewRegular> {
  late Tree todoTree;
  late TreeNode center;

  // final ScrollController _scrollController = ScrollController();
  final IndexTrackingCarouselController _controller =
      IndexTrackingCarouselController();
  late BitonicSequence bitonicSiblings;
  late BitonicSequence bitonicChildren;

  // https://stackoverflow.com/questions/66327785/flutter-how-to-notify-custompainter-to-redraw
  final _scrollOffsetParent = ValueNotifier<List<double>>([0, 0]);
  final _scrollOffsetChildren = ValueNotifier<List<double>>([0, 0]);

  @override
  void initState() {
    super.initState();
    todoTree = widget.todoTree;
    center = PageStorage.of(context).readState(context, identifier: const ValueKey("RegularViewCenter")) ?? todoTree.root;
    bitonicSiblings = center.bitonicSiblings;
    bitonicChildren = BitonicSequence.fromIterable(center.children);
    _scrollOffsetParent.value = [0, bitonicSiblings.indexOf(center) * AppConstants.paddedNodeHeight * -1];
    Timer.periodic(Duration(minutes: 3), (Timer t) async {
      timerService.isNoseModeAllowed();
      noseModeAllowed.value = timerService.isAllowed;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (rebuildBitonicChildren) {
      bitonicChildren = BitonicSequence.fromIterable(center.children);
    }
    return LayoutBuilder(builder: (context, constraints) {
      return Stack(
        children: [
          SizedBox(
            //decoration: BoxDecoration(
            //  border: Border.all(
            //    color: Colors.lightBlue, width: AppConstants.nodeLineWidth),
            //  borderRadius: BorderRadius.circular(8),
            //),
            height: MediaQuery.of(context).size.height,
            child: Padding(
              padding: const EdgeInsets.only(left: 6, right: 6),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  ShaderMask(
                    shaderCallback: (bounds) => const LinearGradient(
                            colors: [Colors.transparent, Colors.black])
                        .createShader(bounds),
                    child: CustomPaint(
                      painter: CarouselConnectionLayerPainter(
                        scrollOffset: _scrollOffsetParent,
                        connection: Connection(
                            0, bitonicSiblings.equallyDistributedHeights),
                        height: constraints.maxHeight,
                        width: AppConstants.canvasWidth * 0.22,
                      ),
                      child: SizedBox(
                        //decoration: BoxDecoration(
                        //  border: Border.all(
                        //      color: Colors.lightBlue,
                        //      width: AppConstants.nodeLineWidth),
                        //  borderRadius: BorderRadius.circular(8),
                        //),
                        width: AppConstants.canvasWidth * 0.22,
                        height: constraints.maxHeight,
                      ),
                    ),
                  ),
                  NodeListCarousel(
                      items: bitonicSiblings,
                      height: constraints.maxHeight,
                      controller: _controller,
                      onPageChangeCallback: onPageChangeCallback,
                      onHorDragEndCallback: onHorDragEndCallbackParent,
                      notificationListener: parentScrollNotification,
                      onTapCallback: onTapCallback,
                      onLongPressCallback: onLongPressCallback,
                      onDoubleTapCallback: onDoubleTapCallback),
                  CustomPaint(
                    painter: RegularConnectionLayerPainter(
                        scrollOffset: _scrollOffsetChildren,
                        connection: Connection(
                            0, bitonicChildren.equallyDistributedHeights),
                        height: constraints.maxHeight),
                    child: SizedBox(
                      //decoration: BoxDecoration(
                      //  border: Border.all(
                      //      color: Colors.lightBlue,
                      //      width: AppConstants.nodeLineWidth),
                      //  borderRadius: BorderRadius.circular(8),
                      //),
                      width: AppConstants.canvasWidth,
                      height: constraints.maxHeight,
                    ),
                  ),
                  NodeListRegular(
                      items: bitonicChildren,
                      height: constraints.maxHeight,
                      onHorDragEndCallback: onHorDragEndCallbackChild,
                      notificationListener: childScrollNotification,
                      onTapCallback: onTapCallback,
                      onLongPressCallback: onLongPressCallback,
                      onDoubleTapCallback: onDoubleTapCallback)
                ],
              ),
            ),
          ),
          Positioned(
            bottom: 16.0,
            left: 16.0,
            child: Row(
              children: [
                ValueListenableBuilder<bool>(
                  valueListenable: timerService.isRunning,
                  builder: (context, isRunning, child) {
                    return ValueListenableBuilder<bool>(
                      valueListenable: noseModeAllowed,
                      builder: (context, level, child) {
                        return ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            foregroundColor: timerService.isRunning.value
                                ? Colors.white
                                : Colors.black,
                            backgroundColor: timerService.isRunning.value
                                ? Colors.blueGrey
                                : Colors.white,
                          ),
                          onPressed: (noseModeAllowed.value || isRunning)
                              ? () {
                                  if (isRunning) {
                                    timerService.stopTimer();
                                  } else {
                                    timerService.startTimer();
                                  }
                                }
                              : null,
                          child: Text(
                              isRunning ? 'Stop Nose Mode' : 'Start Nose Mode'),
                        );
                      },
                    );
                  },
                ),
                const SizedBox(width: 10),
                StreamBuilder<int>(
                  stream: timerService.tickStream,
                  builder: (context, snapshot) {
                    if (timerService.isRunning.value && snapshot.hasData) {
                      remaining_nose_mode_duration = snapshot.data!;
                      return Text('($remaining_nose_mode_duration min)');
                    } else {
                      return Text('');
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      );
    });
  }

  void onHorDragEndCallbackChild(TreeNode node, DragEndDetails details) =>
      setState(() {
        // could check for primary velocity
        if (details.primaryVelocity != null) {
          newCenter(center = node);
        }
      });

  void onHorDragEndCallbackParent(TreeNode node, DragEndDetails details) =>
      setState(() {
        if (details.primaryVelocity != null && node.parent != null) {
          newCenter(node.parent!);
        }
      });

  void onPageChangeCallback(int index, CarouselPageChangedReason reason) =>
      setState(() {
        if (reason == CarouselPageChangedReason.manual) {
          shiftCenter(bitonicSiblings.elementAt(index));
        }
      });

  // this sets a new center in the parent (left view)
  void newCenter(TreeNode newCenter) {
    center = newCenter;
    bitonicSiblings = BitonicSequence.ofSiblings(center);
    bitonicChildren = BitonicSequence.fromIterable(center.children);
    centerCarouselView(center);
    // save center in the bucket
    PageStorage.of(context).writeState(context, center, identifier: const ValueKey("RegularViewCenter"));
  }

  void shiftCenter(TreeNode sCenter) {
    center = sCenter;
    _scrollOffsetParent.value = [0, bitonicSiblings.indexOf(center) * AppConstants.paddedNodeHeight * -1];
    _scrollOffsetChildren.value = [0, 0];
    bitonicChildren = BitonicSequence.fromIterable(center.children);
    PageStorage.of(context).writeState(context, center, identifier: const ValueKey("RegularViewCenter"));
  }

  void centerCarouselView(TreeNode center) {
    int index = bitonicSiblings.indexOf(center);
    _scrollOffsetParent.value = [0, index * AppConstants.paddedNodeHeight * -1];
    _scrollOffsetChildren.value = [0, 0];
    _controller.jumpToPage(index);
  }

  bool childScrollNotification(Notification notification) {
    double oldStartChildren = _scrollOffsetChildren.value[0];
    if (notification is ScrollEndNotification) {
      _scrollOffsetChildren.value = [
        oldStartChildren,
        -notification.metrics.pixels
      ];
    } else if (notification is ScrollUpdateNotification) {
      _scrollOffsetChildren.value = [
        oldStartChildren,
        -notification.metrics.pixels
      ];
    }
    return true;
  }

  bool parentScrollNotification(Notification notification) {
    double oldStartParent = _scrollOffsetParent.value[0];
    double oldEndChildren = _scrollOffsetChildren.value[1];
    double newEndParent;
    double newStartChildren;

    double scrollOffset;
    // this is cursed!
    double scrollOffsetOffset = 0;

    if (notification is ScrollEndNotification) {
      scrollOffset = notification.metrics.pixels;
    } else if (notification is ScrollUpdateNotification) {
      scrollOffset = notification.metrics.pixels;
    } else {
      return false;
    }

    newEndParent = -scrollOffset;
    scrollOffset %= AppConstants.paddedNodeHeight;
    scrollOffsetOffset = AppConstants.paddedNodeHeight *
        (scrollOffset / AppConstants.paddedNodeCenter).floor();
    if (scrollOffsetOffset > AppConstants.paddedNodeHeight) {
      scrollOffsetOffset %= AppConstants.paddedNodeHeight;
    }
    newStartChildren =
        -(scrollOffset % AppConstants.paddedNodeHeight) + scrollOffsetOffset;
    _scrollOffsetParent.value = [oldStartParent, newEndParent];
    _scrollOffsetChildren.value = [newStartChildren, oldEndChildren];
    return true;
  }
}

abstract class NodeList extends StatelessWidget {
  final BitonicSequence items;
  final double height;

  final void Function(TreeNode, DragEndDetails)? onHorDragEndCallback;
  final void Function(TreeNode, BuildContext)? onTapCallback;
  final void Function(TreeNode, BuildContext)? onLongPressCallback;
  final void Function(TreeNode)? onDoubleTapCallback;

  NodeList(
      {super.key,
      required this.items,
      required this.height,
      required this.onHorDragEndCallback,
      required this.onTapCallback,
      required this.onLongPressCallback,
      required this.onDoubleTapCallback});

  List<Widget> _buildTreeNodesListItems(Iterable<TreeNode> nodes,
      {bool showLeafCount = false}) {
    return nodes
        .map((n) => NodeWidget(
              node: n,
              onHorDragEndCallback: onHorDragEndCallback,
              onDoubleTapCallback: onDoubleTapCallback,
              onLongPressCallback: onLongPressCallback,
              onTapCallback: onTapCallback,
              showLeafCount: showLeafCount,
            ))
        .toList();
  }
}

class NodeListCarousel extends NodeList {
  final IndexTrackingCarouselController controller;
  final Function(int, CarouselPageChangedReason)? onPageChangeCallback;
  final bool Function(Notification)? notificationListener;

  NodeListCarousel(
      {super.key,
      required super.items,
      required super.height,
      required this.controller,
      this.onPageChangeCallback,
      super.onHorDragEndCallback,
      this.notificationListener,
      required super.onTapCallback,
      required super.onLongPressCallback,
      required super.onDoubleTapCallback});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return Container();
    }
    return SizedBox(
        //decoration: BoxDecoration(
        //  border: Border.all(
        //      color: Colors.lightBlueAccent, width: AppConstants.nodeLineWidth),
        //  borderRadius: BorderRadius.circular(8),
        //),
        width: AppConstants.nodeWidth,
        height: height,
        child: NotificationListener(
          onNotification: notificationListener,
          child: CarouselSlider(
              options: CarouselOptions(
                  height: height,
                  enlargeCenterPage: false,
                  enableInfiniteScroll: false,
                  scrollDirection: Axis.vertical,
                  viewportFraction: AppConstants.interNodeDistance / height,
                  onPageChanged: onPageChangeCallback),
              carouselController: controller,
              items: List.from(_buildTreeNodesListItems(items.iter))),
        ));
  }
}

class NodeListRegular extends NodeList {
  final bool Function(Notification)? notificationListener;
  final ScrollController scrollController;

  NodeListRegular(
      {super.key,
      required super.items,
      required super.height,
      super.onHorDragEndCallback,
      this.notificationListener,
      required super.onTapCallback,
      required super.onLongPressCallback,
      required super.onDoubleTapCallback,
      ScrollController? scrollController})
  : scrollController = scrollController ?? ScrollController();

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return Container();
    }
    return SizedBox(
        //decoration: BoxDecoration(
        //  border: Border.all(
        //      color: Colors.lightBlueAccent, width: AppConstants.nodeLineWidth),
        //  borderRadius: BorderRadius.circular(8),
        //),
        width: AppConstants.nodeWidth,
        height: items.length * AppConstants.interNodeDistance,
        child: NotificationListener(
          onNotification: notificationListener,
          child: ListView(
              controller: scrollController,
              physics: SnapScrollPhysics.builder(getSnaps),
              scrollDirection: Axis.vertical,
              children: List.from(
                  _buildTreeNodesListItems(items.iter, showLeafCount: true))
                // TODO: can this be solved more elegantly? (EDIT: yes if the paddedSize is a multiple of the screen height minus the appbar)
                // TLDR: Invisible SizeBox to make sure our scroll offset is a multiple of the paddedNodeHeight
                // right now when the height of the screen (minus appbar) is less than the height of our nodes
                // (or in other words if scrolling will be enabled) we add an invisible sizebox which
                // is has the exact height to make the combined height of our list items (nodes + invisible sizebox)
                // equal to the screen height. So even if we scroll all the way to the bottom the bezier curves and
                // and the nodes still line up
                ..addAll(
                    (items.length * AppConstants.interNodeDistance <= height)
                        ? []
                        : [
                            Container(
                                decoration: BoxDecoration(
                                  border: Border.all(
                                      color: Colors.lightBlueAccent,
                                      width: AppConstants.nodeLineWidth),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                height: height % AppConstants.interNodeDistance)
                          ])),
        ));
  }

  List<Snap> getSnaps() {
    List<Snap> res = [];
    for (int i = 0; i < items.length + 1; i++) {
      res.add(Snap(AppConstants.interNodeDistance * i,
          distance: AppConstants.interNodeDistance / 2));
    }
    return res;
  }

  static List<double> getBezierHeights(int numberOfChildren, double height) {
    if (numberOfChildren == 0) {
      return [];
    }

    List<double> res = [];
    double listHeight = numberOfChildren * AppConstants.paddedNodeHeight;
    // if the list is filling the height we have no offset
    double offset = (height > listHeight) ? (height - listHeight) / 2 : 0;
    offset += AppConstants.paddedNodeHeight / 2;

    for (int i = numberOfChildren - 1; i >= 0; i--) {
      res.add(offset + i * AppConstants.paddedNodeHeight);
    }

    return res;
  }
}

// Just a CarouselController with a getter for the index
class IndexTrackingCarouselController extends CarouselControllerImpl {
  int _index = 0;

  @override
  Future<void> nextPage({Duration? duration, Curve? curve}) async {
    _index++;
    super.nextPage(duration: duration, curve: curve);
  }

  @override
  Future<void> previousPage({Duration? duration, Curve? curve}) async {
    _index--;
    super.previousPage(duration: duration, curve: curve);
  }

  @override
  void jumpToPage(int page) {
    _index = page;
    super.jumpToPage(page);
  }

  @override
  Future<void> animateToPage(int page,
      {Duration? duration, Curve? curve}) async {
    _index = page;
    super.animateToPage(page, duration: duration, curve: curve);
  }

  // yeah 20 lines of code for this
  int get index => _index;
}
