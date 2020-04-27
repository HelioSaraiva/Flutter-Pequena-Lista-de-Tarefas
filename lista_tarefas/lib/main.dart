import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'dart:async';
import 'package:random_string/random_string.dart';
import 'dart:math';

void main() {
  runApp(MaterialApp(
    home: Home(),
  ));
}

class Home extends StatefulWidget {
  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final _toDocontroller = TextEditingController();

  List _toDoList = [];

  Map<String, dynamic> _lastRemoved;
  int _lastRemovedPos;

  @override
  void initState() {
    super.initState();
    _readData().then((data) {
      setState(() {
        _toDoList = json.decode(data);
      });
    });
  }

  void addToDo() {
    setState(() {
      Map<String, dynamic> newToDo = Map();
      newToDo["title"] = _toDocontroller.text;
      _toDocontroller.text = "";
      newToDo["Ok"] = false;
      _toDoList.add(newToDo);
      _saveData();
    });
  }

  Future<File> _getFile() async {
    final directory = await getApplicationDocumentsDirectory();
    return File("${directory.path}/datas.json");
  }

  Future<File> _saveData() async {
    String data = json.encode(_toDoList);
    final file = await _getFile();
    return file.writeAsString(data);
  }

  Future<String> _readData() async {
    try {
      final file = await _getFile();
      return file.readAsString();
    } catch (e) {
      return null;
    }
  }

  Widget buildItem(BuildContext context, int index) {
    return Dismissible(
      //key: Key(DateTime.now().millisecondsSinceEpoch.toString()),
      key: Key(randomString(1000)),
      background: Container(
        color: Colors.red,
        child: Align(
          alignment: Alignment(-0.9, 0.0),
          child: Icon(
            Icons.delete,
            color: Colors.white,
          ),
        ),
      ),
      direction: DismissDirection.startToEnd,
      child: CheckboxListTile(
          title: Text(_toDoList[index]["title"]),
          value: _toDoList[index]["Ok"],
          secondary: CircleAvatar(
            child: Icon(
              _toDoList[index]["Ok"] ? Icons.check : Icons.error,
            ),
          ),
          onChanged: (check) {
            setState(() {
              _toDoList[index]["Ok"] = check;
              _saveData();
            });
          }),
      onDismissed: (direction) {
        setState(() {
          _lastRemoved = Map.from(_toDoList[index]);
          _lastRemovedPos = index;
          _toDoList.removeAt(index);
          _saveData();
          final snack = SnackBar(
            content: Text("Tarefa \"${_lastRemoved["title"]}\" Removida!!"),
            action: SnackBarAction(
                label: "Desfazer",
                onPressed: () {
                  setState(() {
                    _toDoList.insert(_lastRemovedPos, _lastRemoved);
                    _saveData();
                  });
                }),
            duration: Duration(seconds: 2),
          );

          Scaffold.of(context).removeCurrentSnackBar(); // não soberpor snackbar
          Scaffold.of(context).showSnackBar(snack);
        });
      },
    );
  }

  Future<Null> _refresh() async {
    await Future.delayed(Duration(seconds: 1));
    setState(() {
      _toDoList.sort((a, b) {
        if (a["Ok"] && !b["Ok"])
          return 1;
        else if (!a["Ok"] && b["Ok"])
          return -1;
        else
          return 0;

        _saveData();
      });
    });
    return null;
  }

  /* */

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Lista de Tarefas"),
        centerTitle: true,
      ),
      body: Column(
        children: <Widget>[
          Container(
            padding: EdgeInsets.fromLTRB(17.0, 1.0, 7.0, 1.0),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: TextField(
                    controller: _toDocontroller,
                    decoration: InputDecoration(
                      labelText: "Nova Tarefa",
                      labelStyle: TextStyle(color: Colors.blueAccent),
                    ),
                  ),
                ),
                RaisedButton(
                  color: Colors.blueAccent,
                  child: Text("ADD"),
                  textColor: Colors.white,
                  onPressed: addToDo,
                ),
              ],
            ),
          ),
          Expanded(
            child: RefreshIndicator(
                onRefresh: _refresh,
                child: ListView.builder(
                  padding: EdgeInsets.only(top: 10.0),
                  itemCount: _toDoList.length,
                  itemBuilder: buildItem,
                )),
          ),
        ],
      ),
    );
  }
}
