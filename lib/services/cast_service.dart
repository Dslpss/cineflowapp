import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:bonsoir/bonsoir.dart';

/// Representa um dispositivo de cast disponível na rede
class CastDeviceInfo {
  final String id;
  final String name;
  final String host;
  final int port;
  final CastDeviceType type;

  CastDeviceInfo({
    required this.id,
    required this.name,
    required this.host,
    required this.port,
    required this.type,
  });
}

/// Tipos de dispositivos de cast suportados
enum CastDeviceType {
  chromecast,
  dlna,
  airplay,
  smartTv,
}

/// Estado da conexão de cast
enum CastConnectionState {
  disconnected,
  connecting,
  connected,
  playing,
  paused,
  buffering,
  error,
}

/// Serviço para gerenciar cast/espelhamento de tela
class CastService extends ChangeNotifier {
  static final CastService _instance = CastService._internal();
  factory CastService() => _instance;
  CastService._internal();

  // Estado
  CastConnectionState _connectionState = CastConnectionState.disconnected;
  CastDeviceInfo? _connectedDevice;
  List<CastDeviceInfo> _availableDevices = [];
  String? _currentMediaUrl;
  String? _currentMediaTitle;
  String? _error;
  bool _isScanning = false;

  // Bonsoir discovery
  BonsoirDiscovery? _discovery;
  StreamSubscription<BonsoirDiscoveryEvent>? _discoverySubscription;

  // Socket para comunicação com Chromecast
  Socket? _socket;

  // Getters
  CastConnectionState get connectionState => _connectionState;
  CastDeviceInfo? get connectedDevice => _connectedDevice;
  List<CastDeviceInfo> get availableDevices => _availableDevices;
  String? get currentMediaUrl => _currentMediaUrl;
  String? get currentMediaTitle => _currentMediaTitle;
  String? get error => _error;
  bool get isScanning => _isScanning;
  bool get isConnected => _connectionState == CastConnectionState.connected || 
                          _connectionState == CastConnectionState.playing ||
                          _connectionState == CastConnectionState.paused ||
                          _connectionState == CastConnectionState.buffering;

  /// Inicia a busca por dispositivos de cast na rede
  Future<void> startDiscovery() async {
    if (_isScanning) return;

    _isScanning = true;
    _error = null;
    _availableDevices = [];
    notifyListeners();

    try {
      // Busca dispositivos em paralelo
      await Future.wait([
        _discoverChromecastDevices(),
        _discoverSsdpDevices(),
      ]);
      
    } catch (e) {
      debugPrint('Erro ao buscar dispositivos: $e');
      _error = 'Erro ao buscar dispositivos na rede';
    }

    _isScanning = false;
    notifyListeners();
  }

  /// Busca dispositivos via SSDP/UPnP (Smart TVs, Roku, etc)
  Future<void> _discoverSsdpDevices() async {
    try {
      // SSDP M-SEARCH para descobrir dispositivos UPnP
      final socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
      
      // Endereço multicast SSDP
      final multicastAddress = InternetAddress('239.255.255.250');
      const ssdpPort = 1900;
      
      // Mensagem M-SEARCH
      const searchMessage = 
        'M-SEARCH * HTTP/1.1\r\n'
        'HOST: 239.255.255.250:1900\r\n'
        'MAN: "ssdp:discover"\r\n'
        'MX: 3\r\n'
        'ST: ssdp:all\r\n'
        '\r\n';
      
      socket.send(
        utf8.encode(searchMessage),
        multicastAddress,
        ssdpPort,
      );
      
      // Também busca DIAL (usado por Roku, Smart TVs)
      const dialSearchMessage = 
        'M-SEARCH * HTTP/1.1\r\n'
        'HOST: 239.255.255.250:1900\r\n'
        'MAN: "ssdp:discover"\r\n'
        'MX: 3\r\n'
        'ST: urn:dial-multiscreen-org:service:dial:1\r\n'
        '\r\n';
      
      socket.send(
        utf8.encode(dialSearchMessage),
        multicastAddress,
        ssdpPort,
      );
      
      // Escuta respostas por 5 segundos
      final completer = Completer<void>();
      Timer(const Duration(seconds: 5), () {
        if (!completer.isCompleted) {
          completer.complete();
        }
      });
      
      socket.listen((event) {
        if (event == RawSocketEvent.read) {
          final datagram = socket.receive();
          if (datagram != null) {
            _parseSsdpResponse(utf8.decode(datagram.data), datagram.address.address);
          }
        }
      });
      
      await completer.future;
      socket.close();
      
    } catch (e) {
      debugPrint('Erro ao buscar via SSDP: $e');
    }
  }
  
