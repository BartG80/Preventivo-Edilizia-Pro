import 'package:flutter/material.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Voce {
  final String nome;
  final String unita;
  final double prezzoDefault;
  const Voce(this.nome, this.unita, this.prezzoDefault);
}

const LISTINO = [
  Voce("Fondazioni", "ml", 0),
  Voce("Massetto", "mq", 0),
  Voce("Armatura pilastri", "manuale", 0),
  Voce("Muratura", "mq", 0),
  Voce("Armatura solaio", "mq", 0),
  Voce("Armatura scala", "mq", 0),
  Voce("Armatura balconi", "mq", 0),
  Voce("Armatura tetto", "mq", 0),
  Voce("Massetto a secco (sabbia e cemento)", "mq", 0),
  Voce("Intonaco", "mq", 0),
  Voce("Rasatura", "mq", 0),
  Voce("Posa pavimento", "mq", 0),
  Voce("Posa rivestimento", "mq", 0),
  Voce("Posa piastrelle", "mq", 0),
  Voce("Posa mosaico", "mq", 0),
  Voce("Posa contro telaio", "pz", 10),
  Voce("Cartongesso", "mq", 0),
  Voce("Ristrutturazione cucina", "mq", 0),
  Voce("Ristrutturazione bagno", "mq", 0),
  Voce("Demolizione", "mq", 0),
];

class Riga {
  Voce voce;
  double qty;
  double prezzo;
  String nota;
  Riga(this.voce, this.qty, this.prezzo, {this.nota = ""});
  double get tot => qty * prezzo;
}

void main() => runApp(const App());

class App extends StatelessWidget {
  const App({super.key});
  @override
  Widget build(BuildContext context) {
    return const MaterialApp(home: Home(), debugShowCheckedModeBanner: false);
  }
}

class Home extends StatefulWidget {
  const Home({super.key});
  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final cliente = TextEditingController();
  final List<Riga> righe = [];
  double get totale => righe.fold(0, (s, r) => s + r.tot);
  double get acconto => totale * 0.40;
  double get saldo => totale * 0.60;

  // DATI DITTA
  String nomeImpresa = "";
  String titolare = "";
  String piva = "";
  String cf = "";
  String indirizzo = "";
  String citta = "";
  String telefono = "";
  String email = "";
  String pec = "";

  @override
  void initState() {
    super.initState();
    _caricaDati();
  }

