// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/httpheaders/httpheaders-data-type
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160), LT P87 Helper (codeunit 74228)
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: which header names are accepted by which HttpHeaders collection (request, request content, stand-alone content, response, response content)
// BC versions: 29 (27 and 28 by CI)

codeunit 74222 "LT P87 Header Matrix"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Run(var Observer: Codeunit "Probe Observer"; Kind: Integer; FromIdx: Integer; ToIdx: Integer)
    var
        Helper: Codeunit "LT P87 Helper";
        Names: List of [Text];
        i: Integer;
    begin
        Helper.Names(Names);
        for i := FromIdx to ToIdx do begin
            if not ((Kind = 5) and (Names.Get(i) in ['Content-Length', 'Transfer-Encoding'])) then
                if not ((Kind = 3) and (Names.Get(i) = 'Transfer-Encoding')) then
                    Observer.Observe(Names.Get(i), Helper.Matrix(Kind, Names.Get(i)));
        end;
    end;

    [Test]
    procedure MatrixRequestHeaders_Part1()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Run(Observer, 1, 1, 2);
        Observer.Finish();
    end;

    [Test]
    procedure MatrixRequestHeaders_Part2()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Run(Observer, 1, 3, 4);
        Observer.Finish();
    end;

    [Test]
    procedure MatrixRequestHeaders_Part3()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Run(Observer, 1, 5, 6);
        Observer.Finish();
    end;

    [Test]
    procedure MatrixRequestHeaders_Part4()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Run(Observer, 1, 7, 8);
        Observer.Finish();
    end;

    [Test]
    procedure MatrixRequestHeaders_Part5()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Run(Observer, 1, 9, 10);
        Observer.Finish();
    end;

    [Test]
    procedure MatrixRequestHeaders_Part6()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Run(Observer, 1, 11, 12);
        Observer.Finish();
    end;

    [Test]
    procedure MatrixRequestHeaders_Part7()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Run(Observer, 1, 13, 14);
        Observer.Finish();
    end;

    [Test]
    procedure MatrixRequestHeaders_Part8()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Run(Observer, 1, 15, 16);
        Observer.Finish();
    end;

    [Test]
    procedure MatrixRequestHeaders_Part9()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Run(Observer, 1, 17, 18);
        Observer.Finish();
    end;

    [Test]
    procedure MatrixRequestHeaders_Part10()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Run(Observer, 1, 19, 19);
        Observer.Finish();
    end;

    [Test]
    procedure MatrixRequestContentHeaders_Part1()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Run(Observer, 2, 1, 2);
        Observer.Finish();
    end;

    [Test]
    procedure MatrixRequestContentHeaders_Part2()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Run(Observer, 2, 3, 4);
        Observer.Finish();
    end;

    [Test]
    procedure MatrixRequestContentHeaders_Part3()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Run(Observer, 2, 5, 6);
        Observer.Finish();
    end;

    [Test]
    procedure MatrixRequestContentHeaders_Part4()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Run(Observer, 2, 7, 8);
        Observer.Finish();
    end;

    [Test]
    procedure MatrixRequestContentHeaders_Part5()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Run(Observer, 2, 9, 10);
        Observer.Finish();
    end;

    [Test]
    procedure MatrixRequestContentHeaders_Part6()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Run(Observer, 2, 11, 12);
        Observer.Finish();
    end;

    [Test]
    procedure MatrixRequestContentHeaders_Part7()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Run(Observer, 2, 13, 14);
        Observer.Finish();
    end;

    [Test]
    procedure MatrixRequestContentHeaders_Part8()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Run(Observer, 2, 15, 16);
        Observer.Finish();
    end;

    [Test]
    procedure MatrixRequestContentHeaders_Part9()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Run(Observer, 2, 17, 18);
        Observer.Finish();
    end;

    [Test]
    procedure MatrixRequestContentHeaders_Part10()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Run(Observer, 2, 19, 19);
        Observer.Finish();
    end;

    [Test]
    procedure MatrixStandaloneContentHeaders_Part1()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Run(Observer, 3, 1, 2);
        Observer.Finish();
    end;

    [Test]
    procedure MatrixStandaloneContentHeaders_Part2()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Run(Observer, 3, 3, 4);
        Observer.Finish();
    end;

    [Test]
    procedure MatrixStandaloneContentHeaders_Part3()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Run(Observer, 3, 5, 6);
        Observer.Finish();
    end;

    [Test]
    procedure MatrixStandaloneContentHeaders_Part4()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Run(Observer, 3, 7, 8);
        Observer.Finish();
    end;

    [Test]
    procedure MatrixStandaloneContentHeaders_Part5()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Run(Observer, 3, 9, 10);
        Observer.Finish();
    end;

    [Test]
    procedure MatrixStandaloneContentHeaders_Part6()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Run(Observer, 3, 11, 12);
        Observer.Finish();
    end;

    [Test]
    procedure MatrixStandaloneContentHeaders_Part7()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Run(Observer, 3, 13, 14);
        Observer.Finish();
    end;

    [Test]
    procedure MatrixStandaloneContentHeaders_Part8()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Run(Observer, 3, 15, 16);
        Observer.Finish();
    end;

    [Test]
    procedure MatrixStandaloneContentHeaders_Part9()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Run(Observer, 3, 17, 18);
        Observer.Finish();
    end;

    [Test]
    procedure MatrixStandaloneContentHeaders_Part10()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Run(Observer, 3, 19, 19);
        Observer.Finish();
    end;

    [Test]
    procedure MatrixResponseHeaders_Part1()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Run(Observer, 4, 1, 2);
        Observer.Finish();
    end;

    [Test]
    procedure MatrixResponseHeaders_Part2()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Run(Observer, 4, 3, 4);
        Observer.Finish();
    end;

    [Test]
    procedure MatrixResponseHeaders_Part3()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Run(Observer, 4, 5, 6);
        Observer.Finish();
    end;

    [Test]
    procedure MatrixResponseHeaders_Part4()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Run(Observer, 4, 7, 8);
        Observer.Finish();
    end;

    [Test]
    procedure MatrixResponseHeaders_Part5()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Run(Observer, 4, 9, 10);
        Observer.Finish();
    end;

    [Test]
    procedure MatrixResponseHeaders_Part6()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Run(Observer, 4, 11, 12);
        Observer.Finish();
    end;

    [Test]
    procedure MatrixResponseHeaders_Part7()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Run(Observer, 4, 13, 14);
        Observer.Finish();
    end;

    [Test]
    procedure MatrixResponseHeaders_Part8()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Run(Observer, 4, 15, 16);
        Observer.Finish();
    end;

    [Test]
    procedure MatrixResponseHeaders_Part9()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Run(Observer, 4, 17, 18);
        Observer.Finish();
    end;

    [Test]
    procedure MatrixResponseHeaders_Part10()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Run(Observer, 4, 19, 19);
        Observer.Finish();
    end;

    [Test]
    procedure MatrixResponseContentHeaders_Part1()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Run(Observer, 5, 1, 2);
        Observer.Finish();
    end;

    [Test]
    procedure MatrixResponseContentHeaders_Part2()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Run(Observer, 5, 3, 4);
        Observer.Finish();
    end;

    [Test]
    procedure MatrixResponseContentHeaders_Part3()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Run(Observer, 5, 5, 6);
        Observer.Finish();
    end;

    [Test]
    procedure MatrixResponseContentHeaders_Part4()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Run(Observer, 5, 7, 8);
        Observer.Finish();
    end;

    [Test]
    procedure MatrixResponseContentHeaders_Part5()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Run(Observer, 5, 9, 10);
        Observer.Finish();
    end;

    [Test]
    procedure MatrixResponseContentHeaders_Part6()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Run(Observer, 5, 11, 12);
        Observer.Finish();
    end;

    [Test]
    procedure MatrixResponseContentHeaders_Part7()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Run(Observer, 5, 13, 14);
        Observer.Finish();
    end;

    [Test]
    procedure MatrixResponseContentHeaders_Part8()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Run(Observer, 5, 15, 16);
        Observer.Finish();
    end;

    [Test]
    procedure MatrixResponseContentHeaders_Part9()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Run(Observer, 5, 17, 18);
        Observer.Finish();
    end;

    [Test]
    procedure MatrixResponseContentHeaders_Part10()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Run(Observer, 5, 19, 19);
        Observer.Finish();
    end;

}
