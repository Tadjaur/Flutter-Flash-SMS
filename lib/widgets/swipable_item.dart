import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';

enum SwipableDirection { horizontal, startToEnd, endToStart }
enum _FlingGestureKind { none, forward, reverse }

const double _defaultSeuil = 0.3;
const double _defaultMaxLimit = 0.7;
const Curve _kResizeTimeCurve = Interval(0.4, 1.0, curve: Curves.ease);
const double _kMinFlingVelocity = 700.0;
const double _kMinFlingVelocityDelta = 400.0;
const double _kFlingVelocityScale = 1.0 / 300.0;

class SwipableItem extends StatefulWidget {
  SwipableItem(
      {@required this.child,
      this.dragStartBehavior = DragStartBehavior.start,
      this.crossAxisEndOffset = 0.0,
      this.movementDuration = const Duration(milliseconds: 200),
      this.direction = SwipableDirection.horizontal,
      this.seuil = const <SwipableDirection, double>{},
      this.maxLimit = const <SwipableDirection, double>{},
      this.background,
      this.secondaryBackground,
      @required this.onSuccess,
      this.onTap,
      this.maxLimitNotify})
      : assert(child != null),
        assert(onSuccess != null, "null callback is not allowed"),
        assert(background != null || secondaryBackground != null,
            "the background value must not be null"),
        assert(dragStartBehavior != null);
  final Widget child, background, secondaryBackground;
  final DragStartBehavior dragStartBehavior;
  final Duration movementDuration;

  /// Defines the end offset across the main axis after the card is dismissed.
  ///
  /// If non-zero value is given then widget moves in cross direction depending on whether
  /// it is positive or negative.
  final double crossAxisEndOffset;

  /// The offset threshold the item has to be dragged in order to be considered
  /// dismissed.
  ///
  /// Represented as a fraction, e.g. if it is 0.4 (the default), then the item
  /// has to be dragged at least 40% towards one direction to be considered
  /// dismissed. Clients can define different thresholds for each dismiss
  /// direction.
  ///
  /// Flinging is treated as being equivalent to dragging almost to 1.0, so
  /// flinging can dismiss an item past any threshold less than 1.0.
  ///
  /// See also [direction], which controls the directions in which the items can
  /// be dismissed. Setting a threshold of 1.0 (or greater) prevents a drag in
  /// the given [SwipableDirection] even if it would be allowed by the
  /// [direction] property.
  final Map<SwipableDirection, double> seuil, maxLimit;
  final SwipableDirection direction;

  /// called when swipe success
  final VoidCallback onSuccess, onTap, maxLimitNotify;

  @override
  _SwipableItemState createState() => _SwipableItemState();
}

