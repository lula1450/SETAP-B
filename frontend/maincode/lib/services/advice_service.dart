// This service provides advice for pet owners based on their pet's breed and recent health metrics.

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

  // Metric-specific advice: key is 'MetricName|high_or_low|BreedOrSpecies'
  // Falls back from breed → species → generic metric fallback
  static const Map<String, String> _metricAdvice = {
    // Weight - high
    "Weight|high|Dog - Labrador":        "Labradors are prone to weight gain. Measure portions carefully and add an extra daily walk.",
    "Weight|high|Dog - Golden Retriever":"Golden Retrievers can easily gain weight. Reduce treats and increase activity.",
    "Weight|high|Dog":                   "Your dog is above their target weight. Reduce treats and increase daily exercise.",
    "Weight|high|Cat":                   "Your cat is above their target weight. Switch to measured meals and encourage active play.",
    "Weight|high|Rabbit":                "Your rabbit may be overweight. Limit pellets and increase fresh leafy greens and exercise time.",
    "Weight|high|Hamster":               "Your hamster is above target weight. Reduce seed-heavy mixes and offer more fresh veg.",
    "Weight|high|Bird":                  "Your bird is above target weight. Reduce fatty seeds and offer more fresh fruit and veg.",
    "Weight|high|Snake":                 "Your snake is above target weight. Adjust feeding frequency and prey size.",
    // Weight - low
    "Weight|low|Dog - Labrador":         "Your Labrador is underweight. Check appetite and increase meal portions gradually.",
    "Weight|low|Dog":                    "Your dog is below their target weight. Increase meal portions and consult your vet if appetite is low.",
    "Weight|low|Cat":                    "Your cat is underweight. Offer more frequent small meals and consult your vet if appetite remains low.",
    "Weight|low|Rabbit":                 "Your rabbit may be underweight. Ensure unlimited hay access and check for dental issues.",
    "Weight|low|Hamster":                "Your hamster is underweight. Check they are eating regularly and offer protein-rich foods.",
    "Weight|low|Bird":                   "Your bird is underweight. Offer a varied diet with calorie-rich foods and monitor intake.",
    "Weight|low|Snake":                  "Your snake may be underweight. Review feeding schedule and consider increasing prey size.",
    // Heart Rate - high
    "Heart Rate|high|Dog":               "Your dog's heart rate is elevated. Ensure they have rest after exercise and watch for signs of stress.",
    "Heart Rate|high|Cat":               "An elevated heart rate in cats can indicate stress or illness. Keep the environment calm and contact your vet if it persists.",
    "Heart Rate|high|Rabbit":            "A high heart rate in rabbits often signals stress. Ensure a quiet, calm environment.",
    "Heart Rate|high|Bird":              "An elevated heart rate in birds can indicate illness. Keep your bird calm and consult your vet.",
    // Heart Rate - low
    "Heart Rate|low|Dog":                "Your dog's heart rate is lower than expected. Monitor for lethargy and consult your vet.",
    "Heart Rate|low|Cat":                "A low heart rate in cats may need veterinary attention. Contact your vet.",
    "Heart Rate|low|Rabbit":             "Your rabbit's heart rate is lower than expected. Keep them warm and contact your vet promptly.",
    // Temperature - high
    "Temperature|high|Dog":              "Your dog's temperature is elevated. Ensure plenty of water and a cool resting space. Contact your vet if it persists.",
    "Temperature|high|Cat":              "Your cat's temperature is higher than normal. Watch for signs of fever and consult your vet.",
    "Temperature|high|Rabbit":           "A high temperature in rabbits is serious. Move them to a cool area and contact your vet promptly.",
    "Temperature|high|Hamster":          "Your hamster may be too warm. Ensure their enclosure is out of direct sunlight with good ventilation.",
    "Temperature|high|Bird":             "Your bird may be overheating. Ensure shade and fresh water are available.",
    "Temperature|high|Snake":            "Check your snake's enclosure — overheating is dangerous for reptiles. Adjust the heat source.",
    // Temperature - low
    "Temperature|low|Dog":               "Your dog's temperature is below normal. Keep them warm and contact your vet if they seem unwell.",
    "Temperature|low|Cat":               "A low temperature in cats can be serious. Keep your cat warm and seek veterinary advice.",
    "Temperature|low|Rabbit":            "Rabbits can suffer from hypothermia. Ensure a warm, draught-free environment.",
    "Temperature|low|Hamster":           "A cold hamster may be entering torpor. Warm them gradually and check their food supply.",
    "Temperature|low|Snake":             "Your snake's temperature is too low. Check the heating in their enclosure immediately.",
    "Temperature|low|Bird":              "Your bird may be cold. Move them to a warmer spot away from draughts.",
    // Activity Level - low
    "Activity Level|low|Dog - Labrador": "Labradors need daily exercise. Try a longer walk or introduce a new game to boost activity.",
    "Activity Level|low|Dog":            "Your dog's activity level is lower than usual. Try a new route or a play session to encourage movement.",
    "Activity Level|low|Cat":            "Encourage your cat to be more active with interactive toys or a laser pointer.",
    "Activity Level|low|Rabbit":         "Rabbits need regular out-of-enclosure exercise. Provide a safe space for running and exploration.",
    "Activity Level|low|Bird":           "Encourage your bird to be active with foraging toys and supervised out-of-cage time.",
    "Activity Level|low|Hamster":        "Ensure your hamster's wheel is working and their environment offers enough enrichment.",
    // Activity Level - high
    "Activity Level|high":               "High activity is generally positive — just ensure your pet has enough rest and hydration.",
    // Food Intake - high
    "Food Intake|high|Dog":              "Your dog is eating more than usual. Monitor for weight gain and check portion sizes.",
    "Food Intake|high|Cat":              "Your cat is overeating. Switch to timed meals and avoid free-feeding.",
    "Food Intake|high|Rabbit":           "Too many pellets can cause obesity in rabbits. Ensure hay makes up the majority of their diet.",
    // Food Intake - low
    "Food Intake|low|Dog":               "Your dog's appetite is reduced. Check the food is fresh and consult your vet if this continues.",
    "Food Intake|low|Cat":               "A cat not eating well can indicate illness. Try warming their food slightly or consult your vet.",
    "Food Intake|low|Rabbit":            "A rabbit not eating could have gut stasis — this is urgent. Contact your vet immediately.",
    "Food Intake|low|Bird":              "Your bird's food intake is low. Offer varied fresh foods and consult your vet if it continues.",
    "Food Intake|low|Snake":             "Snakes can refuse food for various reasons. Monitor closely and consult your vet if refusal continues.",
    "Food Intake|low|Hamster":           "Check your hamster isn't hoarding food instead of eating it. Ensure fresh food is provided daily.",
    // Water Intake - high
    "Water Intake|high":                 "Increased thirst can indicate diabetes or kidney issues. Consult your vet if this persists.",
    // Water Intake - low
    "Water Intake|low|Dog":              "Your dog isn't drinking enough. Try adding water to their food or using a pet water fountain.",
    "Water Intake|low|Cat":              "Cats often under-drink. Try a cat water fountain or add wet food to increase hydration.",
    "Water Intake|low|Rabbit":           "Ensure your rabbit always has fresh water. Low intake can quickly cause serious health issues.",
    "Water Intake|low|Bird":             "Ensure fresh water is always available for your bird and change it daily.",
    "Water Intake|low|Hamster":          "Check your hamster's water bottle is not blocked and is delivering water correctly.",
    "Water Intake|low|Snake":            "Ensure your snake always has access to clean, fresh water.",
  };

  static const Map<String, String> _metricGeneralAdvice = {
    'Weight|Dog - Labrador': 'Weight is on track! Labradors can gain weight easily — keep up the regular monitoring.',
    'Weight|Dog':            'Weight is on track! Consistent monitoring helps catch changes before they become a problem.',
    'Weight|Cat':            'Weight is on track! Regular weighing helps detect health changes in cats early.',
    'Weight|Rabbit':         'Weight looks good! Regular checks help catch digestive or dental issues early in rabbits.',
    'Weight|Hamster':        'Weight is on track! Regular monitoring helps spot health issues early in small pets.',
    'Weight|Bird':           'Weight is on track! Birds can hide illness well, so regular weighing is very valuable.',
    'Weight|Snake':          'Weight is on track! Regular weighing helps confirm your snake is feeding well.',
    'Weight':                'Weight is within target — great job monitoring this regularly!',
    'Heart Rate|Dog':        'Heart rate is normal! Keep tracking it alongside rest and exercise for a clear picture of health.',
    'Heart Rate|Cat':        'Heart rate looks good! Cats can show elevated rates from stress, so calm checks give the most accurate reading.',
    'Heart Rate|Rabbit':     'Heart rate is normal! Rabbits naturally have fast heart rates, so regular baselines are very helpful.',
    'Heart Rate':            'Heart rate is within normal range — well done keeping track of this.',
    'Temperature|Dog':       'Temperature is normal! Monitoring this is a great early indicator of illness.',
    'Temperature|Cat':       'Temperature looks good! Regular checks help catch illness before other symptoms appear.',
    'Temperature|Rabbit':    'Temperature is normal! Rabbits are sensitive to temperature changes, so this is a great habit.',
    'Temperature|Snake':     'Temperature is normal! Maintaining the right range in the enclosure is vital for reptiles.',
    'Temperature':           'Temperature is within range — good work keeping an eye on this.',
    'Activity Level|Dog - Labrador': 'Activity level is on target! Labradors thrive with consistent daily exercise.',
    'Activity Level|Dog':    'Activity level looks good! Regular exercise keeps dogs healthy and mentally stimulated.',
    'Activity Level|Cat':    'Activity level is on track! Regular play keeps cats physically and mentally sharp.',
    'Activity Level|Rabbit': 'Activity level is good! Daily out-of-enclosure time is important for rabbit wellbeing.',
    'Activity Level':        'Activity level is within target — great habit to track this regularly.',
    'Food Intake|Dog':       'Food intake is on track! Consistent portions help maintain a healthy weight.',
    'Food Intake|Cat':       'Food intake looks good! Measured meals help prevent obesity in cats.',
    'Food Intake|Rabbit':    'Food intake is on target! Ensure hay makes up the majority of the diet.',
    'Food Intake':           'Food intake is within target — well done monitoring this consistently.',
    'Water Intake|Dog':      'Water intake is good! Staying well hydrated supports kidney health in dogs.',
    'Water Intake|Cat':      'Water intake is on track! Good hydration is especially important for cats prone to kidney issues.',
    'Water Intake|Rabbit':   'Water intake is normal! Rabbits need constant access to fresh water for good gut health.',
    'Water Intake':          'Water intake is within target — great work keeping hydration in check.',
  };

  /// Returns contextual advice based on the latest logged metric value relative to the target.
  /// If the value deviates more than 15% from the target, returns metric-specific advice.
  /// Otherwise returns a positive reinforcement message or falls back to daily breed advice.
  String getAdviceForLastMetric(int breedId, String metricName, String value, String target) {
    final current = double.tryParse(value);
    final targetVal = double.tryParse(target);

    if (current != null && targetVal != null && targetVal != 0) {
      final deviation = (current - targetVal).abs() / targetVal;
      if (deviation > 0.15) {
        return getMetricBasedAdvice(breedId, metricName, current > targetVal);
      }
    }

    final breedName = _breedMap[breedId] ?? '';
    final species = breedName.contains(' - ') ? breedName.split(' - ').first : breedName;
    return _metricGeneralAdvice['$metricName|$breedName']
        ?? _metricGeneralAdvice['$metricName|$species']
        ?? _metricGeneralAdvice[metricName]
        ?? getDailyAdvice(breedId);
  }

  /// Returns breed/species-specific advice for a metric that is above or below target.
  /// Resolves from most specific (breed) to least specific (generic metric fallback).
  String getMetricBasedAdvice(int breedId, String metricName, bool isHigh) {
    final breedName = _breedMap[breedId] ?? '';
    final species = breedName.contains(' - ') ? breedName.split(' - ').first : breedName;
    final dir = isHigh ? 'high' : 'low';

    return _metricAdvice['$metricName|$dir|$breedName']
        ?? _metricAdvice['$metricName|$dir|$species']
        ?? _metricAdvice['$metricName|$dir']
        ?? (isHigh
            ? '$metricName is above target. Consider speaking to your vet.'
            : '$metricName is below target. Consider speaking to your vet.');
  }

  /// Returns one piece of breed-specific daily care advice.
  /// The same advice is returned for the entire day (date-seeded random selection).
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