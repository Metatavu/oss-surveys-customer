///
/// Use this file to define extension methods on existing Dart types.
///

/// Extension method for List<T> to filter the list by given [test] function.
extension ListFilter<T> on List<T> {
  /// Filters the list by given [test] function.
  ///
  /// Returns a new list containing only the elements that satisfy the given [test].
  List<T> filter(bool Function(T) test) {
    List<T> result = [];
    for (T element in this) {
      if (test(element)) {
        result.add(element);
      }
    }

    return result;
  }
}
