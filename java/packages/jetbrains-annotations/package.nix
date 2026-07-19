{
  lib,
  buildMavenJar,
  fetchFromGitHub,
}:
buildMavenJar {
  pname = "annotations";
  groupId = "org.jetbrains";
  version = "23.0.0";

  src = fetchFromGitHub {
    owner = "JetBrains";
    repo = "java-annotations";
    rev = "23.0.0";
    hash = "sha256-pMI7q9UzwpZaobaAYC4DLF2q//083l22X9Fjm+SnNWA=";
  };

  # The `annotations` artifact combines these two modules;
  # the java5 module produces the separate annotations-java5 artifact.
  sourceDirs = [
    "common/src/main/java"
    "java8/src/main/java"
  ];
  javaRelease = "8";

  meta = {
    description = "Annotations for JVM-based languages (@Nullable, @NotNull, ...)";
    homepage = "https://github.com/JetBrains/java-annotations";
    license = lib.licenses.asl20;
    maintainers = with lib.maintainers; [ osbm ];
  };
}
