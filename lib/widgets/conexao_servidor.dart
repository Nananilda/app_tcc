import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../config/api_config.dart';
import '../state/app_state.dart';
import '../theme/cores.dart';
import 'servidor_dialog.dart';

/// Indicador de conexão exibido na tela de login: mostra se o servidor (e o
/// banco de dados por trás dele) está respondendo e dá acesso ao diálogo
/// "Servidor" para trocar o endereço. Toque no texto para testar de novo.
class ConexaoServidor extends StatefulWidget {
  const ConexaoServidor({super.key});

  @override
  State<ConexaoServidor> createState() => _ConexaoServidorState();
}

class _ConexaoServidorState extends State<ConexaoServidor> {
  StatusServidor? _status; // null = verificando
  int _consulta = 0; // descarta respostas de verificações antigas

  @override
  void initState() {
    super.initState();
    _verificar();
  }

  Future<void> _verificar() async {
    final minha = ++_consulta;
    setState(() => _status = null);
    final status = await context.read<AppState>().verificarServidor();
    if (!mounted || minha != _consulta) return;
    setState(() => _status = status);
  }

  Future<void> _configurar() async {
    final mudou = await mostrarDialogoServidor(context);
    if (mudou && mounted) _verificar();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.cores;
    final verificando = _status == null;
    final ok = _status?.conectado ?? false;
    final cor = verificando ? c.textoFraco : (ok ? c.sucesso : c.erro);
    final servidor =
        Uri.tryParse(ApiConfig.baseUrl)?.authority ?? ApiConfig.baseUrl;
    final texto = verificando
        ? 'Verificando servidor…'
        : ok
        ? 'Conectado a $servidor'
        : 'Servidor indisponível ($servidor)';

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(
          child: Semantics(
            button: true,
            hint: 'Toque para testar novamente',
            child: InkWell(
              onTap: verificando ? null : _verificar,
              borderRadius: BorderRadius.circular(6),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: cor,
                        shape: BoxShape.circle,
                        boxShadow: ok
                            ? [
                                BoxShadow(
                                  color: cor.withValues(alpha: 0.6),
                                  blurRadius: 6,
                                ),
                              ]
                            : null,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        texto,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 12.5, color: c.textoSuave),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        IconButton(
          tooltip: 'Servidor',
          icon: const Icon(Icons.settings_ethernet, size: 18),
          visualDensity: VisualDensity.compact,
          onPressed: _configurar,
        ),
      ],
    );
  }
}
