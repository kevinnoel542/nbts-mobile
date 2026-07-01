enum SocialAuthProvider {
  google('Google', 'google.com'),
  apple('Apple', 'apple.com');

  const SocialAuthProvider(this.label, this.firebaseProviderId);

  final String label;
  final String firebaseProviderId;
}
