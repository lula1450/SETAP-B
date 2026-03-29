class PetInfoService {
  Map<String, dynamic> getPetInfo(int speciesId) {
    final Map<int, Map<String, dynamic>> petData = {
      1: {
        "name": "Labrador",
        "image": "https://images.unsplash.com/photo-1518717758536-85ae29035b6d",
        "traits": "Friendly • Active • Outgoing",
        "helpUrl": "https://www.rspca.org.uk/adviceandwelfare/pets/dogs",
        "breedInfo": ["• Large", "• 10–12 years", "• High energy", "• Easy to train"],
        "careTips": ["• Daily exercise", "• Loves water", "• Regular brushing"],
        "personality": ["• Friendly", "• Loyal", "• Good with families", "• Playful"],
        "diet": ["• High-Quality protein", "Omega-3 for healthy Coat","• Balanced diet", "• Avoid overfeeding"],
      },

      2: {
        "name": "Golden Retriever",
        "image": "https://images.unsplash.com/photo-1552053831-71594a27632d",
        "traits": "Friendly • Intelligent • Loyal",
        "helpUrl": "https://www.golden-retriever-owners.co.uk/info-guides/general-care-and-welfare-advice",
        "breedInfo": ["• Large", "• 10–12 years", "• High energy", "• Excellent training"],
        "careTips": ["• Daily exercise", "• Brush 2–3x weekly", "• Needs attention", "• Regular Vet Checkups"],
        "personality": ["• Gentle", "• Social", "• Playful", "• Intelligent"],
        "diet": ["• High protein", "• Joint support nutrients", "• Healthy fats for Coat", "• Portion Cotrol"],
      },

      3: {
        "name": "Maine Coon",
        "image": "https://images.unsplash.com/photo-1518791841217-8f162f1e1131",
        "traits": "Gentle • Large • Friendly",
        "helpUrl": "https://www.rspca.org.uk/adviceandwelfare/pets/cats",
        "breedInfo": ["• Large cat", "• 12–15 years", "• Medium energy", "• Thick Coat"],
        "careTips": ["• Regular grooming", "• Needs space", "• Interactive play", "• Regular Vet Checkups"], 
        "personality": ["• Friendly", "• Intelligent", "• Playful", "• Gentle"],
        "diet": ["• Protein-rich food", "• Wet & Dry Mixed Meals", "• Fresh Water", "• Portion Control"],
      }, 

      4: {
        "name": "Siamese",
        "image": "https://images.unsplash.com/photo-1543852786-1cf6624b9987",
        "traits": "Vocal • Social • Intelligent",
        "helpUrl": "https://www.rspca.org.uk/adviceandwelfare/pets/cats",
        "breedInfo": ["• Medium size", "• 12–20 years", "• Slim Build", "• Short Coat"],
        "careTips": ["• Needs attention", "• Indoor living", "• Interactive Toys", "• Warm environment"],
        "personality": ["• Talkative", "• Affectionate", "• Social", "• Intelligent"],
        "diet": ["• High-quality cat food", "• Protein Rich Meals", "• Fresh Water", "• Portion Control"],
      },

      5: {
        "name": "Holland Lop",
        "image": "https://images.unsplash.com/photo-1585110396000-c9ffd4e4b308",
        "traits": "Small • Friendly • Calm",
        "helpUrl": "https://www.rspca.org.uk/adviceandwelfare/pets/rabbits",
        "breedInfo": ["• Small", "• 7–10 years", "• Compact Body", "• Indoor Friendly"],
        "careTips": ["• Hay-based diet", "• Clean enclosure", "• Daily excercise", "• Social interactions"],
        "personality": ["• Calm", "• Friendly", "• Gentle", "• Social"],
        "diet": ["• Hay", "• Fresh Veggies", "• Pellets", "• Fresh Water"],
      },

      6: {
        "name": "Rex Rabbit",
        "image": "https://images.unsplash.com/photo-1592194996308-7b43878e84a6",
        "traits": "Soft coat • Gentle • Quiet",
        "helpUrl": "https://www.rspca.org.uk/adviceandwelfare/pets/rabbits",
        "breedInfo": ["• Medium", "• 6–8 years", "• Soft Fur", "• Indoor Pet"],
        "careTips": ["• Gentle handling", "• Warm shelter", "• Clean Enclosure", "• Daily exercise"],
        "personality": ["• Calm", "• Quiet", "• Friendly", "• Gentle"],
        "diet": ["• Hay", "• Pellets", "• Fresh Vegetables", "• Fresh Water"],
      },

      7: {
        "name": "Syrian Hamster",
        "image": "https://images.unsplash.com/photo-1548767797-d8c844163c4c",
        "traits": "Small • Nocturnal • Independent",
        "helpUrl": "https://www.rspca.org.uk/adviceandwelfare/pets/rodents",
        "breedInfo": ["• Small", "• 2–3 years", "• Solitary", "Nocturnal"],
        "careTips": ["• Exercise wheel", "• Clean cage", "• Fresh Bedding", "• Hideouts for rest"],
        "personality": ["• Solitary", "• Active at night", "• Curious", "• Territorial"],
        "diet": ["• Seeds", "• Fresh Vegetables", "• Protein rich snacks", "• Fresh Water"],
      },

      8: {
        "name": "Roborovski Hamster",
        "image": "https://images.unsplash.com/photo-1592194996308-7b43878e84a6",
        "traits": "Tiny • Fast • Energetic",
        "helpUrl": "https://www.rspca.org.uk/adviceandwelfare/pets/rodents",
        "breedInfo": ["• Very small", "• 3–3.5 years", "• Fast-moving", "• Desert species"],
        "careTips": ["• Large enclosure", "• Minimal handling", "• Excercise wheel", "• Clean habitat"],
        "personality": ["• Fast", "• Shy", "• Energetic", "• Curious"],
        "diet": ["• Seeds", "• Insects", "• Fresh Vegetables", "• Fresh Water"],
      },

      9: {
        "name": "African Grey",
        "image": "https://images.unsplash.com/photo-1552728089-57bdde30beb3",
        "traits": "Intelligent • Talkative • Sensitive",
        "helpUrl": "https://www.rspca.org.uk/adviceandwelfare/pets/birds",
        "breedInfo": ["• Medium bird", "• 40–60 + years", "• Highly Intelligent", "• Strong Beak"],
        "careTips": ["• Mental stimulation", "• Social interaction", "• Large Cage", "• Regular Cleaning"],
        "personality": ["• Smart", "• Emotional", "• Social", "• Sensitive"],
        "diet": ["• Fruits", "• Seeds", "• Pellets", "• Fresh Water"],
      },

      10: {
        "name": "Cockatiel",
        "image": "https://images.unsplash.com/photo-1591195853828-11db59a44f6b",
        "traits": "Friendly • Vocal • Social",
        "helpUrl": "https://www.rspca.org.uk/adviceandwelfare/pets/birds",
        "breedInfo": ["• Small bird", "• 15–20 years", "• Easy to tame", "• Crest features"],
        "careTips": ["• Social time", "• Clean cage", "• Toys for stimulation", "• Regular feeding"],
        "personality": ["• Friendly", "• Curious", "• Social", "• Playful"],
        "diet": ["• Seeds", "• Pellets", "• Fresh Vegetables", "• Fresh Water"],
      },

      11: {
        "name": "Corn Snake",
        "image": "https://images.unsplash.com/photo-1583511655826-05700442b31b",
        "traits": "Docile • Easy care • Quiet",
        "helpUrl": "https://www.rspca.org.uk/adviceandwelfare/pets/reptiles",
        "breedInfo": ["• Medium snake", "• 15–20 years", "• Easy to handle", "• Non-venomous"],
        "careTips": ["• Heat lamp", "• Secure enclosure", "• Regular cleaning", "• Proper humidity"],
        "personality": ["• Calm", "• Easy to handle", "• Docile", "• Low maintenance"],
        "diet": ["• Frozen mice", "• Regulated Portions", "• Clean Water", "• Feeding schedule"],
      },

      12: {
        "name": "Ball Python",
        "image": "https://images.unsplash.com/photo-1601758064226-1b7d2dcb1e53",
        "traits": "Shy • Calm • Nocturnal",
        "helpUrl": "https://www.rspca.org.uk/adviceandwelfare/pets/reptiles",
        "breedInfo": ["• Medium snake", "• 20–30 years", "• Thick Body", "• Nocturnal"],
        "careTips": ["• Warm enclosure", "• Humidity control", "• Hide Spots", "• Regualar cleaning"],
        "personality": ["• Shy", "• Docile", "• Calm", "• Slow-moving"],
        "diet": ["• Rodents", "• Feeding schedule", "• Regulated Portions", "• Clean Water"],
      },
    };

    return petData[speciesId] ??
        {
          "name": "Unknown Pet",
          "image": "",
          "traits": "",
          "helpUrl": "",
          "breedInfo": [],
          "careTips": [],
          "personality": [],
          "diet": [],
        };
  }
}