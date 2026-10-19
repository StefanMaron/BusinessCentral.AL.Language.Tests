// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/system/system-getdotnettype-method
// Scope: in-scope, but ONLY for a Target = OnPrem app (DotNet), AL compiler 18.0 or newer (see TestDotNetValueKindsContracts.al)
// Fixtures used: Probe Observer (69160), from the AL Language Coverage Tests app; self-contained codeunit 99220
// Probe: corpus issue 653 items 14 and 15: GetDotNetType of an unassigned DotNet String, Char, Byte, Int32, StringBuilder and Type variable;
//   of a Variant holding a Byte, Char, Time, Option, Enum and closing Date; of an AL Enum and a DateFormula; and of an unassigned DotNet Type,
//   Object and Exception variable. Each test records Type.FullName and Format(Type), or the error text and code.
//   Variant holding Integer ... Duration: DotNetTypeVariant.al; scalars: DotNetTypeScalars.al (lt-dotnet-interop).
// BC versions: 27, 28, 29
dotnet
{
    assembly("mscorlib")
    {
        type("System.Type"; LtBbType) { }
        type("System.String"; LtBbStr) { }
        type("System.Char"; LtBbChar) { }
        type("System.Byte"; LtBbByte) { }
        type("System.Int32"; LtBbInt) { }
        type("System.Text.StringBuilder"; LtBbSb) { }
        type("System.Object"; LtBbObj) { }
        type("System.Exception"; LtBbExc) { }
    }
}

