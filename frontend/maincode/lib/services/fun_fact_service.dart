import 'dart:math';

class FunFactService {
  final List<String>_facts = [
    "Dogs only sweat from the bottom of their feet!",
    "Cats have over one hundred vocal sounds, while dogs have around 10!",
    "Hamsters cheeck pouches extend all the way don to their hips!",
    "A birds feathers weigh more than its skeleton!",
    "As a fish gets bigger, so do its scales!",
    "Some lizards can actually detach their tails from their bodies when they feel threatned!",
    "26% of pet parents throw their pets birthday parties!",
    "Did you know, horses can sleep both standing up and lying down!",
    "Did you know Cows have best friends and can get stressed when they're separated from them",
    "Goats are natural climbers and can be found on top of hills, rocks and even TREES!",
    "Despite the common stereotype, pigs are incredibly clean animals!",
    "Parrots can live for over 50 years!",
    "Hamsters can run up to 5 miles a night on a wheel",
    "Rabbits can jump up to 3 feet high!",
  ];

  String getDailyFact() {
    final today =  DateTime.now();

    final seed = today.year + today.month + today.day;
    final random = Random(seed);
    return _facts[random.nextInt(_facts.length)];
  }
}