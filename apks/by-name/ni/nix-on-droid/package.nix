{
  flutterTools,
  fetchFromGithub,
}:

flutterTools.buildApk {

  src = fetchFromGithub {
    owner = "";
    repo = "";
    tag = "";
    hash = "";
  }

}
