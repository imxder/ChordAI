/// Confere o endereço do servidor que a pessoa digita nas configurações.
///
/// O áudio vai sem criptografia quando o endereço é http://, então http só
/// vale pra endereços da rede local (o IP do computador no Wi-Fi de casa, ou
/// o nome dele terminado em .local). Pra qualquer outro endereço, só https.
class ServerAddress {
  /// Endereço pronto pra usar (ex.: http://192.168.0.10:5000), ou null se não passou.
  final String? url;

  /// Mensagem pra mostrar quando o endereço não passou.
  final String? error;

  const ServerAddress._({this.url, this.error});

  bool get isValid => url != null;

  static ServerAddress parse(String input) {
    var value = input.trim();
    if (value.isEmpty) {
      return const ServerAddress._(error: 'Informe o endereço do servidor');
    }
    if (!value.contains('://')) value = 'http://$value';
    while (value.endsWith('/')) {
      value = value.substring(0, value.length - 1);
    }

    final uri = Uri.tryParse(value);
    if (uri == null) {
      return const ServerAddress._(error: 'Endereço inválido');
    }
    if (uri.scheme != 'http' && uri.scheme != 'https') {
      return const ServerAddress._(
        error: 'O endereço tem que começar com http:// ou https://',
      );
    }
    if (uri.host.isEmpty) {
      return const ServerAddress._(error: 'Falta o IP ou o nome do computador');
    }
    if (!_validHost(uri.host)) {
      return const ServerAddress._(error: 'IP ou nome do computador inválido');
    }
    if (uri.hasPort && (uri.port < 1 || uri.port > 65535)) {
      return const ServerAddress._(error: 'A porta vai de 1 a 65535');
    }
    if (uri.path.isNotEmpty || uri.hasQuery || uri.hasFragment) {
      return const ServerAddress._(
        error:
            'Use só o IP e a porta, sem nada depois (ex.: 192.168.0.10:5000)',
      );
    }
    if (uri.userInfo.isNotEmpty) {
      return const ServerAddress._(error: 'Endereço inválido');
    }
    if (uri.scheme == 'http' && !isLocalNetworkHost(uri.host)) {
      return const ServerAddress._(
        error:
            'Sem https, só endereço da rede local (ex.: 192.168.0.10:5000 '
            'ou meu-mac.local:5001)',
      );
    }

    final port = uri.hasPort ? ':${uri.port}' : '';
    return ServerAddress._(url: '${uri.scheme}://${uri.host}$port');
  }

  static final _ipv4 = RegExp(r'^\d{1,3}(\.\d{1,3}){3}$');
  static final _hostname = RegExp(
    r'^[a-z0-9]([a-z0-9-]*[a-z0-9])?(\.[a-z0-9]([a-z0-9-]*[a-z0-9])?)*$',
  );

  static bool _validHost(String host) {
    if (_ipv4.hasMatch(host)) {
      return host.split('.').every((p) => int.parse(p) <= 255);
    }
    return _hostname.hasMatch(host);
  }

  /// IPs privados (192.168.x.x, 10.x.x.x, 172.16 a 172.31), o próprio aparelho
  /// (127.x.x.x, localhost) e nomes da rede local (meu-mac.local, ou um nome
  /// sem ponto, como "desktop-casa").
  static bool isLocalNetworkHost(String host) {
    final h = host.toLowerCase();
    if (h == 'localhost' || h.endsWith('.local') || !h.contains('.')) {
      return true;
    }
    if (!_ipv4.hasMatch(h)) return false;
    final p = h.split('.').map(int.parse).toList();
    return p[0] == 10 ||
        p[0] == 127 ||
        (p[0] == 192 && p[1] == 168) ||
        (p[0] == 172 && p[1] >= 16 && p[1] <= 31);
  }
}
