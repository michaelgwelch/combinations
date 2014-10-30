//
//  main.swift
//  combinations
//
//  Created by Michael Welch on 10/29/14.
//  Copyright (c) 2014 Michael Welch. All rights reserved.
//

import Foundation

println("Hello, World!")


class BoolStack : DebugPrintable {

    let top:Bool? = nil;

    private init(top:Bool? = nil) {
        self.top = top;
    }

    func push(boolean:Bool) -> BoolStack {
        return NonEmptyStack(top: boolean, tail: self);
    }

    func pop() -> BoolStack? {
        return nil;
    }

    func isEmpty() -> Bool {
        return true;
    }

    class func emptyStack() -> BoolStack {
        return BoolStack();
    }

    var debugDescription : String {
        get {
            return "";
        }
    }


    private class NonEmptyStack : BoolStack {
        let tail:BoolStack;

        init(top:Bool, tail:BoolStack) {
            self.tail = tail;
            super.init(top: top);
        }

        override func push(boolean: Bool) -> BoolStack {
            return NonEmptyStack(top: boolean, tail: self);
        }

        override func pop() -> BoolStack {
            return tail;
        }

        override func isEmpty() -> Bool {
            return false;
        }

        override var debugDescription : String {
            get {
                var bit = top! ? "1" : "0";
                return bit + tail.debugDescription;
            }
        }
    }

}

extension BoolStack : SequenceType {
    func generate() -> GeneratorOf<Bool> {
        var stack = self;

        return GeneratorOf {
            if (stack.isEmpty()) {
                return nil;
            } else {
                let result = stack.top;
                stack = stack.pop()!;
                return result;
            }
        };
    }
}


struct SequenceOfOneEmptyBoolStack : SequenceType {
    private init() {}
    static func instance() -> SequenceOf<BoolStack> {
        return SequenceOf(SequenceOfOneEmptyBoolStack());
    }
    func generate() -> GeneratorOfOne<BoolStack> {
        return GeneratorOfOne<BoolStack>(BoolStack.emptyStack());
    }
}

struct EmptySequenceOfBoolStack : SequenceType {
    private init() {}
    static func instance() -> SequenceOf<BoolStack> {
        return SequenceOf(EmptySequenceOfBoolStack());
    }
    func generate() -> GeneratorOfOne<BoolStack> {
        return GeneratorOfOne<BoolStack>(nil);
    }
}


func combinations(n:UInt,k:UInt) -> SequenceOf<BoolStack> {
    if (k == 0 && n == 0) {
        return SequenceOfOneEmptyBoolStack.instance();
    }

    if (n < k) {
        return EmptySequenceOfBoolStack.instance();
    }

    var trueCombinations:SequenceOf<BoolStack>;
    if (k > 0) {
        trueCombinations = combinations(n-1, k-1);
    } else {
        trueCombinations = EmptySequenceOfBoolStack.instance();
    }
    var falseCombinations = combinations(n-1, k);

    var trueGenerator:GeneratorOf<BoolStack> = trueCombinations.generate();
    var falseGenerator:GeneratorOf<BoolStack> = falseCombinations.generate();

    return SequenceOf<BoolStack> { () -> GeneratorOf<BoolStack> in
        return GeneratorOf<BoolStack> {
            var result = trueGenerator.next();
            if (result != nil) {
                return result!.push(true);
            } else {
                result = falseGenerator.next();
                return result?.push(false);
            }
        }
    };

}

extension Zip2 {
    func asArray() -> [(S0.Generator.Element,S1.Generator.Element)] {
        return Array(self);
    }
}

extension Array {
    func asSequence() -> SequenceOf<Element> {
        return SequenceOf<Element>(self);
    }
}

struct ZipWhere<S:SequenceType> : SequenceType {
    private let s:S;
    private let bools:SequenceOf<Bool>;

    init(_ s:S, _ bools:[Bool]) {
        self.init(s, bools.asSequence());
    }
    init(_ s:S, _ bools:SequenceOf<Bool>) {
        self.s = s;
        self.bools = bools;
    }


    func generate() -> GeneratorOf<S.Generator.Element> {

        var generator = Zip2(s, bools).generate();

        return GeneratorOf<S.Generator.Element> {
            var next = generator.next();

            while (next != nil) {
                let (v,b) = next!;
                if (b) {
                    return v;
                } else {
                    next = generator.next();
                }
            }

            return nil;

        }
    }

    func asArray() -> [S.Generator.Element] {
        return Array(self);
    }

}

extension SequenceOf {
    func count() -> UInt {
        var i:UInt = 0;
        for e in self {
            i++;
        }
        return i;
    }
}

struct Combinations<S:SequenceType> : SequenceType {
    private let s:S;
    private let k:UInt;

    init(_ s:S, _ k:UInt) {
        self.s = s;
        self.k = k;
    }

    func generate() -> GeneratorOf<SequenceOf<S.Generator.Element>> {
        let n = SequenceOf(s).count();

        var boolCombinationsGenerator = combinations(n, k).generate();

        return GeneratorOf<SequenceOf<S.Generator.Element>> {
            var bools = boolCombinationsGenerator.next();
            if (bools == nil) { return nil; }


            var zw = ZipWhere(self.s, SequenceOf(bools!.generate()));
            return SequenceOf(zw.generate());
        }

    }

}

extension Combinations {
    func asArray() -> [SequenceOf<S.Generator.Element>] {
        return Array(self);
    }
}

var combs = Combinations([50,60,70,80,90],3);

for comb in combs {
    println(Array(comb));
}
for comb in combs {
    println(Array(comb));
}


