import 'package:flutter/material.dart';

class CategoryStyle {
  final Color color;
  final IconData icon;
  const CategoryStyle({required this.color, required this.icon});
}

CategoryStyle getCategoryStyle(String name) {
  final lower = name.toLowerCase();

  if (lower.contains('φαγητό') || lower.contains('εστιατόριο') || lower.contains('food') || lower.contains('φαι'))
    return CategoryStyle(color: const Color.fromARGB(255, 205, 186, 155), icon: Icons.restaurant_outlined);

  if (lower.contains('σούπερ') || lower.contains('super') || lower.contains('αγορά') || lower.contains('ψώνια'))
    return CategoryStyle(color: const Color.fromARGB(255, 150, 188, 153), icon: Icons.shopping_cart_outlined);

  if (lower.contains('μεταφορ') || lower.contains('transport') || lower.contains('λεωφορ') || lower.contains('βενζίν'))
    return CategoryStyle(color: const Color.fromARGB(255, 160, 184, 201), icon: Icons.directions_bus_outlined);

  if (lower.contains('καφέ') || lower.contains('coffee') || lower.contains('cafe'))
    return CategoryStyle(color: const Color.fromARGB(255, 189, 152, 148), icon: Icons.coffee_outlined);

  if (lower.contains('υγεία') || lower.contains('health') || lower.contains('φαρμ') || lower.contains('γιατρ'))
    return CategoryStyle(color: const Color.fromARGB(255, 190, 150, 163), icon: Icons.local_hospital_outlined);

  if (lower.contains('ψυχαγωγ') || lower.contains('entertainment') || lower.contains('κινηματ') || lower.contains('σινεμά'))
    return CategoryStyle(color: const Color.fromARGB(255, 170, 154, 194), icon: Icons.movie_outlined);

  if (lower.contains('ρούχ') || lower.contains('clothes') || lower.contains('shopping'))
    return CategoryStyle(color: const Color.fromARGB(255, 168, 139, 173), icon: Icons.checkroom_outlined);

  if (lower.contains('σπίτι') || lower.contains('home') || lower.contains('ενοίκ') || lower.contains('ηλεκτρ'))
    return CategoryStyle(color: const Color.fromARGB(255, 147, 183, 188), icon: Icons.home_outlined);

  if (lower.contains('sport') || lower.contains('γυμναστ') || lower.contains('αθλητ'))
    return CategoryStyle(color: const Color.fromARGB(255, 147, 185, 150), icon: Icons.fitness_center_outlined);

  if (lower.contains('εκπαίδ') || lower.contains('σχολ') || lower.contains('βιβλ') || lower.contains('education'))
    return CategoryStyle(color: const Color.fromARGB(255, 197, 188, 160), icon: Icons.school_outlined);

  if (lower.contains('ταξίδ') || lower.contains('travel') || lower.contains('ξενοδ'))
    return CategoryStyle(color: const Color.fromARGB(255, 154, 193, 191), icon: Icons.flight_outlined);

  if (lower.contains('τεχνολ') || lower.contains('tech') || lower.contains('ηλεκτρον'))
    return CategoryStyle(color: const Color.fromARGB(255, 144, 150, 186), icon: Icons.devices_outlined);

  //χρώμα βάσει πρώτου γράμματος ώστε κάθε κατηγορία να έχει σταθερό χρώμα
  final colors = [
    CategoryStyle(color: const Color.fromARGB(255, 164, 171, 213), icon: Icons.label_outline),
    CategoryStyle(color: const Color.fromARGB(255, 154, 201, 159), icon: Icons.label_outline),
    CategoryStyle(color: const Color.fromARGB(255, 233, 215, 186), icon: Icons.label_outline),
    CategoryStyle(color: const Color.fromARGB(255, 215, 155, 175), icon: Icons.label_outline),
    CategoryStyle(color: const Color.fromARGB(255, 142, 189, 196), icon: Icons.label_outline),
    CategoryStyle(color: const Color.fromARGB(255, 188, 167, 220), icon: Icons.label_outline),
    CategoryStyle(color: const Color.fromARGB(255, 204, 159, 211), icon: Icons.label_outline),
    CategoryStyle(color: const Color.fromARGB(255, 205, 150, 144), icon: Icons.label_outline),
  ];
  final index = name.isEmpty ? 0 : name.codeUnitAt(0) % colors.length;
  return colors[index];
}