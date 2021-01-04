const assert = require("chai").assert,
expect = require("chai").expect,
fs = require("fs"),
path = require("path"),
config = require("../src/config"),
input = require("../src/input"),
messages = require("../src/messages"),
textAssembler = require("../src/text"),
sharedData = require("./shared-data"),
dataDir = path.join(config.BASE_DIR, "data", path.sep);

function escapeRegExp (string) {
  // $& means the whole matched string
  return string.replace(/[.*+?^${}()|[\]\\]/g, "\\$&");
}

describe("textAssembler.decode", function () {
  it("should turn URL-encoded gubbins into normal text", function () {
    const frags = {
      "ffset%0A++++rando": `ffset
    rando`,
      "+random.shuffle": " random.shuffle",
      "eText+%2B%3D+f.read": "eText += f.read",
      "python%0A%23%0A%23+Chop": `python
#
# Chop`,
      "+++++offset+%3D+r": "     offset = r",
      "tart+%2B+fragLen+": "tart + fragLen ",
      "rt+%3D+0%0A++++frag": `rt = 0
    frag`,
      "%D1%88%D0%B5%D0%BB%D0%BB%D1%8B": "шеллы",
      "%3Fx%3Dtest+string%20with%20some+exciting+chars":
        "?x=test string with some exciting chars"
    };

    Object.keys(frags).forEach(function (t) {
      expect(textAssembler.decode(t)).to.equal(frags[t]);
    });
  });
});

describe("textAssembler.mergeFragments", () => {
  // rl%0Ause+feature+
  // e+feature+qw%28+s
  // bin%2Fenv+perl%0Aus
  // %0Asay+%27Hello%2C+Wo
  // +%29%3B%0A%0Asay+%27Hello
  // e+qw%28+say+%29%3B%0A%0As
  // %23%2Fusr%2Fbin%2Fenv+p
  // %2C+World%21%27%3B
  // %27Hello%2C+World%21%27
  // nv+perl%0Ause+fea

  const testData = [
    [
      "ature+qw%28+say+%29",
      "%28+say+%29%3B%0A%0Asay+%27",
      "ature+qw%28+say+%29%3B%0A%0Asay+%27"
    ],
    [
      "%23%2Fusr%2Fbin%2Fenv+p",
      "nv+perl%0Ause+fea",
      "%23%2Fusr%2Fbin%2Fenv+perl%0Ause+fea"
    ]
  ];
  testData.forEach(inputArray => {
    it("can merge text fragments", () => {
      const decoded = inputArray.map(str => textAssembler.decode(str));

      const regexOne = escapeRegExp(decoded[0]),
      regexTwo = escapeRegExp(decoded[1]),
      matchString = `${regexOne}__SEP__${regexTwo}`;

      expect(
        textAssembler.mergeFragments(decoded[0], decoded[1], matchString)
      ).to.equal(decoded[2].replace(/\\/g));
    });
  });
});

describe("textAssembler.assemble", function () {
  describe("input errors", () => {
    const unmatchable = ["+%29%3B%0A%0Asay+%27Hello", "nv+perl%0Ause+fea"];
    it("should reject unmatchable fragments", function () {
      const decoded = unmatchable.map(str => textAssembler.decode(str)),
      errorString = messages.error.noAssembly;
      console.log(errorString);
      expect(textAssembler.assemble(decoded).to.throw(Error, errorString));
    });

    for (let errorType in sharedData.invalid) {
      it("should reject badly-formed input, " + errorType, () => {
        let fragmentArray = sharedData.invalid[errorType].split(/[\r\n]+/),
        decoded = unmatchable.map(str => textAssembler.decode(str));
        expect(textAssembler.assemble(decoded)).to.throw(
          messages.error[errorType]
        );
      });
    }
  });
  describe('correct functioning', () => {
    const sourceFiles = sharedData.files.valid;
    sourceFiles.forEach( function (file) {
      it('should decode ' + file, function (done) {
        const fragmentArray = input.readFile( `${dataDir}${file}-frags.txt` ),
        assembledFragments  = input.readFile( `${dataDir}${file}.txt` );

        console.log( fragmentArray );
        console.log( assembledFragments );
        expect( fragmentArray ).to.be.defined();
        expect( assembledFragments ).to.be.defined();
        done();
      });
    });
  });
});

