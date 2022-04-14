class PageEventConnector {
  static final PageEventConnector _instance = PageEventConnector.instance();
  factory PageEventConnector() => _instance;
  PageEventConnector.instance();

  late Function _foregroundFirebaseMessageHandler;

  set foregroundFirebaseMessageHandler(Function function) =>
      _foregroundFirebaseMessageHandler = function;

  get onForegroundFirebaseMessage => _foregroundFirebaseMessageHandler;
}
