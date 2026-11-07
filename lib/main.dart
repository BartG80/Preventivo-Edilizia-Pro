import 'dart:io';
import 'package:flutter/material.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:printing/printing.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

  // PROGRESSIVO PREVENTIVO - aumenta in automatico a ogni invio
  int progressivo = 1;
  String get numero {
    final anno = DateTime.now().year;
    return '$anno-${progressivo.toString().padLeft(3, '0')}';
  }

  // DATI DITTA
  String ragioneSociale = '';
  String indirizzoDitta = '';
  String piva = '';
  String telefonoDitta = '';
  String emailDitta = '';
  String citta = '';

  @override
  void initState() {
    super.initState();
    _caricaDatiDitta();
    _caricaProgressivo();
  }

  Future<void> _caricaProgressivo() async {
    final prefs = await SharedPreferences.getInstance();
    final annoSalvato = prefs.getInt('annoProgressivo') ?? DateTime.now().year;
    final annoOra = DateTime.now().year;
    setState(() {
      if (annoSalvato != annoOra) {
        // Anno nuovo -> riparte da 001
        progressivo = 1;
      } else {
        progressivo = prefs.getInt('progressivo') ?? 1;
      }
    });
  }

  Future<void> _aumentaProgressivo() async {
    final prefs = await SharedPreferences.getInstance();
    final nuovo = progressivo + 1;
    await prefs.setInt('progressivo', nuovo);
    await prefs.setInt('annoProgressivo', DateTime.now().year);
    setState(() {
      progressivo = nuovo;
    });
  }

  Future<void> _caricaDatiDitta() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      ragioneSociale = prefs.getString('ragione') ?? '';
      indirizzoDitta = prefs.getString('indirizzo') ?? '';
      piva = prefs.getString('piva') ?? '';
      telefonoDitta = prefs.getString('telefonoDitta') ?? '';
      emailDitta = prefs.getString('email') ?? '';
      citta = prefs.getString('citta') ?? '';
    });
    if (ragioneSociale.isEmpty) {
      Future.delayed(Duration(milliseconds: 500), () => _apriImpostazioni());
    }
  }

  Future<void> _salvaDatiDitta() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('ragione', ragioneSociale);
    await prefs.setString('indirizzo', indirizzoDitta);
    await prefs.setString('piva', piva);
    await prefs.setString('telefonoDitta', telefonoDitta);
    await prefs.setString('email', emailDitta);
    await prefs.setString('citta', citta);
  }

  void _apriImpostazioni() async {
    final cRagione = TextEditingController(text: ragioneSociale);
    final cIndirizzo = TextEditingController(text: indirizzoDitta);
    final cPiva = TextEditingController(text: piva);
    final cTel = TextEditingController(text: telefonoDitta);
    final cEmail = TextEditingController(text: emailDitta);
    final cCitta = TextEditingController(text: citta);

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: Text('Dati della tua Ditta'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Questi dati usciranno in automatico in tutti i PDF.', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
              SizedBox(height: 12),
              TextField(controller: cRagione, decoration: InputDecoration(labelText: 'Ragione Sociale *', hintText: 'Es. DBG EDILE SRL')),
              TextField(controller: cIndirizzo, decoration: InputDecoration(labelText: 'Indirizzo *', hintText: 'Via Roma 10')),
              TextField(controller: cCitta, decoration: InputDecoration(labelText: 'Citta *', hintText: 'Es. Bergamo')),
              TextField(controller: cPiva, decoration: InputDecoration(labelText: 'P.IVA *', hintText: 'Es. 01234567890')),
              TextField(controller: cTel, decoration: InputDecoration(labelText: 'Telefono *', hintText: 'Es. 333 1234567')),
              TextField(controller: cEmail, decoration: InputDecoration(labelText: 'Email *', hintText: 'info@...')),
            ],
          ),
        ),
        actions: [
          if (ragioneSociale.isNotEmpty) TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Annulla')),
          ElevatedButton(
            onPressed: () {
              if (cRagione.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Inserisci almeno la Ragione Sociale')));
                return;
              }
              setState(() {
                ragioneSociale = cRagione.text.trim();
                indirizzoDitta = cIndirizzo.text.trim();
                citta = cCitta.text.trim();
                piva = cPiva.text.trim();
                telefonoDitta = cTel.text.trim();
                emailDitta = cEmail.text.trim();
              });
              _salvaDatiDitta();
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Dati ditta salvati!')));
            },
            child: Text('Salva'),
          ),
        ],
      ),
    );
  }

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

  Future<pw.Document> _creaPdf() async {
    final font = await PdfGoogleFonts.robotoRegular();
    final fontBold = await PdfGoogleFonts.robotoBold();
    final foroText = citta.isNotEmpty ? 'Foro competente: Tribunale di $citta.' : '';

    final pdf = pw.Document();
    pdf.addPage(
      pw.MultiPage(
        theme: pw.ThemeData.withFont(base: font, bold: fontBold),
        build: (ctx) => [
          pw.Text(ragioneSociale.toUpperCase(), style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold)),
          if (indirizzoDitta.isNotEmpty || citta.isNotEmpty) pw.Text('$indirizzoDitta, $citta', style: pw.TextStyle(fontSize: 10)),
          if (piva.isNotEmpty) pw.Text('P.IVA $piva', style: pw.TextStyle(fontSize: 10)),
          if (telefonoDitta.isNotEmpty || emailDitta.isNotEmpty) pw.Text('$telefonoDitta - $emailDitta', style: pw.TextStyle(fontSize: 10)),
          pw.Divider(),
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
          pw.Divider(),
          pw.Text('NOTE LEGALI E CONDIZIONI', style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 6),
          pw.Text('1. Il presente preventivo ha validita di 30 giorni dalla data di emissione.', style: pw.TextStyle(fontSize: 9)),
          pw.Text('2. I prezzi indicati sono IVA esclusa, salvo diversa indicazione.', style: pw.TextStyle(fontSize: 9)),
          pw.Text('3. Per conferma dell\'ordine e richiesto il versamento di un acconto pari al 40% dell\'importo totale.', style: pw.TextStyle(fontSize: 9)),
          pw.Text('4. Il saldo dovra essere corrisposto a lavoro finito, prima della consegna.', style: pw.TextStyle(fontSize: 9)),
          pw.Text('5. Eventuali varianti, modifiche o lavori extra richiesti in corso d\'opera saranno conteggiati a parte e dovranno essere approvati per iscritto.', style: pw.TextStyle(fontSize: 9)),
          pw.Text('6. I materiali sono quelli indicati nel preventivo. Eventuali sostituzioni saranno concordate con il cliente.', style: pw.TextStyle(fontSize: 9)),
          pw.Text('7. Il presente documento non costituisce fattura. La fattura verra emessa al pagamento secondo normativa vigente.', style: pw.TextStyle(fontSize: 9)),
          if (foroText.isNotEmpty) pw.Text('8. $foroText', style: pw.TextStyle(fontSize: 9)),
          pw.SizedBox(height: 16),
          pw.Text('Firma per accettazione: ___________________________', style: pw.TextStyle(fontSize: 10)),
          pw.SizedBox(height: 8),
          pw.Text('Data: ____ / ____ / ________', style: pw.TextStyle(fontSize: 10)),
          pw.SizedBox(height: 16),
          pw.Text('Grazie per aver scelto $ragioneSociale.', style: pw.TextStyle(fontSize: 10)),
        ],
      ),
    );
    return pdf;
  }

  Future<void> _condividiWhatsApp() async {
    if (righe.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Aggiungi almeno una voce')));
      return;
    }
    if (ragioneSociale.isEmpty) {
      _apriImpostazioni();
      return;
    }
    final numeroCorrente = numero;
    final pdf = await _creaPdf();
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/PREV-$numeroCorrente.pdf');
    await file.writeAsBytes(await pdf.save());
    await Share.shareXFiles(
      [XFile(file.path)],
      text: 'Ecco il tuo preventivo $ragioneSociale - N. $numeroCorrente\nTotale: ${totale.toStringAsFixed(2)} €',
    );

    // AUMENTA IN AUTOMATICO SOLO DOPO L'INVIO
    await _aumentaProgressivo();
    setState(() {
      righe.clear();
      _nomeController.clear();
      _telefonoController.clear();
      _indirizzoController.clear();
    });
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Preventivo $numeroCorrente inviato. Prossimo: $numero')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(ragioneSociale.isEmpty ? 'DBG Edile - Preventivo $numero' : '$ragioneSociale - $numero'),
        backgroundColor: Colors.brown[800],
        actions: [
          IconButton(icon: Icon(Icons.settings), onPressed: _apriImpostazioni, tooltip: 'Dati Ditta'),
        ],
      ),
      body: Padding(
        padding: EdgeInsets.all(12),
        child: Column(
          children: [
            if (ragioneSociale.isEmpty)
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(10),
                color: Colors.orange[100],
                child: Text('⚙️ Prima volta? Premi l\'ingranaggio in alto e inserisci i dati della tua ditta.', style: TextStyle(fontSize: 13)),
              ),
            Text('Preventivo N. $numero', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.brown[800])),
            SizedBox(height: 6),
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
