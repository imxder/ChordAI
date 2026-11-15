enum OnDeviceModel {
  v3('v3', 'Só v3', '8 acordes, treinado com o dataset v3'),
  v3Meu(
    'v3_meu',
    'v3 + meu dataset',
    '9 acordes, com o Lá maior, treinado também com as minhas gravações',
  );

  const OnDeviceModel(this.folder, this.label, this.description);

  final String folder;
  final String label;
  final String description;

  String get assetDir => 'assets/models/$folder';
}
