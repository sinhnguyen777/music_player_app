import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/track.dart';
import '../providers/favorite_provider.dart';

class FavoriteButton extends StatefulWidget {
  final Track track;
  final double size;
  final Color? favoriteColor;
  final Color? unfavoriteColor;
  final bool showAnimation;

  const FavoriteButton({
    Key? key,
    required this.track,
    this.size = 24.0,
    this.favoriteColor = Colors.red,
    this.unfavoriteColor,
    this.showAnimation = true,
  }) : super(key: key);

  @override
  State<FavoriteButton> createState() => _FavoriteButtonState();
}

class _FavoriteButtonState extends State<FavoriteButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    // Check initial favorite status
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkFavoriteStatus();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _checkFavoriteStatus() async {
    final favoriteProvider = Provider.of<FavoriteProvider>(
      context,
      listen: false,
    );
    await favoriteProvider.checkFavoriteStatus(widget.track.id);
  }

  Future<void> _toggleFavorite() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    final favoriteProvider = Provider.of<FavoriteProvider>(
      context,
      listen: false,
    );
    final success = await favoriteProvider.toggleFavorite(widget.track);

    if (success && widget.showAnimation) {
      _animationController.forward().then((_) {
        _animationController.reverse();
      });
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
      });

      // Show feedback
      final isFavorite = favoriteProvider.isFavorite(widget.track.id);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isFavorite ? Icons.favorite : Icons.heart_broken,
                color: isFavorite ? Colors.red : Colors.white70,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                isFavorite ? 'Added to favorites ❤️' : 'Removed from favorites',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          backgroundColor: isFavorite
              ? const Color(0xFF1DB954).withOpacity(0.9)
              : const Color(0xFF404040).withOpacity(0.9),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          elevation: 4,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<FavoriteProvider>(
      builder: (context, favoriteProvider, child) {
        final isFavorite = favoriteProvider.isFavorite(widget.track.id);

        return GestureDetector(
          onTap: _toggleFavorite,
          child: AnimatedBuilder(
            animation: _scaleAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _scaleAnimation.value,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  child: _isLoading
                      ? SizedBox(
                          width: widget.size,
                          height: widget.size,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              widget.favoriteColor ?? Colors.red,
                            ),
                          ),
                        )
                      : Icon(
                          isFavorite ? Icons.favorite : Icons.favorite_border,
                          size: widget.size,
                          color: isFavorite
                              ? (widget.favoriteColor ?? Colors.red)
                              : (widget.unfavoriteColor ??
                                    Colors.white.withOpacity(0.7)),
                        ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
