# Fixes applied to crate sources, shared by every package using the crate.
#
# Keyed by crate name; each value is a function from `{ name, version }` to
# extra arguments for rustCrates.fetchCrateSource (`patches`, `postPatch`), e.g.
#
#   some-sys =
#     { version, ... }:
#     {
#       patches = lib.optional (lib.versionOlder version "0.4") ./some-sys-unbundle.patch;
#     };
#
# Add whatever arguments you need to the function below; it is called with callPackage.
{ }:
{
}
