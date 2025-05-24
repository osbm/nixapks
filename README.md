

I am using nix to build android applications to be sure that it is being built safely from the source code to the apk file.

# Why though? Why not just use google play or even f-droid?

I love nix and being able to build my packages and even my operating system in a pure and reproducible way is awesome. I want that for my android devices. But i find the state of development in the android worse than python 😭🙏.

Goals:

- Collect the list of open source famous android applications and games.
- Create a derivation that builds those applications (also tests them if possible)
- Use that derivation to generate the APK.
- Then collect these APKs in a cache that could be used to serve those applications inside a static website.
- Check my own packages for reproducibility.
    - Get the list of all our dependencies for builds of all apks
    - Check them for reproducibility
    - Check our all derivations for reproducibility
- No runtime dependencies (we are just producing a file)


Applications:
- lichess
- signal
- tailscale
- wikipedia
- f-droid
- mihon
- mastodon
- anki
- bluesky-social/social-app
- smoking-durtles

Successful nix apk builds:
- https://github.com/CrazyChaoz/Minimal-Android-UWB-App
- https://github.com/iyox-studios/iyox-Wormhole
- https://github.com/expenses/irohdroid
- https://github.com/nix-community/robotnix/tree/master/apks/chromium
- https://github.com/nix-community/robotnix/tree/463c3f66062a999cf339bc752501ae5906582df7/apks/fdroid
- https://github.com/SpiralP/mobile_nebula


Important tools:
- https://github.com/CrazyChaoz/gradle-dot-nix : This flake can generate the full maven repo required to build a gradle app from gradle/verification-metadata.xml, all in the sandbox, without code generation.
