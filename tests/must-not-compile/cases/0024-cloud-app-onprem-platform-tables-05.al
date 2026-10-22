// @expect AL0161 | 'Table System.Agents.Internal."Agent Troubleshoot Info Data"' is inaccessible due to its protection level
// @expect AL0296 | The application object or method 'Agent Troubleshoot Info Data' has scope 'OnPrem' and cannot be used for 'Cloud' development.
// @expect AL0296 | The application object or method 'Inplace Installed Application' has scope 'OnPrem' and cannot be used for 'Cloud' development.
// @expect AL0296 | The application object or method 'User AI Consumption Data' has scope 'OnPrem' and cannot be used for 'Cloud' development.
// @until 27
// @from 27
// group
codeunit 50000 "MNC OnPrem Tables"
{
    procedure P0(): Integer
    var
        R: Record "User AI Consumption Data";
    begin
        exit(R.Count());
    end;

    procedure P1(): Integer
    var
        R: Record "Agent Troubleshoot Info Data";
    begin
        exit(R.Count());
    end;

    procedure P2(): Integer
    var
        R: Record "Inplace Installed Application";
    begin
        exit(R.Count());
    end;

}
