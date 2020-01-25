import 'dart:math' as math;

class Automata {
  List<String> states = [];
  List<String> alphabet = [];
  List<String> finalStates = [];
  String initialState = '';
  Automata nfa;
  Automata thompson;
  Automata afd;
  Automata afdreducido;
  static int contadorAutomatas = 0;
  static int nextState() {
    contadorAutomatas++;
    return contadorAutomatas;
  }

  List<Transicion> transitions = [];

  Automata convertirDFA() {
    int nCombinations = math.pow(2, this.states.length).toInt();

    List<List<String>> nuevosEstados = [];
    List<List<String>> finales = [];
    String inicial = "";
    //Construcción de los nuevos estados
    for (var i = 1; i < nCombinations; i++) {
      int binario = toBin(i);
      String binFormated = formatBin(this.states.length, binario);
      String binChido = binFormated.split('').reversed.join();
      List<String> estadoNuevo = [];
      bool isFinal = false;

      for (var j = 0; j < this.states.length; j++) {
        if (binChido[j] == '1') {
          estadoNuevo.add(this.states[j]);
          if (!isFinal && this.finalStates.contains(this.states[j])) {
            isFinal = true;
          }
        }
        estadoNuevo.sort();
      }
      estadoNuevo.sort();
      if (estadoNuevo.length == 1 && estadoNuevo[0] == this.initialState) {
        inicial = estadoNuevo.toString();
      }

      nuevosEstados.add(estadoNuevo);
      if (isFinal) {
        finales.add(estadoNuevo);
      }
    }
    List<Transicion> nuevasTransiciones = [];
    for (List<String> estado in nuevosEstados) {
      for (String leter in this.alphabet) {
        List<String> resultado = this.busqueda(estado, leter);
        Transicion t = Transicion(
            qinput: estado.toString(), leter: leter, qouput: resultado);

        nuevasTransiciones.add(t);
      }
    }
    this.afd = Automata(
        states: nuevosEstados.map((f) => f.toString()).toList(),
        finalStates: finales.map((f) => f.toString()).toList(),
        alphabet: alphabet,
        initialState: inicial,
        transitions: nuevasTransiciones);

    this.afdreducido = this.afd.renombrar(this.afd);
    afdreducido.printAutomata();
    return afdreducido;
  }

  void printAutomata() {
    print("Q = $states");
    print("QF = $finalStates");
    print("QS = $initialState");
    print("A = $alphabet");
    for (var t in this.transitions) {
      print(t.toString());
    }
  }

  //Clausura Epsilon
  List<String> epsilonClosure(String q, List<Transicion> ts) {
    List<String> qs = [];
    qs.add(q);
    List<String> busqueda = [];
    busqueda.add(q);
    //print("Estado $q");
    //print("TS: $ts");
    while (busqueda.length > 0) {
      String qBuscando = busqueda[0];
      for (Transicion t in ts) {
        if (t.qinput == qBuscando &&
            t.leter == "" &&
            qs.indexOf(t.qouput.toString()) == -1) {
          qs.addAll(t.qouput);
          busqueda.addAll(t.qouput);
        }
      }
      busqueda.removeAt(0);
    }

    qs.sort();
    //print("Resultado $qs");
    return qs;
  }

  void thompsonToNFA(Automata a) {
    print("Convirtiendo a NFA");
    List<String> ep1 = [];
    Map<String, int> mapEstados = new Map();
    List<String> finales = [];
    List<Transicion> ts = [];
    for (String q in a.states) {
      ep1 = this.epsilonClosure(q, a.transitions);
      print("Recorriendo $q");
      print("FS ${a.finalStates}");
      if (finales.indexOf(a.finalStates[0]) == -1 &&
          ep1.contains(a.finalStates[0])) {
        finales.add(q);
      }
      for (String letra in a.alphabet) {
        List<String> alcanzables = this.alcanzables(ep1, a.transitions, letra);
        //print("Alcanzables $alcanzables");
        List<String> ep2 = [];
        for (String q in alcanzables) {
          List<String> epCs = this.epsilonClosure(q, a.transitions);

          for (var q2 in epCs) {
            if (ep2.indexOf(q2) == -1) ep2.add(q2);
          }
        }
        if (mapEstados[ep2.toString()] == null)
          mapEstados[ep2.toString()] = Automata.nextState();

        if (ep2.length > 0) {
          //print("($q,$letra) = ${ep2.toString()}");
          ts.add(Transicion(
            qinput: q,
            leter: letra,
            qouput: ep2,
          ));
        }
      }
    }

    this.nfa = new Automata(
        states: a.states,
        alphabet: a.alphabet,
        finalStates: finales,
        initialState: a.initialState,
        transitions: ts);
    this.nfa.printAutomata();
    this.nfa.convertirDFA();
    //this.nfa.afd.printAutomata();
    this.nfa.afdreducido.printAutomata();
  }

