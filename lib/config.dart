/// Where the HisabKhata API lives. Override at build time with
/// `flutter run --dart-define=API_BASE=http://10.0.2.2:3012/api/v1`.
const String kApiBase = String.fromEnvironment(
  'API_BASE',
  defaultValue: 'https://messhisabkhata.vercel.app/api/v1',
);
