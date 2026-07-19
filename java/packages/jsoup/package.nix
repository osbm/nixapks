{
  lib,
  buildMavenJar,
  fetchFromGitHub,
  jspecify,
}:
buildMavenJar {
  pname = "jsoup";
  groupId = "org.jsoup";
  version = "1.21.2";

  src = fetchFromGitHub {
    owner = "jhy";
    repo = "jsoup";
    rev = "jsoup-1.21.2";
    hash = "sha256-A0vmhLMVqx9KCltyO0AV2b0X7V9XBaTNkUhskE7ev3U=";
  };

  excludeSources = [
    "module-info.java"
    # not part of the released artifact
    "org/jsoup/examples"
  ];
  # compile-time only (provided scope upstream)
  deps = [ jspecify ];
  javaRelease = "8";

  meta = {
    description = "Java HTML parser, with DOM, CSS, and jquery-like methods";
    homepage = "https://jsoup.org";
    license = lib.licenses.mit;
    maintainers = with lib.maintainers; [ osbm ];
  };
}
