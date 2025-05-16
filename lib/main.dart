import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: InicioScreen(),
    );
  }
}

// Clase para manejar SQLite
class DatabaseHelper {
  static final _databaseName = "gastos.db";
  static final _databaseVersion = 1;
  static final table = "gastos";
  static final columnId = "_id";
  static final columnNombre = "nombre";
  static final columnCategoria = "categoria";
  static final columnFecha = "fecha";
  static final columnCantidad = "cantidad";

  DatabaseHelper._privateConstructor();
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();

  static Database? _database;

  Future<Database?> get database async {
    if (_database != null) return _database;
    _database = await _initDatabase();
    return _database;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), _databaseName);
    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
    );
  }

  Future _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $table (
        $columnId INTEGER PRIMARY KEY AUTOINCREMENT,
        $columnNombre TEXT NOT NULL,
        $columnCategoria TEXT NOT NULL,
        $columnFecha TEXT NOT NULL,
        $columnCantidad REAL NOT NULL
      )
    ''');
  }

  Future<int> insert(Map<String, dynamic> row) async {
    Database db = await instance.database as Database;
    return await db.insert(table, row);
  }

  Future<List<Map<String, dynamic>>> queryAllRows() async {
    Database db = await instance.database as Database;
    return await db.query(table);
  }

  Future<List<Map<String, dynamic>>> queryLastThreeRows() async {
    Database db = await instance.database as Database;
    return await db.query(table, orderBy: "$columnId DESC", limit: 3);
  }

  Future<double> getTotalGastos() async {
    Database db = await instance.database as Database;
    final result = await db.rawQuery("SELECT SUM($columnCantidad) as total FROM $table");
    return result.first["total"] as double? ?? 0.0;
  }

  Future<int> delete(int id) async {
    Database db = await instance.database as Database;
    return await db.delete(table, where: '$columnId = ?', whereArgs: [id]);
  }
}

// Pantalla de Inicio
class InicioScreen extends StatefulWidget {
  @override
  _InicioScreenState createState() => _InicioScreenState();
}

class _InicioScreenState extends State<InicioScreen> {
  final dbHelper = DatabaseHelper.instance;
  double totalGastos = 0.0;
  List<Map<String, dynamic>> ultimosGastos = [];


  @override
  void initState() {
    super.initState();
    _actualizarDatos();
  }

  void _actualizarDatos() async {
    final total = await dbHelper.getTotalGastos();
    final gastos = await dbHelper.queryLastThreeRows();
    setState(() {
      totalGastos = total;
      ultimosGastos = gastos;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Container(
            height: 90,
            color: Colors.green,
            child: Center(
              child: Text(
                "Tus finanzas son nuestra prioridad",
                style: TextStyle(fontSize: 20,
                    color: Colors.white,
                    fontWeight: FontWeight.bold),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Text(
                  "Total de Gastos: \$${totalGastos.toStringAsFixed(2)}",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 10),
                Text("Últimos 3 gastos registrados:", style: TextStyle(
                    fontSize: 16, fontWeight: FontWeight.bold)),
                Column(
                  children: ultimosGastos.map((gasto) {
                    return ListTile(
                      title: Text(gasto['nombre']),
                      subtitle: Text(
                          "Fecha: ${gasto['fecha']} - Monto: \$${gasto['cantidad']}"),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () {
              _actualizarDatos(); // 🔄 Refresca los datos
            },
            child: Text("Actualizar Datos"),
          ),
          Expanded(
            child: Center(
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => GestionGastosScreen()),
                  );
                },
                child: Text("Gestionar Gastos"),
              ),
            ),
          ),GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => CreditosScreen()),
              );
            },
            child: Image.asset("assets/Logo.png",
              width: 100,
              height: 100,
            ),
          ),
        ],
      ),
    );
  }
}

class CreditosScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Créditos")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text("ESIT\nDesarrollado por el grupo 32 \n\nIntegrantes:\n\nLuis Enrique Molina \nNoelia Elisa Gomez \nHelen Maria Fuentes \nIris Soraya Mulato \nMarvin Josue Ayala \nAlexis Rodrigo Cartagena \n\nVersion: 1.0.1 \n\nGracias por usar nuestra aplicación",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 10),
            Text("App enfocada en la gestión de gastos"),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: Text("Volver"),
            ),
          ],
        ),
      ),
    );
  }
}

// Pantalla de Gestión de Gastos.
class GestionGastosScreen extends StatefulWidget {
  @override
  _GestionGastosScreenState createState() => _GestionGastosScreenState();
}

// Lista de Gastos, formulario y eliminación de gastos
class _GestionGastosScreenState extends State<GestionGastosScreen> {
  final dbHelper = DatabaseHelper.instance;
  List<Map<String, dynamic>> gastos = [];

  @override
  void initState() {
    super.initState();
    _actualizarListaGastos(); // **Cargamos los datos al iniciar la pantalla**
  }

  void _actualizarListaGastos() async {
    final datos = await dbHelper.queryAllRows();
    setState(() {
      gastos = datos;
    });
  }

  void _eliminarGasto(BuildContext context, int id) async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Confirmación"),
          content: Text("¿Estás seguro de eliminar este gasto?"),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(),
                child: Text("Cancelar")),
            TextButton(
              onPressed: () async {
                await dbHelper.delete(id);
                Navigator.of(context).pop();
                _actualizarListaGastos();

                // mensaje de éxito
                ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Gasto eliminado con éxito"))
                );

                // Actualizar datos en la pantalla de inicio
                setState(() {
                  InicioScreen().createState()._actualizarDatos();
                });
              },
              child: Text("Eliminar"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Gestión de Gastos")),
      body: Column(
        children: [
          ElevatedButton(
            onPressed: () => _mostrarFormularioCrearGasto(context),
            child: Text("Agregar Gasto"),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: gastos.length,
              itemBuilder: (context, index) {
                final gasto = gastos[index];
                return ListTile(
                  title: Text(gasto['nombre']),
                  subtitle: Text(
                      "Categoría: ${gasto['categoria']} - Fecha: ${gasto['fecha']} - Monto: \$${gasto['cantidad']}"),
                  trailing: IconButton(
                    icon: Icon(Icons.delete),
                    onPressed: () => _eliminarGasto(context, gasto['_id']),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _mostrarFormularioCrearGasto(BuildContext context) {
    TextEditingController nombreController = TextEditingController();
    TextEditingController categoriaController = TextEditingController();
    TextEditingController fechaController = TextEditingController();
    TextEditingController cantidadController = TextEditingController();

    Future<void> _seleccionarFecha(BuildContext context) async {
      DateTime? seleccionada = await showDatePicker(
        context: context,
        initialDate: DateTime.now(),
        firstDate: DateTime(2000),
        lastDate: DateTime(2100),
      );

      if (seleccionada != null) {
        fechaController.text = DateFormat('yyyy-MM-dd').format(seleccionada);
      }
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Nuevo Gasto"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nombreController,
                  decoration: InputDecoration(labelText: "Nombre")),
              TextField(controller: categoriaController,
                  decoration: InputDecoration(labelText: "Categoría")),
              TextField(controller: cantidadController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(labelText: "Monto")),
              TextField(controller: fechaController,
                  decoration: InputDecoration(labelText: "Fecha"),
                  readOnly: true),
              ElevatedButton(
                onPressed: () => _seleccionarFecha(context),
                child: Text("Seleccionar Fecha"),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context),
                child: Text("Cancelar")),
            TextButton(
              onPressed: () {
                if (nombreController.text.isEmpty ||
                    categoriaController.text.isEmpty ||
                    fechaController.text.isEmpty ||
                    cantidadController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text("Todos los campos son obligatorios.")));
                } else {
                  dbHelper.insert({
                    DatabaseHelper.columnNombre: nombreController.text,
                    DatabaseHelper.columnCategoria: categoriaController.text,
                    DatabaseHelper.columnFecha: fechaController.text,
                    DatabaseHelper.columnCantidad: double.tryParse(
                        cantidadController.text) ?? 0.0,
                  });

                  Navigator.pop(context);
                  _actualizarListaGastos();

                  // mensaje de éxito
                  ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Gasto guardado con éxito"))
                  );
                }
              },
              child: Text("Guardar"),
            ),
          ],
        );
      },
    );
  }
}

//muchas de las clases estan nombradas en ingles porque el material de apoyo estaba en
//ingles y para practicar se uso ese formato.