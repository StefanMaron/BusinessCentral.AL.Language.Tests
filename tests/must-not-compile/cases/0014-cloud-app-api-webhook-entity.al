// @expect AL0296 | The application object or method 'API Webhook Entity' has scope 'OnPrem' and cannot be used for 'Cloud' development.
// A Target = Cloud app names the table "API Webhook Entity", which is declared Scope = OnPrem.
codeunit 50000 "MNC Webhook"
{
    procedure Count(): Integer
    var
        Entity: Record "API Webhook Entity";
    begin
        exit(Entity.Count());
    end;
}
