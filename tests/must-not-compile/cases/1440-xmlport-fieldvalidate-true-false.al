// @expect AL0107 | Syntax error, identifier expected.
// @expect AL0116 | Invalid value for 'FieldValidate'. Allowed values are 'Yes,No,Undefined'
// @expect AL0107 | Syntax error, identifier expected.
// @expect AL0116 | Invalid value for 'FieldValidate'. Allowed values are 'Yes,No,Undefined'
// XMLport FieldValidate (microsoft/AL issue 5451): the values true and false are refused (each gives AL0107 and AL0116). Yes, No and
// Undefined compile (no diagnostic for them).
xmlport 51440 "MNC BP X1440"
{
    schema
    {
        textelement(Root)
        {
            tableelement(C; Customer)
            {
                fieldelement(No; C."No.") { FieldValidate = Yes; }
                fieldelement(Name; C.Name) { FieldValidate = No; }
                fieldelement(Name2; C."Name 2") { FieldValidate = true; }
                fieldelement(Addr; C.Address) { FieldValidate = false; }
                fieldelement(City; C.City) { FieldValidate = Undefined; }
            }
        }
    }
}
