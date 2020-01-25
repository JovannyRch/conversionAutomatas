// Transicion Normal para automatas AFND y AFD
import 'conversionAutomatas.dart';

class TransicionNFA {
  List<int> qentrada;
  String letra;
  List<int> qsalida;
  TransicionNFA({this.qentrada, this.letra, this.qsalida});

  @override
  String toString() {
    return '($qentrada,$letra)=$qsalida';
  }
}

class AutomataNFA {
  List<int> estados = [];
  List<TransicionNFA> trasnsiciones = [];
  List<String> alfabeto = [];
  List<int> finales = [];
  int inicial = 0;
}

// Transicion de Thompson
class TransicionT {
  int qentrada;
  String letra;
  int qsalida;
  TransicionT({this.qentrada, this.letra, this.qsalida});

  @override
  String toString() {
    return '($qentrada,$letra)=$qsalida';
  }
}

class Convertidor {
  void thompsonToNFA(AutomataT a) {
    List<int> ep1 = [];
    print(a.estados);
    Map<String, int> mapEstados = new Map();
    List<String> finales = [];
    List<Transicion> ts = [];
    for (int q in a.estados) {
      ep1 = this.epsilonClosure(q, a.transiciones);
      if (finales.indexOf(a.qfinal.toString()) == -1 &&
          ep1.contains(a.qfinal)) {
        finales.add(q.toString());
      }
      for (String letra in a.alfabeto) {
        List<int> alcanzables = this.alcanzables(ep1, a.transiciones, letra);
        List<int> ep2 = [];
        for (int q in alcanzables) {
          List<int> epCs = this.epsilonClosure(q, a.transiciones);
          for (var q2 in epCs) {
            if (ep2.indexOf(q2) == -1) ep2.add(q2);
          }
        }
        if (mapEstados[ep2.toString()] == null)
          mapEstados[ep2.toString()] = Expresion.nextState();

        if (ep2.length > 0) {
          //print("($q,$letra) = ${ep2.toString()}");
          Transicion(
            qinput: q.toString(),
            leter: letra,
            qouput: ep2.map((f) => f.toString()).toList(),
          );
        }
      }
    }
    print("finales $finales");
    Automata b = new Automata(
        states: a.estados.map((f) => f.toString()).toList(),
        alphabet: a.alfabeto,
        finalStates: finales,
        initialState: a.qinicial.toString(),
        transitions: ts);
    b.printAutomata();
    b.convertirDFA();
    b.afd.printAutomata();
    b.afdreducido.printAutomata();
  }

  //Alcanzables con una letra
  List<int> alcanzables(List<int> lista, List<TransicionT> ts, String letra) {
    List<int> qs = [];
    for (int q in lista) {
      for (TransicionT t in ts) {
        if (t.qentrada == q &&
            t.letra == letra &&
            qs.indexOf(t.qsalida) == -1) {
          qs.add(t.qsalida);
        }
      }
    }
    qs.sort();
    return qs;
  }

  //Clausura Epsilon
  List<int> epsilonClosure(int q, List<TransicionT> ts) {
    List<int> qs = [];
    qs.add(q);
    List<int> busqueda = [];
    busqueda.add(q);

    while (busqueda.length > 0) {
      int qBuscando = busqueda[0];
      for (TransicionT t in ts) {
        if (t.qentrada == qBuscando &&
            t.letra == "" &&
            qs.indexOf(t.qsalida) == -1) {
          qs.add(t.qsalida);
          busqueda.add(t.qsalida);
        }
      }
      busqueda.removeAt(0);
    }

    qs.sort();
    return qs;
  }
}

// Automata de Thompson
class AutomataT {
  List<TransicionT> transiciones;
  List<String> alfabeto;
  int qinicial;
  int qfinal;
  List<int> estados;

  AutomataT(
      {this.alfabeto,
      this.estados,
      this.transiciones,
      this.qinicial,
      this.qfinal});

  @override
  String toString() {
    String result = "";
    result = "----- AUTOMATA----\nTransiciones\n";
    for (var t in this.transiciones) {
      result = result + t.toString() + "\n";
    }
    result += "\nAlfabeto: " + this.alfabeto.toString();
    result += "\nEstados: " + this.estados.toString();
    result += "\ninicial: $qinicial";
    result += "\nfinal: $qfinal";
    return result; // volver a poner result
  }

  joinEstados(AutomataT a) {
    for (int e in a.estados) {
      if (this.estados.indexOf(e) == -1) {
        this.estados.add(e);
      }
    }
  }

  joinAlfabeto(AutomataT a) {
    for (String c in a.alfabeto) {
      if (this.alfabeto.indexOf(c) == -1) {
        this.alfabeto.add(c);
      }
    }
    this.alfabeto.sort();
  }

  joinTransiciones(AutomataT a) {
    for (TransicionT t in a.transiciones) {
      this.transiciones.add(t);
    }
  }

  joinElementos(AutomataT a) {
    this.joinTransiciones(a);
    this.joinAlfabeto(a);
    this.joinEstados(a);
  }

  void or(AutomataT a) {
    int e0 = Expresion.nextState();
    int e01 = this.qinicial;
    int e02 = a.qinicial;
    int ef1 = this.qfinal;
    int ef2 = a.qfinal;
    int ef0 = Expresion.nextState();

    this.estados.add(e0);
    this.estados.add(ef0);
    this.joinElementos(a);

    this.transiciones.add(TransicionT(qentrada: e0, letra: "", qsalida: e01));
    this.transiciones.add(TransicionT(qentrada: e0, letra: "", qsalida: e02));
    this.transiciones.add(TransicionT(qentrada: ef1, letra: "", qsalida: ef0));
    this.transiciones.add(TransicionT(qentrada: ef2, letra: "", qsalida: ef0));
    this.qinicial = e0;
    this.qfinal = ef0;
  }

