enum ChordRecognitionMode {
  onDevice('No aparelho', 'Reconhece direto no celular, sem internet nem computador'),
  server('Servidor', 'Avançado: precisa de um computador na mesma rede rodando o ChordAI-backend');

  const ChordRecognitionMode(this.label, this.description);

  final String label;
  final String description;
}
