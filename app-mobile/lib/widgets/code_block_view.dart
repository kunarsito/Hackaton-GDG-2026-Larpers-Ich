import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/theme/app_theme.dart';

class CodeBlockView extends StatelessWidget {
  final String code;
  final String? language;
  final bool showHeader;

  const CodeBlockView({
    super.key,
    required this.code,
    this.language = 'dart',
    this.showHeader = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.darkSiliconDeep,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppTheme.circuitTrace, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (showHeader)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: const BoxDecoration(
                color: Color(0xFF0F1511),
                borderRadius: BorderRadius.vertical(top: Radius.circular(5)),
                border: Border(
                  bottom: BorderSide(color: AppTheme.circuitTrace, width: 1),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: const BoxDecoration(
                      color: AppTheme.solderGold,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '// SNIPPET: ${language?.toUpperCase() ?? "SOURCE"}',
                    style: const TextStyle(
                      fontFamily: AppTheme.monoFont,
                      fontSize: 11,
                      color: AppTheme.greenishGray,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  InkWell(
                    onTap: () {
                      Clipboard.setData(ClipboardData(text: code));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          backgroundColor: AppTheme.darkSilicon,
                          content: Text(
                            '[SYS_MSG]: Código copiado al portapapeles',
                            style: TextStyle(
                              color: AppTheme.phosphorGreen,
                              fontFamily: AppTheme.monoFont,
                            ),
                          ),
                          duration: Duration(seconds: 1),
                        ),
                      );
                    },
                    borderRadius: BorderRadius.circular(4),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      child: Row(
                        children: [
                          Icon(
                            Icons.copy_rounded,
                            size: 13,
                            color: AppTheme.phosphorGreen,
                          ),
                          SizedBox(width: 4),
                          Text(
                            'COPIAR',
                            style: TextStyle(
                              fontFamily: AppTheme.monoFont,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.phosphorGreen,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.all(12),
            child: SelectableText(
              code,
              style: AppTheme.codeTextStyle.copyWith(
                color: AppTheme.boneWhite,
                fontSize: 12.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