codeunit 99220 "LT BB GetDotNetType"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";

    local procedure Show(T: DotNet LtBbType): Text
    begin
        exit(T.FullName() + '|' + Format(T));
    end;

    local procedure Run(Name: Text; Ok: Boolean; Shown: Text)
    begin
        if Ok then
            Observer.Observe(Name, Shown)
        else
            Observer.ObserveError(Name);
        Observer.Finish();
    end;

    [TryFunction]
    local procedure TryUnassignedString(var Shown: Text)
    var
        T: DotNet LtBbType;
        X: DotNet LtBbStr;
    begin
        T := GetDotNetType(X);
        Shown := Show(T);
    end;

    [TryFunction]
    local procedure TryUnassignedChar(var Shown: Text)
    var
        T: DotNet LtBbType;
        X: DotNet LtBbChar;
    begin
        T := GetDotNetType(X);
        Shown := Show(T);
    end;

    [TryFunction]
    local procedure TryUnassignedByte(var Shown: Text)
    var
        T: DotNet LtBbType;
        X: DotNet LtBbByte;
    begin
        T := GetDotNetType(X);
        Shown := Show(T);
    end;

    [TryFunction]
    local procedure TryUnassignedInt32(var Shown: Text)
    var
        T: DotNet LtBbType;
        X: DotNet LtBbInt;
    begin
        T := GetDotNetType(X);
        Shown := Show(T);
    end;

    [TryFunction]
    local procedure TryUnassignedStringBuilder(var Shown: Text)
    var
        T: DotNet LtBbType;
        X: DotNet LtBbSb;
    begin
        T := GetDotNetType(X);
        Shown := Show(T);
    end;

    [TryFunction]
    local procedure TryUnassignedType(var Shown: Text)
    var
        T: DotNet LtBbType;
        X: DotNet LtBbType;
    begin
        T := GetDotNetType(X);
        Shown := Show(T);
    end;

    [TryFunction]
    local procedure TryVariantByte(var Shown: Text)
    var
        T: DotNet LtBbType;
        V: Variant;
        B: Byte;
    begin
        B := 7;
        V := B;
        T := GetDotNetType(V);
        Shown := Show(T);
    end;

    [TryFunction]
    local procedure TryVariantChar(var Shown: Text)
    var
        T: DotNet LtBbType;
        V: Variant;
        C: Char;
    begin
        C := 'x';
        V := C;
        T := GetDotNetType(V);
        Shown := Show(T);
    end;

    [TryFunction]
    local procedure TryVariantTime(var Shown: Text)
    var
        T: DotNet LtBbType;
        V: Variant;
        Tm: Time;
    begin
        Tm := 103000T;
        V := Tm;
        T := GetDotNetType(V);
        Shown := Show(T);
    end;

    [TryFunction]
    local procedure TryVariantOption(var Shown: Text)
    var
        T: DotNet LtBbType;
        V: Variant;
        O: Option First,Second;
    begin
        O := O::Second;
        V := O;
        T := GetDotNetType(V);
        Shown := Show(T);
    end;

    [TryFunction]
    local procedure TryVariantEnum(var Shown: Text)
    var
        T: DotNet LtBbType;
        V: Variant;
        E: Enum "Sales Document Type";
    begin
        E := E::Order;
        V := E;
        T := GetDotNetType(V);
        Shown := Show(T);
    end;

    [TryFunction]
    local procedure TryVariantClosingDate(var Shown: Text)
    var
        T: DotNet LtBbType;
        V: Variant;
    begin
        V := ClosingDate(20240131D);
        T := GetDotNetType(V);
        Shown := Show(T);
    end;

    [TryFunction]
    local procedure TryAlEnum(var Shown: Text)
    var
        T: DotNet LtBbType;
        E: Enum "Sales Document Type";
    begin
        E := E::Order;
        T := GetDotNetType(E);
        Shown := Show(T);
    end;

    [TryFunction]
    local procedure TryDateFormula(var Shown: Text)
    var
        T: DotNet LtBbType;
        DF: DateFormula;
    begin
        Evaluate(DF, '<1D>');
        T := GetDotNetType(DF);
        Shown := Show(T);
    end;

    [TryFunction]
    local procedure TryUnassignedPlainObject(var Shown: Text)
    var
        T: DotNet LtBbType;
        X: DotNet LtBbObj;
    begin
        T := GetDotNetType(X);
        Shown := Show(T);
    end;

    [TryFunction]
    local procedure TryUnassignedPlainException(var Shown: Text)
    var
        T: DotNet LtBbType;
        X: DotNet LtBbExc;
    begin
        T := GetDotNetType(X);
        Shown := Show(T);
    end;

    [Test]
    procedure GetDotNetType_UnassignedString()
    var
        Shown: Text;
    begin
        ClearLastError();
        Run('UnassignedString', TryUnassignedString(Shown), Shown);
    end;

    [Test]
    procedure GetDotNetType_UnassignedChar()
    var
        Shown: Text;
    begin
        ClearLastError();
        Run('UnassignedChar', TryUnassignedChar(Shown), Shown);
    end;

    [Test]
    procedure GetDotNetType_UnassignedByte()
    var
        Shown: Text;
    begin
        ClearLastError();
        Run('UnassignedByte', TryUnassignedByte(Shown), Shown);
    end;

    [Test]
    procedure GetDotNetType_UnassignedInt32()
    var
        Shown: Text;
    begin
        ClearLastError();
        Run('UnassignedInt32', TryUnassignedInt32(Shown), Shown);
    end;

    [Test]
    procedure GetDotNetType_UnassignedStringBuilder()
    var
        Shown: Text;
    begin
        ClearLastError();
        Run('UnassignedStringBuilder', TryUnassignedStringBuilder(Shown), Shown);
    end;

    [Test]
    procedure GetDotNetType_UnassignedType()
    var
        Shown: Text;
    begin
        ClearLastError();
        Run('UnassignedType', TryUnassignedType(Shown), Shown);
    end;

    [Test]
    procedure GetDotNetType_VariantByte()
    var
        Shown: Text;
    begin
        ClearLastError();
        Run('VariantByte', TryVariantByte(Shown), Shown);
    end;

    [Test]
    procedure GetDotNetType_VariantChar()
    var
        Shown: Text;
    begin
        ClearLastError();
        Run('VariantChar', TryVariantChar(Shown), Shown);
    end;

    [Test]
    procedure GetDotNetType_VariantTime()
    var
        Shown: Text;
    begin
        ClearLastError();
        Run('VariantTime', TryVariantTime(Shown), Shown);
    end;

    [Test]
    procedure GetDotNetType_VariantOption()
    var
        Shown: Text;
    begin
        ClearLastError();
        Run('VariantOption', TryVariantOption(Shown), Shown);
    end;

    [Test]
    procedure GetDotNetType_VariantEnum()
    var
        Shown: Text;
    begin
        ClearLastError();
        Run('VariantEnum', TryVariantEnum(Shown), Shown);
    end;

    [Test]
    procedure GetDotNetType_VariantClosingDate()
    var
        Shown: Text;
    begin
        ClearLastError();
        Run('VariantClosingDate', TryVariantClosingDate(Shown), Shown);
    end;

    [Test]
    procedure GetDotNetType_AlEnum()
    var
        Shown: Text;
    begin
        ClearLastError();
        Run('AlEnum', TryAlEnum(Shown), Shown);
    end;

    [Test]
    procedure GetDotNetType_DateFormula()
    var
        Shown: Text;
    begin
        ClearLastError();
        Run('DateFormula', TryDateFormula(Shown), Shown);
    end;

    [Test]
    procedure GetDotNetType_UnassignedPlainObject()
    var
        Shown: Text;
    begin
        ClearLastError();
        Run('UnassignedPlainObject', TryUnassignedPlainObject(Shown), Shown);
    end;

    [Test]
    procedure GetDotNetType_UnassignedPlainException()
    var
        Shown: Text;
    begin
        ClearLastError();
        Run('UnassignedPlainException', TryUnassignedPlainException(Shown), Shown);
    end;
}
