// semmle-extractor-options: /r:System.Linq.dll

using System;
using System.Collections.Generic;
using System.Linq;
using static StaticMethods;

interface I1 { int Foo(); }
interface I2 { float Foo(); }
interface I3 : I2 { }
interface I4 : I3 { }

class A : I1, I2
{
    public int Foo() { return 0; }
    float I2.Foo() { return 0; }
    public void M(A a) { }
}

class B : A
{
    public static bool operator==(B b1, B b2) { return false; }
    public static bool operator!=(B b1, B b2) { return true; }
    public void M(B b) { }
}

class C : B { }

class D : C { }

static class AExtensions1
{
    public static void M1(this A a, A x) { }
    public static void M2(this A a, A x) { }
}

static class AExtensions2
{
    public static void M2(this A a, B b) { }
}

class Tests
{
    void Fn(A a) { }
    void Fn(B a) { }
    void Fn2(A a) { }

    void Test1(string[] args)
    {
        A a = new A();
        B b = new B();
        object o;

        o = (A)b; // BAD

        o = (B)b; // GOOD: Not an upcast

        b.M((A)b); // GOOD: Disambiguating method call

        a.M1((A)b); // BAD
        a.M2((A)b); // GOOD: Disambiguating method call

        o = true ? (A)a : b; // GOOD: Needed for ternary

        o = a ?? (A)b; // GOOD: Null coalescing expression

        Fn((A)b); // GOOD: Disambiguating method call

        Fn2((A)b); // BAD

        ((I2)a).Foo(); // GOOD: Cast to an interface

        o = a==(A)b; // GOOD: EQExpr

        o = b==(B)b; // GOOD: Operator call

        var act = (Action) (() => { }); // GOOD

        var objects = args.Select(arg => (object)arg); // GOOD

        M1((A)b); // GOOD: disambiguate targets from `StaticMethods`
        StaticMethods.M1((A)b); // GOOD: disambiguate targets from `StaticMethods`

        void M2(A _) { }
        M2((A)b); // BAD: local functions cannot be overloaded
    }

    static void M2(A _) { }

    void Test2(B b)
    {
        // BAD: even though `StaticMethods` has an `M2`, only overloads in
        // `Tests` are taken into account
        M2((A)b);
    }

    class Nested
    {
        static void M2(B _) { }

        static void Test(C c)
        {
            // BAD: even though `StaticMethods` and `Tests` have `M2`s, only
            // overloads in `Nested` are taken into account
            M2((B)c);
        }
    }
}

static class IExtensions
{
    public static void M1(this I2 i) { }

    public static void M1(this I3 i) =>
        M1((I2)i); // GOOD

    public static void M1(I4 i)
    {
        M1((I3)i); // GOOD
        ((I3)i).M1(); // GOOD
    }

    public static void M2(I2 i) { }

    public static void M2(this I3 i) =>
        M2((I2)i); // GOOD
}

static class StaticMethods
{
   public static void M1(A _) { }
   public static void M1(B _) { }
   public static void M2(B _) { }
}
