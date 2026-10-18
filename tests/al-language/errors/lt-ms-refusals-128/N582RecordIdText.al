// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/system/system-evaluate-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160), self-contained tables 67601 to 67603, codeunit 67601
// Probe: observed on the corpus CI matrix; every literal asserted below is what the BC service tier produced.
// Facts: Format(RecordId) of a Code key value that holds quotes; Evaluate(RecordId) with an empty unquoted key part, a Text key part,
// and blanks around a Code key value (trimmed or kept, and what Format gives afterwards).
// BC versions: 27, 28, 29

table 67601 "LT N582 Rid Code"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Code; Code[20]) { }
    }

    keys
    {
        key(PK; Code) { Clustered = true; }
    }
}

table 67602 "LT N582 Rid Text"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Name; Text[30]) { }
    }

    keys
    {
        key(PK; Name) { Clustered = true; }
    }
}

table 67603 "LT N582 Rid Two"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Part1; Code[20]) { }
        field(2; Part2; Code[20]) { }
    }

    keys
    {
        key(PK; Part1, Part2) { Clustered = true; }
    }
}

codeunit 67601 "LT N582 RecordId Text"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure FormatCode(var Observer: Codeunit "Probe Observer"; Name: Text; Value: Text)
    var
        Row: Record "LT N582 Rid Code";
    begin
        Row.Code := CopyStr(Value, 1, MaxStrLen(Row.Code));
        Observer.Observe(Name, '[' + Row.Code + ']|' + Format(Row.RecordId));
    end;

    local procedure EvalCode(var Observer: Codeunit "Probe Observer"; Name: Text; Txt: Text)
    var
        Plain: Record "LT N582 Rid Code";
        Rid: RecordId;
        Ok: Boolean;
    begin
        Ok := Evaluate(Rid, Txt);
        Plain.Code := 'A';
        Observer.Observe(Name, Format(Ok) + '|' + Format(Rid) + '|' + Format(Rid.TableNo()) + '|equalsA=' + Format(Rid = Plain.RecordId));
    end;

    [Test]
    procedure N582_Format_RecordId_CodeKeyWithQuotes()
    var
        Observer: Codeunit "Probe Observer";
    begin
        FormatCode(Observer, 'quote inside', 'A"B');
        FormatCode(Observer, 'quote at end', 'AB"');
        FormatCode(Observer, 'quote at start', '"AB');
        FormatCode(Observer, 'only a quote', '"');
        FormatCode(Observer, 'two quotes', '""');
        FormatCode(Observer, 'plain', 'AB');
        FormatCode(Observer, 'comma', 'A,B');
        FormatCode(Observer, 'blank inside', 'A B');
        Observer.Finish();
    end;

    [Test]
    procedure N582_Evaluate_RecordId_EmptyUnquotedPart()
    var
        Observer: Codeunit "Probe Observer";
        Rid: RecordId;
        Ok: Boolean;
    begin
        Ok := Evaluate(Rid, 'LT N582 Rid Two: ,X');
        Observer.Observe('empty first part', Format(Ok) + '|' + Format(Rid) + '|' + Format(Rid.TableNo()));
        Ok := Evaluate(Rid, 'LT N582 Rid Two: X,');
        Observer.Observe('empty second part', Format(Ok) + '|' + Format(Rid) + '|' + Format(Rid.TableNo()));
        Ok := Evaluate(Rid, 'LT N582 Rid Two: ,');
        Observer.Observe('both parts empty', Format(Ok) + '|' + Format(Rid) + '|' + Format(Rid.TableNo()));
        Ok := Evaluate(Rid, 'LT N582 Rid Two: "",X');
        Observer.Observe('quoted empty first part', Format(Ok) + '|' + Format(Rid) + '|' + Format(Rid.TableNo()));
        Ok := Evaluate(Rid, 'LT N582 Rid Two: X,Y');
        Observer.Observe('two parts', Format(Ok) + '|' + Format(Rid) + '|' + Format(Rid.TableNo()));
        Ok := Evaluate(Rid, 'LT N582 Rid Two: X');
        Observer.Observe('one part for two', Format(Ok) + '|' + Format(Rid) + '|' + Format(Rid.TableNo()));
        Ok := Evaluate(Rid, 'LT N582 Rid Two: X,Y,Z');
        Observer.Observe('three parts for two', Format(Ok) + '|' + Format(Rid) + '|' + Format(Rid.TableNo()));
        Observer.Finish();
    end;

    [Test]
    procedure N582_Evaluate_RecordId_TextKeyPart()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT N582 Rid Text";
        Rid: RecordId;
        Ok: Boolean;
    begin
        Ok := Evaluate(Rid, 'LT N582 Rid Text: Hello');
        Observer.Observe('text key', Format(Ok) + '|' + Format(Rid) + '|' + Format(Rid.TableNo()));
        Ok := Evaluate(Rid, 'LT N582 Rid Text: Hello World');
        Observer.Observe('text key with blank', Format(Ok) + '|' + Format(Rid) + '|' + Format(Rid.TableNo()));
        Ok := Evaluate(Rid, 'LT N582 Rid Text: hello');
        Row.Name := 'Hello';
        Observer.Observe('text key lower case', Format(Ok) + '|' + Format(Rid) + '|equalsHello=' + Format(Rid = Row.RecordId));
        Ok := Evaluate(Rid, 'LT N582 Rid Text: ');
        Observer.Observe('text key empty', Format(Ok) + '|' + Format(Rid) + '|' + Format(Rid.TableNo()));
        Ok := Evaluate(Rid, 'LT N582 Rid Text: "A,B"');
        Observer.Observe('text key quoted comma', Format(Ok) + '|' + Format(Rid) + '|' + Format(Rid.TableNo()));
        Row.Name := 'A"B';
        Observer.Observe('text key with quote, format', Format(Row.RecordId));
        Row.Name := ' A ';
        Observer.Observe('text key with blanks, format', Format(Row.RecordId));
        Ok := Evaluate(Rid, 'LT N582 Rid Text: ' + ' A ');
        Observer.Observe('text key blanks around', Format(Ok) + '|' + Format(Rid) + '|equalsBlanks=' + Format(Rid = Row.RecordId));
        Observer.Finish();
    end;

    [Test]
    procedure N582_Evaluate_RecordId_BlanksAroundCodeKey()
    var
        Observer: Codeunit "Probe Observer";
    begin
        EvalCode(Observer, 'no blanks', 'LT N582 Rid Code: A');
        EvalCode(Observer, 'blanks both sides', 'LT N582 Rid Code:  A ');
        EvalCode(Observer, 'trailing blank', 'LT N582 Rid Code: A ');
        EvalCode(Observer, 'leading blank only', 'LT N582 Rid Code:  A');
        EvalCode(Observer, 'two leading blanks', 'LT N582 Rid Code:   A');
        EvalCode(Observer, 'no separator blank', 'LT N582 Rid Code:A');
        EvalCode(Observer, 'quoted with blanks', 'LT N582 Rid Code: " A "');
        EvalCode(Observer, 'quoted trailing blank', 'LT N582 Rid Code: "A "');
        EvalCode(Observer, 'quoted plain', 'LT N582 Rid Code: "A"');
        EvalCode(Observer, 'lower case', 'LT N582 Rid Code: a');
        EvalCode(Observer, 'only blanks', 'LT N582 Rid Code:   ');
        Observer.Finish();
    end;

    [Test]
    procedure N582_Evaluate_RecordId_QuotedKeysRoundTrip()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT N582 Rid Code";
        Rid: RecordId;
        Ok: Boolean;
        Txt: Text;
    begin
        Row.Code := 'A"B';
        Txt := Format(Row.RecordId);
        Ok := Evaluate(Rid, Txt);
        Observer.Observe('inside quote round trip', Format(Ok) + '|' + Format(Rid) + '|same=' + Format(Rid = Row.RecordId));
        Row.Code := 'AB"';
        Txt := Format(Row.RecordId);
        Ok := Evaluate(Rid, Txt);
        Observer.Observe('end quote round trip', Format(Ok) + '|' + Format(Rid) + '|same=' + Format(Rid = Row.RecordId));
        Row.Code := '"';
        Txt := Format(Row.RecordId);
        Ok := Evaluate(Rid, Txt);
        Observer.Observe('only quote round trip', Format(Ok) + '|' + Format(Rid) + '|same=' + Format(Rid = Row.RecordId));
        Row.Code := 'A,B';
        Txt := Format(Row.RecordId);
        Ok := Evaluate(Rid, Txt);
        Observer.Observe('comma round trip', Format(Ok) + '|' + Format(Rid) + '|same=' + Format(Rid = Row.RecordId));
        Observer.Finish();
    end;
}