  Future<void> _caricaDati() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      nomeImpresa = prefs.getString('nome_impresa') ?? "";
      titolare = prefs.getString('titolare') ?? "";
      piva = prefs.getString('piva') ?? "";
      cf = prefs.getString('cf') ?? "";
      indirizzo = prefs.getString('indirizzo') ?? "";
      citta = prefs.getString('citta') ?? "";
      telefono = prefs.getString('telefono') ?? "";
      email = prefs.getString('email') ?? "";
      pec = prefs.getString('pec') ?? "";
    });
  }

  Future<void> _apriImpostazioni() async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => const Impostazioni()));
    _caricaDati();
  }

  Future<void> aggiungiVoce(Voce v) async {
    final qtyCtrl = TextEditingController(text: "1");
    final prezzoCtrl = TextEditingController(text: v.prezzoDefault.toStringAsFixed(0));
    final notaCtrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(v.nome),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          if (v.nome == "Armatura pilastri")
            TextField(controller: notaCtrl, decoration: const InputDecoration(labelText: "Misure pilastro es: 30x30 h 300")),
          TextField(controller: qtyCtrl, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: "Quantità in ${v.unita == "manuale" ? "n°" : v.unita}")),
          TextField(controller: prezzoCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: "Prezzo € / unità")),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text("Annulla")),
          ElevatedButton(onPressed: () => Navigator.pop(c, true), child: const Text("Aggiungi")),
        ],
      ),
    );
    if (ok == true) {
      setState(() => righe.add(Riga(v, double.tryParse(qtyCtrl.text.replaceAll(",", ".")) ?? 1, double.tryParse(prezzoCtrl.text.replaceAll(",", ".")) ?? 0, nota: notaCtrl.text)));
    }
  }

  Future<void> genPDF() async {
    final prefs = await SharedPreferences.getInstance();
    int ultimo = prefs.getInt('ultimo_numero_preventivo') ?? 0;
    int nuovo = ultimo + 1;
    await prefs.setInt('ultimo_numero_preventivo', nuovo);
    final ora = DateTime.now();
    final numeroFormattato = nuovo.toString().padLeft(3, '0');
    final numeroPreventivo = "${ora.year}-$numeroFormattato";
    final dataStr = "${ora.day.toString().padLeft(2, '0')}/${ora.month.toString().padLeft(2, '0')}/${ora.year}";
    final scadenza = DateTime(ora.year, ora.month, ora.day + 30);
    final scadenzaStr = "${scadenza.day.toString().padLeft(2, '0')}/${scadenza.month.toString().padLeft(2, '0')}/${scadenza.year}";
    final luogoData = citta.isEmpty ? dataStr : "$citta, $dataStr";

    final doc = pw.Document();
    doc.addPage(pw.Page(
        build: (c) => pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
              pw.Text(nomeImpresa.isEmpty ? "Nome Ditta" : nomeImpresa, style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
              pw.Text(titolare),
              pw.Text("P.IVA $piva"),
              pw.Text("Cod. Fisc. $cf"),
              pw.Text(indirizzo),
              pw.Text("$telefono - $email"),
              pw.Text("PEC: $pec"),
              pw.SizedBox(height: 12),
              pw.Divider(),
              pw.Text("PREVENTIVO N. $numeroPreventivo", style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
              pw.Text("$luogoData - Valido fino al: $scadenzaStr"),
              pw.Text("Cliente: ${cliente.text}"),
              pw.SizedBox(height: 16),
              ...righe.map((r) => pw.Padding(
                  padding: const pw.EdgeInsets.only(bottom: 4),
                  child: pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
                    pw.Expanded(child: pw.Text("${r.qty.toStringAsFixed(0)} ${r.voce.unita == "manuale" ? "pz" : r.voce.unita} x ${r.voce.nome}${r.nota.isNotEmpty ? " (${r.nota})" : ""}")),
                    pw.Text("${r.tot.toStringAsFixed(2)}€"),
                  ]))),
              pw.Divider(),
              pw.Text("TOTALE: ${totale.toStringAsFixed(2)}€", style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 4),
              pw.Text("ACCONTO 40% DA VERSARE: ${acconto.toStringAsFixed(2)}€", style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold)),
              pw.Text("SALDO A FINE LAVORI: ${saldo.toStringAsFixed(2)}€"),
              pw.SizedBox(height: 20),
              pw.Text("NOTE LEGALI", style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 6),
              pw.Text(
                "1. Il presente preventivo ha validità di 30 giorni dalla data di emissione (fino al $scadenzaStr).\n"
                "2. I prezzi indicati sono IVA esclusa, salvo diversa indicazione.\n"
                "3. Il preventivo si intende accettato con firma del cliente o conferma scritta.\n"
                "4. Eventuali lavori aggiuntivi non compresi nel presente preventivo saranno quantificati a parte.\n"
                "5. Materiali e manodopera sono compresi salvo diversa specifica per singola voce.\n"
                "6. PAGAMENTO: Acconto del 40% all'accettazione del preventivo. Saldo a fine lavori, salvo diverso accordo tra le parti.\n"
                "7. Per quanto non espressamente indicato valgono le norme di legge vigenti.",
                style: const pw.TextStyle(fontSize: 9),
              ),
              pw.SizedBox(height: 24),
              pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
                pw.Column(children: [pw.Text(luogoData), pw.SizedBox(height: 20), pw.Text("Firma Impresa ________________")]),
                pw.Column(children: [pw.Text("Per accettazione"), pw.SizedBox(height: 20), pw.Text("Firma Cliente ________________")]),
              ]),
            ])));
    await Printing.layoutPdf(onLayout: (f) => doc.save());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Preventivo Edile Pro"), backgroundColor: Colors.brown, actions: [IconButton(icon: const Icon(Icons.settings), onPressed: _apriImpostazioni)]),
      body: Column(children: [
        if (nomeImpresa.isEmpty)
          GestureDetector(
            onTap: _apriImpostazioni,
            child: Container(width: double.infinity, color: Colors.amber[100], padding: const EdgeInsets.all(12), child: const Text("⚠️ Inserisci i dati della tua ditta in Impostazioni (ingranaggio in alto) - clicca qui", textAlign: TextAlign.center)),
          ),
        Padding(padding: const EdgeInsets.all(8), child: TextField(controller: cliente, decoration: const InputDecoration(labelText: "Nome Cliente", border: OutlineInputBorder()))),
        Expanded(child: ListView.builder(itemCount: LISTINO.length, itemBuilder: (c, i) {
          final v = LISTINO[i];
          return ListTile(title: Text("${i + 1}. ${v.nome}"), subtitle: Text("Unità: ${v.unita}"), trailing: const Icon(Icons.add), onTap: () => aggiungiVoce(v));
        })),
        const Divider(),
        Text("TOTALE: ${totale.toStringAsFixed(2)}€ - ACCONTO 40%: ${acconto.toStringAsFixed(2)}€", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        Expanded(child: ListView.builder(itemCount: righe.length, itemBuilder: (c, i) {
          final r = righe[i];
          return ListTile(title: Text("${r.qty.toStringAsFixed(0)} ${r.voce.unita} x ${r.voce.nome}${r.nota.isNotEmpty ? " (${r.nota})" : ""}"), trailing: Row(mainAxisSize: MainAxisSize.min, children: [Text("${r.tot.toStringAsFixed(0)}€"), IconButton(icon: const Icon(Icons.delete, size: 18), onPressed: () => setState(() => righe.removeAt(i)))]));
        })),
        Padding(padding: const EdgeInsets.all(8.0), child: SizedBox(width: double.infinity, child: ElevatedButton.icon(onPressed: righe.isEmpty ? null : genPDF, icon: const Icon(Icons.picture_as_pdf), label: const Text("GENERA PDF PREVENTIVO")))),
      ]),
    );
  }
}