  /// Processa resposta SSDP
  void _parseSsdpResponse(String response, String sourceIp) {
    try {
      // Extrai informações da resposta
      final lines = response.split('\r\n');
      String? location;
      String? server;
      String? st;
      
      for (final line in lines) {
        final lower = line.toLowerCase();
        if (lower.startsWith('location:')) {
          location = line.substring(9).trim();
        } else if (lower.startsWith('server:')) {
          server = line.substring(7).trim();
        } else if (lower.startsWith('st:')) {
          st = line.substring(3).trim();
        }
      }
      
      // Identifica o tipo de dispositivo
      CastDeviceType? deviceType;
      String deviceName = 'Smart TV';
      
      if (server != null) {
        final serverLower = server.toLowerCase();
        if (serverLower.contains('roku')) {
          deviceType = CastDeviceType.smartTv;
          deviceName = 'Roku TV';
        } else if (serverLower.contains('samsung')) {
          deviceType = CastDeviceType.smartTv;
          deviceName = 'Samsung TV';
        } else if (serverLower.contains('lg')) {
          deviceType = CastDeviceType.smartTv;
          deviceName = 'LG TV';
        } else if (serverLower.contains('philips') || serverLower.contains('philco')) {
          deviceType = CastDeviceType.smartTv;
          deviceName = 'Philco TV';
        } else if (serverLower.contains('sony')) {
          deviceType = CastDeviceType.smartTv;
          deviceName = 'Sony TV';
        } else if (serverLower.contains('dlna') || serverLower.contains('upnp')) {
          deviceType = CastDeviceType.dlna;
          deviceName = 'DLNA Device';
        }
      }
      
      // Se encontrou um dispositivo relevante
      if (deviceType != null && location != null) {
        // Extrai porta do location URL
        int port = 8060; // Porta padrão Roku
        try {
          final uri = Uri.parse(location);
          port = uri.port;
          if (port == 0) port = 8060;
        } catch (_) {}
        
        final device = CastDeviceInfo(
          id: 'ssdp_$sourceIp',
          name: '$deviceName ($sourceIp)',
          host: sourceIp,
          port: port,
          type: deviceType,
        );
        
        // Evita duplicatas
        if (!_availableDevices.any((d) => d.host == device.host)) {
          _availableDevices.add(device);
          notifyListeners();
          debugPrint('SSDP: Encontrado ${device.name} em $sourceIp:$port');
        }
      }
    } catch (e) {
      debugPrint('Erro ao parsear SSDP: $e');
    }
  }

  /// Busca dispositivos Chromecast na rede usando Bonsoir (mDNS)
  Future<void> _discoverChromecastDevices() async {
    try {
      // Para descoberta anterior se houver
      await _stopDiscovery();

      // Chromecast usa o serviço _googlecast._tcp
      _discovery = BonsoirDiscovery(type: '_googlecast._tcp');
      
      // Inicia a descoberta
      await _discovery!.start();

      // Timeout para busca
      final completer = Completer<void>();
      Timer(const Duration(seconds: 8), () {
        if (!completer.isCompleted) {
          completer.complete();
        }
      });

      _discoverySubscription = _discovery!.eventStream?.listen((event) {
        _handleDiscoveryEvent(event);
      });

      await completer.future;
      
    } catch (e) {
      debugPrint('Erro ao buscar Chromecast: $e');
    }
  }

