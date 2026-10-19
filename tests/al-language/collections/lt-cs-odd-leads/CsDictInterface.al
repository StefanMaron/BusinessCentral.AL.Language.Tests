// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/dictionary/dictionary-get-tkey-tvalue-method
// Scope: in-scope
// Fixtures used: Probe Observer, collections/Fixtures.al (interface "LT ClT Shape", codeunits 74600/74601)
// Probe: corpus issue 670 item 5 (microsoft/AL#8247): Dictionary.Get(Key, var Value) where Value is a var Interface parameter, in an exit statement.
//   Every literal asserted below is what BC produced; the CI matrix checks BC 27.5, 28.5 and 29.0.
// BC versions: 27, 28, 29

codeunit 85182 "LT CS Dict Interface"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Shapes: Dictionary of [Text, Interface "LT ClT Shape"];

    local procedure TryGetShape(ShapeKey: Text; var Result: Interface "LT ClT Shape"): Boolean
    begin
        exit(Shapes.Get(ShapeKey, Result));
    end;

    local procedure GetShapeChecked(ShapeKey: Text; var Result: Interface "LT ClT Shape"): Boolean
    begin
        if not Shapes.ContainsKey(ShapeKey) then
            exit(false);
        Result := Shapes.Get(ShapeKey);
        exit(true);
    end;

    [Test]
    procedure DictionaryGet_VarInterfaceParameter()
    var
        Observer: Codeunit "Probe Observer";
        C: Codeunit "LT ClT Circle";
        S: Codeunit "LT ClT Square";
        I: Interface "LT ClT Shape";
        Got: Interface "LT ClT Shape";
    begin
        Clear(Shapes);
        C.SetTag('K');
        I := C;
        Shapes.Add('c', I);
        I := S;
        Got := I;
        Observer.Observe('found', Format(TryGetShape('c', Got)));
        Observer.Observe('found name', Got.Name());
        Got := S;
        Observer.Observe('missing', Format(TryGetShape('x', Got)));
        Observer.Observe('missing keeps value', Got.Name());
        Got := S;
        Observer.Observe('checked found', Format(GetShapeChecked('c', Got)));
        Observer.Observe('checked found name', Got.Name());
        Observer.Observe('checked missing', Format(GetShapeChecked('x', Got)));
        Observer.Finish();
    end;
}