class Impostazioni extends StatefulWidget {
  const Impostazioni({super.key});
  @override
  State<Impostazioni> createState() => _ImpostazioniState();
}

class _ImpostazioniState extends State<Impostazioni> {
  final nome = TextEditingController();
  final titolare = TextEditingController();
  final piva = TextEditingController();
  final cf = TextEditingController();
  final indirizzo = TextEditingController();
  final citta = TextEditingController();
  final telefono = TextEditingController();
  final email = TextEditingController();
  final pec = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final p = await SharedPreferences.getInstance();
    setState(() {
      nome.text = p.getString('nome_impresa') ?? "";
      titolare.text = p.getString('titolare') ?? "";
      piva.text = p.getString('piva') ?? "";
      cf.text = p.getString('cf') ?? "";
      indirizzo.text = p.getString('indirizzo') ?? "";
      citta.text = p.getString('citta') ?? "";
      telefono.text = p.getString('telefono') ?? "";
      email.text = p.getString('email') ?? "";
      pec.text = p.getString('pec') ?? "";
    });
  }

  Future<void> _save() async {
    final p = await SharedPreferences.getInstance();
    await p.setString('nome_impresa', nome.text);
    await p.setString('titolare', titolare.text);
    await p.setString('piva', piva.text);
    await p.setString('cf', cf.text);
    await p.setString('indirizzo', indirizzo.text);
    await p.setString('citta', citta.text);
    await p.setString('telefono', telefono.text);
    await p.setString('email', email.text);
    await p.setString('pec', pec.text);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Dati Ditta"), backgroundColor: Colors.brown),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          TextField(controller: nome, decoration: const InputDecoration(labelText: "Nome Ditta")),
          TextField(controller: titolare, decoration: const InputDecoration(labelText: "Titolare Nome Cognome")),
          TextField(controller: piva, decoration: const InputDecoration(labelText: "P.IVA")),
          TextField(controller: cf, decoration: const InputDecoration(labelText: "Codice Fiscale")),
          TextField(controller: indirizzo, decoration: const InputDecoration(labelText: "Indirizzo")),
          TextField(controller: citta, decoration: const InputDecoration(labelText: "Città es: Soresina (CR)")),
          TextField(controller: telefono, decoration: const InputDecoration(labelText: "Telefono")),
          TextField(controller: email, decoration: const InputDecoration(labelText: "Email")),
          TextField(controller: pec, decoration: const InputDecoration(labelText: "PEC")),
          const SizedBox(height: 20),
          SizedBox(width: double.infinity, child: ElevatedButton(onPressed: _save, child: const Text("SALVA DATI DITTA"))),
        ]),
      ),
    );
  }
}