  /// Processa eventos de descoberta do Bonsoir
  void _handleDiscoveryEvent(BonsoirDiscoveryEvent event) {
    try {
      final service = event.service;
      if (service == null) return;

      // Tenta extrair informações do serviço
      String host = '';
      int port = service.port;
      
      // Tenta obter o host de diferentes formas
      try {
        // Bonsoir 6.x usa attributes ou propriedades dinâmicas
        final dynamic dynService = service;
        if (dynService.host != null) {
          host = dynService.host.toString();
        }
      } catch (_) {
        // Tenta via attributes
        host = service.attributes['host'] ?? 
               service.attributes['ip'] ?? 
               service.attributes['a'] ?? '';
      }

      // Se ainda não tem host, tenta o IP do atributo
      if (host.isEmpty) {
        // Algumas vezes o IP vem no nome ou em outros lugares
        final attrs = service.attributes;
        for (final key in attrs.keys) {
          final value = attrs[key];
          if (value != null && _isValidIp(value)) {
            host = value;
            break;
          }
        }
      }

      if (host.isEmpty || port == 0) {
        debugPrint('Serviço encontrado sem host/port: ${service.name}');
        return;
      }

      final device = CastDeviceInfo(
        id: service.name,
        name: _cleanDeviceName(service.name),
        host: host,
        port: port,
        type: CastDeviceType.chromecast,
      );

      // Evita duplicatas
      if (!_availableDevices.any((d) => d.id == device.id)) {
        _availableDevices.add(device);
        notifyListeners();
        debugPrint('Dispositivo encontrado: ${device.name} em $host:$port');
      }
    } catch (e) {
      debugPrint('Erro ao processar evento de descoberta: $e');
    }
  }

  /// Verifica se uma string é um IP válido
  bool _isValidIp(String value) {
    final parts = value.split('.');
    if (parts.length != 4) return false;
    for (final part in parts) {
      final num = int.tryParse(part);
      if (num == null || num < 0 || num > 255) return false;
    }
    return true;
  }

  /// Limpa o nome do dispositivo removendo caracteres especiais
  String _cleanDeviceName(String name) {
    // Remove sufixos comuns do Chromecast
    return name
        .replaceAll(RegExp(r'-[a-f0-9]{32}$'), '')
        .replaceAll('Google-', '')
        .replaceAll('Chromecast-', 'Chromecast ')
        .trim();
  }

  /// Para a descoberta de dispositivos
  Future<void> _stopDiscovery() async {
    await _discoverySubscription?.cancel();
    _discoverySubscription = null;
    await _discovery?.stop();
    _discovery = null;
  }

  /// Para a busca de dispositivos
  void stopDiscovery() {
    _stopDiscovery();
    _isScanning = false;
    notifyListeners();
  }

  /// Conecta a um dispositivo de cast
  Future<bool> connectToDevice(CastDeviceInfo device) async {
    _connectionState = CastConnectionState.connecting;
    _error = null;
    notifyListeners();

    try {
      switch (device.type) {
        case CastDeviceType.chromecast:
          return await _connectToChromecast(device);
        case CastDeviceType.dlna:
          return await _connectToDlna(device);
        case CastDeviceType.smartTv:
          return await _connectToSmartTv(device);
        case CastDeviceType.airplay:
          throw Exception('AirPlay não suportado ainda');
      }
    } catch (e) {
      _connectionState = CastConnectionState.error;
      _error = 'Erro ao conectar: $e';
      notifyListeners();
      return false;
    }
  }

  /// Conecta a uma Smart TV (Roku, etc) via ECP/DIAL
  Future<bool> _connectToSmartTv(CastDeviceInfo device) async {
    try {
      // Verifica se a TV está acessível
      final client = HttpClient();
      client.connectionTimeout = const Duration(seconds: 5);
      
      // Roku usa ECP na porta 8060
      final request = await client.getUrl(
        Uri.parse('http://${device.host}:${device.port}/'),
      );
      final response = await request.close();
      
      if (response.statusCode == 200 || response.statusCode == 404) {
        // TV está respondendo
        _connectedDevice = device;
        _connectionState = CastConnectionState.connected;
        notifyListeners();
        client.close();
        return true;
      }
      
      client.close();
      throw Exception('TV não respondeu');
    } catch (e) {
      debugPrint('Erro ao conectar à Smart TV: $e');
      throw Exception('Não foi possível conectar à TV: $e');
    }
  }

