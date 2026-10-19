// @expect AL0187 | Attribute 'RequiredPending' is valid only for normal methods.
// @expect AL0666 | 'RequiredPending' is not available in runtime version '17.1'. The supported runtime versions are: '18.0' or greater.
// @from 28
// @until 28
// Corpus #664 item 19. [RequiredPending] on a method of an interface at runtime 17.1 (BC 28): AL0187 as on BC 29 (case 1570), and the
// runtime gate AL0666 as well. BC 27 (runtime 16.1) is case 1572.
interface "MNC BM I1571"
{
    [RequiredPending('Use the new procedure', '29.0')]
    procedure Foo();
}
