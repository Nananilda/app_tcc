import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../config/api_config.dart';
import '../state/app_state.dart';
import '../theme/cores.dart';
import 'feedback_box.dart';

/// Abre o diálogo "Servidor", onde o endereço da API pode ser trocado sem
/// recompilar o app (no laboratório o IP do servidor muda a cada aula).
/// Devolve true se um novo endereço foi salvo.
Future<bool> mostrarDialogoServidor(BuildContext context) async {
  final salvou = await showDialog<bool>(
    context: context,
    builder: (_) => const _ServidorDialog(),
  );
  return salvou ?? false;
}

class _ServidorDialog extends StatefulWidget {
  const _ServidorDialog();

  @override
  State<_ServidorDialog> createState() => _ServidorDialogState();
}

class _ServidorDialogState extends State<_ServidorDialog> {
  late final TextEditingController _ctrl = TextEditingController(
    text: ApiConfig.baseUrl,
  );
  bool _testando = false;
  StatusServidor? _resultado;
  String? _erroCampo;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _testar() async {
    if (!ApiConfig.urlValida(_ctrl.text)) {
      setState(
        () => _erroCampo =
            'Informe um endereço válido, ex.: http://192.168.0.10/tcc/api',
      );
      return;
    }
    setState(() {
      _erroCampo = null;
      _testando = true;
      _resultado = null;
    });
    final status = await context.read<AppState>().testarEndereco(_ctrl.text);
    if (!mounted) return;
    setState(() {
      _testando = false;
      _resultado = status;
    });
  }

  Future<void> _salvar() async {
    if (!ApiConfig.urlValida(_ctrl.text)) {
      setState(
        () => _erroCampo =
            'Informe um endereço válido, ex.: http://192.168.0.10/tcc/api',
      );
      return;
    }
    await ApiConfig.salvar(_ctrl.text);
    if (mounted) Navigator.of(context).pop(true);
  }

  Future<void> _restaurar() async {
    await ApiConfig.restaurarPadrao();
    if (mounted) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.cores;
    return AlertDialog(
      title: const Text('Servidor'),
      content: SizedBox(
        width: 460,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Endereço da API do sistema ÁKRON (a pasta "api" do projeto web). '
                'Use o IP do computador que roda o Apache/PHP.',
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _ctrl,
                keyboardType: TextInputType.url,
                autocorrect: false,
                decoration: InputDecoration(
                  labelText: 'Endereço da API',
                  hintText: 'http://192.168.0.10/tcc/api',
                  errorText: _erroCampo,
                ),
                onSubmitted: (_) => _testar(),
              ),
              const SizedBox(height: 12),
              if (_testando)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 6),
                  child: LinearProgressIndicator(minHeight: 2),
                ),
              if (_resultado != null)
                _resultado!.conectado
                    ? FeedbackBox.sucesso(_resultado!.mensagem)
                    : FeedbackBox.erros([_resultado!.mensagem]),
              Text(
                'Padrão desta plataforma: ${ApiConfig.padrao}',
                style: TextStyle(fontSize: 12, color: c.textoFraco),
              ),
            ],
          ),
        ),
      ),
      actionsOverflowButtonSpacing: 8,
      actions: [
        TextButton(
          onPressed: _restaurar,
          child: const Text('Restaurar padrão'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancelar'),
        ),
        OutlinedButton(
          onPressed: _testando ? null : _testar,
          child: const Text('Testar'),
        ),
        ElevatedButton(onPressed: _salvar, child: const Text('Salvar')),
      ],
    );
  }
}
