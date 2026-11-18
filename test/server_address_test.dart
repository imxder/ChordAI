import 'package:chordai/services/server_address.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('aceita e arruma', () {
    for (final (digitado, esperado) in [
      ('192.168.0.10:5000', 'http://192.168.0.10:5000'),
      ('  192.168.0.10:5000  ', 'http://192.168.0.10:5000'),
      ('http://192.168.0.10:5000/', 'http://192.168.0.10:5000'),
      ('10.0.0.5:5000', 'http://10.0.0.5:5000'),
      ('172.20.1.1:5000', 'http://172.20.1.1:5000'),
      ('localhost:5001', 'http://localhost:5001'),
      ('HTTP://Meu-Mac.Local:5001', 'http://meu-mac.local:5001'),
      ('desktop-casa:5000', 'http://desktop-casa:5000'),
      ('https://chordai.exemplo.com', 'https://chordai.exemplo.com'),
    ]) {
      test(digitado, () {
        final r = ServerAddress.parse(digitado);
        expect(r.isValid, isTrue, reason: r.error);
        expect(r.url, esperado);
      });
    }
  });

  group('recusa com mensagem', () {
    for (final (digitado, mensagem) in [
      ('', 'Informe o endereço do servidor'),
      ('   ', 'Informe o endereço do servidor'),
      (
        'ftp://192.168.0.10',
        'O endereço tem que começar com http:// ou https://',
      ),
      ('http://', 'Falta o IP ou o nome do computador'),
      ('http://:5000', 'Falta o IP ou o nome do computador'),
      ('192.168.0.300:5000', 'IP ou nome do computador inválido'),
      ('meu mac:5000', 'IP ou nome do computador inválido'),
      ('192.168.0.10:99999', 'A porta vai de 1 a 65535'),
      ('192.168.0.10:0', 'A porta vai de 1 a 65535'),
      ('192.168.0.10:abc', 'Endereço inválido'),
      ('usuario:senha@192.168.0.10:5000', 'Endereço inválido'),
    ]) {
      test('"$digitado"', () {
        final r = ServerAddress.parse(digitado);
        expect(r.isValid, isFalse);
        expect(r.url, isNull);
        expect(r.error, mensagem);
      });
    }

    test('caminho depois da porta', () {
      // o app já coloca o /predict_chord no fim
      final r = ServerAddress.parse('192.168.0.10:5000/predict_chord');
      expect(r.isValid, isFalse);
      expect(r.error, startsWith('Use só o IP e a porta'));
    });
  });

  group('http sem criptografia só na rede local', () {
    for (final digitado in [
      '8.8.8.8:5000',
      '172.32.0.1:5000',
      'exemplo.com:5000',
      'http://chordai.exemplo.com',
    ]) {
      test(digitado, () {
        final r = ServerAddress.parse(digitado);
        expect(r.isValid, isFalse);
        expect(r.error, startsWith('Sem https, só endereço da rede local'));
      });
    }

    test('com https o mesmo endereço passa', () {
      expect(ServerAddress.parse('https://8.8.8.8:5000').isValid, isTrue);
    });

    test('faixas de IP privado', () {
      expect(ServerAddress.isLocalNetworkHost('192.168.1.1'), isTrue);
      expect(ServerAddress.isLocalNetworkHost('10.255.0.1'), isTrue);
      expect(ServerAddress.isLocalNetworkHost('172.16.0.1'), isTrue);
      expect(ServerAddress.isLocalNetworkHost('172.31.255.255'), isTrue);
      expect(ServerAddress.isLocalNetworkHost('127.0.0.1'), isTrue);
      expect(ServerAddress.isLocalNetworkHost('172.15.0.1'), isFalse);
      expect(ServerAddress.isLocalNetworkHost('192.169.0.1'), isFalse);
      expect(ServerAddress.isLocalNetworkHost('100.64.0.1'), isFalse);
    });
  });
}
