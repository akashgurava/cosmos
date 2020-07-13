/// A template string similar to python string template.
///
/// in python we can have string like s = '{hello}' and then
/// replace hello variable with value like s.format(hello='world').
/// This class creates the similar functionliaty in dart.
class TemplateString {
  /// Create a template string.
  /// Like - '{host}/api/v3/{container}/{resourceid}'
  TemplateString(String template)
      : fixedComponents = <String>[],
        genericComponents = <int, String>{},
        totalComponents = 0 {
    final components = template.split('{');

    for (final component in components) {
      if (component == '') {
        // If the template starts with "{", skip the first element.
        continue;
      }

      final split = component.split('}');

      if (split.length != 1) {
        // The condition allows for template strings without parameters.
        genericComponents[totalComponents] = split.first;
        totalComponents++;
      }

      if (split.last != '') {
        fixedComponents.add(split.last);
        totalComponents++;
      }
    }
  }

  /// Actual string in the template
  final List<String> fixedComponents;

  /// The components which will get replaced using .format
  final Map<int, String> genericComponents;

  /// Total string components in the template
  int totalComponents;

  /// Format a [TemplateString] into normal string
  /// by replacing variables between '{' and '}'
  String format(Map<String, dynamic> params) {
    // Check if all the variables are passed in params
    final stringVariables = genericComponents.values.toSet();
    final check = params.keys.toSet().containsAll(stringVariables);

    if (!check) {
      final missing = stringVariables.difference(params.keys.toSet());
      throw FormatException(
        'Not all variables in template present in params. Missing: $missing',
      );
    }

    final result = StringBuffer();

    var fixedComponent = 0;
    for (var i = 0; i < totalComponents; i++) {
      if (genericComponents.containsKey(i)) {
        result.write(params[genericComponents[i]]);
        continue;
      }
      result.write(fixedComponents[fixedComponent++]);
    }

    return result.toString();
  }
}
