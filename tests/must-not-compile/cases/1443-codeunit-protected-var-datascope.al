// @expect AL0676 | The member 'MyDataScope2' in object 'MNC BP C1443' cannot be declared as protected in object type 'Codeunit'.
// A codeunit with a `protected var` section (microsoft/AL issue 6620 used one for a DataScope variable): refused, protected variables
// exist on tables, pages and reports only. The plain global DataScope variable compiles (no diagnostic for it); its runtime test is in
// tests/al-language/types/lt-scalars/ScT70063.al (Defaults_DataScopeGlobal_BP).
codeunit 51443 "MNC BP C1443"
{
    var
        MyDataScope: DataScope;

    protected var
        MyDataScope2: DataScope;

    procedure P(): DataScope
    begin
        MyDataScope := DataScope::Company;
        MyDataScope2 := MyDataScope;
        exit(MyDataScope2);
    end;
}