  //Alcanzables con una letra
  List<String> alcanzables(
      List<String> lista, List<Transicion> ts, String letra) {
    List<String> qs = [];
    /*  print("lista $lista");
    print("letra $letra"); */
    for (String q in lista) {
      for (Transicion t in ts) {
        //print(t);
        if (t.qinput == q && t.leter == letra) {
          qs.addAll(t.qouput);
        }
      }
    }
    qs.sort();
    return qs;
  }

  @override
  String toString() {
    String ts = "( ";
    for (var t in this.transitions) {
      ts = ts + t.toString() + ", ";
    }
    ts = ts + " )";
    return "Q = $states"
        "QF = $finalStates"
        "QS = $initialState"
        "A = $alphabet"
        "TS =>  $ts";
  }

  Automata(
      {this.states,
      this.alphabet,
      this.finalStates,
      this.initialState,
      this.transitions}) {}

  Automata renombrar(Automata a) {
    //Renombrar estados

    //Buscar transiciones del estado inicial
    String estadoActual = a.initialState;
    List<String> porRecorrer = [estadoActual];
    List<String> estados = [estadoActual];
    int i = 0;
    List<Transicion> tsRenombradas = [];
    while (i < porRecorrer.length) {
      String q = porRecorrer[i];

      List<Transicion> ts = this.buscarTransiciones(q, a.transitions);

      List<List<String>> siguientes = ts.map((f) => f.qouput).toList();

      for (List<String> s in siguientes) {
        if (estados.indexOf(s.toString()) == -1) {
          estados.add(s.toString());
        }
        if (porRecorrer.indexOf(s.toString()) == -1) {
          porRecorrer.add(s.toString());
        }
      }
      for (Transicion t in ts) {
        Transicion newT = Transicion(
            qinput: "q${estados.indexOf(t.qinput)}",
            leter: t.leter,
            qouput: ["q${estados.indexOf(t.qouput.toString())}"]);
        tsRenombradas.add(newT);
      }

      i++;
    }
    List<String> estadosRenombrados = [];
    List<String> finalesRenombrados = [];
    for (var i = 0; i < estados.length; i++) {
      estadosRenombrados.add('q$i');
      if (a.finalStates.contains(estados[i])) {
        finalesRenombrados.add('q$i');
      }
    }

    Automata resultado = new Automata(
        transitions: tsRenombradas,
        states: estadosRenombrados,
        finalStates: finalesRenombrados,
        alphabet: a.alphabet,
        initialState: 'q0');
    return resultado;
  }

  //Busca las transiciones de un estado
  List<Transicion> buscarTransiciones(String q, List<Transicion> ts) {
    List<Transicion> resultado = [];
    for (Transicion t in ts) {
      if (t.qinput == q) {
        resultado.add(t);
      }
    }
    return resultado;
  }

  List<String> busqueda(List<String> estados, String leter) {
    List<String> resultado = [];
    for (String q in estados) {
      for (Transicion t in this.transitions) {
        if (t.qinput == q && t.leter == leter) {
          resultado.addAll(t.qouput);
        }
      }
    }

    if (resultado.length > 0) {
      resultado = resultado.toSet().toList();
      resultado.sort();
    }
    return resultado;
  }

  static formatBin(int size, int bin) {
    String binString = bin.toString();
    while (binString.length < size) {
      binString = '0' + binString;
    }

    return binString;
  }

