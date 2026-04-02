import 'dart:math';

class AdviceService {
  // Map breed ID to breed name (same logic as FunFactService)
  final Map<int, String> _breedMap = {
    1: "Dog - Labrador",
    2: "Dog - Golden Retriever",
    3: "Cat - Maine Coon",
    4: "Cat - Siamese",
    5: "Rabbit - Holland Lop",
    6: "Rabbit - Rex",
    7: "Hamster - Syrian",
    8: "Hamster - Roborovski",
    9: "Bird - African Grey",
    10: "Bird - Cockatiel",
    11: "Snake - Corn Snake",
    12: "Snake - Ball Python",
  };

  // Advice grouped by breed
  final Map<String, List<String>> _adviceByBreed = {
    "Dog - Labrador": [
      "Take your Labrador for a 30 min walk today.",
      "Offer your Labrador a new toy to play with.",
      "Labradors love swimming—if safe, let them enjoy water play!"
    ],
    "Dog - Golden Retriever": [
      "Golden Retrievers benefit from daily training sessions.",
      "Give your Golden Retriever some affection and playtime.",
      "Check your Golden Retriever's diet and water supply."
    ],
    "Cat - Maine Coon": [
      "Play with your Maine Coon using interactive toys.",
      "Brush your Maine Coon's fur today to reduce shedding.",
      "Provide a cozy spot for your Maine Coon to nap."
    ],
    "Cat - Siamese": [
      "Siamese cats enjoy social interaction—spend some time together.",
      "Offer a climbing toy for your Siamese.",
      "Ensure your Siamese has fresh water and a comfortable space."
    ],
    "Rabbit - Holland Lop": [
      "Holland Lops enjoy digging—give them a safe digging area.",
      "Offer fresh veggies to your Holland Lop.",
      "Let your Holland Lop explore a safe play area."
    ],
    "Rabbit - Rex": [
      "Rex rabbits love gentle petting.",
      "Check your Rex's cage for cleanliness and safety.",
      "Provide chew toys for your Rex to prevent boredom."
    ],
    "Hamster - Syrian": [
      "Syrian hamsters need their own space—avoid cage mates.",
      "Ensure your hamster's wheel is clean and working.",
      "Offer fresh water and healthy snacks for your hamster."
    ],
    "Hamster - Roborovski": [
      "Roborovski hamsters are very active—provide climbing opportunities.",
      "Check your Roborovski's bedding regularly.",
      "Provide hiding spots for your Roborovski hamster."
    ],
    "Bird - African Grey": [
      "Talk and interact with your African Grey parrot today.",
      "Provide toys to stimulate your African Grey's intelligence.",
      "Ensure your African Grey has a safe environment to explore."
    ],
    "Bird - Cockatiel": [
      "Whistle and play with your Cockatiel to encourage interaction.",
      "Offer fresh water and a balanced diet to your Cockatiel.",
      "Let your Cockatiel have some supervised out-of-cage time."
    ],
    "Snake - Corn Snake": [
      "Check the temperature and humidity in your Corn Snake's habitat.",
      "Provide hiding spots and climbing areas for your Corn Snake.",
      "Offer fresh water and ensure your Corn Snake's enclosure is secure."
    ],
    "Snake - Ball Python": [
      "Ensure your Ball Python's enclosure has proper warmth.",
      "Check for any shedding issues in your Ball Python.",
      "Give your Ball Python a calm, safe space for the day."
    ],
  };

  String getDailyAdvice(int breedId) {
    final breedName = _breedMap[breedId] ?? "Unknown Animal";
    final advices = _adviceByBreed[breedName];

    if (advices == null || advices.isEmpty) {
      return "Remember to care for your pet today!";
    }

    // Seed ensures SAME advice for the day for this pet
    final today = DateTime.now();
    final seed = today.year + today.month + today.day + breedId;
    final random = Random(seed);

    return advices[random.nextInt(advices.length)];
  }
}