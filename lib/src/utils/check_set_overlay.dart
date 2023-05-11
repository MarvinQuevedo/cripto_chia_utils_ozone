extension IterableCheckSetOverLay on Iterable {
  bool checkOverlay(Iterable<dynamic> other) {
    for (final value in other) {
      if (contains(value)) {
        return true;
      }
    }
    //I think with the first is sufficient, but for maybe
    for (final value in this) {
      if (other.contains(value)) {
        return true;
      }
    }

    return false;
  }
}