  static int toBin(int decimal) {
    int bin = 0, i = 1;
    while (decimal > 0) {
      bin = bin + (decimal % 2) * i;
      decimal = (decimal / 2).floor();
      i = i * 10;
    }
    return bin;
  }

  //RE
  void or(Automata a) {
    String e0 = Automata.nextState().toString();
    String e01 = this.initialState;
    String e02 = a.initialState;
    List<String> ef1 = this.finalStates;
    List<String> ef2 = a.finalStates;
    String ef0 = Automata.nextState().toString();

    this.states.add(e0);
    this.states.add(ef0);
    this.joinElementos(a);

    this.transitions.add(Transicion(qinput: e0, leter: "", qouput: [e01]));
    this.transitions.add(Transicion(qinput: e0, leter: "", qouput: [e02]));
    this.transitions.add(Transicion(qinput: ef1[0], leter: "", qouput: [ef0]));
    this.transitions.add(Transicion(qinput: ef2[0], leter: "", qouput: [ef0]));
    this.initialState = e0;
    this.finalStates = [ef0];
  }

  void and(Automata a) {
    String e01 = this.initialState;
    String e02 = a.initialState;
    List<String> ef1 = this.finalStates;
    List<String> ef2 = a.finalStates;

    this.transitions.add(Transicion(qinput: ef1[0], leter: "", qouput: [e02]));
    this.joinElementos(a);
    this.finalStates = ef2;
    this.initialState = e01;
  }

  void kleen() {
    String e01 = this.initialState;
    List<String> ef1 = this.finalStates;
    String e0 = Automata.nextState().toString();
    String ef0 = Automata.nextState().toString();

    this.states.add(e0);
    this.states.add(ef0);

    this.transitions.add(Transicion(qinput: e0, leter: "", qouput: [e01]));
    this.transitions.add(Transicion(qinput: e0, leter: "", qouput: [ef0]));
    this.transitions.add(Transicion(qinput: ef1[0], leter: "", qouput: [e01]));
    this.transitions.add(Transicion(qinput: ef1[0], leter: "", qouput: [ef0]));

    this.finalStates = [ef0];
    this.initialState = e0;
  }

  joinEstados(Automata a) {
    for (String e in a.states) {
      if (this.states.indexOf(e) == -1) {
        this.states.add(e);
      }
    }
  }

  joinAlfabeto(Automata a) {
    for (String c in a.alphabet) {
      if (this.alphabet.indexOf(c) == -1) {
        this.alphabet.add(c);
      }
    }
    this.alphabet.sort();
  }

  joinTransiciones(Automata a) {
    for (Transicion t in a.transitions) {
      this.transitions.add(t);
    }
  }

  joinElementos(Automata a) {
    this.joinTransiciones(a);
    this.joinAlfabeto(a);
    this.joinEstados(a);
  }
}

class Transicion {
  String qinput = "";
  List<String> qouput = [];
  String leter;

  Transicion({this.qinput, this.leter, this.qouput});

  @override
  String toString() {
    return "($qinput, $leter) = $qouput";
  }
}

main(List<String> args) {
  /* List<Transicion> ts = [
    Transicion(qinput: 'q0', leter: 'a', qouput: ['q0', 'q1']),
    Transicion(qinput: 'q0', leter: 'b', qouput: ['q0']),
    Transicion(qinput: 'q1', leter: 'b', qouput: ['q2'])
  ]; */

  List<Transicion> ts = [
    Transicion(qinput: 'A', leter: '', qouput: ['B']),
    Transicion(qinput: 'A', leter: '0', qouput: ['A']),
    Transicion(qinput: 'B', leter: '0', qouput: ['C']),
    Transicion(qinput: 'B', leter: '', qouput: ['D']),
    Transicion(qinput: 'C', leter: '1', qouput: ['B']),
    Transicion(qinput: 'D', leter: '0', qouput: ['D']),
    Transicion(qinput: 'D', leter: '1', qouput: ['D']),
  ];
  Automata a = new Automata(states: [
    'A',
    'B',
    'C',
    'D',
  ], alphabet: [
    '0',
    '1'
  ], finalStates: [
    'D'
  ], initialState: 'A', transitions: ts);

  a.thompsonToNFA(a);
}
