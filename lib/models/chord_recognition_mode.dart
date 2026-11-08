enum ChordRecognitionMode {
  server('Servidor', 'Reconhece pelo computador na mesma rede (ou Tailscale)'),
  onDevice('No aparelho', 'Reconhece direto no celular, sem precisar de servidor');

  const ChordRecognitionMode(this.label, this.description);

  final String label;
  final String description;
}
