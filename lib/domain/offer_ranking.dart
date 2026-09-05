/// Badge selection for a list of offers.
///
/// Each function returns a SINGLE index — first wins on a tie — so 'two Lowest
/// badges rendered at once' is structurally impossible rather than merely
/// unlikely.
library;

import 'package:autonect/data/models/offer.dart';

/// Index of the cheapest offer, or null for an empty list.
int? lowestPriceOfferIndex(List<Offer> offers) {
  int? best;
  for (var i = 0; i < offers.length; i++) {
    if (best == null || offers[i].pricePence < offers[best].pricePence) best = i;
  }
  return best;
}

/// Index of the offer with the fewest delivery days, or null when the list is
/// empty or no offer states a delivery time.
///
/// A null `deliveryTimeDays` never wins: 'unstated' is not 'instant'.
int? fastestOfferIndex(List<Offer> offers) {
  int? best;
  int? bestDays;
  for (var i = 0; i < offers.length; i++) {
    final days = offers[i].deliveryTimeDays;
    if (days == null) continue;
    if (bestDays == null || days < bestDays) {
      best = i;
      bestDays = days;
    }
  }
  return best;
}
