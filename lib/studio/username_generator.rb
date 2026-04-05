module Studio
  class UsernameGenerator
    def self.generate
      2.times do
        candidate = build_name
        return candidate unless User.exists?(username: candidate)
      end
      "#{build_name}-#{rand(1000..9999)}"
    end

    def self.build_name
      plant = Faker::Food.send(%i[vegetables fruits].sample)
      animal = Faker::Creature::Animal.name
      "#{sanitize(plant)}-#{sanitize(animal)}"
    end

    def self.sanitize(str)
      str.downcase.gsub(/[^a-z0-9]/, "-").gsub(/-+/, "-").gsub(/^-|-$/, "")
    end
  end
end
