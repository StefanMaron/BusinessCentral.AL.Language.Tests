// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-xmlport-object
//   https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-testisolation-property
// Scope: fixture XmlPort used by "Test Write Tx Test Boundary" (60878)
// Fixture table: ALT Universal (60000)
//
// The xmlport arm's target. Direction = Import with a tableelement over "ALT Universal", so
// the import itself is the write — there is no AL statement in the test body doing it. The
// question is whether XmlPort.Import begins a transaction of its own the way Codeunit.Run
// does, asked from a TransactionModel::None test body that has none.
//
// A separate object from "ALT Universal XmlPort" (60023) rather than a reuse: 60023 is
// Direction = Both and is already the subject of the XmlPort coverage suite, and a
// transaction question should not ride on an object another suite is free to re-shape.
xmlport 60413 "ALT Run Tx None XmlPort"
{
    Caption = 'ALT Run Tx None XmlPort';
    Direction = Import;
    Format = Xml;
    UseRequestPage = false;

    schema
    {
        textelement(Universals)
        {
            tableelement(Universal; "ALT Universal")
            {
                XmlName = 'Universal';

                fieldelement(EntryNo; Universal."Entry No.")
                {
                }
                fieldelement(TextValue; Universal."Text Field")
                {
                }
            }
        }
    }
}
