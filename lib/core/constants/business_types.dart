import 'package:feather_icons/feather_icons.dart';
import 'package:flutter/widgets.dart';

/// Навъҳои бизнес барои дӯконҳо (storefront) — калид дар backend нигоҳ дошта
/// мешавад (`business_type`), нишона ва номи тоҷикӣ дар frontend.
class BusinessType {
  final String key;
  final String label; // тоҷикӣ
  final IconData icon;
  const BusinessType(this.key, this.label, this.icon);
}

const List<BusinessType> kBusinessTypes = [
  BusinessType('shop', 'Дӯкон', FeatherIcons.shoppingBag),
  BusinessType('restaurant', 'Тарабхона', FeatherIcons.coffee),
  BusinessType('service', 'Хизматрасонӣ', FeatherIcons.tool),
  BusinessType('pharmacy', 'Дорухона', FeatherIcons.plusCircle),
  BusinessType('beauty', 'Зебоӣ', FeatherIcons.scissors),
  BusinessType('grocery', 'Озуқаворӣ', FeatherIcons.shoppingCart),
  BusinessType('electronics', 'Техника', FeatherIcons.smartphone),
  BusinessType('other', 'Дигар', FeatherIcons.grid),
];

BusinessType businessTypeFor(String? key) {
  return kBusinessTypes.firstWhere(
    (t) => t.key == key,
    orElse: () => kBusinessTypes.first,
  );
}
