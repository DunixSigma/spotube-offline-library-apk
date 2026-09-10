import 'package:flutter/widgets.dart';

String offlineText(BuildContext context, String english, String portuguese) {
  return Localizations.localeOf(context).languageCode.toLowerCase() == 'pt'
      ? portuguese
      : english;
}
