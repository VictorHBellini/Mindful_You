import 'package:flutter/material.dart';

/// Widget utilitário que centraliza o conteúdo e impõe uma largura máxima ([maxWidth]).
///
/// Em telas pequenas (smartphones), comporta-se naturalmente ocupando a largura total disponível.
/// Em telas médias e grandes (tablets, dobráveis, desktops, web), impede que formulários e
/// cartões se estiquem desproporcionalmente, mantendo proporções visuais elegantes e ergonômicas.
class ResponsiveCenter extends StatelessWidget {
  final Widget child;
  final double maxWidth;
  final EdgeInsetsGeometry padding;

  const ResponsiveCenter({
    super.key,
    required this.child,
    this.maxWidth = 600,
    this.padding = EdgeInsets.zero,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Padding(
          padding: padding,
          child: child,
        ),
      ),
    );
  }
}
