

# Derivation Metadata

A derivation's metadata gives information regarding the application and its target android environment.

An example of a proper metadata field for an android application is as follows:

```nix
meta = {
    description = "An open source flashcard app for spaced repetition learning";
    homepage = "https://mihon.app";
    license = lib.licenses.asl20;
    maintainers = with lib.maintainers; [ osbm ];
    android = {
        minSdk = 26;
        targetSdk = 36;
        applicationId = "app.mihon";
        abis = [
        "armeabi-v7a"
        "arm64-v8a"
        "x86"
        "x86_64"
        ];
    };
};
```

