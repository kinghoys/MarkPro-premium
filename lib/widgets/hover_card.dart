import 'package:flutter/material.dart';

class HoverCard extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  final double elevation;
  final double hoverElevation;
  final EdgeInsetsGeometry margin;
  final Color? shadowColor;
  final Color? hoverShadowColor;
  final BorderRadius borderRadius;
  final bool useScale;
  final bool useTranslation;
  
  const HoverCard({
    Key? key,
    required this.child,
    required this.onTap,
    this.elevation = 2,
    this.hoverElevation = 6,
    this.margin = const EdgeInsets.only(bottom: 16),
    this.shadowColor,
    this.hoverShadowColor,
    this.borderRadius = const BorderRadius.all(Radius.circular(12)),
    this.useScale = false,
    this.useTranslation = true,
  }) : super(key: key);

  @override
  State<HoverCard> createState() => _HoverCardState();
}

class _HoverCardState extends State<HoverCard> {
  bool _isHovering = false;
  
  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          transform: _buildTransform(),
          child: Container(
            margin: widget.margin,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: widget.borderRadius,
              border: Border.all(
                color: _isHovering ? Colors.blue.withOpacity(0.5) : Colors.grey.withOpacity(0.2),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: _isHovering 
                      ? (widget.hoverShadowColor ?? Colors.purple.withOpacity(0.25)) 
                      : (widget.shadowColor ?? Colors.black.withOpacity(0.1)),
                  blurRadius: _isHovering ? widget.hoverElevation * 2 : widget.elevation * 2,
                  spreadRadius: _isHovering ? 1 : 0,
                  offset: Offset(0, _isHovering ? 2 : 1),
                ),
              ],
            ),
            child: widget.child,
          ),
        ),
      ),
    );
  }
  
  Matrix4 _buildTransform() {
    if (!_isHovering) {
      return Matrix4.identity();
    }
    
    final transform = Matrix4.identity();
    
    if (widget.useTranslation) {
      transform.translate(0, -5, 0);
    }
    
    if (widget.useScale) {
      transform.scale(1.03);
    }
    
    return transform;
  }
}
