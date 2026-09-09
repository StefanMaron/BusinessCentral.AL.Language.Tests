codeunit 60119 "Test Text Extended"
{
    Subtype = Test;
    // BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/text/text-data-type
    // Scope: in-scope
    // Runtime: 16.1, Target: Cloud

    var
        Assert: Codeunit Assert;
        Cleanup: Codeunit ALTFixtureCleanup;

    local procedure Initialize()
    begin
        Cleanup.Initialize();
    end;

    // ============================================================================
    // ConvertStr - replace characters in a string
    // ============================================================================

    [Test]
    procedure ConvertStr_ReplacesCharacters()
    var
        Result: Text;
    begin
        Initialize();
        Result := ConvertStr('hello', 'eo', '--');
        Assert.AreEqual('h-ll-', Result, 'ConvertStr must replace "e" with "-" and "o" with "-"');
    end;

    [Test]
    procedure ConvertStr_MultipleCharacterSubstitution()
    var
        Result: Text;
    begin
        Initialize();
        Result := ConvertStr('hello', 'helo', 'HELO');
        Assert.AreEqual('HELLO', Result, 'ConvertStr must replace each character according to mapping');
    end;

    // ============================================================================
    // DelChr - delete characters
    // ============================================================================

    [Test]
    procedure DelChr_RemoveSpecificCharacter()
    var
        Result: Text;
    begin
        Initialize();
        Result := DelChr('hello', '=', 'e');
        Assert.AreEqual('hllo', Result, 'DelChr must remove all "e" characters');
    end;

    [Test]
    procedure DelChr_TrimLeadingAndTrailingSpaces()
    var
        Result: Text;
    begin
        Initialize();
        Result := DelChr('  hello  ', '<>');
        Assert.AreEqual('hello', Result, 'DelChr with "<>" must trim leading and trailing spaces');
    end;

    [Test]
    procedure DelChr_RemoveAllSpaces()
    var
        Result: Text;
    begin
        Initialize();
        Result := DelChr('h e l l o', '=', ' ');
        Assert.AreEqual('hello', Result, 'DelChr must remove all spaces when specified');
    end;

    // ============================================================================
    // IncStr - increment number at end of string
    // ============================================================================

    [Test]
    procedure IncStr_increments_SimpleNumber()
    var
        Result: Text;
    begin
        Initialize();
        Result := IncStr('ABC1');
        Assert.AreEqual('ABC2', Result, 'IncStr must increment "ABC1" to "ABC2"');
    end;

    [Test]
    procedure IncStr_HandlesCarryOver()
    var
        Result: Text;
    begin
        Initialize();
        Result := IncStr('ABC9');
        Assert.AreEqual('ABC10', Result, 'IncStr must carry over: "ABC9" becomes "ABC10"');
    end;

    [Test]
    procedure IncStr_PaddedNumbers()
    var
        Result: Text;
    begin
        Initialize();
        Result := IncStr('Item 001');
        Assert.AreEqual('Item 002', Result, 'IncStr must increment padded numbers while maintaining format');
    end;

    // ============================================================================
    // Text.Contains(Substring) - method on Text type
    // ============================================================================

    [Test]
    procedure TextContains_FindsSubstring()
    var
        Text1: Text;
    begin
        Initialize();
        Text1 := 'hello world';
        Assert.IsTrue(Text1.Contains('world'), 'Text.Contains must find "world" in "hello world"');
    end;

    [Test]
    procedure TextContains_DoesNotFindMissingSubstring()
    var
        Text1: Text;
    begin
        Initialize();
        Text1 := 'hello';
        Assert.IsFalse(Text1.Contains('xyz'), 'Text.Contains must return false for non-existent substring');
    end;

    // ============================================================================
    // Text.StartsWith(Prefix)
    // ============================================================================

    [Test]
    procedure TextStartsWith_MatchesPrefix()
    var
        Text1: Text;
    begin
        Initialize();
        Text1 := 'hello';
        Assert.IsTrue(Text1.StartsWith('hel'), 'Text.StartsWith must match "hel" prefix');
    end;

    [Test]
    procedure TextStartsWith_RejectsNonMatchingPrefix()
    var
        Text1: Text;
    begin
        Initialize();
        Text1 := 'hello';
        Assert.IsFalse(Text1.StartsWith('world'), 'Text.StartsWith must reject non-matching prefix');
    end;

    // ============================================================================
    // Text.EndsWith(Suffix)
    // ============================================================================

    [Test]
    procedure TextEndsWith_MatchesSuffix()
    var
        Text1: Text;
    begin
        Initialize();
        Text1 := 'hello';
        Assert.IsTrue(Text1.EndsWith('llo'), 'Text.EndsWith must match "llo" suffix');
    end;

    [Test]
    procedure TextEndsWith_RejectsNonMatchingSuffix()
    var
        Text1: Text;
    begin
        Initialize();
        Text1 := 'hello';
        Assert.IsFalse(Text1.EndsWith('hel'), 'Text.EndsWith must reject non-matching suffix');
    end;

    // ============================================================================
    // Text.ToUpper() / Text.ToLower()
    // ============================================================================

    [Test]
    procedure TextToUpper_ConvertsToUppercase()
    var
        Text1: Text;
        Result: Text;
    begin
        Initialize();
        Text1 := 'hello';
        Result := Text1.ToUpper();
        Assert.AreEqual('HELLO', Result, 'Text.ToUpper must convert "hello" to "HELLO"');
    end;

    [Test]
    procedure TextToLower_ConvertsToLowercase()
    var
        Text1: Text;
        Result: Text;
    begin
        Initialize();
        Text1 := 'HELLO';
        Result := Text1.ToLower();
        Assert.AreEqual('hello', Result, 'Text.ToLower must convert "HELLO" to "hello"');
    end;

    // ============================================================================
    // Text.Trim() / Text.TrimStart() / Text.TrimEnd()
    // ============================================================================

    [Test]
    procedure TextTrim_RemovesLeadingAndTrailing()
    var
        Text1: Text;
        Result: Text;
    begin
        Initialize();
        Text1 := '  hello  ';
        Result := Text1.Trim();
        Assert.AreEqual('hello', Result, 'Text.Trim must remove leading and trailing spaces');
    end;

    [Test]
    procedure TextTrimStart_RemovesLeadingOnly()
    var
        Text1: Text;
        Result: Text;
    begin
        Initialize();
        Text1 := '  hello  ';
        Result := Text1.TrimStart();
        Assert.AreEqual('hello  ', Result, 'Text.TrimStart must remove only leading spaces');
    end;

    [Test]
    procedure TextTrimEnd_RemovesTrailingOnly()
    var
        Text1: Text;
        Result: Text;
    begin
        Initialize();
        Text1 := '  hello  ';
        Result := Text1.TrimEnd();
        Assert.AreEqual('  hello', Result, 'Text.TrimEnd must remove only trailing spaces');
    end;

    // ============================================================================
    // Text.Replace(OldStr, NewStr)
    // ============================================================================

    [Test]
    procedure TextReplace_ReplacesSingleCharacter()
    var
        Text1: Text;
        Result: Text;
    begin
        Initialize();
        Text1 := 'hello';
        Result := Text1.Replace('e', 'X');
        Assert.AreEqual('hXllo', Result, 'Text.Replace must replace "e" with "X"');
    end;

    [Test]
    procedure TextReplace_ChainsMultipleReplacements()
    var
        Text1: Text;
        Result: Text;
    begin
        Initialize();
        Text1 := 'hello';
        Result := Text1.Replace('e', 'X').Replace('o', 'X');
        Assert.AreEqual('hXllX', Result, 'Text.Replace chained must replace "e" and "o" with "X"');
    end;

    [Test]
    procedure TextReplace_ReplacesWholeString()
    var
        Text1: Text;
        Result: Text;
    begin
        Initialize();
        Text1 := 'hello';
        Result := Text1.Replace('hello', 'world');
        Assert.AreEqual('world', Result, 'Text.Replace must replace entire string');
    end;

    // ============================================================================
    // Text.Substring(StartIndex [, Length]) - 1-based indexing
    // ============================================================================

    [Test]
    procedure TextSubstring_FromIndexToEnd()
    var
        Text1: Text;
        Result: Text;
    begin
        Initialize();
        Text1 := 'hello';
        Result := Text1.Substring(2);
        Assert.AreEqual('ello', Result, 'Text.Substring(2) must extract from position 2 to end (1-based)');
    end;

    [Test]
    procedure TextSubstring_WithLength()
    var
        Text1: Text;
        Result: Text;
    begin
        Initialize();
        Text1 := 'hello';
        Result := Text1.Substring(2, 3);
        Assert.AreEqual('ell', Result, 'Text.Substring(2, 3) must extract 3 chars starting at position 2 (1-based)');
    end;

    [Test]
    procedure TextSubstring_FromBeginning()
    var
        Text1: Text;
        Result: Text;
    begin
        Initialize();
        Text1 := 'hello';
        Result := Text1.Substring(1, 2);
        Assert.AreEqual('he', Result, 'Text.Substring(1, 2) must extract first 2 characters (1-based)');
    end;

    // ============================================================================
    // Text.IndexOf(Value [, StartIndex]) - 1-based, returns 0 if not found
    // ============================================================================

    [Test]
    procedure TextIndexOf_FindsSubstring()
    var
        Text1: Text;
        Index: Integer;
    begin
        Initialize();
        Text1 := 'hello';
        Index := Text1.IndexOf('ll');
        Assert.AreEqual(3, Index, 'Text.IndexOf must find "ll" at 1-based position 3');
    end;

    [Test]
    procedure TextIndexOf_NotFound_ReturnsZero()
    var
        Text1: Text;
        Index: Integer;
    begin
        Initialize();
        Text1 := 'hello';
        Index := Text1.IndexOf('xyz');
        Assert.AreEqual(0, Index, 'Text.IndexOf must return 0 when substring not found');
    end;

    [Test]
    procedure TextIndexOf_WithStartIndex()
    var
        Text1: Text;
        Index: Integer;
    begin
        Initialize();
        Text1 := 'hello';
        Index := Text1.IndexOf('l', 3);
        Assert.AreEqual(3, Index, 'Text.IndexOf(l, 3) must find "l" at position 3 or later (1-based)');
    end;

    // ============================================================================
    // Text.IndexOfAny(Values: List of [Char] [, StartIndex])
    // ============================================================================

    [Test]
    procedure TextIndexOfAny_FindsFirstMatchingChar()
    var
        Text1: Text;
        Chars: List of [Char];
        Index: Integer;
    begin
        Initialize();
        Text1 := 'hello';
        Chars.Add('e');
        Chars.Add('o');
        Index := Text1.IndexOfAny(Chars);
        Assert.AreEqual(2, Index, 'Text.IndexOfAny must find first matching char "e" at position 2 (1-based)');
    end;

    [Test]
    procedure TextIndexOfAny_NoMatch_ReturnsZero()
    var
        Text1: Text;
        Chars: List of [Char];
        Index: Integer;
    begin
        Initialize();
        Text1 := 'hello';
        Chars.Add('x');
        Chars.Add('y');
        Index := Text1.IndexOfAny(Chars);
        Assert.AreEqual(0, Index, 'Text.IndexOfAny must return 0 when no chars match');
    end;

    // ============================================================================
    // Text.LastIndexOf(Value [, StartIndex]) - finds last occurrence
    // ============================================================================

    [Test]
    procedure TextLastIndexOf_FindsLastOccurrence()
    var
        Text1: Text;
        Index: Integer;
    begin
        Initialize();
        Text1 := 'hello';
        Index := Text1.LastIndexOf('l');
        Assert.AreEqual(4, Index, 'Text.LastIndexOf must find last "l" at position 4 (1-based)');
    end;

    [Test]
    procedure TextLastIndexOf_NotFound_ReturnsZero()
    var
        Text1: Text;
        Index: Integer;
    begin
        Initialize();
        Text1 := 'hello';
        Index := Text1.LastIndexOf('xyz');
        Assert.AreEqual(0, Index, 'Text.LastIndexOf must return 0 when substring not found');
    end;

    // ============================================================================
    // Text.PadLeft(Count [, Char]) / Text.PadRight(Count [, Char])
    // ============================================================================

    [Test]
    procedure TextPadLeft_WithDefaultSpace()
    var
        Text1: Text;
        Result: Text;
    begin
        Initialize();
        Text1 := 'hi';
        Result := Text1.PadLeft(5);
        Assert.AreEqual('   hi', Result, 'Text.PadLeft(5) must pad with 3 spaces on left');
    end;

    [Test]
    procedure TextPadLeft_WithCustomChar()
    var
        Text1: Text;
        Result: Text;
    begin
        Initialize();
        Text1 := 'hi';
        Result := Text1.PadLeft(5, '#');
        Assert.AreEqual('###hi', Result, 'Text.PadLeft(5, ''#'') must pad with 3 "#" on left');
    end;

    [Test]
    procedure TextPadRight_WithDefaultSpace()
    var
        Text1: Text;
        Result: Text;
    begin
        Initialize();
        Text1 := 'hi';
        Result := Text1.PadRight(5);
        Assert.AreEqual('hi   ', Result, 'Text.PadRight(5) must pad with 3 spaces on right');
    end;

    [Test]
    procedure TextPadRight_WithCustomChar()
    var
        Text1: Text;
        Result: Text;
    begin
        Initialize();
        Text1 := 'hi';
        Result := Text1.PadRight(5, '#');
        Assert.AreEqual('hi###', Result, 'Text.PadRight(5, ''#'') must pad with 3 "#" on right');
    end;

    // ============================================================================
    // Text.Split([Separators: Text,...])
    // ============================================================================

    [Test]
    procedure TextSplit_SplitsBySingleSeparator()
    var
        Text1: Text;
        Parts: List of [Text];
    begin
        Initialize();
        Text1 := 'a,b,c';
        Parts := Text1.Split(',');
        Assert.AreEqual(3, Parts.Count(), 'Text.Split must create 3 parts from "a,b,c"');
        Assert.AreEqual('a', Parts.Get(1), 'First part must be "a"');
        Assert.AreEqual('b', Parts.Get(2), 'Second part must be "b"');
        Assert.AreEqual('c', Parts.Get(3), 'Third part must be "c"');
    end;

    [Test]
    procedure TextSplit_WithMultipleSeparators()
    var
        Text1: Text;
        Parts: List of [Text];
        Separators: List of [Char];
    begin
        Initialize();
        Text1 := 'a,b;c';
        Separators.Add(',');
        Separators.Add(';');
        Parts := Text1.Split(Separators);
        Assert.AreEqual(3, Parts.Count(), 'Text.Split must split on multiple separator chars');
    end;

    // Text.Split(Separator1, Separator2, ...): several separator ARGUMENTS, each a whole
    // string, as opposed to the List of [Char] form above where each character separates.

    [Test]
    procedure TextSplit_TwoSeparatorLiterals_SplitsOnEither()
    var
        Parts: List of [Text];
    begin
        Initialize();
        Parts := 'a,b;c'.Split(',', ';');
        Assert.AreEqual(3, Parts.Count(), 'Split(",", ";") must split "a,b;c" into 3 parts');
        Assert.AreEqual('a', Parts.Get(1), 'First part must be "a"');
        Assert.AreEqual('b', Parts.Get(2), 'Second part must be "b"');
        Assert.AreEqual('c', Parts.Get(3), 'Third part must be "c"');
    end;

    [Test]
    procedure TextSplit_ThreeSeparatorLiterals_SplitsOnAny()
    var
        Parts: List of [Text];
    begin
        Initialize();
        Parts := 'a,b;c|d'.Split(',', ';', '|');
        Assert.AreEqual(4, Parts.Count(), 'Split(",", ";", "|") must split "a,b;c|d" into 4 parts');
        Assert.AreEqual('d', Parts.Get(4), 'Fourth part must be "d"');
    end;

    [Test]
    procedure TextSplit_TwoSeparatorVariables_SplitsOnEither()
    var
        Input: Text;
        Sep1: Text;
        Sep2: Text;
        Parts: List of [Text];
    begin
        Initialize();
        Input := 'a,b;c';
        Sep1 := ',';
        Sep2 := ';';
        Parts := Input.Split(Sep1, Sep2);
        Assert.AreEqual(3, Parts.Count(), 'Split(Sep1, Sep2) with Text variables must split "a,b;c" into 3 parts');
        Assert.AreEqual('b', Parts.Get(2), 'Second part must be "b"');
    end;

    [Test]
    procedure TextSplit_TwoMultiCharSeparators_EachIsAWholeString()
    var
        Parts: List of [Text];
    begin
        Initialize();
        Parts := 'a--b::c'.Split('--', '::');
        Assert.AreEqual(3, Parts.Count(), 'Split("--", "::") must treat each separator as a whole string and yield 3 parts');
        Assert.AreEqual('b', Parts.Get(2), 'Second part must be "b"');
        // A lone "-" is not "--": nothing to split on, the whole text comes back as one part.
        Parts := 'a-b'.Split('--', '::');
        Assert.AreEqual(1, Parts.Count(), 'Split("--", "::") on "a-b" must find no separator and return 1 part');
        Assert.AreEqual('a-b', Parts.Get(1), 'The single part must be the whole text');
    end;

    [Test]
    procedure TextSplit_TwoSeparatorsNoneFound_ReturnsWholeText()
    var
        Parts: List of [Text];
    begin
        Initialize();
        Parts := 'abc'.Split(',', ';');
        Assert.AreEqual(1, Parts.Count(), 'Split(",", ";") on "abc" must return exactly 1 part');
        Assert.AreEqual('abc', Parts.Get(1), 'The single part must be the whole text');
    end;

    [Test]
    procedure TextSplit_EmptyString()
    var
        Text1: Text;
        Parts: List of [Text];
    begin
        Initialize();
        Text1 := '';
        Parts := Text1.Split(',');
        Assert.AreEqual(1, Parts.Count(), 'Text.Split of empty string must return 1 empty part');
    end;

    // ============================================================================
    // MaxStrLen(Variable) - returns max length of Text/Code variable
    // ============================================================================

    [Test]
    procedure MaxStrLen_ReturnsMaxLengthOfTextVariable()
    var
        T: Text[50];
        MaxLen: Integer;
    begin
        Initialize();
        MaxLen := MaxStrLen(T);
        Assert.AreEqual(50, MaxLen, 'MaxStrLen must return 50 for Text[50] variable');
    end;

    [Test]
    procedure MaxStrLen_UnlimitedText_ReturnsMaxInt()
    var
        T: Text;
        MaxLen: Integer;
    begin
        Initialize();
        MaxLen := MaxStrLen(T);
        Assert.AreEqual(2147483647, MaxLen, 'MaxStrLen must return MaxInt (2147483647) for unlimited Text variable');
    end;

    [Test]
    procedure MaxStrLen_CodeVariableReturnsMaxLength()
    var
        C: Code[10];
        MaxLen: Integer;
    begin
        Initialize();
        MaxLen := MaxStrLen(C);
        Assert.AreEqual(10, MaxLen, 'MaxStrLen must return 10 for Code[10] variable');
    end;
}