class _SwipableItemState extends State<SwipableItem>
    with TickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  double _dragExtent = 0.0;
  AnimationController _moveController;
  bool _dragUnderway = false;

  double get _overallDragAxisExtent => context.size.width;

  bool get _isActive {
    return _dragUnderway || _moveController.isAnimating;
  }

  Animation<Offset> _moveAnimation;

  void _handleDragStart(DragStartDetails details) {
    _dragUnderway = true;
    if (_moveController.isAnimating) {
      _dragExtent = _moveController.value * _overallDragAxisExtent * _dragExtent.sign;
      _moveController.stop();
    } else {
      _dragExtent = 0.0;
      _moveController.value = 0.0;
    }
    setState(() {
      _updateMoveAnimation();
    });
  }

  @override
  void initState() {
    super.initState();
    _moveController = AnimationController(duration: widget.movementDuration, vsync: this)
      ..addStatusListener(_handleDismissStatusChanged);
    _updateMoveAnimation();
  }

  Future<void> _handleDismissStatusChanged(AnimationStatus status) async {
    /*  if (status == AnimationStatus.completed && !_dragUnderway) {
      if (await _confirmStartResizeAnimation() == true)
        _startResizeAnimation();
      else
        _moveController.reverse();
    }
  */
    updateKeepAlive();
  }

  SwipableDirection _extentToDirection(double extent) {
    if (extent == 0.0) return null;
    switch (Directionality.of(context)) {
      case TextDirection.rtl:
        return extent < 0 ? SwipableDirection.startToEnd : SwipableDirection.endToStart;
      case TextDirection.ltr:
        return extent > 0 ? SwipableDirection.startToEnd : SwipableDirection.endToStart;
    }
    assert(false);
    return null;
  }

  SwipableDirection get _swipableItemDirection => _extentToDirection(_dragExtent);

  void _updateMoveAnimation() {
    final double end = _dragExtent.sign;
    _moveAnimation = _moveController.drive(
      Tween<Offset>(
        begin: Offset.zero,
        end: Offset(end, widget.crossAxisEndOffset),
      ),
    );
  }

  void _handleDragUpdate(DragUpdateDetails details) {
    if (!_isActive || _moveController.isAnimating) return;

    final double delta = details.primaryDelta;
    final double oldDragExtent = _dragExtent;
    switch (widget.direction) {
      case SwipableDirection.horizontal:
        _dragExtent += delta;
        break;

      case SwipableDirection.endToStart:
        switch (Directionality.of(context)) {
          case TextDirection.rtl:
            if (_dragExtent + delta > 0) _dragExtent += delta;
            break;
          case TextDirection.ltr:
            if (_dragExtent + delta < 0) _dragExtent += delta;
            break;
        }
        break;

      case SwipableDirection.startToEnd:
        switch (Directionality.of(context)) {
          case TextDirection.rtl:
            if (_dragExtent + delta < 0) _dragExtent += delta;
            break;
          case TextDirection.ltr:
            if (_dragExtent + delta > 0) _dragExtent += delta;
            break;
        }
        break;
    }
    if (oldDragExtent.sign != _dragExtent.sign) {
      setState(() {
        _updateMoveAnimation();
      });
    }
    final posVal = _dragExtent.abs() / _overallDragAxisExtent;
    if (!_moveController.isAnimating &&
        posVal < (widget.maxLimit[_swipableItemDirection] ?? _defaultMaxLimit)) {
      _moveController.value = posVal;
    } else {
      if (widget.maxLimitNotify != null) {
        widget.maxLimitNotify();
      }
    }
  }

  _FlingGestureKind _describeFlingGesture(Velocity velocity) {
    assert(widget.direction != null);
    if (_dragExtent == 0.0) {
      // If it was a fling, then it was a fling that was let loose at the exact
      // middle of the range (i.e. when there's no displacement). In that case,
      // we assume that the user meant to fling it back to the center, as
      // opposed to having wanted to drag it out one way, then fling it past the
      // center and into and out the other side.
      return _FlingGestureKind.none;
    }
    final double vx = velocity.pixelsPerSecond.dx;
    final double vy = velocity.pixelsPerSecond.dy;
    SwipableDirection flingDirection;
    // Verify that the fling is in the generally right direction and fast enough.
    if (vx.abs() - vy.abs() < _kMinFlingVelocityDelta || vx.abs() < _kMinFlingVelocity)
      return _FlingGestureKind.none;
    assert(vx != 0.0);
    flingDirection = _extentToDirection(vx);

    assert(_swipableItemDirection != null);
    if (flingDirection == _swipableItemDirection) return _FlingGestureKind.forward;
    return _FlingGestureKind.reverse;
  }

  Future<void> _handleDragEnd(DragEndDetails details) async {
    if (!_isActive || _moveController.isAnimating) return;
    _dragUnderway = false;
//    if (_moveController.isCompleted &&
//        await _confirmStartResizeAnimation() == true) {
//      _startResizeAnimation();
//      return;
//    }
    final double flingVelocity = details.velocity.pixelsPerSecond.dx;
    switch (_describeFlingGesture(details.velocity)) {
      case _FlingGestureKind.forward:
        assert(_dragExtent != 0.0);
        assert(!_moveController.isDismissed);
        _moveController.reverse();
        if ((widget.seuil[_swipableItemDirection] ?? _defaultSeuil) >= 1.0) {
          break;
        }
        widget.onSuccess();
//        _dragExtent = flingVelocity.sign;
//        _moveController.fling(
//            velocity: flingVelocity.abs() * _kFlingVelocityScale);
        break;
      case _FlingGestureKind.reverse:
        assert(_dragExtent != 0.0);
        assert(!_moveController.isDismissed);
        _dragExtent = flingVelocity.sign;
        _moveController.fling(velocity: -flingVelocity.abs() * _kFlingVelocityScale);
        break;
      case _FlingGestureKind.none:
        if (!_moveController.isDismissed) {
          // we already know it's not completed, we check that above
          if (_moveController.value > (widget.seuil[_swipableItemDirection] ?? _defaultSeuil)) {
            widget.onSuccess();
            _moveController.reverse();
//            _moveController.forward();
          } else {
            _moveController.reverse();
          }
        }
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget background = widget.background;
    if (widget.secondaryBackground != null) {
      final SwipableDirection direction = _swipableItemDirection;
      if (direction == SwipableDirection.endToStart) background = widget.secondaryBackground;
    }

    Widget content = SlideTransition(
      position: _moveAnimation,
      child: widget.child,
    );

    if (background != null) {
      final List<Widget> children = <Widget>[];

      if (!_moveAnimation.isDismissed) {
        children.add(Positioned.fill(
          child: ClipRect(
            clipper: _SwipableClipper(
              axis: Axis.horizontal,
              moveAnimation: _moveAnimation,
            ),
            child: background,
          ),
        ));
      }

      children.add(content);
      content = Stack(children: children);
    }
    return GestureDetector(
      onHorizontalDragStart: _handleDragStart,
      onHorizontalDragUpdate: _handleDragUpdate,
      onHorizontalDragEnd: _handleDragEnd,
      onTap: widget.onTap ?? () {},
      behavior: HitTestBehavior.opaque,
      child: content,
      dragStartBehavior: widget.dragStartBehavior,
    );
  }

  @override
  // TODO: implement wantKeepAlive
  bool get wantKeepAlive => _moveController?.isAnimating == true;
}

class _SwipableClipper extends CustomClipper<Rect> {
  _SwipableClipper({
    @required this.axis,
    @required this.moveAnimation,
  })  : assert(axis != null),
        assert(moveAnimation != null),
        super(reclip: moveAnimation);

  final Axis axis;
  final Animation<Offset> moveAnimation;

  @override
  Rect getClip(Size size) {
    assert(axis != null);
    switch (axis) {
      case Axis.horizontal:
        final double offset = moveAnimation.value.dx * size.width;
        if (offset < 0) return Rect.fromLTRB(size.width + offset, 0.0, size.width, size.height);
        return Rect.fromLTRB(0.0, 0.0, offset, size.height);
      default:
        return null;
    }
  }

  @override
  Rect getApproximateClipRect(Size size) => getClip(size);

  @override
  bool shouldReclip(_SwipableClipper oldClipper) {
    return oldClipper.axis != axis || oldClipper.moveAnimation.value != moveAnimation.value;
  }
}
