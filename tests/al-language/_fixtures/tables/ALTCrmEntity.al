// ALTCrmEntity: TableType = CRM fixture.
// Shaped like Base Application's own Dataverse tables (Guid primary key with
// ExternalAccess = Insert, ExternalName/ExternalType on the table and every field).
// BC serves a TableType = CRM table through the session's current CRM table connection,
// never through SQL; with the '@@test@@' connection string registered inside a test the
// platform's in-memory test provider stands in for Dataverse and assigns a fresh Guid to
// an empty primary key on Insert. Used to prove the table-connection contract
// (session/TestDatabaseTableConnectionCrm.al).
table 60291 "ALT CRM Entity"
{
    TableType = CRM;
    ExternalName = 'alt_entity';
    Caption = 'ALT CRM Entity';
    DataClassification = SystemMetadata;

    fields
    {
        field(1; EntityId; Guid)
        {
            ExternalName = 'alt_entityid';
            ExternalType = 'Uniqueidentifier';
            ExternalAccess = Insert;
            Caption = 'Entity Id';
            DataClassification = SystemMetadata;
        }
        field(2; Name; Text[100])
        {
            ExternalName = 'alt_name';
            ExternalType = 'String';
            Caption = 'Name';
            DataClassification = SystemMetadata;
        }
        field(3; Amount; Decimal)
        {
            ExternalName = 'alt_amount';
            ExternalType = 'Decimal';
            Caption = 'Amount';
            DataClassification = SystemMetadata;
        }
    }

    keys
    {
        key(PK; EntityId)
        {
            Clustered = true;
        }
    }
}
