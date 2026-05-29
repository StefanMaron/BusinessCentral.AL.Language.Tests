codeunit 60030 "ALT Event Mutation Control"
{
    SingleInstance = true;

    var
        Scenario: Code[50];

    procedure SetScenario(NewScenario: Code[50])
    begin
        Scenario := NewScenario;
    end;

    procedure GetScenario(): Code[50]
    begin
        exit(Scenario);
    end;

    procedure ClearScenario()
    begin
        Clear(Scenario);
    end;
}
