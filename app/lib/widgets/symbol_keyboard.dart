import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';

class SymbolKeyboard extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback? onSymbolInserted;

  const SymbolKeyboard({
    super.key,
    required this.controller,
    this.onSymbolInserted,
  });

  void _insertText(String text) {
    final textVal = controller.text;
    final selection = controller.selection;

    if (selection.start >= 0 && selection.end >= 0) {
      final newText = textVal.replaceRange(selection.start, selection.end, text);
      controller.value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(offset: selection.start + text.length),
      );
    } else {
      controller.text = textVal + text;
      controller.selection = TextSelection.collapsed(offset: controller.text.length);
    }

    if (onSymbolInserted != null) {
      onSymbolInserted!();
    }
  }

  @override
  Widget build(BuildContext context) {
    final symbols = [
      '{',
      '}',
      '(',
      ')',
      '[',
      ']',
      ';',
      '=',
      '==',
      '=>',
      'return ',
      'print',
      '<',
      '>',
      '+',
      '-',
      'tab',
    ];

    return Container(
      height: 44,
      decoration: const BoxDecoration(
        color: AppTheme.darkSilicon,
        border: Border(
          top: BorderSide(color: AppTheme.circuitTrace, width: 1),
          bottom: BorderSide(color: AppTheme.circuitTrace, width: 1),
        ),
      ),
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        scrollDirection: Axis.horizontal,
        itemCount: symbols.length,
        separatorBuilder: (_, __) => const SizedBox(width: 6),
        itemBuilder: (context, index) {
          final sym = symbols[index];
          final isKeyword = sym == 'return ' || sym == 'print' || sym == 'tab';

          return InkWell(
            onTap: () {
              if (sym == 'tab') {
                _insertText('  ');
              } else {
                _insertText(sym);
              }
            },
            borderRadius: BorderRadius.circular(4),
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: isKeyword ? 10 : 12,
                vertical: 4,
              ),
              decoration: BoxDecoration(
                color: isKeyword
                    ? const Color(0xFF19251F)
                    : AppTheme.darkSiliconDeep,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: isKeyword
                      ? AppTheme.phosphorGreen.withValues(alpha: 0.5)
                      : AppTheme.circuitTrace,
                ),
              ),
              alignment: Alignment.center,
              child: Text(
                sym == 'tab' ? 'TAB ⇥' : sym.trim(),
                style: TextStyle(
                  fontFamily: AppTheme.monoFont,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: isKeyword
                      ? AppTheme.phosphorGreen
                      : AppTheme.boneWhite,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
