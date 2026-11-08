import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

void main() => runApp(const EdilBlackApp());

class EdilBlackApp extends StatelessWidget {
  const EdilBlackApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'EdilBlack',
      theme: ThemeData(primarySwatch: Colors.blue, useMaterial3: false),
      home: const PreventivoPage(),
    );
  }
}

class Voce {
  String descrizione;
  double quantita;
  double prezzo;
  Voce({required this.descrizione, this.quantita = 1, this.prezzo = 0});
  double get totale => quantita * prezzo;
}

class PreventivoPage extends StatefulWidget {
  const PreventivoPage({super.key});
  @override
  State<PreventivoPage> createState() => _PreventivoPageState();
}

class _PreventivoPageState extends State<PreventivoPage> {
  int numeroPreventivo = 1;
  int anno = DateTime.now().year;
  double iva = 10;

  List<Voce> voci = [];
  List<Map<String, String>> clientiSalvati = [
    {'nome': 'Mario Rossi', 'telefono': '3456788776', 'indirizzo': 'Via Roma 1'},
  ];

  final nomeCtrl = TextEditingController();
  final telCtrl = TextEditingController();
  final indCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _caricaNumero();
  }

  // FIX 1 - NUMERO PROGRESSIVO CHE AVANZA E RESTA SALVATO
  Future<void> _caricaNumero() async {
    final prefs = await SharedPreferences.getInstance();
    int salvato = prefs.getInt('ultimo_numero_$anno') ?? 0;
    setState(() => numeroPreventivo = salvato + 1);
  }

  Future<void> _salvaENumeroAvanti() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('ultimo_numero_$anno', numeroPreventivo);
    setState(() => numeroPreventivo = numeroPreventivo + 1);
  }

  double get subtotale => voci.fold(0, (s, v) => s + v.totale);
  double get totale => subtotale + (subtotale * iva / 100);
  String get numeroFormattato =>
      'PREV-$anno-${numeroPreventivo.toString().padLeft(3, '0')}';

  void _aggiungiVoce() {
    setState(() => voci.add(Voce(descrizione: '')));
  }

  // FIX 3 - NUOVO PREVENTIVO PULISCE TUTTO DAVVERO
  void _nuovoPreventivo() {
    setState(() {
      voci = [];
      nomeCtrl.clear();
      telCtrl.clear();
      indCtrl.clear();
    });
  }

  Future<void> _condividiWhatsApp() async {
    // Crea PDF
    final pdf = pw.Document();
    pdf.addPage(
      pw.Page(
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text('Preventivo N. $numeroFormattato',
                style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 10),
            pw.Text('Cliente: ${nomeCtrl.text}'),
            pw.Text('Telefono: ${telCtrl.text}'),
            pw.Text('Indirizzo lavoro: ${indCtrl.text}'),
            pw.SizedBox(height: 16),
            ...voci.map((v) => pw.Text(
                '${v.descrizione} - ${v.quantita} x ${v.prezzo.toStringAsFixed(2)} = ${v.totale.toStringAsFixed(2)} Euro')),
            pw.SizedBox(height: 16),
            pw.Text('Subtotale: ${subtotale.toStringAsFixed(2)} Euro'),
            pw.Text('IVA $iva%: ${(totale - subtotale).toStringAsFixed(2)} Euro'),
            pw.Text('TOTALE: ${totale.toStringAsFixed(2)} Euro',
                style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
          ],
        ),
      ),
    );

    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/$numeroFormattato.pdf');
    await file.writeAsBytes(await pdf.save());

    // Condividi su WhatsApp / altro
    await Share.shareXFiles([XFile(file.path)],
        text: 'Preventivo N. $numeroFormattato - Totale ${totale.toStringAsFixed(2)} Euro');

    // SOLO DOPO L'INVIO: avanza il numero e pulisce
    await _salvaENumeroAvanti();
    _nuovoPreventivo();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('EdilBlack - $numeroFormattato')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Preventivo N. $numeroFormattato',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),

            DropdownButton<String>(
              isExpanded: true,
              hint: Text('Seleziona cliente salvato (${clientiSalvati.length})'),
              items: clientiSalvati
                  .map((c) => DropdownMenuItem(value: c['nome'], child: Text(c['nome']!)))
                  .toList(),
              onChanged: (val) {
                var c = clientiSalvati.firstWhere((e) => e['nome'] == val);
                setState(() {
                  nomeCtrl.text = c['nome']!;
                  telCtrl.text = c['telefono']!;
                  indCtrl.text = c['indirizzo']!;
                });
              },
            ),
            TextField(controller: nomeCtrl, decoration: const InputDecoration(labelText: 'Nome cliente')),
            TextField(controller: telCtrl, decoration: const InputDecoration(labelText: 'Telefono')),
            TextField(controller: indCtrl, decoration: const InputDecoration(labelText: 'Indirizzo lavoro')),
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(child: ElevatedButton(onPressed: _aggiungiVoce, child: const Text('Aggiungi voce'))),
                const SizedBox(width: 8),
                Expanded(child: ElevatedButton(onPressed: _nuovoPreventivo, child: const Text('Nuovo / Refresh'))),
              ],
            ),
            const SizedBox(height: 16),
            const Text('LAVORAZIONI:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),

            // FIX 2 - COME WOOD PRO: NIENTE ALTEZZA FISSA
            // E' una Column dentro SingleChildScrollView.
            // Ogni voce che aggiungi fa ALLUNGARE la pagina.
            // 1 voce = corto, 22 voci = lunghissimo, scorri e vedi tutto.
            Column(
              children: voci.asMap().entries.map((entry) {
                int i = entry.key;
                Voce v = entry.value;
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      children: [
                        TextField(
                          decoration: InputDecoration(labelText: 'Lavorazione ${i + 1}'),
                          controller: TextEditingController(text: v.descrizione),
                          onChanged: (val) => v.descrizione = val,
                        ),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                decoration: const InputDecoration(labelText: 'Qta'),
                                keyboardType: TextInputType.number,
                                controller: TextEditingController(text: v.quantita.toString()),
                                onChanged: (val) => setState(() => v.quantita = double.tryParse(val) ?? 1),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextField(
                                decoration: const InputDecoration(labelText: 'Prezzo'),
                                keyboardType: TextInputType.number,
                                controller: TextEditingController(text: v.prezzo.toString()),
                                onChanged: (val) => setState(() => v.prezzo = double.tryParse(val) ?? 0),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text('${v.totale.toStringAsFixed(2)} €',
                                style: const TextStyle(fontWeight: FontWeight.bold)),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => setState(() => voci.removeAt(i)),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),

            if (voci.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Text('Nessuna lavorazione. Premi "Aggiungi voce" per iniziare.',
                    style: TextStyle(color: Colors.grey)),
              ),

            const SizedBox(height: 16),
            Text('Subtotale: ${subtotale.toStringAsFixed(2)} Euro'),
            Text('IVA $iva%: ${(totale - subtotale).toStringAsFixed(2)} Euro'),
            Text('TOTALE: ${totale.toStringAsFixed(2)} Euro',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),

            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                onPressed: _condividiWhatsApp,
                child: const Text('Condividi su WhatsApp',
                    style: TextStyle(fontSize: 18, color: Colors.white)),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
