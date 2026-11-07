import 'dart:io';
import 'package:flutter/material.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:printing/printing.dart';

void main() => runApp(MaterialApp(home: PreventivoEdile(), debugShowCheckedModeBanner: false));

class Voce {
  String nome; String unita; double prezzo;
  Voce({required this.nome, required this.unita, required this.prezzo});
}

class Riga {
  Voce voce; double quantita;
  Riga({required this.voce, required this.quantita});
  double get totale => voce.prezzo * quantita;
}

// LISTINO EDILE - base Wood Pro, solo voci cambiate
final List<Voce> LISTINO = [
  Voce(nome: 'Fondazioni', unita: 'ml', prezzo: 120),
  Voce(nome: 'Massetto', unita: 'mq', prezzo: 25),
  Voce(nome: 'Armatura pilastri', unita: 'pz', prezzo: 350),
  Voce(nome: 'Armatura travi fonde', unita: 'ml', prezzo: 180),
  Voce(nome: 'Armatura travi piatte', unita: 'ml', prezzo: 160),
  Voce(nome: 'Muratura', unita: 'mq', prezzo: 55),
  Voce(nome: 'Armatura solaio', unita: 'mq', prezzo: 45),
  Voce(nome: 'Armatura scala', unita: 'pz', prezzo: 450),
  Voce(nome: 'Armatura balconi', unita: 'mq', prezzo: 40),
  Voce(nome: 'Armatura tetto', unita: 'mq', prezzo: 50),
  Voce(nome: 'Massetto a secco (sabbia e cemento)', unita: 'mq', prezzo: 30),
  Voce(nome: 'Intonaco', unita: 'mq', prezzo: 22),
  Voce(nome: 'Rasatura', unita: 'mq', prezzo: 12),
  Voce(nome: 'Posa pavimento', unita: 'mq', prezzo: 28),
  Voce(nome: 'Posa rivestimento', unita: 'mq', prezzo: 30),
  Voce(nome: 'Posa piastrelle', unita: 'mq', prezzo: 28),
  Voce(nome: 'Posa mosaico', unita: 'mq', prezzo: 45),
  Voce(nome: 'Posa contro telaio', unita: 'pz', prezzo: 10),
  Voce(nome: 'Cartongesso', unita: 'mq', prezzo: 35),
  Voce(nome: 'Ristrutturazione cucina', unita: 'mq', prezzo: 350),
  Voce(nome: 'Ristrutturazione bagno', unita: 'mq', prezzo: 550),
  Voce(nome: 'Demolizione', unita: 'mq', prezzo: 25),
];

class PreventivoEdile extends StatefulWidget {
  @override
  _PreventivoEdileState createState() => _PreventivoEdileState();
}

class _PreventivoEdileState extends State<PreventivoEdile> {
  final _nomeController = TextEditingController();
  final _telefonoController = TextEditingController();
  final _indirizzoController = TextEditingController();
  List<Riga> righe = [];
  String numero = '2026-001';

  double get totale => righe.fold(0, (s, r) => s + r.totale);
  double get acconto => totale * 0.40;
  double get saldo => totale - acconto;

