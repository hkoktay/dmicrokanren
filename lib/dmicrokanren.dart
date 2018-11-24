/// This is an implementation of microkanren based on Jasen Hemanns and
/// Daniel P. Friedmanns microkanren implementation. This implementation
/// is a little more verbose because of the abstractions for logic
/// variables, the State, Substitutions and the Stream data structure.
///
/// This implementation uses four data structures: [Var], [Substitution],
/// [State], and [MkStream]. Also we use two types of functions the [Goal]
/// and [MkFunc].
///
/// The [Var] data structure is a class with one property, a natural number,
/// and represents a logic variable. Logic variables are used to bind values
/// like numbers, strings, symbols or lists. These bindings are stored in a
/// [Substitution]. A Substitution can be searched for a [Var] binding with
/// the [walk] method and extended with other bindings with the [extend]
/// method. A [State] is a class with two properties: a [Substitution] and a
/// [counter]. We use the [counter] property to create unique logic variables
/// inside [State] data structure. Everytime we create a new [Var] inside a
/// State we increase the [counter] by one. The last data structure, a
/// [MkStream], is a class with one property. This property is either a list
/// or a function.
///
/// In the original microkanren implementation cons pairs are used to create
/// a microkanren Stream. This stream could be either a function or a list.
/// The former is called an immature Stream and the latter a mature Stream.
/// The mature Stream is either an empty list or a list with a [State] data
/// structure as its first element and a stream as its second element.
///
/// Instead of using "cons" pairs this implementation uses a list data
/// structure inside the [MkStream] class. You can see the difference in the
/// implementation of the [mplus] function. It is mostly the same as the
/// original implementation, except that it uses a helper function, which uses
/// the buildin dart List data structure instead of cons pairs. I could have
/// used an iterative algorithm for mplus instead of the original recursive one
/// but I wanted to stay close to the orginal implementation.
library dmicrokanren;

import 'dart:core';

/// A representation of a logic variable
///
/// This class represents a logic variable. Logic variables are equal if
/// the property value [n] is equal.
class Var {
  final int n;

  Var(this.n);

  /// Checks if two logic variables are equal
  bool isEqual(Var v) {
    if (this.n == v.n) {
      return true;
    } else {
      return false;
    }
  }

  /// The logic variable equality operator
  ///
  /// Two logic variables are equal if their property value [n]
  /// is equal.
  bool operator ==(other) {
    if (other is! Var) return false;
    if (this.n == other.n) {
      return true;
    } else {
      return false;
    }
  }

  int get hashCode => super.hashCode;
}

/// Holds bindings of logic variables to values
///
/// The datastructure for the bindings is implemented as an alist.
/// The first elemenent of the elements of the a list is a logic
/// variable and the second element is the bound value. For example
/// if the value of the [bindings] property is something like this:
/// ```
/// [[Var(0), 5], [Var(1), "test"]]
/// ```
/// The value 5 is bound to the logic variable Var(0) and the value
/// "test" is bound to the logic variable Var(1).
class Substitution {
  var bindings = List();

  Substitution(List l) {
    this.bindings = l;
  }

  Substitution.empty();

  /// Checks if the Substitution is empty.
  bool isEmpty() {
    if (bindings.isEmpty) {
      return true;
    } else {
      return false;
    }
  }

  /// Returns a new, extended Substitution.
  ///
  /// Returns a new Substitution extended with the logic variable [u]
  /// and a value [val].
  Substitution extend(Var u, dynamic val) {
    var newBindings = this.bindings +
        [
          [u, val]
        ];
    return Substitution(newBindings);
  }

  /// Looks up the value of a logic variable
  ///
  /// Searches for the logic variable in the bindings of the Substitution.
  /// Logic variables can be linked to other logic variables so we can't simply
  /// get use a simple lookup. If a logic varible has another logic variable as
  /// a value we have to walk the substitution again for that logic variable.
  /// This method returns either the boolean false or the argument value [u].
  dynamic walk(dynamic u) {
    dynamic pr;
    dynamic getVar(Var v) {
      for (var item in this.bindings) {
        if (v.isEqual(item[0])) return item[1];
      }
      return false;
    }

    if (u is Var) {
      pr = getVar(u);
      if (pr == false) {
        return u;
      } else {
        return walk(pr);
      }
    } else {
      return u;
    }
  }
}

/// The microkanren State data structure
///
/// A microkanren program proceeds by applying a goal function to a state.
/// A state is a datastructure which holds all the relevant information
/// for executing a microkanren program and is implemented as a class with
/// two properties: a Substitution [sub] and a [counter]. The Substitution
/// holds the bindings of the logic variables while the counter is used to
/// assign a unique number to a logic variable.
class State {
  var sub = Substitution.empty();
  int counter = 0;

