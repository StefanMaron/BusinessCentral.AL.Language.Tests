// @expect AL0309 | Table 'MNC BN T1394' contains too many keys.
// A table with 41 keys (the primary key and 40 more). 40 keys compile; a key of 17 fields also compiles with AL 30.
table 51394 "MNC BN T1394"
{
    fields
    {
        field(1; "F1"; Integer) { }
        field(2; "F2"; Integer) { }
        field(3; "F3"; Integer) { }
        field(4; "F4"; Integer) { }
        field(5; "F5"; Integer) { }
        field(6; "F6"; Integer) { }
        field(7; "F7"; Integer) { }
        field(8; "F8"; Integer) { }
        field(9; "F9"; Integer) { }
        field(10; "F10"; Integer) { }
        field(11; "F11"; Integer) { }
        field(12; "F12"; Integer) { }
        field(13; "F13"; Integer) { }
        field(14; "F14"; Integer) { }
        field(15; "F15"; Integer) { }
        field(16; "F16"; Integer) { }
        field(17; "F17"; Integer) { }
        field(18; "F18"; Integer) { }
        field(19; "F19"; Integer) { }
        field(20; "F20"; Integer) { }
        field(21; "F21"; Integer) { }
        field(22; "F22"; Integer) { }
        field(23; "F23"; Integer) { }
        field(24; "F24"; Integer) { }
        field(25; "F25"; Integer) { }
        field(26; "F26"; Integer) { }
        field(27; "F27"; Integer) { }
        field(28; "F28"; Integer) { }
        field(29; "F29"; Integer) { }
        field(30; "F30"; Integer) { }
        field(31; "F31"; Integer) { }
        field(32; "F32"; Integer) { }
        field(33; "F33"; Integer) { }
        field(34; "F34"; Integer) { }
        field(35; "F35"; Integer) { }
        field(36; "F36"; Integer) { }
        field(37; "F37"; Integer) { }
        field(38; "F38"; Integer) { }
        field(39; "F39"; Integer) { }
        field(40; "F40"; Integer) { }
        field(41; "F41"; Integer) { }
    }
    keys
    {
        key(PK; "F1") { Clustered = true; }
        key(K2; "F2") { }
        key(K3; "F3") { }
        key(K4; "F4") { }
        key(K5; "F5") { }
        key(K6; "F6") { }
        key(K7; "F7") { }
        key(K8; "F8") { }
        key(K9; "F9") { }
        key(K10; "F10") { }
        key(K11; "F11") { }
        key(K12; "F12") { }
        key(K13; "F13") { }
        key(K14; "F14") { }
        key(K15; "F15") { }
        key(K16; "F16") { }
        key(K17; "F17") { }
        key(K18; "F18") { }
        key(K19; "F19") { }
        key(K20; "F20") { }
        key(K21; "F21") { }
        key(K22; "F22") { }
        key(K23; "F23") { }
        key(K24; "F24") { }
        key(K25; "F25") { }
        key(K26; "F26") { }
        key(K27; "F27") { }
        key(K28; "F28") { }
        key(K29; "F29") { }
        key(K30; "F30") { }
        key(K31; "F31") { }
        key(K32; "F32") { }
        key(K33; "F33") { }
        key(K34; "F34") { }
        key(K35; "F35") { }
        key(K36; "F36") { }
        key(K37; "F37") { }
        key(K38; "F38") { }
        key(K39; "F39") { }
        key(K40; "F40") { }
        key(K41; "F41") { }
    }
}
