// @expect AL0135 | There is no argument given that corresponds to the required formal parameter 'String' of 'Message(Text, [Joker])'
// Message is called without arguments.
codeunit 50056 "MNC C250"
{
    procedure Run1()
    begin
        Message();
    end;
}
