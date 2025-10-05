# Solo App #3 - Lovin

The following is a basic flutter app that renders a Pokemon from PokeAPI (any pokemon from gen 1). To run it, simply go to the 
command line, and type

```flutter pub get```
followed by
```flutter run```

IMPORTANT: This is best run in Google Chrome, though it does work on the IOS simulator as well. This has more to do with PokeAPI liking chrome.

As a user, you should be able to enter in a dex number for a Pokemon (1-151), and it will display their sprite, name, and dex number on the next page. Additional searches may be conducted, as desired. One edge case the app handles is using dex numbers over 151, since there are . . . well a LOT more Pokemon than the original 151. Due to this, it's important that the user can't enter in numbers higher than 151, since the API only supports gen 1 Pokemon.
