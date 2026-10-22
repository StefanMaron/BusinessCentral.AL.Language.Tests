// @expect AL0187 | Attribute 'RequiredPending' is valid only for normal methods.
// @expect AL0666 | 'RequiredPending' is not available in runtime version '16.1'. The supported runtime versions are: '18.0' or greater.
// @from 27
// @until 27
// Corpus #664 item 19. [RequiredPending] on a method of an interface at runtime 16.1 (BC 27): AL0187 as on BC 29 (case 1570), and the
// runtime gate AL0666 as well. BC 28 is case 1571.
interface "MNC BM I1572"
{
    [RequiredPending('Use the new procedure', '29.0')]
    procedure Foo();
}
