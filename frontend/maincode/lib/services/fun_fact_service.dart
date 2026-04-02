import 'dart:math';

class FunFactService {

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

  //Facts grouped by breed
  final Map<String, List<String>> _factsByBreed = {
    "Dog - Labrador": [
      "Labradors love water and are excellent swimmers!",
      "Labradors have a friendly, outgoing personality!"
    ],
    "Dog - Golden Retriever": [
      "Golden Retrievers are known for their loyalty and gentle temperament!",
      "Golden Retrievers excel in obedience training!"
    ],
    "Cat - Maine Coon": [
      "Maine Coons are one of the largest domesticated cats!",
      "They have a distinctive tufted ear appearance!"
    ],
    "Cat - Siamese": [
      "Siamese cats are highly vocal and social!",
      "They have striking blue almond-shaped eyes!"
    ],
    "Rabbit - Holland Lop": [
      "Holland Lops are small but very energetic!",
      "They enjoy chewing and digging!"
    ],
    "Rabbit - Rex": [
      "Rex rabbits have plush, velvety fur!",
      "They are very gentle and friendly!"
    ],
    "Hamster - Syrian": [
      "Syrian hamsters are solitary and need their own cage!",
      "They can run several miles on their wheel each night!"
    ],
    "Hamster - Roborovski": [
      "Roborovski hamsters are tiny and very fast!",
      "They are extremely active and curious!"
    ],
    "Bird - African Grey": [
      "African Grey parrots are excellent mimics of human speech!",
      "They are highly intelligent and social!"
    ],
    "Bird - Cockatiel": [
      "Cockatiels love to whistle and mimic sounds!",
      "They are affectionate and playful companions!"
    ],
    "Snake - Corn Snake": [
      "Corn snakes are excellent climbers and explorers!",
      "They are one of the most popular beginner snakes!"
    ],
    "Snake - Ball Python": [
      "Ball Pythons curl into a ball when scared!",
      "They are gentle and easy to handle!"
    ],
  };


  String getDailyFact(int breedId) {
    final breedName = _breedMap[breedId] ?? "Unknown Animal";
    final facts = _factsByBreed[breedName];

    if (facts == null || facts.isEmpty) {
      return "Animals are amazing companions!";
    }

  // Seed ensures SAME fact for the whole day
    final today = DateTime.now();
    final seed = today.year + today.month + today.day + breedId;
    final random = Random(seed);

    return facts[random.nextInt(facts.length)];
  }
}