{
  lib,
  buildMavenJar,
  fetchFromGitHub,
}:
buildMavenJar {
  pname = "jsr305";
  groupId = "com.google.code.findbugs";
  version = "3.0.2";

  # Mirror of the defunct Google Code svn repository
  src = fetchFromGitHub {
    owner = "amaembo";
    repo = "jsr-305";
    rev = "d7734b13c61492982784560ed5b4f4bd6cf9bb2c";
    hash = "sha256-QRjn1eKuJZ3CHLJT7DaNrbqvIBd45UZKNOxdM0IqYfI=";
  };

  sourceDirs = [ "ri/src/main/java" ];
  javaRelease = "8";

  meta = {
    description = "JSR-305 annotations for software defect detection";
    homepage = "https://github.com/amaembo/jsr-305";
    license = lib.licenses.bsd3;
    maintainers = with lib.maintainers; [ osbm ];
  };
}
