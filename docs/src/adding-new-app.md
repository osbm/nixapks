
# Adding new applications to NixApks

To create a new application to nixapks, you just need to create a derivation that outputs an apk file.

## Gradle-based Android apps

Gradle based Android apps use the Java/Kotlin programming languages and the Gradle build system. They cant be fetched inside the nix sandbox directly, so we need to prepare the dependencies first.


### Gradle-dot-nix way

Repository: https://github.com/CrazyChaoz/gradle-dot-nix

This method is simple and straightforward.

run the following command in the root directory of the Android project:

```bash
gradle -M sha256 build
```

This will generate a `gradle/verification-metadata.nix` file that contains all the necessary information to build the app with Nix.

Then, you can create a new Nix expression for the app in the `apps` directory of NixApks, and import the generated `verification-metadata.nix` file.

### gradle2nix way

Repository: https://github.com/tadfisher/gradle2nix

TODO: Write this section.

## React Native apps

Not yet supported.

## Flutter apps

Not yet supported.