  void and(AutomataT a) {
    int e01 = this.qinicial;
    int e02 = a.qinicial;
    int ef1 = this.qfinal;
    int ef2 = a.qfinal;

    this.transiciones.add(TransicionT(qentrada: ef1, letra: "", qsalida: e02));
    this.joinElementos(a);
    this.qfinal = ef2;
    this.qinicial = e01;
  }

  void kleen() {
    int e01 = this.qinicial;
    int ef1 = this.qfinal;
    int e0 = Expresion.nextState();
    int ef0 = Expresion.nextState();

    this.estados.add(e0);
    this.estados.add(ef0);

    this.transiciones.add(TransicionT(qentrada: e0, letra: "", qsalida: e01));
    this.transiciones.add(TransicionT(qentrada: e0, letra: "", qsalida: ef0));
    this.transiciones.add(TransicionT(qentrada: ef1, letra: "", qsalida: e01));
    this.transiciones.add(TransicionT(qentrada: ef1, letra: "", qsalida: ef0));

    this.qfinal = ef0;
    this.qinicial = e0;
  }
}

String toPostfix(String infija, List<String> operadores, Map prec) {
  List<String> opStack = [];
  List<String> postfixList = [];
  String postfix = "";
  for (var i = 0; i < infija.length; i++) {
    String caracter = infija[i];
    if (!operadores.contains(caracter)) {
      postfixList.add(caracter);
    } else if (caracter == "(") {
      opStack.add(caracter);
    } else if (caracter == ")") {
      String topToken = opStack.removeLast();
      while (topToken != "(") {
        postfixList.add(topToken);
        topToken = opStack.removeLast();
      }
    } else {
      while (opStack.length != 0 && (prec[opStack.last] >= prec[caracter])) {
        postfixList.add(opStack.removeLast());
      }
      opStack.add(caracter);
    }
  }

  while (opStack.length > 0) {
    postfixList.add(opStack.removeLast());
  }

  postfix = postfixList.join("");

  return postfix;
}

class Expresion {
  String infija;
  String postfija;
  List<String> operadores;
  Map precedencia;
  List<String> alfabeto = [];
  Map automatasBase = Map();
  AutomataT thompson;
  Convertidor convertidor = Convertidor();
  static int contadorAutomatas = -1;
  Expresion({this.infija, this.operadores, this.precedencia}) {
    this.postfija = this.getPostfix();
    this.alfabeto.sort();

    //Recorrer el alfabeto para construir los automatas base
    for (String car in this.alfabeto) {
      int q0 = Expresion.nextState();
      int qf = Expresion.nextState();
      List<TransicionT> ts = [
        TransicionT(qentrada: q0, letra: car, qsalida: qf)
      ];
      automatasBase[car] = AutomataT(
          transiciones: ts,
          alfabeto: [car],
          estados: [q0, qf],
          qinicial: q0,
          qfinal: qf);
    }

    this.thompson = this.evaluar(this.postfija);
    Automata thompson = Automata(
      alphabet: this.thompson.alfabeto,
      initialState: this.thompson.qinicial.toString(),
      finalStates: [this.thompson.qfinal.toString()],
      states: this.thompson.estados.map((f) => f.toString()).toList(),
    );
    print(this.thompson);

    this.convertidor.thompsonToNFA(this.thompson);
  }

  static int nextState() {
    contadorAutomatas++;
    return contadorAutomatas;
  }

  getPostfix() {
    List<String> opStack = [];
    List<String> postfixList = [];
    String postfix = "";
    for (var i = 0; i < infija.length; i++) {
      String caracter = infija[i];
      if (!operadores.contains(caracter)) {
        postfixList.add(caracter);
        if (!alfabeto.contains(caracter)) {
          alfabeto.add(caracter);
        }
      } else if (caracter == "(") {
        opStack.add(caracter);
      } else if (caracter == ")") {
        String topToken = opStack.removeLast();
        while (topToken != "(") {
          postfixList.add(topToken);
          topToken = opStack.removeLast();
        }
      } else {
        while (opStack.length != 0 &&
            (precedencia[opStack.last] >= precedencia[caracter])) {
          postfixList.add(opStack.removeLast());
        }
        opStack.add(caracter);
      }
    }

    while (opStack.length > 0) {
      postfixList.add(opStack.removeLast());
    }

    postfix = postfixList.join("");

    return postfix;
  }

  AutomataT evaluar(expresion) {
    List<AutomataT> pila = [];
    for (int i = 0; i < expresion.length; i++) {
      String car = expresion[i];
      if (operadores.indexOf(car) >= 0) {
        // Evaluar
        AutomataT a = pila.removeLast();
        if (["|", "."].indexOf(car) >= 0) {
          AutomataT b = pila.removeLast();
          switch (car) {
            case "|":
              b.or(a);
              pila.add(b);
              break;
            case ".":
              b.and(a);
              pila.add(b);
              break;
          }
        }
        if (car == "*") {
          a.kleen();
          pila.add(a);
        }
      } else {
        pila.add(automatasBase[car]);
      }
    }
    return pila.removeLast();
  }
}

main() {
  List<String> operadores = ["*", ".", "|", "(", ")"];
  Map prec = {"*": 2, ".": 1, "|": 0, "(": -1, ")": -2};
  String infija = "a*";
  Expresion ex =
      Expresion(infija: infija, operadores: operadores, precedencia: prec);
  print(ex.postfija);
}
