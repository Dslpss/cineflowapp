import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/app_check_service.dart';

/// Widget para mostrar card de atualização disponível
class UpdateCard extends StatelessWidget {
  final AppVersionInfo versionInfo;
  final VoidCallback? onDismiss;
  
  const UpdateCard({
    super.key,
    required this.versionInfo,
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF6C5CE7),
            const Color(0xFF00D9FF),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6C5CE7).withOpacity(0.4),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Ícone
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.system_update_rounded,
              color: Colors.white,
              size: 32,
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Título
          const Text(
            'Nova versão disponível!',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          
          const SizedBox(height: 8),
          
          // Versão
          Text(
            'Versão ${versionInfo.minVersion}',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withOpacity(0.9),
            ),
          ),
          
          const SizedBox(height: 12),
          
          // Mensagem
          if (versionInfo.updateMessage.isNotEmpty)
            Text(
              versionInfo.updateMessage,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.white.withOpacity(0.85),
              ),
            ),
          
          const SizedBox(height: 20),
          
          // Botão de Download
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: () => _launchDownload(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF6C5CE7),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.download_rounded, size: 22),
                  SizedBox(width: 8),
                  Text(
                    'Baixar Atualização',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Botão de fechar (apenas se não for forçado)
          if (!versionInfo.forceUpdate && onDismiss != null)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: TextButton(
                onPressed: onDismiss,
                child: Text(
                  'Mais tarde',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 14,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
  
  Future<void> _launchDownload(BuildContext context) async {
    final url = versionInfo.downloadUrl;
    
    if (url.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('URL de download não disponível'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
      } else {
        throw Exception('Não foi possível abrir o link');
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao abrir download: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

/// Dialog de atualização obrigatória (bloqueia o app)
class ForceUpdateDialog extends StatelessWidget {
  final AppVersionInfo versionInfo;
  
  const ForceUpdateDialog({
    super.key,
    required this.versionInfo,
  });

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false, // Impede fechar o dialog
      child: Dialog(
        backgroundColor: Colors.transparent,
        child: UpdateCard(versionInfo: versionInfo),
      ),
    );
  }
}
