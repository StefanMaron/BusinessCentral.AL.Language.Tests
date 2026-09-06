/// <summary>
/// The SOURCE side of a <c>Database::&lt;Object&gt;</c> constant.
/// <para>"Table ID" is a plain Integer column holding an object id — the shape the Base
/// Application uses for its polymorphic link tables ("CRM Integration Record"."Table ID",
/// "Alloc. Acc. Modified by User") and the shape a <c>const(Database::&lt;Table&gt;)</c>
/// where-condition pins. Nothing here declares the constant; the rows just carry ids, so a
/// test can seed a row for one table and a row for another and tell them apart.</para>
/// </summary>
table 60327 "CDC Ref Row"
{
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Code"; Code[20]) { DataClassification = CustomerContent; }

        /// The Integer column a const(Database::X) condition compares against. Integer, not
        /// Text or Code: the whole point is that the constant has to arrive as a NUMBER.
        field(2; "Table ID"; Integer) { DataClassification = CustomerContent; }

        field(3; "Owner No."; Code[20]) { DataClassification = CustomerContent; }

        field(4; Amount; Decimal) { DataClassification = CustomerContent; }
    }

    keys
    {
        key(PK; "Code") { Clustered = true; }
        key(ByOwner; "Owner No.", "Table ID") { }
    }
}