  State(this.sub, this.counter);

  State.empty();
}

/// A microkanren Stream
///
/// If we apply a [Goal] to a [State] in a microkanren program we get a [MkStream].
/// A Mkstream can be mature or immature. If the class property [content] is a
/// function MkStream is a immature Stream. If it is a list it is a mature Stream.
class MkStream {
  dynamic content;

  MkStream(dynamic x) {
    if ((x is Function) || (x is List)) {
      this.content = x;
    } else {
      throw Error();
    }
  }

  MkStream.empty() {
    this.content = List();
  }

  /// Checks if the mk stream is empty
  bool isEmpty() {
    if ((this.content is List) && this.content.isEmpty) {
      return true;
    } else {
      return false;
    }
  }

  /// Checks if the MkSteram is mature.
  bool isImmature() {
    if (this.content is Function) {
      return true;
    } else {
      return false;
    }
  }

  /// Returns an new, extendend MkStream data structure.
  MkStream extend(x) {
    this.content.add(x);
    return MkStream(this.content);
  }
}

typedef Goal = MkStream Function(State sc);
typedef MkFunc = Goal Function(Var v);

/// Unifies two microkanren terms
///
/// Takes two terms [u] and [s] and a Substitution [s] as arguments and
/// unifies both terms. Returns either a [Substitution] or false.
dynamic unify(dynamic u, dynamic v, Substitution s) {
  final nu = s.walk(u);
  final nv = s.walk(v);
  if ((nu is Var) && (nv is Var) && nu.isEqual(nv)) {
    return s;
  } else if (nu is Var) {
    return s.extend(nu, nv);
  } else if (nv is Var) {
    return s.extend(nv, nu);
  } else if ((nu is List) && (nv is List) && !nu.isEmpty && !nv.isEmpty) {
    var newSub = unify(nu[0], nv[0], s);
    if (newSub == false) {
      return false;
    } else {
      return unify(nu.sublist(1), nv.sublist(1), newSub);
    }
    // We must add an additional check because the '==' operator returns
    // false when comparing two empty lists.
  } else if ((nu is List) && (nv is List) && nu.isEmpty && nv.isEmpty) {
    return s;
  } else if ((nu == nv) && s != false) {
    return s;
  } else {
    return false;
  }
}

/// Creates a new [MkStream] data structure out of a [State].
MkStream unit(State s) {
  return MkStream.empty().extend(s);
}

/// Goal constructor and constrain
///
/// Returns a [Goal], which is a microkanren constrain. If the goal
/// is applied to a state it returns either an empty [MkStream] or
/// a MkStream with a state where the variables [u] and [v] were unified.
Goal equal(dynamic u, dynamic v) {
  return (State sc) {
    var s = unify(u, v, sc.sub);
    if (s == false) {
      return MkStream.empty();
    } else {
      var newState = State(s, sc.counter);
      return unit(newState);
    }
  };
}

/// Goal constructor that introduces new logic variables
///
/// Expects a [MkFunc] function as an argument and returns a [Goal].
Goal callFresh(MkFunc f) {
  return (State sc) {
    var c = sc.counter;
    var v = Var(c);
    var newState = State(sc.sub, sc.counter + 1);
    return f(v)(newState);
  };
}

/// disjunction goal constructor
///
/// Returns a [Goal] if either of the two goal constructors succeed. The
/// disj function is like a logical *or*.
Goal disj(Goal g1, Goal g2) {
  return (State sc) {
    return mplus(g1(sc), g2(sc));
  };
}

/// conjunction goal constructor
///
/// Returns a [Goal] if both of its goal constructor arguments succeed. The
/// conj function is like a logical *and*.
Goal conj(Goal g1, Goal g2) {
  return (State sc) {
    return bind(g1(sc), g2);
  };
}

/// Merges two streams
MkStream mplus(MkStream st1, MkStream st2) {
  var lst1 = st1.content;
  var lst2 = st2.content;

  // The helper function returns either a function or a list
  dynamic mplusHelper(dynamic l1, dynamic l2) {
    if (l1 is List && l1.isEmpty) {
      return l2;
    } else if (l1 is Function) {
      return () => mplus(st2, l1());
    } else {
      var first = List()..add(l1.first);
      return first + mplusHelper(l1.sublist(1), l2);
    }
  }

  return MkStream(mplusHelper(lst1, lst2));
}

/// Applies the goal [g] to the MkStream [st].
MkStream bind(MkStream st, Goal g) {
  if (st.isEmpty()) {
    return MkStream.empty();
  } else if (st.isImmature()) {
    return MkStream(() => bind(st.content.first(), g));
  } else {
    return mplus(g(st.content[0]), bind(MkStream(st.content.sublist(1)), g));
  }
}
