import 'package:flutter/material.dart';

void main() => runApp(EdileApp());

class EdileApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Preventivo Edilizia Pro',
      theme: ThemeData(primarySwatch: Colors.orange),
      home: HomePage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class Voce {
  String nome;
  double prezzo;
  double quantita;
  Voce(this.nome, this.prezzo, this.quantita);
}

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Voce> voci = [
    Voce('Demolizione mq', 25, 0),
    Voce('Muratura mq', 65, 0),
    Voce('Intonaco mq', 28, 0),
    Voce('Pavimento mq', 45, 0),
    Voce('Impianto elettrico punto', 85, 0),
    Voce('Impianto idraulico punto', 120, 0),
    Voce('Tinteggiatura mq', 12, 0),
    Voce('Cartongesso mq', 38, 0),
    Voce('Ristrutturazione bagno', 4500, 0),
    Voce('Ristrutturazione cucina', 6500, 0),
  ];

  String cliente = '';
  String cantiere = '';

  double get totale => voci.fold(0, (s, v) => s + v.prezzo * v.quantita);
  double get iva => totale * 0.22;
  double get totaleIva => totale + iva;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Preventivo Edilizia Pro')),
      body: ListView(
        padding: EdgeInsets.all(16),
        children: [
          TextField(
            decoration: InputDecoration(labelText: 'Cliente'),
            onChanged: (v) => cliente = v,
          ),
          TextField(
            decoration: InputDecoration(labelText: 'Cantiere / Indirizzo'),
            onChanged: (v) => cantiere = v,
          ),
          SizedBox(height: 16),
          ...voci.map((v) => Card(
            child: ListTile(
              title: Text(v.nome),
              subtitle: Text('${v.prezzo.toStringAsFixed(2)} €'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(icon: Icon(Icons.remove), onPressed: () => setState(() { if (v.quantita > 0) v.quantita--; })),
                  Text('${v.quantita.toStringAsFixed(0)}'),
                  IconButton(icon: Icon(Icons.add), onPressed: () => setState(() { v.quantita++; })),
                ],
              ),
            ),
          )).toList(),
          SizedBox(height: 16),
          Card(
            color: Colors.orange[50],
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Cliente: $cliente', style: TextStyle(fontWeight: FontWeight.bold)),
                  Text('Cantiere: $cantiere'),
                  Divider(),
                  Text('Imponibile: ${totale.toStringAsFixed(2)} €'),
                  Text('IVA 22%: ${iva.toStringAsFixed(2)} €'),
                  Text('TOTALE: ${totaleIva.toStringAsFixed(2)} €', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),
          SizedBox(height: 12),
          ElevatedButton(
            onPressed: () => setState(() { for (var v in voci) v.quantita = 0; }),
            child: Text('Azzera Preventivo'),
          ),
        ],
      ),
    );
  }
}
