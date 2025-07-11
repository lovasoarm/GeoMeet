class Splash {
  String description;
  Splash({required this.description});
}

class SplashModel {
  List<Splash> descriptions = [
    Splash(
        description:
            "Bienvenue sur GeoMeet ! Préparez-vous à une expérience de suivi fluide et sécurisée."),
    Splash(
        description:
            "Votre sécurité, notre priorité. Nous préparons votre espace personnel pour un suivi précis et sécurisé."),
    Splash(
        description:
            "Localisez, suivez et restez connecté en toute simplicité. Nous lançons l'application pour vous offrir la meilleure expérience !"),
  ];
  List<Splash> getDescriptions() {
    return descriptions;
  }
}
