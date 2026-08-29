import 'package:flutter/material.dart';

import '../../models/ingredient.dart';
import '../../services/recipe_image_resolver.dart';
import 'fallback_image.dart';

/// Resolves and shows a real photo for a pantry [Ingredient] (e.g. "chicken
/// breast", "red onion"), searched by its own name via
/// [RecipeImageResolver.urlForIngredient] — the same Unsplash lookup already
/// used for recipe photos, just keyed per-ingredient instead of per-category.
///
/// [RecipeImageResolver] caches every resolved query in memory, so re-
/// building this widget (list scrolling, re-render, etc.) for the same
/// ingredient name never re-hits the network after the first lookup.
///
/// While the photo is resolving, and if the lookup fails or returns nothing
/// (offline, no API key, no results), this shows the bundled local
/// category placeholder via [FallbackImage] — the UI never looks broken or
/// empty.
class IngredientImage extends StatefulWidget {
  const IngredientImage({
    super.key,
    required this.ingredient,
    this.fit = BoxFit.cover,
    this.borderRadius,
  });

  final Ingredient ingredient;
  final BoxFit fit;
  final BorderRadius? borderRadius;

  @override
  State<IngredientImage> createState() => _IngredientImageState();
}

class _IngredientImageState extends State<IngredientImage> {
  late Future<String> _urlFuture;

  @override
  void initState() {
    super.initState();
    _urlFuture = RecipeImageResolver.urlForIngredient(widget.ingredient);
  }

  @override
  void didUpdateWidget(covariant IngredientImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.ingredient.name != widget.ingredient.name) {
      _urlFuture = RecipeImageResolver.urlForIngredient(widget.ingredient);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: _urlFuture,
      builder: (context, snapshot) {
        return FallbackImage(
          assetPath: RecipeImageResolver.assetForIngredient(widget.ingredient),
          networkUrl: snapshot.data,
          fit: widget.fit,
          borderRadius: widget.borderRadius,
        );
      },
    );
  }
}