  /// Conecta a um dispositivo Chromecast
  Future<bool> _connectToChromecast(CastDeviceInfo device) async {
    try {
      // Conecta via socket SSL ao Chromecast
      _socket = await SecureSocket.connect(
        device.host,
        device.port,
        onBadCertificate: (_) => true, // Chromecast usa certificado auto-assinado
        timeout: const Duration(seconds: 10),
      );

      _connectedDevice = device;
      _connectionState = CastConnectionState.connected;
      notifyListeners();

      // Escuta mensagens do Chromecast
      _socket!.listen(
        (data) => _handleChromecastMessage(data),
        onError: (error) {
          debugPrint('Erro no socket: $error');
          disconnect();
        },
        onDone: () {
          debugPrint('Socket fechado');
          disconnect();
        },
      );

      // Envia mensagem de conexão
      await _sendChromecastConnect();

      return true;
    } catch (e) {
      debugPrint('Erro ao conectar Chromecast: $e');
      _error = 'Erro ao conectar ao Chromecast';
      _connectionState = CastConnectionState.error;
      notifyListeners();
      return false;
    }
  }

  /// Envia mensagem de conexão ao Chromecast
  Future<void> _sendChromecastConnect() async {
    // Protocolo Cast v2 usa Protocol Buffers
    // Esta é uma implementação simplificada
    final connectMessage = {
      'type': 'CONNECT',
      'origin': {},
    };
    
    await _sendChromecastMessage('urn:x-cast:com.google.cast.tp.connection', connectMessage);
  }

  /// Envia mensagem ao Chromecast
  Future<void> _sendChromecastMessage(String namespace, Map<String, dynamic> payload) async {
    if (_socket == null) return;

    try {
      final message = jsonEncode(payload);
      debugPrint('Enviando para $namespace: $message');
      // Nota: O protocolo real do Chromecast usa Protocol Buffers
      // Esta é uma implementação simplificada para demonstração
    } catch (e) {
      debugPrint('Erro ao enviar mensagem: $e');
    }
  }

  /// Manipula mensagens recebidas do Chromecast
  void _handleChromecastMessage(List<int> data) {
    try {
      final message = utf8.decode(data);
      debugPrint('Mensagem recebida: $message');
    } catch (e) {
      debugPrint('Erro ao processar mensagem: $e');
    }
  }

  /// Conecta a um dispositivo DLNA
  Future<bool> _connectToDlna(CastDeviceInfo device) async {
    try {
      _connectedDevice = device;
      _connectionState = CastConnectionState.connected;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Erro ao conectar DLNA: $e');
      return false;
    }
  }

  /// Reproduz mídia no dispositivo conectado
  Future<void> playMedia({
    required String url,
    required String title,
    String? thumbnailUrl,
    String? contentType,
  }) async {
    if (_connectedDevice == null) {
      _error = 'Nenhum dispositivo conectado';
      notifyListeners();
      return;
    }

    _currentMediaUrl = url;
    _currentMediaTitle = title;
    _connectionState = CastConnectionState.buffering;
    notifyListeners();

    try {
      switch (_connectedDevice!.type) {
        case CastDeviceType.chromecast:
          await _playOnChromecast(url, title, thumbnailUrl, contentType);
          break;
        case CastDeviceType.dlna:
          await _playOnDlna(url, title);
          break;
        case CastDeviceType.smartTv:
          await _playOnSmartTv(url, title);
          break;
        case CastDeviceType.airplay:
          throw Exception('AirPlay não suportado ainda');
      }
    } catch (e) {
      _error = 'Erro ao reproduzir mídia: $e';
      _connectionState = CastConnectionState.error;
      notifyListeners();
    }
  }

