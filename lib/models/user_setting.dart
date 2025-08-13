class UserSetting {
  final int credentialId;
  final bool isSelected;
  final bool hasError;

  UserSetting({
    required this.credentialId,
    required this.isSelected,
    this.hasError = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'credential_id': credentialId,
      'is_selected': isSelected ? 1 : 0,
      'error': hasError ? 1 : 0,
    };
  }

  factory UserSetting.fromMap(Map<String, dynamic> map) {
    return UserSetting(
      credentialId: map['credential_id'],
      isSelected: map['is_selected'] == 1,
      hasError: map['error'] == 1,
    );
  }
}
