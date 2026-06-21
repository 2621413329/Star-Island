import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';

export '../../l10n/app_localizations.dart';

/// 统一访问国际化文案：`context.l10n.saveSuccess`
extension L10nContext on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}