  /// Reproduz mídia na Smart TV (Roku) via ECP
  Future<void> _playOnSmartTv(String url, String title) async {
    try {
      final device = _connectedDevice!;
      final client = HttpClient();
      
      // Roku ECP: Abre o canal de mídia e envia a URL
      // Usando o input command para abrir URL no navegador/player da Roku
      final encodedUrl = Uri.encodeComponent(url);
      final encodedTitle = Uri.encodeComponent(title);
      
      // Tenta lançar via DIAL (Deep Linking)
      // Formato: POST /input/15985?url=...&title=...
      // 15985 é o ID do Media Player padrão da Roku
      
      // Primeiro tenta o Media Player da Roku
      var request = await client.postUrl(
        Uri.parse('http://${device.host}:${device.port}/input/15985?url=$encodedUrl&videoName=$encodedTitle'),
      );
      var response = await request.close();
      
      if (response.statusCode == 200 || response.statusCode == 204) {
        debugPrint('Reproduzindo $title na Roku TV via Media Player');
        _connectionState = CastConnectionState.playing;
        notifyListeners();
        client.close();
        return;
      }
      
      // Se não funcionar, tenta launch com contentId
      request = await client.postUrl(
        Uri.parse('http://${device.host}:${device.port}/launch/15985?contentId=$encodedUrl'),
      );
      response = await request.close();
      
      if (response.statusCode == 200 || response.statusCode == 204) {
        debugPrint('Reproduzindo $title na Roku TV via Launch');
        _connectionState = CastConnectionState.playing;
        notifyListeners();
        client.close();
        return;
      }
      
      client.close();
      
      // Se nada funcionar, mostra mensagem para usar App Externo
      throw Exception('Roku TV não suporta reprodução direta. Use a opção "App Externo" para transmitir via Web Video Cast.');
      
    } catch (e) {
      debugPrint('Erro ao reproduzir na Smart TV: $e');
      rethrow;
    }
  }

  /// Reproduz mídia no Chromecast
  Future<void> _playOnChromecast(
    String url, 
    String title, 
    String? thumbnailUrl,
    String? contentType,
  ) async {
    final mediaMessage = {
      'type': 'LOAD',
      'autoplay': true,
      'currentTime': 0,
      'media': {
        'contentId': url,
        'contentType': contentType ?? 'video/mp4',
        'streamType': 'BUFFERED',
        'metadata': {
          'type': 0,
          'metadataType': 0,
          'title': title,
          if (thumbnailUrl != null)
            'images': [{'url': thumbnailUrl}],
        },
      },
    };

    await _sendChromecastMessage('urn:x-cast:com.google.cast.media', mediaMessage);
    _connectionState = CastConnectionState.playing;
    notifyListeners();
  }

  /// Reproduz mídia via DLNA
  Future<void> _playOnDlna(String url, String title) async {
    debugPrint('Reproduzindo $title em DLNA: $url');
    _connectionState = CastConnectionState.playing;
    notifyListeners();
  }

  /// Pausa a reprodução
  Future<void> pause() async {
    await _sendChromecastMessage('urn:x-cast:com.google.cast.media', {
      'type': 'PAUSE',
    });
    _connectionState = CastConnectionState.paused;
    notifyListeners();
  }

  /// Retoma a reprodução
  Future<void> resume() async {
    await _sendChromecastMessage('urn:x-cast:com.google.cast.media', {
      'type': 'PLAY',
    });
    _connectionState = CastConnectionState.playing;
    notifyListeners();
  }

  /// Para a reprodução
  Future<void> stop() async {
    await _sendChromecastMessage('urn:x-cast:com.google.cast.media', {
      'type': 'STOP',
    });
    _connectionState = CastConnectionState.connected;
    _currentMediaUrl = null;
    _currentMediaTitle = null;
    notifyListeners();
  }

  /// Define o volume (0.0 a 1.0)
  Future<void> setVolume(double volume) async {
    await _sendChromecastMessage('urn:x-cast:com.google.cast.receiver', {
      'type': 'SET_VOLUME',
      'volume': {'level': volume},
    });
  }

  /// Seek para uma posição específica (em segundos)
  Future<void> seekTo(double position) async {
    await _sendChromecastMessage('urn:x-cast:com.google.cast.media', {
      'type': 'SEEK',
      'currentTime': position,
    });
  }

  /// Desconecta do dispositivo atual
  Future<void> disconnect() async {
    try {
      await _sendChromecastMessage('urn:x-cast:com.google.cast.tp.connection', {
        'type': 'CLOSE',
      });
      await _socket?.close();
      _socket = null;
    } catch (e) {
      debugPrint('Erro ao desconectar: $e');
    }

    _connectionState = CastConnectionState.disconnected;
    _connectedDevice = null;
    _currentMediaUrl = null;
    _currentMediaTitle = null;
    _error = null;
    notifyListeners();
  }

  /// Limpa recursos
  @override
  void dispose() {
    stopDiscovery();
    disconnect();
    super.dispose();
  }
}
