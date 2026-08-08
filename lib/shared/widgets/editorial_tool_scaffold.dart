import 'package:flutter/material.dart';

/// Shell commun pour les outils : barre native, titre Fraunces et surface
/// éditoriale. Les écrans historiques peuvent migrer sans modifier leur body.
class EditorialToolScaffold extends StatelessWidget {
  static const double maxBodyWidth = 920;

  final String title;
  final String heroTag;
  final Widget body;
  final List<Widget>? actions;
  final PreferredSizeWidget? bottom;
  final Widget? leading;
  final Widget? floatingActionButton;
  final bool constrainBody;

  const EditorialToolScaffold({
    super.key,
    required this.title,
    required this.heroTag,
    required this.body,
    this.actions,
    this.bottom,
    this.leading,
    this.floatingActionButton,
    this.constrainBody = true,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: leading,
        title: Hero(
          tag: heroTag,
          child: Material(
            type: MaterialType.transparency,
            child: Text(
              title,
              style: Theme.of(context).appBarTheme.titleTextStyle,
            ),
          ),
        ),
        actions: actions,
        bottom: bottom,
      ),
      body: SafeArea(
        top: false,
        child: constrainBody
            ? Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: maxBodyWidth),
                  child: body,
                ),
              )
            : body,
      ),
      floatingActionButton: floatingActionButton,
    );
  }
}
