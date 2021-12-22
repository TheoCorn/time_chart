import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:time_chart/src/chart.dart';
import 'package:time_chart/src/components/utils/time_assistant.dart';
import 'package:time_chart/src/components/utils/time_data_processor.dart';
import 'package:time_chart/time_chart.dart';

class _MockTimeDataProcessor with TimeDataProcessor {
  void process(List<DateTimeRange> data, {int defaultPivotHour = 18}) {
    processData(_getChart(data, defaultPivotHour: defaultPivotHour),
        data.first.end.add(const Duration(days: 1)).dateWithoutTime());
  }
}

Chart _getChart(List<DateTimeRange> data, {int defaultPivotHour = 18}) {
  return Chart(
    chartType: ChartType.time,
    width: 300,
    height: 400,
    data: data,
    timeChartSizeAnimationDuration: const Duration(milliseconds: 300),
    tooltipDuration: const Duration(milliseconds: 500),
    tooltipBackgroundColor: Colors.black,
    tooltipStart: "START",
    tooltipEnd: "END",
    activeTooltip: true,
    viewMode: ViewMode.weekly,
    defaultPivotHour: defaultPivotHour,
    barColor: Colors.red,
  );
}

void main() {
  group('Time chart data processor test', () {
    testWidgets('merge if has overlapping time', (tester) async {
      final _MockTimeDataProcessor processor = _MockTimeDataProcessor();
      final data = [
        DateTimeRange(
          start: DateTime(2021, 2, 24, 23, 15),
          end: DateTime(2021, 2, 25, 7, 30),
        ),
        DateTimeRange(
          start: DateTime(2021, 2, 22, 1, 55),
          end: DateTime(2021, 2, 22, 9, 12),
        ),
      ];
      processor.process(data);

      expect(processor.topHour, 22);
      expect(processor.bottomHour, 10);
    });

    testWidgets('compare empty space for setting pivot hours', (tester) async {
      final _MockTimeDataProcessor processor = _MockTimeDataProcessor();
      final data = [
        DateTimeRange(
          start: DateTime(2021, 2, 2, 18, 42),
          end: DateTime(2021, 2, 2, 21, 22),
        ),
        DateTimeRange(
          start: DateTime(2021, 2, 2, 11, 39),
          end: DateTime(2021, 2, 2, 18, 2),
        ),
        DateTimeRange(
          start: DateTime(2021, 2, 2, 4, 52),
          end: DateTime(2021, 2, 2, 9, 0),
        ),
        DateTimeRange(
          start: DateTime(2021, 2, 1, 22, 12),
          end: DateTime(2021, 2, 2, 3, 30),
        ),
      ];
      processor.process(data);

      expect(processor.topHour, 11);
      expect(processor.bottomHour, 9);
    });

    testWidgets('compare and merge time for setting pivot hours',
        (tester) async {
      final _MockTimeDataProcessor processor = _MockTimeDataProcessor();
      final data = [
        DateTimeRange(
          start: DateTime(2021, 2, 2, 14, 42),
          end: DateTime(2021, 2, 2, 21, 22),
        ),
        DateTimeRange(
          start: DateTime(2021, 2, 2, 11, 39),
          end: DateTime(2021, 2, 2, 16, 2),
        ),
        DateTimeRange(
          start: DateTime(2021, 2, 2, 2, 52),
          end: DateTime(2021, 2, 2, 9, 0),
        ),
        DateTimeRange(
          start: DateTime(2021, 2, 1, 22, 12),
          end: DateTime(2021, 2, 2, 3, 30),
        ),
      ];
      processor.process(data);

      expect(processor.topHour, 11);
      expect(processor.bottomHour, 9);
    });

    testWidgets('default pivot hours is used if there are no space',
        (tester) async {
      final _MockTimeDataProcessor processor = _MockTimeDataProcessor();
      final data = [
        DateTimeRange(
          start: DateTime(2021, 2, 2, 17, 42),
          end: DateTime(2021, 2, 2, 22, 22),
        ),
        DateTimeRange(
          start: DateTime(2021, 2, 2, 8, 39),
          end: DateTime(2021, 2, 2, 18, 2),
        ),
        DateTimeRange(
          start: DateTime(2021, 2, 2, 2, 52),
          end: DateTime(2021, 2, 2, 9, 0),
        ),
        DateTimeRange(
          start: DateTime(2021, 2, 1, 22, 12),
          end: DateTime(2021, 2, 2, 3, 30),
        ),
      ];
      final chart = _getChart(data);

      processor.process(data);

      expect(processor.topHour, chart.defaultPivotHour);
      expect(processor.bottomHour, chart.defaultPivotHour);
    });

    testWidgets(
        'set both pivot hours to 12 AM if both pivot hours are the same',
        (tester) async {
      final _MockTimeDataProcessor processor = _MockTimeDataProcessor();
      final data = [
        DateTimeRange(
          start: DateTime(2021, 12, 17, 3, 12),
          end: DateTime(2021, 12, 18, 2, 30),
        ),
      ];
      final chart = _getChart(data);

      processor.process(data);

      expect(processor.topHour, chart.defaultPivotHour);
      expect(processor.bottomHour, chart.defaultPivotHour);
    });

    testWidgets(
        'custom defaultPivotHour parameter is used if time range is fully visible',
        (tester) async {
      const pivotHour = 2;
      final _MockTimeDataProcessor processor = _MockTimeDataProcessor();
      final data = [
        DateTimeRange(
          start: DateTime(2021, 12, 17, 3, 12),
          end: DateTime(2021, 12, 18, 2, 30),
        ),
      ];
      processor.process(data, defaultPivotHour: pivotHour);

      expect(processor.topHour, pivotHour);
      expect(processor.bottomHour, pivotHour);
    });

    testWidgets(
        'all data is not changed to next day if the bottom pivot hour is 12 AM',
        (tester) async {
      final _MockTimeDataProcessor processor = _MockTimeDataProcessor();
      final data = DateTimeRange(
        start: DateTime(2021, 12, 18, 22, 12),
        end: DateTime(2021, 12, 18, 23, 30),
      );

      processor.process([data]);

      expect(processor.processedData.first.end, data.end);
    });
  });
}
