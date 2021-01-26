(* ::Package:: *)

(* Copyright 2019 lsp-wl Authors *)
(* SPDX-License-Identifier: MIT *)


(* Wolfram Language Server Table Generator *)


BeginPackage["WolframLanguageServer`TableGenerator`"]
ClearAll[Evaluate[Context[] <> "*"]]


GenerateUnicodeTable::usage = "GenerateUnicodeTable[file_] generates unicode table to file."


Begin["`Private`"]
ClearAll[Evaluate[Context[] <> "*"]]


GenerateUnicodeTable[file_] := Module[
    {
        UnicodeCharacters = Import[FileNameJoin[{
            $InstallationDirectory, "SystemFiles", "FrontEnd", "TextResources", "UnicodeCharacters.tr"
        }], "Text"],
        AliasToLongName, LongNameToUnicode
    },

    OpenWrite[file];

    WriteLine[file, "(* "~~"::Package::" ~~ " *)\n"];
    WriteLine[file, "(* This file is generated by WolframLanguageServer`TableGenerator` package. *)\n\n"];
    WriteLine[file, "BeginPackage[\"WolframLanguageServer`UnicodeTable`\"]"];
    WriteLine[file, "ClearAll[Evaluate[Context[] <> \"*\"]]\n\n"];

    AliasToLongName =
    UnicodeCharacters
    // StringCases[
        (("\\[" ~~ longName:(LetterCharacter...) ~~ "]") ~~
        Whitespace ~~ "(" ~~ alias:Shortest[___] ~~ ")") :> {
            alias
            // StringCases["$" ~~ shortname : Shortest[__] ~~ "$" :> shortname],
            longName
        }
    ]
    // DeleteCases[{{}, _}]
    // Map[Apply[Thread@*Rule]]
    // Flatten // Association;

    LongNameToUnicode = UnicodeCharacters
    // StringCases[(
        "0x" ~~ unicode:(HexadecimalCharacter..) ~~ Whitespace ~~
        ("\\[" ~~ longName:(LetterCharacter...) ~~ "]")
    ) :> (longName -> FromDigits[unicode, 16])]
    // Association;

    (* aliases without A-Za-z. *)
    NonLetterAliases = Keys[AliasToLongName]
    // Cases[_?(StringMatchQ[Except[WordCharacter]..])];

    (*
        Non-letters which are only used as prefix of aliases that contains letters.
        We know there is only one such leader, i.e. `$`, but we generate it here.
    *)
    NonLetterLeaders = Complement[
        (* all non-letter prefix *)
        Keys[AliasToLongName]
        // Map[StringTake[#, 1]&]
        // Prepend["["] (* for long names `[` is a prefix *)
        // DeleteDuplicates
        // DeleteCases[_?LetterQ],
        (* non-letter prefix *)
        NonLetterAliases
        // Map[StringTake[#, 1]&]
        // DeleteDuplicates
    ];

    (* Use `Function` to do lexical replacement in `Unevaluated` *)
    NonLetterLeaders
    // (leaders \[Function] ( 
        Write[file, Unevaluated[WolframLanguageServer`UnicodeTable`NonLetterLeaders = leaders]];
        leaders
    ));

    WriteLine[file, "\n"];

    NonLetterAliases
    // (aliases \[Function] ( 
        Write[file, Unevaluated[WolframLanguageServer`UnicodeTable`NonLetterAliases = aliases]];
        aliases
    ));

    WriteLine[file, "\n"];

    AliasToLongName
    // (assoc \[Function] (
        Write[file, Unevaluated[WolframLanguageServer`UnicodeTable`AliasToLongName = assoc]];
        assoc
    ));

    WriteLine[file, "\n"];

    LongNameToUnicode
    // (assoc \[Function] (
        Write[file, Unevaluated[WolframLanguageServer`UnicodeTable`LongNameToUnicode = assoc]];
        assoc
    ));

    WriteLine[file, "\n"];
    WriteLine[file, "EndPackage[]"];

    Close[file];

]


End[]


EndPackage[]
