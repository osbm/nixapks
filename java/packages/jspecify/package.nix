{
  lib,
  buildMavenJar,
  fetchFromGitHub,
}:
buildMavenJar {
  pname = "jspecify";
  groupId = "org.jspecify";
  version = "1.0.0";

  src = fetchFromGitHub {
    owner = "jspecify";
    repo = "jspecify";
    rev = "v1.0.0";
    hash = "sha256-WgVRaGm9lYhMeMM6QWUezXtUsXkaK/iPt1gj2koWNu8=";
  };

  # uses ElementType.MODULE, a Java 9 API
  javaRelease = "9";

  meta = {
    description = "Standard nullness annotations for static analysis";
    homepage = "https://jspecify.dev";
    license = lib.licenses.asl20;
    maintainers = with lib.maintainers; [ osbm ];
  };
}
