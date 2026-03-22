class MoAssistantRouteContext {
  const MoAssistantRouteContext({
    required this.route,
    required this.title,
    required this.section,
    required this.summary,
    this.availableActions = const <String>[],
    this.keywords = const <String>[],
  });

  final String route;
  final String title;
  final String section;
  final String summary;
  final List<String> availableActions;
  final List<String> keywords;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'route': route,
      'title': title,
      'section': section,
      'summary': summary,
      'availableActions': availableActions,
      'keywords': keywords,
    };
  }
}