  void _aggiungiVoce() async {
    Voce? selezionata = LISTINO[0];
    final qtaController = TextEditingController(text: '1');
    final prezzoController = TextEditingController(text: selezionata.prezzo.toStringAsFixed(0));

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setD) => AlertDialog(
          title: Text('Aggiungi voce'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButton<Voce>(
                isExpanded: true,
                value: selezionata,
                items: LISTINO.map((v) => DropdownMenuItem(value: v, child: Text(v.nome))).toList(),
                onChanged: (v) {
                  setD(() {
                    selezionata = v;
                    prezzoController.text = v!.prezzo.toStringAsFixed(0);
                  });
                },
              ),
              TextField(controller: qtaController, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: 'Quantita (${selezionata!.unita})')),
              TextField(controller: prezzoController, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: 'Prezzo € / ${selezionata!.unita}')),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Annulla')),
            ElevatedButton(
              onPressed: () {
                final q = double.tryParse(qtaController.text.replaceAll(',', '.')) ?? 1;
                final p = double.tryParse(prezzoController.text.replaceAll(',', '.')) ?? selezionata!.prezzo;
                setState(() {
                  righe.add(Riga(voce: Voce(nome: selezionata!.nome, unita: selezionata!.unita, prezzo: p), quantita: q));
                });
                Navigator.pop(ctx);
              },
              child: Text('Aggiungi'),
            ),
          ],
        ),
      ),
    );
  }

  // STESSA CORREZIONE DELLA WOOD PRO - font Roboto per far vedere € pulito
  Future<pw.Document> _creaPdf() async {
    final font = await PdfGoogleFonts.robotoRegular();
    final fontBold = await PdfGoogleFonts.robotoBold();

    final pdf = pw.Document();
    pdf.addPage(
      pw.MultiPage(
        theme: pw.ThemeData.withFont(
          base: font,
          bold: fontBold,
        ),
        build: (ctx) => [
          pw.Text('DBG - EDILE', style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 8),
          pw.Text('PREVENTIVO N. $numero', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 12),
          pw.Text('Cliente: ${_nomeController.text}'),
          pw.Text('Telefono: ${_telefonoController.text}'),
          pw.Text('Indirizzo lavoro: ${_indirizzoController.text}'),
          pw.SizedBox(height: 16),
          pw.Table.fromTextArray(
            headers: ['Voce', 'Qta', 'Prezzo', 'Totale'],
            data: righe.map((r) => [
              r.voce.nome,
              '${r.quantita.toStringAsFixed(2)} ${r.voce.unita}',
              '${r.voce.prezzo.toStringAsFixed(2)} €',
              '${r.totale.toStringAsFixed(2)} €',
            ]).toList(),
          ),
          pw.SizedBox(height: 16),
          pw.Text('TOTALE: ${totale.toStringAsFixed(2)} €', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
          pw.Text('ACCONTO 40% DA VERSARE: ${acconto.toStringAsFixed(2)} €'),
          pw.Text('SALDO A LAVORO FINITO: ${saldo.toStringAsFixed(2)} €'),
          pw.SizedBox(height: 20),
          pw.Text('Grazie per aver scelto DBG.', style: pw.TextStyle(fontSize: 10)),
        ],
      ),
    );
    return pdf;
  }

  // UGUALE ALLA WOOD PRO - condivisione diretta
  Future<void> _condividiWhatsApp() async {
    if (righe.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Aggiungi almeno una voce')));
      return;
    }
    final pdf = await _creaPdf();
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/PREV-$numero.pdf');
    await file.writeAsBytes(await pdf.save());

    await Share.shareXFiles(
      [XFile(file.path)],
      text: 'Ecco il tuo preventivo DBG Edile - N. $numero\nTotale: ${totale.toStringAsFixed(2)} €',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('DBG Edile - Preventivo $numero'), backgroundColor: Colors.brown[800]),
      body: Padding(
        padding: EdgeInsets.all(12),
        child: Column(
          children: [
            TextField(controller: _nomeController, decoration: InputDecoration(labelText: 'Nome cliente')),
            TextField(controller: _telefonoController, decoration: InputDecoration(labelText: 'Telefono')),
            TextField(controller: _indirizzoController, decoration: InputDecoration(labelText: 'Indirizzo lavoro')),
            SizedBox(height: 10),
            ElevatedButton.icon(onPressed: _aggiungiVoce, icon: Icon(Icons.add), label: Text('Aggiungi voce')),
            Expanded(
              child: ListView.builder(
                itemCount: righe.length,
                itemBuilder: (ctx, i) {
                  final r = righe[i];
                  return ListTile(
                    title: Text(r.voce.nome),
                    subtitle: Text('${r.quantita} ${r.voce.unita} x ${r.voce.prezzo} €'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('${r.totale.toStringAsFixed(2)} €', style: TextStyle(fontWeight: FontWeight.bold)),
                        IconButton(icon: Icon(Icons.delete, color: Colors.red), onPressed: () => setState(() => righe.removeAt(i))),
                      ],
                    ),
                  );
                },
              ),
            ),
            Divider(),
            Text('TOTALE: ${totale.toStringAsFixed(2)} €', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            Text('ACCONTO 40%: ${acconto.toStringAsFixed(2)} €'),
            Text('SALDO: ${saldo.toStringAsFixed(2)} €'),
            SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _condividiWhatsApp,
                icon: Icon(Icons.share),
                label: Text('Condividi su WhatsApp'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green, padding: EdgeInsets.symmetric(vertical: 14)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
