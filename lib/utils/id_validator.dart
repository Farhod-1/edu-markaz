class IdValidator {
  /// MongoDB ObjectId is a 24-character hexadecimal string
  static final RegExp _objectIdRegex = RegExp(r'^[0-9a-fA-F]{24}$');

  /// Validates if a string is a valid MongoDB ObjectId
  static bool isValidObjectId(String? id) {
    if (id == null || id.isEmpty) return false;
    return _objectIdRegex.hasMatch(id);
  }

  /// Cleans and validates an ID, returns null if invalid
  static String? cleanId(String? id) {
    if (id == null || id.isEmpty) return null;
    final cleaned = id.trim();
    if (isValidObjectId(cleaned)) return cleaned;
    return null;
  }

  /// Validates and throws an exception if the ID is invalid
  static String validateAndThrow(String? id, String fieldName) {
    final cleaned = cleanId(id);
    if (cleaned == null) {
      throw ArgumentError(
          'Invalid $fieldName: must be a 24-character MongoDB ObjectId');
    }
    return cleaned;
  }
}
