{ pkgs, lib }:
{
  # Phase 1 verification harness: compare a source-built jar against the
  # binary published on Maven Central.
  #
  # The report never fails the build — a difference is a finding, not an
  # error. Verdicts:
  #   BYTE-IDENTICAL      the whole jar reproduces bit-for-bit
  #   CLASSES-IDENTICAL   every .class matches; only archive metadata differs
  #   DIFFERS             bytecode differs (usually a different javac); the
  #                       report lists which classes
  compareWithCentral =
    { pkg, centralHash }:
    let
      groupPath = lib.replaceStrings [ "." ] [ "/" ] pkg.groupId;
      jarName = "${pkg.pname}-${pkg.version}.jar";
      central = pkgs.fetchurl {
        url = "https://repo.maven.apache.org/maven2/${groupPath}/${pkg.pname}/${pkg.version}/${jarName}";
        hash = centralHash;
      };
    in
    pkgs.runCommand "central-report-${pkg.pname}-${pkg.version}" { nativeBuildInputs = [ pkgs.unzip ]; }
      ''
        mkdir ours central
        unzip -qq ${pkg.jar} -d ours
        unzip -qq ${central} -d central

        digest() { (cd $1 && find . -type f -name '*.class' | sort | xargs -r sha256sum) > $2; }
        digest ours ours.classes
        digest central central.classes

        {
          echo "# ${pkg.mavenCoordinate}"
          echo "ours:    $(sha256sum ${pkg.jar} | cut -d' ' -f1)"
          echo "central: $(sha256sum ${central} | cut -d' ' -f1)"

          if cmp -s ${pkg.jar} ${central}; then
            echo "verdict: BYTE-IDENTICAL"
          elif cmp -s ours.classes central.classes; then
            echo "verdict: CLASSES-IDENTICAL (archive metadata differs)"
          else
            echo "verdict: DIFFERS"
            echo
            echo "## class list differences (ours vs central)"
            diff <(cut -d' ' -f3 ours.classes) <(cut -d' ' -f3 central.classes) || true
            echo
            echo "## classes with differing bytecode"
            join -j2 -o 1.1,2.1,0 <(sort -k2 ours.classes) <(sort -k2 central.classes) 2>/dev/null \
              | while read a b f; do [ "$a" != "$b" ] && echo "$f"; done || true
            echo
            echo "## non-class entry lists"
            diff <(cd ours && find . -type f ! -name '*.class' | sort) \
                 <(cd central && find . -type f ! -name '*.class' | sort) || true
          fi
        } > $out
      '';
}
