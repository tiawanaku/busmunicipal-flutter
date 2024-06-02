import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(
    ChangeNotifierProvider(
      create: (context) => TicketCounter(),
      child: MyApp(),
    ),
  );
}

class TicketCounter extends ChangeNotifier {
  int regularTickets = 0;
  int specialTickets = 0;
  double totalRegularBs = 0;
  double totalSpecialBs = 0;
  List<Ticket> tickets = [];

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  void addTicket(String code) async {
    final dateTime = DateTime.now();
    final formattedDate = '${dateTime.toIso8601String().substring(0, 10)} ${dateTime.toIso8601String().substring(11, 19)}';
    double cost;

    if (code == 'f737582ebb30') {
      cost = 1;
      specialTickets++;
    } else {
      cost = 1.5;
      regularTickets++;
    }

    final ticket = Ticket(
      number: regularTickets + specialTickets,
      code: code,
      dateTime: formattedDate,
      cost: cost,
    );

    tickets.add(ticket);

    totalRegularBs = regularTickets * 1.5;
    totalSpecialBs = specialTickets * 1;

    // Guardar en Firestore
    await _firestore.collection('tickets').add(ticket.toMap());

    notifyListeners();
  }

  void resetCounters() async {
    regularTickets = 0;
    specialTickets = 0;
    totalRegularBs = 0;
    totalSpecialBs = 0;
    tickets.clear();

    // Borrar todos los tickets en Firestore
    final snapshot = await _firestore.collection('tickets').get();
    for (var doc in snapshot.docs) {
      await doc.reference.delete();
    }

    notifyListeners();
  }
}

class Ticket {
  final int number;
  final String code;
  final String dateTime;
  final double cost;

  Ticket({
    required this.number,
    required this.code,
    required this.dateTime,
    required this.cost,
  });

  Map<String, dynamic> toMap() {
    return {
      'number': number,
      'code': code,
      'dateTime': dateTime,
      'cost': cost,
    };
  }
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: TicketCounterScreen(),
    );
  }
}

class TicketCounterScreen extends StatelessWidget {
  final TextEditingController _barcodeController = TextEditingController();
  final FocusNode _barcodeFocusNode = FocusNode(); // Agregar esta línea

  void _showPaseDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        Future.delayed(Duration(seconds: 2), () {
          Navigator.of(context).pop();
          _barcodeFocusNode.requestFocus(); // Enfocar el TextField
        });
        return AlertDialog(
          title: Text('Notificación'),
          content: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FaIcon(FontAwesomeIcons.checkCircle, color: Colors.green, size: 48),
              SizedBox(width: 10),
              Text(
                'PASE',
                style: TextStyle(fontSize: 24, color: Colors.green),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Contador de Boletos'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              focusNode: _barcodeFocusNode, // Asignar el focusNode
              controller: _barcodeController,
              decoration: InputDecoration(
                labelText: 'Código de Boleto',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ElevatedButton(
                  onPressed: () {
                    if (_barcodeController.text.isNotEmpty) {
                      Provider.of<TicketCounter>(context, listen: false)
                          .addTicket(_barcodeController.text);
                      _showPaseDialog(context); // Mostrar el diálogo
                      FocusScope.of(context).unfocus(); // Ocultar el teclado
                      _barcodeController.clear();
                    }
                  },
                  child: Text('Agregar'),
                ),
                ElevatedButton(
                  onPressed: () {
                    Provider.of<TicketCounter>(context, listen: false).resetCounters();
                  },
                  child: Text('Reiniciar'),
                ),
              ],
            ),
            SizedBox(height: 20),
            Expanded(
              child: TicketList(),
            ),
            TicketSummary(),
          ],
        ),
      ),
    );
  }
}

class TicketList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<TicketCounter>(
      builder: (context, ticketCounter, child) {
        return ListView.builder(
          itemCount: ticketCounter.tickets.length,
          itemBuilder: (context, index) {
            final ticket = ticketCounter.tickets[index];
            return ListTile(
              title: Text('${ticket.number}. ${ticket.code}'),
              subtitle: Text('${ticket.dateTime} - ${ticket.cost} Bs'),
            );
          },
        );
      },
    );
  }
}

class TicketSummary extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<TicketCounter>(
      builder: (context, ticketCounter, child) {
        return Column(
          children: [
            Text(
              'Total de Boletos',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            Text('Regulares: ${ticketCounter.regularTickets}',
                style: TextStyle(fontSize: 20)),
            Text('Preferenciales: ${ticketCounter.specialTickets}',
                style: TextStyle(fontSize: 20)),
            Text(
              'Total en Bs Regulares: ${ticketCounter.totalRegularBs.toStringAsFixed(2)} Bs',
              style: TextStyle(fontSize: 20),
            ),
            Text(
              'Total en Bs Preferenciales: ${ticketCounter.totalSpecialBs.toStringAsFixed(2)} Bs',
              style: TextStyle(fontSize: 20),
            ),
          ],
        );
      },
    );
  }
}
