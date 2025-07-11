import 'package:intl/intl.dart';

class DataFormatter {
  static String formaterTimeStamp(String timestampString) {
    DateTime timestamp = DateTime.parse(timestampString);
    final DateFormat dateformat = DateFormat("dd-MMM-yyy 'à' hh:mm a");
    return dateformat.format(timestamp);
  }
}
