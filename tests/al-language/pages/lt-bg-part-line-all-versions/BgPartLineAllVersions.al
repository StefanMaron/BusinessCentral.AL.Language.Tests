// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-page-object
// Scope: in-scope
// Fixtures used: Probe Observer (69160); tables 67573 "LT DL Header" and 67576 "LT DL Line", page 67577 "LT DL Document" with its lines part and log codeunit 67579 "LT DL Log" from pages/lt-part-line-before-host-key/PartLineBeforeHostKey.al; test codeunit 81350
// Probe: a line is entered in the lines part of a document page while the header key is blank, then the key is typed. Typing the key renames the header, and the test client answers the rename Confirm with its default.
// The same scenario as PartLine_EnteredBeforeHostKey_ThenKeyTyped in PartLineBeforeHostKey.al, which is pinned from BC 28 only. This file pins it on every version: BC 27.5 on an official Windows container gave
// exactly these values (corpus run 39125184978), and the Linux image gives them since MsDyn365Bc.On.Linux PR #127 (before, BC 27 on Linux ended the session with a NullReferenceException).
// BC versions: 27, 28, 29
codeunit 81350 "LT BG Part Line All Versions"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Seed()
    var
        Header: Record "LT DL Header";
        Line: Record "LT DL Line";
        Log: Codeunit "LT DL Log";
    begin
        Line.DeleteAll();
        Header.DeleteAll();
        Log.Reset();
    end;

    [TryFunction]
    local procedure TryOpenNew(var Host: TestPage "LT DL Document")
    begin
        Host.OpenNew();
    end;

    [TryFunction]
    local procedure TryNewLine(var Host: TestPage "LT DL Document")
    begin
        Host.Lines.New();
    end;

    [TryFunction]
    local procedure TryDescription(var Host: TestPage "LT DL Document"; Value: Text)
    begin
        Host.Lines.Description.SetValue(Value);
    end;

    [TryFunction]
    local procedure TryQuantity(var Host: TestPage "LT DL Document"; Value: Decimal)
    begin
        Host.Lines.Quantity.SetValue(Value);
    end;

    [TryFunction]
    local procedure TryKey(var Host: TestPage "LT DL Document"; Value: Text)
    begin
        Host."No.".SetValue(Value);
    end;

    [TryFunction]
    local procedure TryName(var Host: TestPage "LT DL Document"; Value: Text)
    begin
        Host.Name.SetValue(Value);
    end;

    local procedure Step(var Observer: Codeunit "Probe Observer"; Name: Text; Ok: Boolean)
    var
        Log: Codeunit "LT DL Log";
    begin
        Observer.Observe(Name, Format(Ok));
        if not Ok then
            Observer.ObserveError(Name + '_error');
        Observer.Observe(Name + '_log', Log.Dump());
        Log.Reset();
    end;

    local procedure Stored(var Observer: Codeunit "Probe Observer"; Name: Text)
    var
        Header: Record "LT DL Header";
        Line: Record "LT DL Line";
        Rows: Text;
    begin
        Observer.Observe(Name + '_headers', Format(Header.Count()));
        if Header.FindSet() then
            repeat
                Rows += '[' + Header."No." + '|' + Header.Name + ']';
            until Header.Next() = 0;
        Observer.Observe(Name + '_header_rows', Rows);
        Rows := '';
        Observer.Observe(Name + '_lines', Format(Line.Count()));
        if Line.FindSet() then
            repeat
                Rows += '[' + Line."Document No." + '|' + Format(Line."Line No.") + '|' + Line.Description + '|' + Format(Line.Quantity) + ']';
            until Line.Next() = 0;
        Observer.Observe(Name + '_line_rows', Rows);
    end;

    local procedure Card(var Observer: Codeunit "Probe Observer"; Name: Text; var Host: TestPage "LT DL Document")
    begin
        Observer.Observe(Name + '_card_no', '[' + Host."No.".Value() + ']');
        Observer.Observe(Name + '_card_name', '[' + Host.Name.Value() + ']');
        Observer.Observe(Name + '_part_description', '[' + Host.Lines.Description.Value() + ']');
        Observer.Observe(Name + '_part_quantity', '[' + Host.Lines.Quantity.Value() + ']');
    end;

    [Test]
    procedure BG_PartLine_EnteredBeforeHostKey_ThenKeyTyped_AllVersions()
    var
        Observer: Codeunit "Probe Observer";
        Host: TestPage "LT DL Document";
    begin
        Seed();
        Step(Observer, 'open_new', TryOpenNew(Host));
        Step(Observer, 'new_line', TryNewLine(Host));
        Step(Observer, 'description_before_key', TryDescription(Host, 'first'));
        Step(Observer, 'quantity_before_key', TryQuantity(Host, 3));
        Stored(Observer, 'before_key');
        Step(Observer, 'type_key', TryKey(Host, 'D1'));
        Card(Observer, 'after_key', Host);
        Stored(Observer, 'after_key');
        Step(Observer, 'type_name', TryName(Host, 'Doc one'));
        Stored(Observer, 'after_name');
        Step(Observer, 'close', TryClose(Host));
        Stored(Observer, 'after_close');
        Observer.Expect('open_new', 'Yes');
        Observer.Expect('open_new_log', '[HP.OnNewRecord | L.OnValidate(Document No.): | LP.OnNewRecord: | LP.OnNewRecord: | L.OnValidate(Document No.): | LP.OnNewRecord:]');
        Observer.Expect('new_line', 'Yes');
        Observer.Expect('new_line_log', '[HP.OnInsertRecord: | H.OnInsert: | L.OnValidate(Document No.): | LP.OnNewRecord: | LP.OnNewRecord: | L.OnValidate(Document No.): | LP.OnNewRecord: | L.OnValidate(Document No.): | LP.OnNewRecord:]');
        Observer.Expect('description_before_key', 'Yes');
        Observer.Expect('description_before_key_log', '[L.OnValidate(Description):first key=/0]');
        Observer.Expect('quantity_before_key', 'Yes');
        Observer.Expect('quantity_before_key_log', '[LP.OnInsertRecord:/20000 | L.OnInsert:/20000 | L.OnValidate(Quantity):3 key=/20000]');
        Observer.Expect('before_key_headers', '1');
        Observer.Expect('before_key_header_rows', '[|]');
        Observer.Expect('before_key_lines', '1');
        Observer.Expect('before_key_line_rows', '[|20000|first|0]');
        Observer.Expect('type_key', 'Yes');
        Observer.Expect('type_key_log', '[L.OnModify:/20000 | H.OnValidate(No.):D1]');
        Observer.Expect('after_key_card_no', '[]');
        Observer.Expect('after_key_card_name', '[]');
        Observer.Expect('after_key_part_description', '[first]');
        Observer.Expect('after_key_part_quantity', '[3.00]');
        Observer.Expect('after_key_headers', '1');
        Observer.Expect('after_key_header_rows', '[|]');
        Observer.Expect('after_key_lines', '1');
        Observer.Expect('after_key_line_rows', '[|20000|first|3]');
        Observer.Expect('type_name', 'Yes');
        Observer.Expect('type_name_log', '[H.OnValidate(Name):Doc one key=]');
        Observer.Expect('after_name_headers', '1');
        Observer.Expect('after_name_header_rows', '[|]');
        Observer.Expect('after_name_lines', '1');
        Observer.Expect('after_name_line_rows', '[|20000|first|3]');
        Observer.Expect('close', 'Yes');
        Observer.Expect('close_log', '[H.OnModify:]');
        Observer.Expect('after_close_headers', '1');
        Observer.Expect('after_close_header_rows', '[|Doc one]');
        Observer.Expect('after_close_lines', '1');
        Observer.Expect('after_close_line_rows', '[|20000|first|3]');
        Observer.Verify();
    end;

    [TryFunction]
    local procedure TryClose(var Host: TestPage "LT DL Document")
    begin
        Host.Close();
    end;
}
