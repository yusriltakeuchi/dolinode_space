/// Enum provider type
enum Providers {
  dospace,
  linodeobject,
}

class DoLinodeCofig {
  /// Get base host based on provider
  static String baseHost(Providers provider) {
    switch (provider) {
      case Providers.dospace:
        return "digitaloceanspaces.com";
      case Providers.linodeobject:
        return "linodeobjects.com";
    }
  }

}