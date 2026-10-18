// @expect AL0829 | Symbol of kind Field 'MncMoved' cannot be moved to its own app.
// MovedTo names the app of the extension itself.
tableextension 59699 "MNC U Ext 699" extends Customer
{
    fields
    {
        field(59699; MncMoved; Text[20])
        {
            ObsoleteState = PendingMove;
            ObsoleteReason = 'x';
            ObsoleteTag = '1.0';
            MovedTo = '6c1f3a52-1b6e-4d1e-9a0a-1f7e4c2b9d10';
        }
    }
}
