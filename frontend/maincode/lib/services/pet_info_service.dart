// Provides static breed info (traits, care tips, diet, health, environment) for each species.
class PetInfoService {
  static const String _base = "http://localhost:8000/static/pet_info_images";

  static final Map<int, Map<String, dynamic>> _petData = {
      1: {
        "name": "Labrador",
        "image": "$_base/labrador.jpg",
        "traits": "Friendly • Active • Outgoing",
        "helpUrl": "https://www.rspca.org.uk/adviceandwelfare/pets/dogs",
        "breedInfo": ["• Large", "• 10–12 years", "• High energy", "• Easy to train"],
        "careTips": ["• Daily exercise", "• Loves water", "• Regular brushing", "• Needs attention"],
        "personality": ["• Friendly", "• Loyal", "• Good with families", "• Playful"],
        "diet": ["• High-Quality protein", "• Omega-3 for healthy Coat","• Balanced diet", "• Avoid overfeeding"],
        "health": ["• Prone to hip dysplasia", "• Obesity risk", "• Ear Infections", "• Regular Vet Checkups"],
        "environment": ["• Needs large spaces", "• Loves outdoor activity", "• Great for families", "• Not ideal for small apartments"],
      },

      2: {
        "name": "Golden Retriever",
        "image": "$_base/golden_retriever.jpg",
        "traits": "Friendly • Intelligent • Loyal",
        "helpUrl": "https://www.golden-retriever-owners.co.uk/info-guides/general-care-and-welfare-advice",
        "breedInfo": ["• Large", "• 10–12 years", "• High energy", "• Excellent training"],
        "careTips": ["• Daily exercise", "• Brush 2–3x weekly", "• Needs attention", "• Regular Vet Checkups"],
        "personality": ["• Gentle", "• Social", "• Playful", "• Intelligent"],
        "diet": ["• High protein", "• Joint support nutrients", "• Healthy fats for Coat", "• Portion Control"],
        "health":["• Hip & Elbow dypsplasia", "• Heart Issues", "• Sensitive Skin", "• Needs regular vet care"],
        "environment":["• Needs space to roam", "• Family-friendly home", "• Not suited for isolation", "• Enjoys outdoor environments"],
      },

      3: {
        "name": "Maine Coon",
        "image": "$_base/maine_coon.jpg",
        "traits": "Gentle • Large • Friendly",
        "helpUrl": "https://www.rspca.org.uk/adviceandwelfare/pets/cats",
        "breedInfo": ["• Large cat", "• 12–15 years", "• Medium energy", "• Thick Coat"],
        "careTips": ["• Regular grooming", "• Needs space", "• Interactive play", "• Regular Vet Checkups"], 
        "personality": ["• Friendly", "• Intelligent", "• Playful", "• Gentle"],
        "diet": ["• Protein-rich food", "• Wet & Dry Mixed Meals", "• Fresh Water", "• Portion Control"],
        "health":["• Risk of Heart Disease(HCM)", "• Hip dysplasia", "• Risk of Obesity if inactive", "• Regular grooming needed"],
        "environment":["• Needs space to move", "• Indoor preferred", "• Good for families", "• Tolerates cold climates well"],
      }, 

      4: {
        "name": "Siamese",
        "image": "$_base/siamese.jpg",
        "traits": "Vocal • Social • Intelligent",
        "helpUrl": "https://www.rspca.org.uk/adviceandwelfare/pets/cats",
        "breedInfo": ["• Medium size", "• 12–20 years", "• Slim Build", "• Short Coat"],
        "careTips": ["• Needs attention", "• Indoor living", "• Interactive Toys", "• Warm environment"],
        "personality": ["• Talkative", "• Affectionate", "• Social", "• Intelligent"],
        "diet": ["• High-quality cat food", "• Protein Rich Meals", "• Fresh Water", "• Portion Control"],
        "health":["• Dental Issues", "• Respiratory problems", "• Sensitive to stress", "• Needs regular vet care"],
        "environment":["• Indoor living preferred", "• Needs attention & interaction", "• Not good when left alone", "• Warm environment ideal"],
      },

      5: {
        "name": "Holland Lop",
        "image": "$_base/holland_lop.jpg",
        "traits": "Small • Friendly • Calm",
        "helpUrl": "https://www.rspca.org.uk/adviceandwelfare/pets/rabbits",
        "breedInfo": ["• Small", "• 7–10 years", "• Compact Body", "• Indoor Friendly"],
        "careTips": ["• Hay-based diet", "• Clean enclosure", "• Daily exercise", "• Social interactions"],
        "personality": ["• Calm", "• Friendly", "• Gentle", "• Social"],
        "diet": ["• Hay", "• Fresh Veggies", "• Pellets", "• Fresh Water"],
        "health":["• Dental problems", "• Ear infections", "• Digestive sensitivity", "• Needs regular Checkups"],
        "environment":["• Indoor environment preffered", "• Needs safe enclosure", "• Quiet household", "• Space for hopping/exercise"],
      },

      6: {
        "name": "Rex Rabbit",
        "image": "$_base/rex_rabbit.jpg",
        "traits": "Soft coat • Gentle • Quiet",
        "helpUrl": "https://www.rspca.org.uk/adviceandwelfare/pets/rabbits",
        "breedInfo": ["• Medium", "• 6–8 years", "• Soft Fur", "• Indoor Pet"],
        "careTips": ["• Gentle handling", "• Warm shelter", "• Clean Enclosure", "• Daily exercise"],
        "personality": ["• Calm", "• Quiet", "• Friendly", "• Gentle"],
        "diet": ["• Hay", "• Pellets", "• Fresh Vegetables", "• Fresh Water"],
        "health":["• Sensitive skin", "• Digestive issues", "• Dental care required", "• Needs regular monitoring"],
        "environment": ["• Indoor living recommended", "• Soft bedding required", "• Dental care required", "• Needs regular monitoring"],
      },

      7: {
        "name": "Syrian Hamster",
        "image": "$_base/syrian_hamster.jpg",
        "traits": "Small • Nocturnal • Independent",
        "helpUrl": "https://www.rspca.org.uk/adviceandwelfare/pets/rodents",
        "breedInfo": ["• Small", "• 2–3 years", "• Solitary", "• Nocturnal"],
        "careTips": ["• Exercise wheel", "• Clean cage", "• Fresh Bedding", "• Hideouts for rest"],
        "personality": ["• Solitary", "• Active at night", "• Curious", "• Territorial"],
        "diet": ["• Seeds", "• Fresh Vegetables", "• Protein rich snacks", "• Fresh Water"],
        "health":["• Prone to obesity", "• Dental overgrowth", "• Short lifespan health decline", "• Needs clean habitat"],
        "environment":["• Solitary living only", "• Quiet environment", "• Nocturnal-friendly space", "• Secure enclosure needed"],
      },

      8: {
        "name": "Roborovski Hamster",
        "image": "$_base/roborovski_hamster.jpg",
        "traits": "Tiny • Fast • Energetic",
        "helpUrl": "https://www.rspca.org.uk/adviceandwelfare/pets/rodents",
        "breedInfo": ["• Very small", "• 3–3.5 years", "• Fast-moving", "• Desert species"],
        "careTips": ["• Large enclosure", "• Minimal handling", "• Exercise wheel", "• Clean habitat"],
        "personality": ["• Fast", "• Shy", "• Energetic", "• Curious"],
        "diet": ["• Seeds", "• Insects", "• Fresh Vegetables", "• Fresh Water"],
        "health":["• Fragile body", "• Stress-sensitive", "• Prone to dehydration", "• Needs a clean habitat"],
        "environment":["• Large enclosure needed", "• Minimal handling", "• Quiet space", "• Warm, dry environment"],
      },

      9: {
        "name": "African Grey",
        "image": "$_base/african_grey.jpg",
        "traits": "Intelligent • Talkative • Sensitive",
        "helpUrl": "https://www.rspca.org.uk/adviceandwelfare/pets/birds",
        "breedInfo": ["• Medium bird", "• 40–60 + years", "• Highly Intelligent", "• Strong Beak"],
        "careTips": ["• Mental stimulation", "• Social interaction", "• Large Cage", "• Regular Cleaning"],
        "personality": ["• Smart", "• Emotional", "• Social", "• Sensitive"],
        "diet": ["• Fruits", "• Seeds", "• Pellets", "• Fresh Water"],
        "health":["• Feather plucking", "• Calcium deficiency", "• Respiratory issues", "• Needs mental stimulation"],
        "environment":["• Large cage required", "• Social interaction needed", "• Quiet but engaging home", "• Needs daily out-of-cage time"],
      },

      10: {
        "name": "Cockatiel",
        "image": "$_base/cockatiel.jpg",
        "traits": "Friendly • Vocal • Social",
        "helpUrl": "https://www.rspca.org.uk/adviceandwelfare/pets/birds",
        "breedInfo": ["• Small bird", "• 15–20 years", "• Easy to tame", "• Crest features"],
        "careTips": ["• Social time", "• Clean cage", "• Toys for stimulation", "• Regular feeding"],
        "personality": ["• Friendly", "• Curious", "• Social", "• Playful"],
        "diet": ["• Seeds", "• Pellets", "• Fresh Vegetables", "• Fresh Water"],
        "health":["• Respiratory infections", "• Vitamin deficiencies", "• Feather issue", "• Regular vet care needed"],
        "environment":["• Social environment", "• Medium cage space", "• Needs interaction", "• Avoid cold drafts"],
      },

      11: {
        "name": "Corn Snake",
        "image": "$_base/corn_snake.jpg",
        "traits": "Docile • Easy care • Quiet",
        "helpUrl": "https://www.rspca.org.uk/adviceandwelfare/pets/reptiles",
        "breedInfo": ["• Medium snake", "• 15–20 years", "• Easy to handle", "• Non-venomous"],
        "careTips": ["• Heat lamp", "• Secure enclosure", "• Regular cleaning", "• Proper humidity"],
        "personality": ["• Calm", "• Easy to handle", "• Docile", "• Low maintenance"],
        "diet": ["• Frozen mice", "• Regulated Portions", "• Clean Water", "• Feeding schedule"],
        "health":["• Shedding issues", "• Respiratory infections", "• Parasites", "• Needs proper humidity"],
        "environment":["• Secure enclosure", "• Warm temperature gradient", "• Low noise environment", "• Proper humidity levels"],
      },

      12: {
        "name": "Ball Python",
        "image": "$_base/ball_python.jpg",
        "traits": "Shy • Calm • Nocturnal",
        "helpUrl": "https://www.rspca.org.uk/adviceandwelfare/pets/reptiles",
        "breedInfo": ["• Medium snake", "• 20–30 years", "• Thick Body", "• Nocturnal"],
        "careTips": ["• Warm enclosure", "• Humidity control", "• Hide Spots", "• Regular cleaning"],
        "personality": ["• Shy", "• Docile", "• Calm", "• Slow-moving"],
        "diet": ["• Rodents", "• Feeding schedule", "• Regulated Portions", "• Clean Water"],
        "health":["• Respiratory infections", "• Shedding problems", "• Refusal to eat", "• Needs humidity control"],
        "environment":["• Warm, humid enclosure", "• Hiding spots required", "• Low-stress environment", "• Stable temperature needed"],
      },
  };

  /// Returns static breed info (traits, care tips, diet, health, environment) for the given species ID.
  /// Returns a default empty-values map if the species ID is not recognised.
  Map<String, dynamic> getPetInfo(int speciesId) {
    return _petData[speciesId] ??
        {
          "name": "Unknown Pet",
          "image": "",
          "traits": "",
          "helpUrl": "",
          "breedInfo": [],
          "careTips": [],
          "personality": [],
          "diet": [],
          "health":[],
          "environment":[]
        };
  }
}