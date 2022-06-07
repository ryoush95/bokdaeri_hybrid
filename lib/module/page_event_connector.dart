class PageEventConnector {
  static final PageEventConnector _instance = PageEventConnector.instance();
  factory PageEventConnector() => _instance;
  PageEventConnector.instance();

  late Function _foregroundFirebaseMessageHandler;
  late Function _backgroundFirebaseMessageHandler;

  set foregroundFirebaseMessageHandler(Function function) =>
      _foregroundFirebaseMessageHandler = function;

  set backgroundFirebaseMessageHandler(Function function) =>
      _backgroundFirebaseMessageHandler = function;

  get onForegroundFirebaseMessage => _foregroundFirebaseMessageHandler;

  get onBackgroundFirebaseMessage => _backgroundFirebaseMessageHandler;
}
