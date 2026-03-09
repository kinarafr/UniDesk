import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class SkeletonLoader extends StatefulWidget {
  final double width;
  final double height;
  final double borderRadius;

  const SkeletonLoader({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = 8.0,
  });

  @override
  State<SkeletonLoader> createState() => _SkeletonLoaderState();
}

class _SkeletonLoaderState extends State<SkeletonLoader> {
  bool _showSkeleton = false;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 50), () {
      if (mounted) {
        setState(() {
          _showSkeleton = true;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_showSkeleton) return const SizedBox.shrink();

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = isDark ? Colors.grey[800]! : Colors.grey[300]!;
    final highlightColor = isDark ? Colors.grey[700]! : Colors.grey[100]!;

    return Shimmer.fromColors(
      baseColor: baseColor,
      highlightColor: highlightColor,
      child: Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          color: isDark ? Colors.white24 : Colors.white,
          borderRadius: BorderRadius.circular(widget.borderRadius),
        ),
      ),
    );
  }
}

class DashboardSkeleton extends StatelessWidget {
  const DashboardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  SkeletonLoader(width: 250, height: 32),
                  SizedBox(height: 8),
                  SkeletonLoader(width: 150, height: 20),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: const [
                  SkeletonLoader(width: 100, height: 32),
                  SizedBox(height: 8),
                  SkeletonLoader(width: 180, height: 20),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 2,
                child: Column(
                  children: [
                    Row(
                      children: const [
                        Expanded(child: SkeletonLoader(width: double.infinity, height: 120, borderRadius: 12)),
                        SizedBox(width: 16),
                        Expanded(child: SkeletonLoader(width: double.infinity, height: 120, borderRadius: 12)),
                      ],
                    ),
                    const SizedBox(height: 24),
                    const SkeletonLoader(width: double.infinity, height: 400, borderRadius: 12),
                  ],
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: Column(
                  children: const [
                    SkeletonLoader(width: double.infinity, height: 250, borderRadius: 12),
                    SizedBox(height: 24),
                    SkeletonLoader(width: double.infinity, height: 300, borderRadius: 12),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class TableSkeleton extends StatelessWidget {
  const TableSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              SkeletonLoader(width: 150, height: 32),
              SkeletonLoader(width: 250, height: 40, borderRadius: 8),
            ],
          ),
          const SizedBox(height: 24),
          const SkeletonLoader(width: double.infinity, height: 50, borderRadius: 8),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.builder(
              itemCount: 8,
              itemBuilder: (context, index) {
                return const Padding(
                  padding: EdgeInsets.only(bottom: 8.0),
                  child: SkeletonLoader(width: double.infinity, height: 60, borderRadius: 8),
                );
              },
            ),
          )
        ],
      ),
    );
  }
}
