import 'package:air_reply/core/l10n/l10n.dart';
import 'package:air_reply/core/theme/app_dimensions.dart';
import 'package:air_reply/core/theme/app_icons.dart';
import 'package:air_reply/core/theme/app_palette.dart';
import 'package:air_reply/core/theme/app_spacing.dart';
import 'package:flutter/material.dart';

/// A search box with a clear button; its fill comes from the theme, so inside a [PinnedSearchBar] it turns to glass
/// when pinned. [value] is the current query; when it changes from outside (filters cleared elsewhere), the box
/// follows.
class SearchField extends StatefulWidget {
  const SearchField({required this.onChanged, this.hint, this.value = '', this.autofocus = false, super.key});

  final ValueChanged<String> onChanged;

  /// The placeholder; "Search" in the person's language by default.
  final String? hint;
  final String value;
  final bool autofocus;

  @override
  State<SearchField> createState() => _SearchFieldState();
}

class _SearchFieldState extends State<SearchField> {
  late final _controller = TextEditingController(text: widget.value);

  @override
  void didUpdateWidget(SearchField old) {
    super.didUpdateWidget(old);
    if (widget.value != _controller.text) _controller.text = widget.value;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _changed(String value) {
    setState(() {});
    widget.onChanged(value);
  }

  @override
  Widget build(BuildContext context) => TextField(
    controller: _controller,
    autofocus: widget.autofocus,
    textInputAction: TextInputAction.search,
    onChanged: _changed,
    decoration: InputDecoration(
      hintText: widget.hint ?? context.l10n.searchHint,
      prefixIcon: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Icon(AppIcons.search, size: AppDimensions.iconMd + 2, color: context.palette.muted),
      ),
      suffixIcon: _controller.text.isEmpty
          ? null
          : IconButton(
              tooltip: context.l10n.searchClear,
              icon: const Icon(AppIcons.close),
              onPressed: () {
                _controller.clear();
                _changed('');
              },
            ),
    ),
  );
}
