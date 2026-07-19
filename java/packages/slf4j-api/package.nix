{
  lib,
  buildMavenJar,
  fetchFromGitHub,
}:
buildMavenJar {
  pname = "slf4j-api";
  groupId = "org.slf4j";
  version = "2.0.7";

  src = fetchFromGitHub {
    owner = "qos-ch";
    repo = "slf4j";
    rev = "v_2.0.7";
    hash = "sha256-WFO8R3ARAVnX5En8jAY0UxYcRh08QCYGZD5ZlXbsYgs=";
  };

  sourceDirs = [ "slf4j-api/src/main/java" ];
  javaRelease = "8";

  meta = {
    description = "Simple Logging Facade for Java API";
    homepage = "https://www.slf4j.org";
    license = lib.licenses.mit;
    maintainers = with lib.maintainers; [ osbm ];
  };
}
