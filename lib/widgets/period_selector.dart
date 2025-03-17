import 'package:flutter/material.dart';
import 'package:goalock/theme/app_theme.dart';

/// 목표 표시 주기 선택 위젯
class PeriodSelector extends StatelessWidget {
  final String selectedPeriod;
  final Function(String) onPeriodSelected;
  final bool isDarkMode;
  final List<String> periods;

  const PeriodSelector({
    Key? key,
    required this.selectedPeriod,
    required this.onPeriodSelected,
    required this.isDarkMode,
    this.periods = const ["Always", "Once a Day", "Weekly"],
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "표시 주기",
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: isDarkMode ? Colors.white : Colors.black,
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 50,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children:
                periods.map((period) {
                  return GestureDetector(
                    onTap: () => onPeriodSelected(period),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.only(right: 10),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color:
                            selectedPeriod == period
                                ? AppTheme.primaryColor
                                : (isDarkMode
                                    ? Colors.grey[700]
                                    : Colors.grey[200]),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: AppTheme.primaryColor,
                          width: 1,
                        ),
                      ),
                      child: Text(
                        period,
                        style: TextStyle(
                          color: isDarkMode ? Colors.white : Colors.black,
                        ),
                      ),
                    ),
                  );
                }).toList(),
          ),
        ),
      ],
    );
  }
}
