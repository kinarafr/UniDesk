import 'package:flutter/material.dart';
import '../main.dart';

class TicketNotificationOverlay extends StatefulWidget {
  final Map<String, dynamic> ticketData;
  final String ticketId;
  final VoidCallback onDismiss;
  final Function(Map<String, dynamic>, String) onViewTicket;

  const TicketNotificationOverlay({
    super.key,
    required this.ticketData,
    required this.ticketId,
    required this.onDismiss,
    required this.onViewTicket,
  });

  @override
  State<TicketNotificationOverlay> createState() =>
      _TicketNotificationOverlayState();
}

class _TicketNotificationOverlayState extends State<TicketNotificationOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _offsetAnimation;
  bool _isDismissed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _offsetAnimation = Tween<Offset>(
      begin: const Offset(1.5, 0.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));

    // Slide in
    _controller.forward();

    // Auto dismiss after 5 seconds
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted && !_isDismissed) {
        _dismiss();
      }
    });
  }

  void _dismiss() {
    if (_isDismissed) return;
    setState(() => _isDismissed = true);
    _controller.reverse().then((_) {
      if (mounted) widget.onDismiss();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 24,
      right: 24,
      child: ValueListenableBuilder<bool>(
        valueListenable: UniDeskAdminApp.reduceMotionNotifier,
        builder: (context, reduceMotion, child) {
          if (reduceMotion) {
            _controller.duration = const Duration(milliseconds: 50);
            _controller.reverseDuration = const Duration(milliseconds: 50);
            return FadeTransition(opacity: _controller, child: child!);
          } else {
            _controller.duration = const Duration(milliseconds: 500);
            _controller.reverseDuration = const Duration(milliseconds: 500);
            return SlideTransition(position: _offsetAnimation, child: child!);
          }
        },
        child: Material(
          color: Colors.transparent,
          child: Container(
            width: 350,
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
              border: Border.all(
                color: Theme.of(context).primaryColor.withOpacity(0.5),
                width: 1,
              ),
            ),
            child: Stack(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Theme.of(
                            context,
                          ).primaryColor.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.notifications_active,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text(
                              'New Ticket Received',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              widget.ticketData['serviceTitle'] ??
                                  'New Request',
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              'From: ${widget.ticketData['userName'] ?? 'Unknown'}',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 8),
                            SizedBox(
                              height: 32,
                              child: ElevatedButton(
                                onPressed: () {
                                  _dismiss();
                                  widget.onViewTicket(
                                    widget.ticketData,
                                    widget.ticketId,
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                  ),
                                ),
                                child: const Text(
                                  'View Ticket',
                                  style: TextStyle(fontSize: 12),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  top: 4,
                  right: 4,
                  child: IconButton(
                    icon: const Icon(Icons.close, size: 16),
                    onPressed: _dismiss,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
