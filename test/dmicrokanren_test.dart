import 'dart:core';
import 'package:test/test.dart';
import 'package:dmicrokanren/dmicrokanren.dart';

var aAndB = conj(callFresh((a) => equal(a, 7)),
    callFresh((b) => disj(equal(b, 5), equal(b, 6))));

fives(x) {
  return disj(equal(x, 5), (ac) {
    return MkStream.empty().extend(() => fives(x)(ac));
  });
}

void main() {
  group("Test substitution walk", () {
    // The substitution has two bindings. This test checks if walk find the
    // value of the binding with the variable Var(2), which is at the end of
    // of the substitution.
    test("Substitution walk, find binding at the end", () {
      var s =
          Substitution.empty().extend(Var(1), "eins").extend(Var(2), "zwei");
      expect(s.walk(Var(2)), "zwei");
    });
    // A slight modification of the test above. This test checks if walk finds
    // a binding which is at the beginning of the substitution.
    test("Test substitution walk, find binding at the beginning", () {
      var s =
          Substitution.empty().extend(Var(1), "eins").extend(Var(2), "zwei");
      expect(s.walk(Var(1)), "eins");
    });
    // This test checks if walk finds a binding which is in the middle of a
    // substitution.
    test("Test substitution walk, find binding in the middle", () {
      var s = Substitution.empty()
          .extend(Var(1), "eins")
          .extend(Var(2), "zwei")
          .extend(Var(3), "drei");
      expect(s.walk(Var(2)), "zwei");
    });
    // Test walk with a Var, which is not in the Substitution data structure.
    // The expected result is the argument itself.
    test("Test substitution walk with Var not in Sub", () {
      var s =
          Substitution.empty().extend(Var(1), "eins").extend(Var(2), "zwei");
      var lv = Var(3);
      expect(s.walk(lv), lv);
    });
    test("Test substitution walk with empty substitution", () {
      var v = Var(1);
      var s = Substitution.empty();
      expect(s.walk(v).n, 1);
    });
    // Bindings can be "linked", which means that logic variable Var can have
    // another logic variable as a value. If the function walk finds such a
    // variable it has to search the substitution again for a binding for that
    // variable. Note that in a Substitution and thus in a state every logic
    // variable is unique, thus there is no circularity.
    //
    // This test checks if walk correctly follows the next Var to find the right
    // value.
    test("Test substitution walk with linked logic variables", () {
      var s = Substitution.empty()
          .extend(Var(1), "eins")
          .extend(Var(2), Var(3))
          .extend(Var(3), "drei");
      var lv = Var(2);
      expect(s.walk(lv), "drei");
    });
    // This test checks if walk finds a deeply linked Var.
    test("Test substitution walk with non logic Variable", () {
      var s = Substitution.empty()
          .extend(Var(1), "eins")
          .extend(Var(5), "five")
          .extend(Var(2), Var(3))
          .extend(Var(3), Var(4))
          .extend(Var(4), Var(5));
      expect(s.walk(Var(2)), "five");
    });
  });

  group("Test unify", () {
    // Tests if the unify returns the same Substitution if both of its arguments
    // are of type Var and both Vars are equal.
    test("test unify with two equal Var objects", () {
      var s = Substitution.empty().extend(Var(0), 2);
      var computedResult = unify(Var(0), Var(0), s);
      var expectedResult = Substitution.empty().extend(Var(0), 2);
      expect(computedResult.bindings.length, 1);
      expect(computedResult.bindings[0][0].n, 0);
      expect(computedResult.bindings[0][1], 2);
    });
    // Test the case where one variable is of type Var and the Var has also the
    // equal value in the substitution. We expect unify to return the original
    // Substitution.
    test("test unify with Var 0 and 2", () {
      var s = Substitution.empty().extend(Var(0), 2);
      var computedResult = unify(Var(0), 2, s);
      var expectedResult = Substitution.empty().extend(Var(0), 2);
      expect(computedResult.bindings.length, 1);
      expect(computedResult.bindings[0][0].n, 0);
      expect(computedResult.bindings[0][1], 2);
    });
    // We test the case where one argument is a Var which is also in the
    // Substitution but with a different value. The unification should
    // return false.
    test("test unify with Var and integer", () {
      var s = Substitution.empty().extend(Var(0), 2);
      var computedResult = unify(Var(0), 3, s);
      expect(computedResult, false);
    });
    // We test if unify extends the Substituion when one of its arguments
    // is a Var which is not in the original Substitution. The result should
    // be a Substitution with the new Var. Note that the unification "connects"
    // The Var(0) with Var(1) and since Var(0) has the binding 2 also Var(1)
    // must have the binding 2.
    test("test unify with a Var extending the substitution", () {
      var s = Substitution.empty().extend(Var(0), 2);
      var computedResult = unify(Var(0), Var(1), s);
      var expectedResult =
          Substitution.empty().extend(Var(0), 2).extend(Var(1), 2);
      expect(computedResult.bindings.length, 2);
      expect(computedResult.bindings[0][0].n, 0);
      expect(computedResult.bindings[0][1], 2);
      expect(computedResult.bindings[1][0].n, 1);
      expect(computedResult.bindings[1][1], 2);
    });
    // We test the conditional of unifying a list arguments.
    test("test unify with a list of Var objects", () {
      var s = Substitution.empty().extend(Var(0), 2);
      var computedResult = unify([Var(0), Var(1)], [Var(0), Var(1)], s);
      expect(computedResult.bindings[0][1], 2);
    });
    test("test unify with two equal terms", () {
      var s = Substitution.empty().extend(Var(0), 2);
      var computedResult = unify(2, 2, s);
      var expectedResult = Substitution.empty().extend(Var(0), 2);
      expect(computedResult.bindings.length, 1);
      expect(computedResult.bindings[0][0].n, 0);
      expect(computedResult.bindings[0][1], 2);
    });
    test("test unify with different arguments", () {
      var s = Substitution.empty().extend(Var(0), 2);
      var computedResult = unify(2, 3, s);
      expect(computedResult, false);
    });
    test("test unify with empty list arguments", () {
      var s = Substitution.empty().extend(Var(0), 2);
      var computedResult = unify([], [], s);
      // Check if the substitution is the same
      expect(computedResult.bindings[0][1], 2);
      expect(computedResult.bindings.length, 1);
    });
  });
  // We must test two scenarios. The equal funciton should return an
  // empty MkStream everytime the unify function returns false. Also
  // equal should return a MkStream with the same Substitution as the
  // unfify function.
  group("Test equal goal constructor", () {
    // With equal arguments the unify function returns simply the
    // unchanged substitution. Thus the equal functions returns a
    // MkStream with the same substitution.
    test("test equal with two equal arguments", () {
      var sub = Substitution.empty().extend(Var(0), 1);
      var s = State(sub, 1);
      var computedResult = equal(1, 1)(s);
      // Check the value bound to Var(0)
      expect(computedResult.content[0].sub.bindings[0][1], 1);
      // Check the length of the Substitution
      expect(computedResult.content[0].sub.bindings.length, 1);
      // Check the counter
      expect(computedResult.content[0].counter, 1);
    });
    // The same like above but with two Var arguments
    test("test equal with two equal Vars", () {
      var s = State(Substitution.empty().extend(Var(0), 1), 1);
      var computedResult = equal(Var(0), Var(0))(s);
      // Check the value bound to Var
      expect(computedResult.content[0].sub.bindings[0][1], 1);
      // Check the length of the Substitution
      expect(computedResult.content[0].sub.bindings.length, 1);
      // Check the counter
      expect(computedResult.content[0].counter, 1);
    });
    // Since the unify function returns false in this scenario,
    // equal returns an empty MkStream.
    test("test equal with non equal arguments", () {
      var s = State(Substitution.empty().extend(Var(0), 1), 1);
      var computedResult = equal(2, 1)(s);
      expect(computedResult.isEmpty(), true);
    });
    // The unify functions extends the Substitution with the new
    // variable, thus the equal function should have the same
    // Substitution inside the MkStream.
    test("test equal with an extendend Substitution", () {
      var s = State(Substitution.empty().extend(Var(0), 1), 1);
      var computedResult = equal(2, Var(1))(s);
      // Since the Substition is extendeed with Var(1) and the value 2
      // its length is now 2.
      expect(computedResult.content[0].sub.bindings.length, 2);
      // Check the value of Var(0)
      expect(computedResult.content[0].sub.bindings[0][1], 1);
      // Check the value of Var(1)
      expect(computedResult.content[0].sub.bindings[1][1], 2);
      // Check the counter
      expect(computedResult.content[0].counter, 1);
    });
    // The unify function returns false, since Var(0) is already in the
    // Substitution with a different value thus cannot have the value 2.
    // The return value of equal is an empty MkStream.
    test("test equal with Var already in the Substitution", () {
      var s = State(Substitution.empty().extend(Var(0), 1), 1);
      var computedResult = equal(2, Var(0))(s);
      expect(computedResult.isEmpty(), true);
    });
    test("test equal with Var with empty Substitution", () {
      var s = State(Substitution.empty(), 1);
      var computedResult = equal(2, Var(0))(s);
      expect(computedResult.content.length, 1);
      expect(computedResult.content[0].sub.bindings[0][1], 2);
    });
    test("test equal with matching list argument", () {
      var s = State(
          Substitution.empty().extend(Var(0), 1).extend(Var(1), [2, 3]), 1);
      var computedResult = equal([2, 3], Var(1))(s);
      expect(computedResult.content[0].sub.bindings[1][1], [2, 3]);
    });
    test("test equal with non matching list argument", () {
      var s = State(
          Substitution.empty().extend(Var(0), 1).extend(Var(1), [2, 3]), 1);
      var computedResult = equal([2, 1], Var(1))(s);
      expect(computedResult.isEmpty(), true);
    });
  });
  // We must test if callFresh creates a new logic variable and if
  // it correctly increases the State counter by one.
  group("Test callFresh", () {
    test("test if callFresh creates a new logic variable", () {
      var sub = Substitution.empty();
      var state0 = State(sub, 0);
      var computedResult = callFresh((x) => equal(x, "a"))(state0);
      // Check value of Var
      expect(computedResult.content[0].sub.bindings[0][1], "a");
      // The property value of the logic variable
      expect(computedResult.content[0].sub.bindings[0][0].n, 0);
      // Check number of bindings
      expect(computedResult.content[0].sub.bindings.length, 1);
      // Check counter
      expect(computedResult.content[0].counter, 1);
    });
    test(
        "test if callFresh creates a new logic variable and extends the substitution",
        () {
      var sub = Substitution.empty().extend(Var(0), "one");
      var state0 = State(sub, 1);
      var computedResult = callFresh((x) => equal(x, "a"))(state0);
      // Check value of first Var
      expect(computedResult.content[0].sub.bindings[0][1], "one");
      // check value of second Var
      expect(computedResult.content[0].sub.bindings[1][1], "a");
      // The property value of the logic variable
      expect(computedResult.content[0].sub.bindings[0][0].n, 0);
      // Check property value of the new logic variable
      expect(computedResult.content[0].sub.bindings[1][0].n, 1);
      // Check number of bindings
      expect(computedResult.content[0].sub.bindings.length, 2);
      // Check counter
      expect(computedResult.content[0].counter, 2);
    });
    test("test if callFresh with conj", () {
      var computedResult =
          callFresh((x) => callFresh((y) => conj(equal(y, x), equal("z", x))))(
              State.empty());
      // Check length of Substitution
      expect(computedResult.content[0].sub.bindings.length, 2);
      // Check counter
      expect(computedResult.content[0].counter, 2);
      // Check first Var value
      expect(computedResult.content[0].sub.bindings[0][0].n, 1);
      expect(computedResult.content[0].sub.bindings[0][1].n, 0);
      expect(computedResult.content[0].sub.bindings[1][0].n, 0);
      expect(computedResult.content[0].sub.bindings[1][1], "z");
    });

    test("test if callFresh with disj", () {
      var computedResult = disj(callFresh((x) => equal("z", x)),
          callFresh((x) => equal(["s", "z"], x)))(State.empty());
      // Check length of content, should be two States
      expect(computedResult.content.length, 2);
      // Check counters
      expect(computedResult.content[0].counter, 1);
      expect(computedResult.content[1].counter, 1);
      // Check length of substitionts
      expect(computedResult.content[0].sub.bindings.length, 1);
      expect(computedResult.content[1].sub.bindings.length, 1);
      // Check first Var value
      expect(computedResult.content[0].sub.bindings[0][0].n, 0);
      expect(computedResult.content[0].sub.bindings[0][1], "z");
      expect(computedResult.content[1].sub.bindings[0][0].n, 0);
      expect(computedResult.content[1].sub.bindings[0][1], ["s", "z"]);
    });
  });
  group("Test mplus", () {
    test("mplus with two empty streams", () {
      var st1 = MkStream.empty();
      var st2 = MkStream.empty();
      var computedResult = mplus(st1, st2);
      expect(computedResult.content, []);
    });
    test("mplus with two streams", () {
      var st1 = MkStream.empty()
          .extend(State(Substitution.empty().extend(Var(0), 5), 1));
      var st2 = MkStream.empty()
          .extend(State(Substitution.empty().extend(Var(0), 6), 1));
      var computedResult = mplus(st1, st2);
      // Check value of the first binding
      expect(computedResult.content[0].sub.bindings[0][1], 5);
      // Check counter of first state
      expect(computedResult.content[1].counter, 1);
      // Check value of second binding
      expect(computedResult.content[1].sub.bindings[0][1], 6);
      // Check counter of second state
      expect(computedResult.content[1].counter, 1);
      // Check length of MkStream content, should be 2 because it has two
      // States.
      expect(computedResult.content.length, 2);
    });
    test("mplus with one non empty stream and one empty stream", () {
      var st1 = MkStream.empty()
          .extend(State(Substitution.empty().extend(Var(0), 5), 1));
      var st2 = MkStream.empty();
      var computedResult = mplus(st1, st2);
      expect(computedResult.content.length, 1);
      expect(computedResult.content[0].sub.bindings[0][1], 5);
    });
    test("mplus with immature MkStream", () {
      var st1 = MkStream((x) => equal(x, 2));
      var st2 = MkStream.empty()
          .extend(State(Substitution.empty().extend(Var(0), 5), 1));
      var computedResult = mplus(st1, st2);
      expect(computedResult.isImmature(), true);
    });
  });
  // disj is the logical or operator.
  group("disj test", () {
    test("disj 1", () {
      var computedResult =
          disj(equal(Var(0), 5), equal(Var(0), 6))(State.empty());
      expect(computedResult.content.length, 2);
    });

    test("disj 2", () {
      var computedResult = callFresh((b) => disj(equal(b, 5), equal(b, 6)));
      // Check number of States in MkStream
      expect(computedResult(State.empty()).content.length, 2);
      // Check value of first binding
      expect(computedResult(State.empty()).content[0].sub.bindings[0][1], 5);
      // Check value of second binding
      expect(computedResult(State.empty()).content[1].sub.bindings[0][1], 6);
    });
  });
  // conj is the logical and operator.
  group("conj test", () {
    test("conj 1", () {
      var computedResult =
          conj(equal(Var(0), 5), equal(Var(0), 6))(State.empty());
      expect(computedResult.content.length, 0);
    });
    test("conj 2", () {
      var computedResult = callFresh((b) => conj(equal(b, 5), equal(b, 5)));
      expect(computedResult(State.empty()).content.length, 1);
      expect(computedResult(State.empty()).content[0].sub.bindings[0][1], 5);
    });
    test("conj 3", () {
      var computedResult = callFresh((b) => conj(equal(b, 5), equal(b, 6)));
      expect(computedResult(State.empty()).isEmpty(), true);
    });
  });

  // These are some tests taken from the scheme implemenation
  group("aAndB test", () {
    test("aAndB test second-set t3", () {
      var computedResult = aAndB(State.empty());
      expect(computedResult.content.length, 2);
      expect(computedResult.content[0].sub.bindings[0][1], 7);
      expect(computedResult.content[0].sub.bindings[1][1], 5);
      expect(computedResult.content[0].counter, 2);
    });
    test("aAndB test second-set t4", () {
      var computedResult = aAndB(State.empty());
      expect(computedResult.content.length, 2);
      expect(computedResult.content[1].sub.bindings[0][1], 7);
      expect(computedResult.content[1].sub.bindings[1][1], 6);
      expect(computedResult.content[1].counter, 2);
    });
    test("who cares", () {
      var computedResult = callFresh((q) => fives(q))(State.empty());
      expect(computedResult.content[0].sub.bindings[0][1], 5);
    });
    test("fives immature stream", () {
      var computedResult = callFresh((q) => fives(q))(State.empty());
      expect(computedResult.content[1] is Function, true);
    });
    test("fives immature stream forced", () {
      var computedResult = callFresh((q) => fives(q))(State.empty());
      expect(computedResult.content[1]().content[0].sub.bindings[0][1], 5);
    });
  });
}
