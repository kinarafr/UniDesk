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

class HomeSkeleton extends StatelessWidget {
  const HomeSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  SkeletonLoader(width: 80, height: 24),
                  SizedBox(height: 8),
                  SkeletonLoader(width: 150, height: 32),
                ],
              ),
              const SkeletonLoader(width: 48, height: 48, borderRadius: 24),
            ],
          ),
          const SizedBox(height: 32),
          const SkeletonLoader(width: double.infinity, height: 56, borderRadius: 28),
          const SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              SkeletonLoader(width: 160, height: 28),
              SkeletonLoader(width: 60, height: 20),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 180,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: 3,
              itemBuilder: (context, index) {
                return const Padding(
                  padding: EdgeInsets.only(right: 16),
                  child: SkeletonLoader(width: 300, height: 180, borderRadius: 16),
                );
              },
            ),
          ),
          const SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              SkeletonLoader(width: 140, height: 28),
              SkeletonLoader(width: 40, height: 20),
            ],
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              int columns = constraints.maxWidth > 450 ? (constraints.maxWidth / 130).floor() : 3;
              return GridView.builder(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: columns,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 0.85,
                ),
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: 6,
                itemBuilder: (context, index) {
                  return const SkeletonLoader(
                    width: double.infinity,
                    height: double.infinity,
                    borderRadius: 16,
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}

class ListSkeleton extends StatelessWidget {
  final int itemCount;
  
  const ListSkeleton({super.key, this.itemCount = 5});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: itemCount,
      itemBuilder: (context, index) {
        return const Padding(
          padding: EdgeInsets.only(bottom: 16),
          child: SkeletonLoader(width: double.infinity, height: 100, borderRadius: 12),
        );
      },
    );
  }
}

class FormSkeleton extends StatelessWidget {
  const FormSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          SkeletonLoader(width: 200, height: 32),
          SizedBox(height: 8),
          SkeletonLoader(width: double.infinity, height: 20),
          SizedBox(height: 32),
          SkeletonLoader(width: 100, height: 20),
          SizedBox(height: 8),
          SkeletonLoader(width: double.infinity, height: 56, borderRadius: 12),
          SizedBox(height: 24),
          SkeletonLoader(width: 120, height: 20),
          SizedBox(height: 8),
          SkeletonLoader(width: double.infinity, height: 56, borderRadius: 12),
          SizedBox(height: 24),
          SkeletonLoader(width: 150, height: 20),
          SizedBox(height: 8),
          SkeletonLoader(width: double.infinity, height: 120, borderRadius: 12),
          SizedBox(height: 32),
          SkeletonLoader(width: double.infinity, height: 56, borderRadius: 28),
        ],
      ),
    );
  }
}
