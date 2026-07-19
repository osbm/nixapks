{
  lib,
  stdenv,
  jdk21,
  stripJavaArchivesHook,
}:
{
  # Build a Maven artifact from source with plain javac.
  #
  # The output is laid out as a Maven repository fragment
  # ($out/<group/path>/<artifactId>/<version>/<artifactId>-<version>.jar + .pom)
  # so that many of these can be composed with symlinkJoin into an offline
  # Maven repository, and eventually overlaid over the binary repositories
  # used by buildGradleApk to substitute source-built jars for binary ones.
  #
  # Deliberately dumb: no Maven, no Gradle, no annotation processors. That
  # keeps the trust root of these artifacts at "nixpkgs JDK + this file".
  # Libraries that genuinely need their upstream build system will get their
  # own builders later; a surprising share of the Java world compiles fine
  # with javac alone.
  buildMavenJar =
    {
      pname, # Maven artifactId
      version,
      groupId,
      src,
      # Directories (relative to the source root) containing .java sources
      sourceDirs ? [ "src/main/java" ],
      # Path substrings to exclude from compilation (matched with `! -path`)
      excludeSources ? [ "module-info.java" ],
      # Other buildMavenJar packages required on the compile classpath
      deps ? [ ],
      # Value for javac --release
      javaRelease ? "8",
      extraJavacFlags ? [ ],
      meta ? { },
    }:
    let
      groupPath = lib.replaceStrings [ "." ] [ "/" ] groupId;
      mavenDir = "${groupPath}/${pname}/${version}";
      jarName = "${pname}-${version}.jar";
    in
    stdenv.mkDerivation (finalAttrs: {
      inherit pname version src;

      nativeBuildInputs = [
        jdk21
        stripJavaArchivesHook
      ];

      dontConfigure = true;

      buildPhase = ''
        runHook preBuild

        find ${lib.escapeShellArgs sourceDirs} -name '*.java' \
          ${lib.concatMapStringsSep " " (e: "! -path '*${e}*'") excludeSources} \
          | sort > sources.txt
        echo "compiling $(wc -l < sources.txt) java files"

        mkdir -p classes
        javac \
          --release ${javaRelease} \
          -encoding UTF-8 \
          -proc:none \
          ${
            lib.optionalString (deps != [ ]) "-classpath '${lib.concatMapStringsSep ":" (d: d.jar) deps}'"
          } \
          ${lib.escapeShellArgs extraJavacFlags} \
          -d classes \
          @sources.txt

        jar --create --file ${jarName} -C classes .

        runHook postBuild
      '';

      installPhase = ''
        runHook preInstall

        install -Dm644 ${jarName} $out/${mavenDir}/${jarName}
        cat > $out/${mavenDir}/${pname}-${version}.pom <<EOF
        <?xml version="1.0" encoding="UTF-8"?>
        <project xmlns="http://maven.apache.org/POM/4.0.0">
          <modelVersion>4.0.0</modelVersion>
          <groupId>${groupId}</groupId>
          <artifactId>${pname}</artifactId>
          <version>${version}</version>
          <packaging>jar</packaging>
        </project>
        EOF

        runHook postInstall
      '';

      passthru = {
        inherit groupId deps;
        mavenCoordinate = "${groupId}:${pname}:${version}";
        jar = "${finalAttrs.finalPackage}/${mavenDir}/${jarName}";
        # Provenance tier of this artifact: binary | rebuilt-verified | from-source
        provenance = "from-source";
      };

      meta = {
        sourceProvenance = [ lib.sourceTypes.fromSource ];
      }
      // meta;
    });
}
