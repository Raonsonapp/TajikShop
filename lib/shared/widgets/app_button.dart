import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import 'fade_slide_in.dart';

class AppButton extends StatelessWidget {
  final String text;
  final VoidCallback? onTap;
  final bool isLoading;
  final bool isOutlined;
  final Color? color;
  final double? width;
  final double height;
  final IconData? icon;

  const AppButton({
    super.key,
    required this.text,
    this.onTap,
    this.isLoading = false,
    this.isOutlined = false,
    this.color,
    this.width,
    this.height = 52,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final bg = color ?? AppColors.primary;
    // Вокуниши пахш: тугма ҳангоми зер каме хурд мешавад.
    //
    // Бе он тугмаи асосии барнома — «Ба сабад», «Харидан», «Фармоиш
    // додан» — «мурда» эҳсос мешуд. Ҳангоми интернети суст корбар
    // намедонист, оё зерашро барнома гирифт, ва боз як бор мезад.
    //
    // ⚠️ `isLoading` ва `onTap == null` вокуниш НАДОРАНД: вокуниши
    // пахш дар тугмаи хомӯш дурӯғ мегӯяд.
    return PressableScale(
      scale: (isLoading || onTap == null) ? 1 : 0.97,
      onTap: isLoading ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: width ?? double.infinity,
        height: height,
        decoration: BoxDecoration(
          color: isOutlined ? Colors.transparent : bg,
          border: isOutlined ? Border.all(color: bg, width: 1.5) : null,
          borderRadius: BorderRadius.circular(14),
          gradient: isOutlined ? null : AppColors.primaryGradient,
        ),
        child: Center(
          child: isLoading
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor: AlwaysStoppedAnimation(Colors.white),
                  ),
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (icon != null) ...[
                      Icon(icon, color: isOutlined ? bg : Colors.white, size: 20),
                      const SizedBox(width: 8),
                    ],
                    Text(
                      text,
                      style: TextStyle(
                        color: isOutlined ? bg : Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
