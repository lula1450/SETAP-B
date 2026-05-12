// Provides static breed info (traits, care tips, diet, health, environment) for each species.
class PetInfoService {
  static final Map<int, Map<String, dynamic>> _petData = {
      1: {
        "name": "Labrador",
        "image": "https://images.unsplash.com/photo-1518717758536-85ae29035b6d?w=800&auto=format&fit=crop",
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
        "image": "https://images.unsplash.com/photo-1552053831-71594a27632d?w=800&auto=format&fit=crop",
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
        "image": "https://images.unsplash.com/photo-1518791841217-8f162f1e1131?w=800&auto=format&fit=crop",
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
        "image": "https://images.unsplash.com/photo-1543852786-1cf6624b9987?w=800&auto=format&fit=crop",
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
        "image": "https://images.unsplash.com/photo-1585110396000-c9ffd4e4b308?w=800&auto=format&fit=crop",
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
        "image": "https://upload.wikimedia.org/wikipedia/commons/1/12/Rex_Rabbit_1.jpg",
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
        "image": "https://images.unsplash.com/photo-1548767797-d8c844163c4c?w=800&auto=format&fit=crop",
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
        "image": "https://images.unsplash.com/photo-1592194996308-7b43878e84a6?w=800&auto=format&fit=crop",
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
        "image": "https://images.unsplash.com/photo-1751905206462-101e79c265c0?w=800&auto=format&fit=crop",
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
        "image": "https://images.unsplash.com/photo-1591195853828-11db59a44f6b?w=800&auto=format&fit=crop",
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
        "image": "https://images.unsplash.com/photo-1583511655826-05700442b31b?w=800&auto=format&fit=crop",
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
        "image": "https://images.unsplash.com/photo-1742748757633-5bbd80f61746?w=800&auto=format&fit=crop",
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