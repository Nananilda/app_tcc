/// Endereço base da API PHP (pasta `api/` do projeto tcc-main).
///
/// IMPORTANTE: este é o endereço do servidor Apache/PHP (não do MySQL).
/// No laboratório os dois costumam rodar na mesma máquina, então o IP
/// abaixo tende a coincidir com o $host de app/config/conexao.php — mas
/// ajuste [baseUrl] sempre que o Apache estiver publicado em outro
/// endereço.
///
/// A pasta `api/` precisa existir dentro do projeto PHP publicado no
/// servidor (junto de app/, includes/, sql/ etc.) — sem ela não há nada
/// para o app conversar e toda chamada aqui falha com erro de conexão.
///
/// - Emulador Android apontando para o PHP rodando no mesmo PC: use
///   "http://10.0.2.2/tcc-main/api".
/// - Dispositivo físico / desktop / web na mesma rede: use o IP da máquina
///   que roda o Apache/PHP, ex.: "http://192.168.0.10/tcc-main/api".
class ApiConfig {
  static const String baseUrl = 'http://10.140.169.12/tcc-main/api';

  static const Duration timeout = Duration(seconds: 12);
}


// Código no flutter: import 'dart:convert';
// import 'package:http/http.dart' as http;

// import 'package:flutter/material.dart';
// import 'package:youwell/main.dart';
// import 'package:youwell/admin.dart';
// import 'package:youwell/gerente.dart';

// void main() {
//   runApp(LoginScreen());
// }

// class LoginScreen extends StatelessWidget {
//   LoginScreen({super.key});

//   final logincontrollerForm = TextEditingController();
//   final senhacontrollerForm = TextEditingController();

//   final _formKey = GlobalKey<FormState>();

//   Future<void> fazerLogin(BuildContext context) async {
//     final response = await http.post(
//       Uri.parse("http://10.140.169.29/entrar_tcc/login.php"),

//       body: {
//         "nome": logincontrollerForm.text,
//         "senha": senhacontrollerForm.text,
//       },
//     );

//     final dados = jsonDecode(response.body);

//     print(dados);

//     if (dados["success"] == true) {
//       if (dados["papel"] == "admin") {
//         Navigator.push(
//           context,
//           MaterialPageRoute(builder: (context) => const AdminScreen()),
//         );
//       } else if (dados["papel"] == "gerente") {
//         Navigator.push(
//           context,
//           MaterialPageRoute(builder: (context) => const GerenteScreen()),
//         );
//       } else {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text("Tipo de usuário não reconhecido")),
//         );
//       }
//     } else {
//       ScaffoldMessenger.of(
//         context,
//       ).showSnackBar(SnackBar(content: Text(dados["mensagem"])));
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: const Color.fromARGB(255, 10, 85, 64),
//       body: SafeArea(
//         child: Center(
//           child: Container(
//             height: 450,
//             width: 350,
//             padding: EdgeInsets.all(5),
//             decoration: BoxDecoration(
//               color: const Color.fromARGB(163, 220, 220, 220),
//               borderRadius: BorderRadius.circular(15),
//             ),
//             child: Padding(
//               padding: EdgeInsets.all(20),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.stretch,
//                 children: [
//                   //   TEXTFORMFIELD COM VALIDAÇÃO
//                   Form(
//                     key: _formKey,
//                     child: Column(
//                       children: [
//                         Text(
//                           "Login:",
//                           style: TextStyle(fontSize: 20, color: Colors.white),
//                         ),

//                         TextFormField(
//                           controller: logincontrollerForm,
//                           decoration: InputDecoration(
//                             labelText: "Nome",
//                             border: OutlineInputBorder(),
//                             filled: true,
//                             fillColor: Color.fromARGB(255, 255, 255, 255),
//                           ),

//                           validator: (value) {
//                             if (value == null || value.isEmpty) {
//                               return "Campo obrigatório";
//                             }
//                             return null;
//                           },
//                         ),

//                         SizedBox(height: 20),

//                         Text(
//                           "Senha:",
//                           style: TextStyle(fontSize: 20, color: Colors.white),
//                         ),

//                         TextFormField(
//                           controller: senhacontrollerForm,
//                           decoration: InputDecoration(
//                             labelText: "Senha",
//                             border: OutlineInputBorder(),
//                             filled: true,
//                             fillColor: Color.fromARGB(255, 255, 255, 255),
//                           ),

//                           validator: (value) {
//                             if (value == null || value.isEmpty) {
//                               return "Campo obrigatório";
//                             }
//                             return null;
//                           },
//                         ),

//                         SizedBox(height: 10),

//                         SizedBox(height: 10),

//                         ElevatedButton(
//                           onPressed: () async {
//                             if (_formKey.currentState!.validate()) {
//                               await fazerLogin(context);
//                             }
//                           },

//                           child: const Text(
//                             "Entrar",
//                             style: TextStyle(fontSize: 16),
//                           ),
//                         ),

//                         SizedBox(height: 30),

//                         ElevatedButton(
//                           onPressed: () {
//                             Navigator.push(
//                               context,
//                               MaterialPageRoute(builder: (context) => MyApp()),
//                             );
//                           },

//                           child: const Text("Voltar"),
//                         ),
//                       ],
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }