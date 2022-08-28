extension IterableCheckSetOverLay on Iterable {
  bool checkOverlay(Iterable<dynamic> other) {
    for (var value in other) {
      if (this.contains(value)) {
        return true;
      }
    }
    //I think with the first is sufficient, but for maybe
    for (var value in this) {
      if (other.contains(value)) {
        return true;
      }
    }

    return false;
  }
}