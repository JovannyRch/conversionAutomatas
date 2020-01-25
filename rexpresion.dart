import 'conversionAutomatas.dart';

class Expresion {
  String infija;
  String postfija;
  List<String> operadores;
  Map precedencia;
  List<String> alfabeto = [];
  Map automatasBase = Map();
  Automata thompson;
  Expresion({this.infija, this.operadores, this.precedencia}) {
    this.postfija = this.getPostfix();
    this.alfabeto.sort();

    for (String car in this.alfabeto) {
      String q0 = Automata.nextState().toString();
      String qf = Automata.nextState().toString();
      List<Transicion> ts = [
        Transicion(qinput: q0, leter: car, qouput: [qf])
      ];
      automatasBase[car] = Automata(
        transitions: ts,
        alphabet: [car],
        states: [q0, qf],
        initialState: q0,
        finalStates: [qf],
      );
      //print(automatasBase[car]);
    }

    this.thompson = this.evaluar(this.postfija);
    this.thompson.printAutomata();
    this.thompson.thompsonToNFA(this.thompson);
  }

  Automata evaluar(expresion) {
    List<Automata> pila = [];
    for (int i = 0; i < expresion.length; i++) {
      String car = expresion[i];
      if (operadores.indexOf(car) >= 0) {
        // Evaluar
        Automata a = pila.removeLast();
        if (["|", "."].indexOf(car) >= 0) {
          Automata b = pila.removeLast();
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
}

main() {
  List<String> operadores = ["*", ".", "|", "(", ")"];
  Map prec = {"*": 2, ".": 1, "|": 0, "(": -1, ")": -2};
  String infija = "a.b*";
  Expresion ex =
      Expresion(infija: infija, operadores: operadores, precedencia: prec);
  print(ex.postfija);
}
