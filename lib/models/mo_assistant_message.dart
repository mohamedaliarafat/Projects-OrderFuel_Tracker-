class MoAssistantMessage {
  MoAssistantMessage({
    required this.id,
    required this.role,
    required this.text,
    required this.createdAt,
    this.suggestions = const <String>[],
  });

  factory MoAssistantMessage.user(String text) {
    return MoAssistantMessage(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      role: 'user',
      text: text,
      createdAt: DateTime.now(),
    );
  }

  factory MoAssistantMessage.assistant(
    String text, {
    List<String> suggestions = const <String>[],
  }) {
    return MoAssistantMessage(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      role: 'assistant',
      text: text,
      createdAt: DateTime.now(),
      suggestions: suggestions,
    );
  }

  final String id;
  final String role;
  final String text;
  final DateTime createdAt;
  final List<String> suggestions;

  Map<String, String> toApiJson() {
    return <String, String>{'role': role, 'content': text};
  }
}
