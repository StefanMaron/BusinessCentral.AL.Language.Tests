// @expect AL0167 | The Property 'MovedTo' can only be used if the property 'ObsoleteState' is set with any of the values of: 'PendingMove,Moved'
// MovedTo needs ObsoleteState PendingMove or Moved.
table 59694 "MNC U 694"
{
    MovedTo = '5c6d7e8f-1a2b-4c3d-9e0f-a1b2c3d4e5f7';
    fields { field(1; Id; Integer) { } }
    keys { key(PK; Id) { Clustered = true; } }
}
