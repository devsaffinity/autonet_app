/// A value paired with the label a picker shows for it.
///
/// It lives in `lib/domain/` rather than `lib/view/widget/` so a controller can
/// expose `List<SelectOption<Region>>` without importing the view layer, which
/// §4 forbids.
class SelectOption<T> {
  const SelectOption(this.value, this.label);

  final T value;
  final String label;
}
