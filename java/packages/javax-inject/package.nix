{
  lib,
  buildMavenJar,
  fetchFromGitHub,
}:
buildMavenJar {
  pname = "javax.inject";
  groupId = "javax.inject";
  version = "1";

  src = fetchFromGitHub {
    owner = "javax-inject";
    repo = "javax-inject";
    rev = "1f74ea7bd05ce4a3a62ddfe4a2511bf1b4287a61";
    hash = "sha256-Tl2De0Bq6EMp8mZBxMstMYNpxI65m82wAH0eZLGYwtY=";
  };

  sourceDirs = [ "src" ];
  javaRelease = "8";

  meta = {
    description = "JSR-330 dependency injection annotations";
    homepage = "https://github.com/javax-inject/javax-inject";
    license = lib.licenses.asl20;
    maintainers = with lib.maintainers; [ osbm ];
  };
}
